import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../invoices/models/invoice_model.dart';
import '../../residents/models/resident_model.dart';

class PaymentInfoModel {
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final String? qrisUrl;

  PaymentInfoModel({this.bankName, this.accountNumber, this.accountName, this.qrisUrl});

  factory PaymentInfoModel.fromMap(Map<String, dynamic> map) => PaymentInfoModel(
        bankName: map['bank_name'] as String?,
        accountNumber: map['account_number'] as String?,
        accountName: map['account_name'] as String?,
        qrisUrl: map['qris_url'] as String?,
      );

  bool get hasBank =>
      bankName != null && bankName!.isNotEmpty && accountNumber != null && accountNumber!.isNotEmpty;
  bool get hasQris => qrisUrl != null && qrisUrl!.isNotEmpty;
  bool get hasAnyMethod => hasBank || hasQris;
}

// Provider untuk data user warga yang sedang login
final currentResidentProfileProvider = FutureProvider.autoDispose<ResidentModel?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;

  final res = await client
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();

  if (res == null) return null;
  return ResidentModel.fromMap(res);
});

// Provider khusus untuk mengambil tagihan milik warga yang sedang login (resident_id = currentUser.id)
// Dilengkapi Supabase Realtime agar status tagihan ter-update otomatis (e.g. dikonfirmasi admin)
final residentInvoicesProvider = FutureProvider.autoDispose<List<InvoiceModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final residentProfile = await ref.watch(currentResidentProfileProvider.future);

  if (residentProfile == null) return [];

  // Realtime: dengarkan perubahan di invoice milik warga ini saja
  final channel = client.channel('resident_invoices_rt_${residentProfile.id}');
  channel.onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'invoices',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'resident_id',
      value: residentProfile.id,
    ),
    callback: (_) => ref.invalidateSelf(),
  ).subscribe();
  ref.onDispose(() => client.removeChannel(channel));

  final res = await client
      .from('invoices')
      .select('''
        *,
        billing_types (
          id,
          name,
          amount,
          is_active
        )
      ''')
      .eq('resident_id', residentProfile.id)
      .order('created_at', ascending: false);

  return (res as List).map((e) => InvoiceModel.fromJson(e)).toList();
});

// Provider untuk fetch info pembayaran komunitas (rekening + QRIS) — dipakai di resident invoices screen
final residentCommunityPaymentProvider = FutureProvider.autoDispose<PaymentInfoModel?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final residentProfile = await ref.watch(currentResidentProfileProvider.future);
  if (residentProfile?.communityId == null) return null;

  final data = await client
      .from('communities')
      .select('bank_name, account_number, account_name, qris_url')
      .eq('id', residentProfile!.communityId!)
      .maybeSingle();

  if (data == null) return null;
  return PaymentInfoModel.fromMap(data);
});

// Ringkasan: Sisa total tagihan yang belum lunas (pending, overdue, awaiting_verification)
final residentTotalPendingInvoicesProvider = Provider.autoDispose<double>((ref) {
  final invoices = ref.watch(residentInvoicesProvider).value ?? [];
  return invoices
      .where((inv) =>
          inv.status == 'pending' ||
          inv.status == 'overdue' ||
          inv.status == 'awaiting_verification')
      .fold(0.0, (sum, inv) => sum + inv.amount);
});
