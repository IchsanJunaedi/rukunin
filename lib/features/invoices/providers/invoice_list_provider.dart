import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../models/invoice_model.dart';

// State untuk filter bulan & tahun
class InvoiceMonthFilterNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().month;
  void setMonth(int month) => state = month;
}
final invoiceMonthFilterProvider = NotifierProvider<InvoiceMonthFilterNotifier, int>(
    InvoiceMonthFilterNotifier.new);

class InvoiceYearFilterNotifier extends Notifier<int> {
  @override
  int build() => DateTime.now().year;
  void setYear(int year) => state = year;
}
final invoiceYearFilterProvider = NotifierProvider<InvoiceYearFilterNotifier, int>(
    InvoiceYearFilterNotifier.new);

class InvoiceListNotifier extends AsyncNotifier<List<InvoiceModel>> {
  @override
  Future<List<InvoiceModel>> build() async {
    return _fetchInvoices();
  }

  Future<List<InvoiceModel>> _fetchInvoices() async {
    final client = ref.read(supabaseClientProvider);
    final profile = await ref.read(currentProfileProvider.future);
    final month = ref.read(invoiceMonthFilterProvider);
    final year = ref.read(invoiceYearFilterProvider);

    if (profile?['community_id'] == null) {
      return [];
    }

    final data = await client
        .from('invoices')
        .select('*, billing_types(name), profiles:resident_id(full_name, unit_number, phone)')
        .eq('community_id', profile!['community_id'])
        .eq('month', month)
        .eq('year', year)
        .order('created_at', ascending: false);

    // Menerapkan relasi custom ke model karena fetch join
    return data.map((map) {
      return InvoiceModel.fromJson(map);
    }).toList();
  }

  Future<void> generateBulkInvoices({
    required String billingTypeId,
    required double amount,
    required DateTime dueDate,
    required int month,
    required int year,
    double costPerMotorcycle = 0,
    double costPerCar = 0,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      final profile = await ref.read(currentProfileProvider.future);
      final communityId = profile?['community_id'];

      if (communityId == null) throw Exception('Community ID not found');

      // 1. Ambil daftar Resident beserta data kendaraan
      final residents = await client
          .from('profiles')
          .select('id, motorcycle_count, car_count')
          .eq('community_id', communityId)
          .eq('role', 'resident');

      if (residents.isEmpty) {
        throw Exception('Tidak ada warga terdaftar di sistem. Tagihan tidak bisa diterbitkan.');
      }

      // 2. Ambil tagihan yang sudah ada untuk bulan & jenis iuran ini
      final existingInvoices = await client
          .from('invoices')
          .select('resident_id')
          .eq('community_id', communityId)
          .eq('billing_type_id', billingTypeId)
          .eq('month', month)
          .eq('year', year);

      final existingResidentIds = existingInvoices.map((e) => e['resident_id'].toString()).toSet();

      // 3. Filter warga yang belum ditagih
      final residentsToBill = residents.where((r) => !existingResidentIds.contains(r['id'].toString())).toList();

      if (residentsToBill.isEmpty) {
        throw Exception('Semua warga sudah memiliki tagihan jenis ini pada periode tersebut.');
      }

      // 4. Siapkan data list dengan kalkulasi nominal dinamis per warga
      final now = DateTime.now().toIso8601String();

      final List<Map<String, dynamic>> invoicesData = residentsToBill.map((r) {
        final motorCount = (r['motorcycle_count'] as int?) ?? 0;
        final carCount = (r['car_count'] as int?) ?? 0;
        
        // Kalkulasi: Tarif Dasar + (Jumlah Motor * Tarif Per Motor) + (Jumlah Mobil * Tarif Per Mobil)
        final totalAmount = amount + (motorCount * costPerMotorcycle) + (carCount * costPerCar);
        
        return {
          'community_id': communityId,
          'resident_id': r['id'],
          'billing_type_id': billingTypeId,
          'amount': totalAmount,
          'month': month,
          'year': year,
          'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
          'status': 'pending',
          'created_at': now,
        };
      }).toList();

      // 3. Bulk Insert
      await client.from('invoices').insert(invoicesData);

      // Refresh data
      return _fetchInvoices();
    });
  }
  
  // Future Raw Map List + Info Warga untuk detail screen
  Future<List<Map<String, dynamic>>> fetchInvoicesWithResident() async {
     final client = ref.read(supabaseClientProvider);
    final profile = await ref.read(currentProfileProvider.future);
    final month = ref.read(invoiceMonthFilterProvider);
    final year = ref.read(invoiceYearFilterProvider);

    if (profile?['community_id'] == null) {
      return [];
    }

    final data = await client
        .from('invoices')
        .select('*, billing_types(name), profiles:resident_id(full_name, unit_number, phone)')
        .eq('community_id', profile!['community_id'])
        .eq('month', month)
        .eq('year', year)
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchInvoices());
  }

  Future<void> markInvoiceAsPaid(String invoiceId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);

      // 1. Ambil data invoice untuk dicatat ke tabel payments
      final invoiceData = await client
          .from('invoices')
          .select('amount, community_id, resident_id, profiles:resident_id(full_name, phone)')
          .eq('id', invoiceId)
          .single();

      // 2. Update status invoice → paid
      await client
          .from('invoices')
          .update({
            'status': 'paid',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invoiceId);

      // 3. Catat riwayat pembayaran ke tabel payments
      await client.from('payments').insert({
        'invoice_id': invoiceId,
        'community_id': invoiceData['community_id'],
        'amount': invoiceData['amount'],
        'method': 'manual_transfer',
        'paid_at': DateTime.now().toIso8601String(),
      });

      // 3b. Insert notifikasi in-app ke warga (best-effort)
      final residentId = invoiceData['resident_id']?.toString();
      if (residentId != null) {
        await insertNotification(
          client: client,
          communityId: invoiceData['community_id'] as String,
          userId: residentId,
          type: 'payment',
          title: 'Pembayaran Dikonfirmasi',
          body: 'Tagihan Anda telah diverifikasi dan dinyatakan lunas.',
          metadata: {'invoice_id': invoiceId},
        );
      }

      // 4. Kirim WA konfirmasi ke warga (best-effort, tidak gagalkan proses)
      try {
        final phone = invoiceData['profiles']?['phone']?.toString();
        final name = invoiceData['profiles']?['full_name'] ?? 'Bapak/Ibu';
        if (phone != null && phone.isNotEmpty) {
          final amount = double.tryParse(invoiceData['amount'].toString()) ?? 0;
          final nominal = 'Rp ${amount.toInt()}';
          final message =
              'Halo *$name*,\n\nPembayaran Anda sebesar *$nominal* telah dikonfirmasi dan dinyatakan *Lunas* ✅\n\nTerima kasih!';
          final session = client.auth.currentSession;
          await client.functions.invoke(
            'send-whatsapp',
            headers: session?.accessToken != null
                ? {'Authorization': 'Bearer ${session!.accessToken}'}
                : null,
            body: {'target': phone, 'message': message},
          );
        }
      } catch (_) {
        // WA konfirmasi bersifat best-effort, tidak gagalkan verifikasi
      }

      return _fetchInvoices();
    });
  }

  Future<void> markAsAwaitingVerification(String invoiceId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('invoices')
          .update({'status': 'awaiting_verification'})
          .eq('id', invoiceId);
      return _fetchInvoices();
    });
  }

  Future<void> rejectInvoice(String invoiceId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('invoices')
          .update({'status': 'pending'})
          .eq('id', invoiceId);
      return _fetchInvoices();
    });
  }

  Future<Map<String, dynamic>> broadcastInvoicesWhatsApp() async {
    int successCount = 0;
    int failCount = 0;
    String lastError = '';
    
    final client = ref.read(supabaseClientProvider);
    final profile = await ref.read(currentProfileProvider.future);
    final communityId = profile?['community_id'];

    if (communityId == null) throw Exception('Community ID not found');

    // Ambil payment settings / info komunitas
    final commData = await client
        .from('communities')
        .select('name, bank_name, account_number, account_name, qris_url')
        .eq('id', communityId)
        .maybeSingle();

    if (commData == null) throw Exception('Data RW tidak ditemukan');

    final rwName = commData['name'] ?? 'Pengurus RW';
    final bankInfo = commData['bank_name'] != null 
        ? '\nBank ${commData['bank_name']}\nNo. Rek: ${commData['account_number']}\na/n: ${commData['account_name']}'
        : '';
    final qrisInfo = commData['qris_url'] != null ? '\nLink QRIS: ${commData['qris_url']}' : '';

    // Ambil tagihan pending & overdue bulan ini
    final month = ref.read(invoiceMonthFilterProvider);
    final year = ref.read(invoiceYearFilterProvider);
    
    final invoices = await client
        .from('invoices')
        .select('*, billing_types(name), profiles:resident_id(full_name, phone)')
        .eq('community_id', communityId)
        .eq('month', month)
        .eq('year', year)
        .or('status.eq.pending,status.eq.overdue'); 

    if (invoices.isEmpty) throw Exception('Tidak ada tagihan tertunda bulan ini.');

    for (final inv in invoices) {
      final phone = inv['profiles']?['phone']?.toString();
      if (phone == null || phone.isEmpty) {
        failCount++;
        continue;
      }
      
      final fullName = inv['profiles']?['full_name'] ?? 'Bapak/Ibu Warga';
      final billingName = inv['billing_types']?['name'] ?? 'Iuran';
      final amount = double.tryParse(inv['amount'].toString()) ?? 0;
      
      final nominal = 'Rp ${amount.toInt()}';

      final message = 'Halo *$fullName*,\nIni adalah pesan dari $rwName.\n\nBerikut rincian tagihan *$billingName* Anda untuk bulan $month tahun $year:\nTotal Tagihan: *$nominal*\n\nSilakan lakukan pembayaran ke:$bankInfo$qrisInfo\n\nJika sudah membayar, abaikan pesan ini atau konfirmasi mandiri ke admin. Terima kasih.';

      try {
        final session = client.auth.currentSession;
        final token = session?.accessToken;
        
        final response = await client.functions.invoke('send-whatsapp', 
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
          body: {
            'target': phone,
            'message': message,
          },
        );
        
        // Edge Function selalu return 200. Cek field 'success' di body.
        final isSuccess = response.data != null && response.data['success'] == true;
        if (isSuccess) {
          successCount++;
        } else {
          failCount++;
          lastError = response.data?['error']?.toString() ?? 'Unknown error';
        }
      } catch (e) {
        failCount++;
        lastError = e.toString();
      }
    }
    
    return {'success': successCount, 'fail': failCount, 'lastError': lastError};
  }
}

final invoiceListProvider =
    AsyncNotifierProvider<InvoiceListNotifier, List<InvoiceModel>>(
        InvoiceListNotifier.new);

// Provider terpisah untuk fetch join map supaya gampang nampilin nama warga
// Dilengkapi Supabase Realtime agar UI admin ter-update otomatis
final invoiceWithResidentProvider =
  FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final month = ref.watch(invoiceMonthFilterProvider);
      final year = ref.watch(invoiceYearFilterProvider);
      final client = ref.watch(supabaseClientProvider);

      // Realtime: invalidate diri sendiri saat ada perubahan di tabel invoices
      final channel = client.channel('admin_invoices_rt_${month}_$year');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'invoices',
        callback: (_) => ref.invalidateSelf(),
      ).subscribe();
      ref.onDispose(() => client.removeChannel(channel));

      final notifier = ref.read(invoiceListProvider.notifier);
      return notifier.fetchInvoicesWithResident();
});
