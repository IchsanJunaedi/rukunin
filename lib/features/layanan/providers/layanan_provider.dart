import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/letter_request_model.dart';
import '../models/complaint_model.dart';
import '../models/community_contact_model.dart';
import '../../notifications/providers/notifications_provider.dart';

// ── Resident: permohonan surat saya ──────────────────────────
final myLetterRequestsProvider =
    FutureProvider.autoDispose<List<LetterRequestModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final res = await client
      .from('letter_requests')
      .select('*, profiles:resident_id(full_name, unit_number)')
      .eq('resident_id', userId)
      .order('created_at', ascending: false);

  return (res as List).map((e) => LetterRequestModel.fromMap(e)).toList();
});

// ── Resident: pengaduan saya ─────────────────────────────────
final myComplaintsProvider =
    FutureProvider.autoDispose<List<ComplaintModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final res = await client
      .from('complaints')
      .select('*, profiles:resident_id(full_name, unit_number)')
      .eq('resident_id', userId)
      .order('created_at', ascending: false);

  return (res as List).map((e) => ComplaintModel.fromMap(e)).toList();
});

// ── Admin: semua permohonan surat ────────────────────────────
final adminLetterRequestsProvider =
    FutureProvider.autoDispose<List<LetterRequestModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final profile = await client
      .from('profiles')
      .select('community_id')
      .eq('id', userId)
      .maybeSingle();
  final communityId = profile?['community_id'] as String?;
  if (communityId == null) return [];

  final res = await client
      .from('letter_requests')
      .select('*, profiles:resident_id(full_name, unit_number)')
      .eq('community_id', communityId)
      .order('created_at', ascending: false);

  return (res as List).map((e) => LetterRequestModel.fromMap(e)).toList();
});

// ── Admin: semua pengaduan ───────────────────────────────────
final adminComplaintsProvider =
    FutureProvider.autoDispose<List<ComplaintModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final profile = await client
      .from('profiles')
      .select('community_id')
      .eq('id', userId)
      .maybeSingle();
  final communityId = profile?['community_id'] as String?;
  if (communityId == null) return [];

  final res = await client
      .from('complaints')
      .select('*, profiles:resident_id(full_name, unit_number)')
      .eq('community_id', communityId)
      .order('created_at', ascending: false);

  return (res as List).map((e) => ComplaintModel.fromMap(e)).toList();
});

// ── Admin: daftar kontak komunitas ────────────────────────────
final adminContactsProvider =
    FutureProvider.autoDispose<List<CommunityContactModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final profile = await client
      .from('profiles')
      .select('community_id')
      .eq('id', userId)
      .maybeSingle();
  final communityId = profile?['community_id'] as String?;
  if (communityId == null) return [];

  final res = await client
      .from('community_contacts')
      .select()
      .eq('community_id', communityId)
      .order('urutan', ascending: true);

  return (res as List).map((e) => CommunityContactModel.fromMap(e)).toList();
});

// ── Resident: daftar kontak komunitas ─────────────────────────
final communityContactsProvider =
    FutureProvider.autoDispose<List<CommunityContactModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return [];

  final profile = await client
      .from('profiles')
      .select('community_id')
      .eq('id', userId)
      .maybeSingle();
  final communityId = profile?['community_id'] as String?;
  if (communityId == null) return [];

  final res = await client
      .from('community_contacts')
      .select()
      .eq('community_id', communityId)
      .order('urutan', ascending: true);

  return (res as List).map((e) => CommunityContactModel.fromMap(e)).toList();
});

// ── Service (mutations) ──────────────────────────────────────
final layananServiceProvider = Provider((ref) => LayananService(ref: ref));

class LayananService {
  final Ref ref;
  const LayananService({required this.ref});

  // Warga buat permohonan surat baru
  Future<void> createLetterRequest({
    required String communityId,
    required String residentId,
    required String letterType,
    String? purpose,
    String? notes,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('letter_requests').insert({
      'community_id': communityId,
      'resident_id': residentId,
      'letter_type': letterType,
      'purpose': purpose,
      'notes': notes,
    });
    ref.invalidate(myLetterRequestsProvider);
  }

  // Warga buat pengaduan baru
  Future<void> createComplaint({
    required String communityId,
    required String residentId,
    required String title,
    required String description,
    required String category,
    String? photoUrl,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('complaints').insert({
      'community_id': communityId,
      'resident_id': residentId,
      'title': title,
      'description': description,
      'category': category,
      'photo_url': photoUrl,
    });
    ref.invalidate(myComplaintsProvider);
  }

  // Admin update status permohonan surat
  Future<void> updateLetterRequestStatus({
    required String requestId,
    required String residentId,
    required String communityId,
    required String newStatus,
    String? adminNotes,
    String? letterId,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('letter_requests').update({
      'status': newStatus,
      if (adminNotes != null) 'admin_notes': adminNotes,
      if (letterId != null) 'letter_id': letterId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);

    String notifBody = 'Status permohonan surat kamu diperbarui: ${letterRequestStatusLabels[newStatus] ?? newStatus}';

    if (newStatus == 'ready') {
      try {
        final adminData = await client
            .from('profiles')
            .select('phone')
            .eq('community_id', communityId)
            .eq('role', 'admin')
            .limit(1)
            .maybeSingle();
        final adminPhone = adminData?['phone'];
        if (adminPhone != null && adminPhone.toString().isNotEmpty) {
          notifBody = 'Surat Anda sudah siap diambil. Silakan kontak admin di nomor: $adminPhone';
        } else {
          notifBody = 'Surat Anda sudah siap diambil. Silakan temui admin/pengurus RW.';
        }
      } catch (_) {
        notifBody = 'Surat Anda sudah siap diambil. Silakan temui admin/pengurus RW.';
      }
    }

    // Gunakan helper yang sudah ada di notifications_provider.dart
    await insertNotification(
      client: client,
      userId: residentId,
      communityId: communityId,
      type: 'letter_request',
      title: 'Update Permohonan Surat',
      body: notifBody,
    );
    ref.invalidate(adminLetterRequestsProvider);
  }

  // Admin update status pengaduan
  Future<void> updateComplaintStatus({
    required String complaintId,
    required String residentId,
    required String communityId,
    required String newStatus,
    String? adminNotes,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('complaints').update(<String, dynamic>{
      'status': newStatus,
      if (adminNotes != null) 'admin_notes': adminNotes,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', complaintId);

    await insertNotification(
      client: client,
      userId: residentId,
      communityId: communityId,
      type: 'complaint',
      title: 'Update Pengaduan',
      body: 'Status pengaduan kamu diperbarui: ${complaintStatusLabels[newStatus] ?? newStatus}',
    );
    ref.invalidate(adminComplaintsProvider);
  }

  // ── Kontak ────────────────────────────────────────────────────

  Future<void> addContact({
    required String communityId,
    required String nama,
    required String jabatan,
    required String phone,
    String? photoUrl,
  }) async {
    final client = ref.read(supabaseClientProvider);

    // Hitung urutan berikutnya
    final existing = await client
        .from('community_contacts')
        .select('urutan')
        .eq('community_id', communityId)
        .order('urutan', ascending: false)
        .limit(1);
    final nextUrutan = existing.isEmpty
        ? 0
        : ((existing.first['urutan'] as int?) ?? 0) + 1;

    await client.from('community_contacts').insert({
      'community_id': communityId,
      'nama': nama,
      'jabatan': jabatan,
      'phone': phone,
      if (photoUrl != null) 'photo_url': photoUrl,
      'urutan': nextUrutan,
      'updated_at': DateTime.now().toIso8601String(),
    });
    ref.invalidate(adminContactsProvider);
  }

  Future<void> updateContact({
    required String id,
    required String nama,
    required String jabatan,
    required String phone,
    String? photoUrl,
  }) async {
    final client = ref.read(supabaseClientProvider);
    // PENTING: photo_url hanya diupdate jika ada nilai baru (tidak null).
    // Ini mencegah foto lama terhapus saat admin tidak mengganti foto.
    await client.from('community_contacts').update({
      'nama': nama,
      'jabatan': jabatan,
      'phone': phone,
      if (photoUrl != null) 'photo_url': photoUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
    ref.invalidate(adminContactsProvider);
  }

  Future<void> deleteContact(String id) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('community_contacts').delete().eq('id', id);
    ref.invalidate(adminContactsProvider);
  }

  /// Swap urutan dua kontak — dua UPDATE sequential.
  Future<void> swapUrutan(
    String idA,
    int urutanA,
    String idB,
    int urutanB,
  ) async {
    final client = ref.read(supabaseClientProvider);
    await client
        .from('community_contacts')
        .update({'urutan': urutanB, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', idA);
    await client
        .from('community_contacts')
        .update({'urutan': urutanA, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', idB);
    ref.invalidate(adminContactsProvider);
  }

  /// Upload foto kontak ke bucket contact_photos, return public URL.
  Future<String> uploadContactPhoto({
    required String communityId,
    required String contactId,
    required List<int> fileBytes,
    required String fileExt,
  }) async {
    final client = ref.read(supabaseClientProvider);
    final path = '$communityId/$contactId.$fileExt';
    await client.storage.from('contact_photos').uploadBinary(
          path,
          Uint8List.fromList(fileBytes),
          fileOptions: FileOptions(upsert: true),
        );
    return client.storage.from('contact_photos').getPublicUrl(path);
  }
}
