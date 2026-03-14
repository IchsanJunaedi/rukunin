import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';

class PaymentSettingsModel {
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final String? qrisUrl;

  PaymentSettingsModel({this.bankName, this.accountNumber, this.accountName, this.qrisUrl});

  factory PaymentSettingsModel.fromMap(Map<String, dynamic> map) {
    return PaymentSettingsModel(
      bankName: map['bank_name'] as String?,
      accountNumber: map['account_number'] as String?,
      accountName: map['account_name'] as String?,
      qrisUrl: map['qris_url'] as String?,
    );
  }
}

class PaymentSettingsNotifier extends AsyncNotifier<PaymentSettingsModel?> {
  @override
  Future<PaymentSettingsModel?> build() async {
    return _fetchSettings();
  }

  Future<PaymentSettingsModel?> _fetchSettings() async {
    final client = ref.read(supabaseClientProvider);
    final profile = await ref.read(currentProfileProvider.future);
    
    if (profile?['community_id'] == null) return null;

    final data = await client
        .from('communities')
        .select('bank_name, account_number, account_name, qris_url')
        .eq('id', profile!['community_id'])
        .maybeSingle();

    if (data == null) return null;
    return PaymentSettingsModel.fromMap(data);
  }

  Future<void> updateSettings({
    required String bankName,
    required String accountNumber,
    required String accountName,
    Uint8List? qrisBytes,
    String? qrisFileExt,
  }) async {
    // Tidak set AsyncLoading di sini — screen sudah handle via _isSaving local state.
    // AsyncLoading di tengah async operation menyebabkan rebuild widget tree
    // yang berpotensi membuat context menjadi deactivated (Navigator assertion error).
    try {
      final client = ref.read(supabaseClientProvider);
      final profile = await ref.read(currentProfileProvider.future);
      final communityId = profile?['community_id'];

      if (communityId == null) throw Exception('Community ID tidak ditemukan');

      String? qrisUrlResult;

      if (qrisBytes != null && qrisFileExt != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${communityId}_qris_$timestamp.$qrisFileExt';
        final mimeType = qrisFileExt == 'png' ? 'image/png' : 'image/jpeg';

        await client.storage.from('community_assets').uploadBinary(
          fileName,
          qrisBytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );
        qrisUrlResult = client.storage.from('community_assets').getPublicUrl(fileName);
      }

      final Map<String, dynamic> updates = {
        'bank_name': bankName,
        'account_number': accountNumber,
        'account_name': accountName,
      };
      if (qrisUrlResult != null) updates['qris_url'] = qrisUrlResult;

      await client.from('communities').update(updates).eq('id', communityId).select().single();

      state = AsyncData(await _fetchSettings());
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow; // biarkan UI catch dan tampilkan error
    }
  }
}

final paymentSettingsProvider = AsyncNotifierProvider<PaymentSettingsNotifier, PaymentSettingsModel?>(PaymentSettingsNotifier.new);
