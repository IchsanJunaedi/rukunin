import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../providers/resident_invoices_provider.dart';

final uploadPaymentProofProvider = Provider((ref) => UploadPaymentProofService(ref));

class UploadPaymentProofService {
  final Ref _ref;
  UploadPaymentProofService(this._ref);

  Future<void> uploadProof(String invoiceId, Uint8List bytes, String fileName) async {
    final client = _ref.read(supabaseClientProvider);
    try {
      final ext = fileName.contains('.') ? '.${fileName.split('.').last}' : '.jpg';
      final filePath = 'proofs/proof_${invoiceId}_${DateTime.now().millisecondsSinceEpoch}$ext';

      // 1. Upload ke Storage Bucket "payment_proofs" (cross-platform via binary)
      await client.storage.from('payment_proofs').uploadBinary(filePath, bytes);

      // 2. Dapatkan public URL
      final publicUrl = client.storage
          .from('payment_proofs')
          .getPublicUrl(filePath);

      // 3. Update tabel invoices: set status = 'awaiting_verification' dan proof_url
      await client.from('invoices').update({
        'status': 'awaiting_verification',
        'proof_url': publicUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', invoiceId);

      // 4. Invalidate provider list invoice agar me-refresh UI
      _ref.invalidate(residentInvoicesProvider);
      
    } catch (e) {
      throw Exception('Gagal mengunggah bukti pembayaran: $e');
    }
  }
}
