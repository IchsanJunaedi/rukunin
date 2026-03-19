import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/letter_request_model.dart';
import '../models/complaint_model.dart';
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

    // Gunakan helper yang sudah ada di notifications_provider.dart
    await insertNotification(
      client: client,
      userId: residentId,
      communityId: communityId,
      type: 'letter_request',
      title: 'Update Permohonan Surat',
      body: 'Status permohonan surat kamu diperbarui: ${letterRequestStatusLabels[newStatus] ?? newStatus}',
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
}
