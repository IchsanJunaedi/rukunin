import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/utils/letter_pdf_generator.dart';
import '../models/letter_request_model.dart';
import '../models/complaint_model.dart';
import '../models/community_contact_model.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../letters/providers/letter_provider.dart';

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

  return res.map((e) => LetterRequestModel.fromMap(e)).toList();
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
    required String applicantName,
    required Map<String, dynamic> formData,
    String? purpose,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('letter_requests').insert({
      'community_id': communityId,
      'resident_id': residentId,
      'letter_type': letterType,
      'applicant_name': applicantName,
      'form_data': formData,
      'purpose': ?purpose,
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
      'admin_notes': ?adminNotes,
      'letter_id': ?letterId,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);

    String notifBody = 'Status permohonan surat kamu diperbarui: ${letterRequestStatusLabels[newStatus] ?? newStatus}';

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
      'admin_notes': ?adminNotes,
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
      'photo_url': ?photoUrl,
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
      'photo_url': ?photoUrl,
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

  // ── Helpers ────────────────────────────────────────────────────

  static String _computeAge(String? ttl) {
    if (ttl == null || ttl.isEmpty) return '-';
    final parts = ttl.split(',');
    if (parts.length < 2) return '-';
    try {
      final dateParts = parts.last.trim().split('-');
      if (dateParts.length != 3) return '-';
      final dob = DateTime(
        int.parse(dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
      );
      final age = DateTime.now().difference(dob).inDays ~/ 365;
      return '$age tahun';
    } catch (_) {
      return '-';
    }
  }

  static String? _extractPurpose(String letterType, Map<String, dynamic> formData) {
    if (letterType == 'kematian') return null;
    if (letterType == 'sktm') return formData['alasan'] as String?;
    return formData['keperluan'] as String?;
  }

  // ── Mutations: Admin verifikasi & tolak ────────────────────────

  Future<void> rejectRequest({
    required String requestId,
    required String residentId,
    required String communityId,
    required String alasan,
  }) async {
    final client = ref.read(supabaseClientProvider);
    await client
        .from('letter_requests')
        .update({
          'status': 'rejected',
          'admin_notes': alasan,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('community_id', communityId);

    await insertNotification(
      client: client,
      userId: residentId,
      communityId: communityId,
      type: 'letter_request',
      title: 'Permohonan Surat Ditolak',
      body: 'Permohonan surat kamu ditolak. Alasan: $alasan',
    );
    ref.invalidate(adminLetterRequestsProvider);
    ref.invalidate(myLetterRequestsProvider);
  }

  Future<void> verifyAndGenerateLetter({
    required LetterRequestModel request,
  }) async {
    final client = ref.read(supabaseClientProvider);

    // 1. Fetch profil admin untuk community_id
    final adminProfile = await client
        .from('profiles')
        .select('community_id')
        .eq('id', client.auth.currentUser!.id)
        .single();
    final communityId = adminProfile['community_id'] as String;

    // 2. Fetch data komunitas (rw_number dan info lokasi)
    final communityData = await client
        .from('communities')
        .select('name, rw_number, kelurahan, kecamatan, kabupaten, province, leader_name')
        .eq('id', communityId)
        .single();

    // 3. Fetch profil resident untuk rt_number (rt_number ada di profiles, bukan communities)
    final residentProfile = await client
        .from('profiles')
        .select('rt_number')
        .eq('id', request.residentId)
        .maybeSingle();

    final fd = request.formData ?? {};
    final letterType = request.letterType;

    // 4. Mapping form_data → getTemplate() parameters
    final isKematian = letterType == 'kematian';

    final residentNik = isKematian
        ? (fd['nik_almarhum'] as String? ?? '-')
        : (fd['nik'] as String? ?? '-');

    final ttlRaw = isKematian
        ? fd['ttl_almarhum'] as String?
        : fd['ttl'] as String?;
    final residentAge = _computeAge(ttlRaw);

    final noGenderTypes = {'ktp_kk', 'sktm', 'kematian', 'custom'};
    final residentGender = noGenderTypes.contains(letterType)
        ? '-'
        : (fd['gender'] as String? ?? '-');

    final rw = communityData['rw_number']?.toString() ?? '01';
    // rt_number dari profil warga (bukan communities)
    final rt = residentProfile?['rt_number']?.toString() ?? '01';
    final kelurahan = communityData['kelurahan'] as String? ?? '';
    final kecamatan = communityData['kecamatan'] as String? ?? '';
    final kabupaten = communityData['kabupaten'] as String? ?? '';

    final residentAddress = 'RT $rt/RW $rw, Kel. $kelurahan, Kec. $kecamatan, $kabupaten';
    final purpose = _extractPurpose(letterType, fd);

    final generatedContent = LetterPdfGenerator.getTemplate(
      letterType: letterType,
      residentName: request.applicantName ?? '-',
      residentNik: residentNik,
      residentAge: residentAge,
      residentGender: residentGender,
      residentAddress: residentAddress,
      rtNumber: rt,
      rwNumber: rw,
      village: kelurahan,
      district: kecamatan,
      city: kabupaten,
      purpose: purpose,
    );

    // 4. Generate nomor surat
    final now = DateTime.now();
    final roman = ['I','II','III','IV','V','VI','VII','VIII','IX','X','XI','XII'];
    final letterNumber = '${now.millisecondsSinceEpoch % 1000}/RW-$rw/${roman[now.month - 1]}/${now.year}';

    // 5. Insert ke tabel letters
    final inserted = await client.from('letters').insert({
      'community_id': communityId,
      'resident_id': request.residentId,
      'letter_type': letterType,
      'letter_number': letterNumber,
      'purpose': purpose,
      'generated_content': generatedContent,
      'status': 'done',
    }).select('id').single();

    final letterId = inserted['id'] as String;

    // 6. Update status request ke verified
    await client
        .from('letter_requests')
        .update({
          'status': 'verified',
          'letter_id': letterId,
          'updated_at': now.toIso8601String(),
        })
        .eq('id', request.id)
        .eq('community_id', communityId);

    // 7. Notifikasi warga
    await insertNotification(
      client: client,
      userId: request.residentId,
      communityId: communityId,
      type: 'letter_request',
      title: 'Surat Kamu Sudah Siap',
      body: 'Surat ${request.typeLabel} kamu sudah diverifikasi dan siap diunduh.',
    );

    ref.invalidate(adminLetterRequestsProvider);
    ref.invalidate(myLetterRequestsProvider);
    ref.invalidate(myLettersProvider); // resident document list di ResidentLettersScreen
  }
}
