import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/supabase/supabase_client.dart';

class RegisterService {
  final SupabaseClient client;
  const RegisterService(this.client);

  String _generateCode() {
    // Alfanumerik tanpa huruf/angka yang membingungkan (I, O, 0, 1)
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Admin mendaftar dan membuat komunitas baru.
  /// Returns the generated community_code.
  Future<String> registerAdmin({
    required String communityName,
    required String rwNumber,
    required String adminPhone,
    required String email,
    required String password,
    required String adminFullName,
  }) async {
    // 1. Create auth user
    final response = await client.auth.signUp(email: email, password: password);
    final userId = response.user?.id;
    if (userId == null) throw Exception('Gagal membuat akun. Coba lagi.');

    // 2. Pastikan user punya session aktif (diperlukan agar request DB pakai
    //    authenticated role, bukan anon key). Jika signUp tidak langsung
    //    memberikan session (karena "Confirm email" masih aktif di Supabase),
    //    kita sign in secara eksplisit.
    if (response.session == null) {
      await client.auth.signInWithPassword(email: email, password: password);
    }

    // 3. Generate community ID client-side untuk menghindari .select() setelah insert
    final communityId = const Uuid().v4();
    final code = _generateCode();
    await client.from('communities').insert({
      'id': communityId,
      'name': communityName,
      'rw_number': rwNumber,
      'admin_phone': adminPhone,
      'community_code': code,
    });

    // 4. Insert admin profile
    await client.from('profiles').insert({
      'id': userId,
      'community_id': communityId,
      'full_name': adminFullName,
      'phone': adminPhone,
      'email': email,
      'role': 'admin',
      'status': 'active',
    });

    return code;
  }

  /// Validasi kode komunitas dan return communityId.
  Future<String> checkCommunityCode(String code) async {
    final community = await client
        .from('communities')
        .select('id')
        .eq('community_code', code.toUpperCase().trim())
        .maybeSingle();
    if (community == null) {
      throw Exception('Kode komunitas "$code" tidak ditemukan. Pastikan kode benar.');
    }
    return community['id'] as String;
  }

  /// Warga mendaftar menggunakan communityId yang sudah divalidasi.
  /// Profile dibuat via DB trigger dari user_metadata — tidak butuh session aktif.
  Future<void> registerResident({
    required String communityId,
    required String fullName,
    required String phone,
    required String email,
    required String password,
    String? nik,
    String? unitNumber,
    String? block,
    int? rtNumber,
  }) async {
    // 1. Create auth user + pass profile data sebagai user_metadata.
    //    DB trigger handle_new_user() akan auto-insert ke profiles.
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'community_id': communityId,
        'full_name': fullName,
        'phone': phone,
        'nik': (nik == null || nik.isEmpty) ? null : nik,
        'unit_number': (unitNumber == null || unitNumber.isEmpty) ? null : unitNumber,
        'block': (block == null || block.isEmpty) ? null : block.toUpperCase(),
        'rt_number': rtNumber ?? 1,
      },
    );

    // identities kosong = email sudah terdaftar (Supabase tidak error untuk cegah enumeration)
    if (response.user?.identities?.isEmpty == true) {
      throw Exception('Email sudah terdaftar. Gunakan email lain atau login.');
    }
    if (response.user == null) throw Exception('Gagal membuat akun. Coba lagi.');

    // Sign out agar user tahu harus konfirmasi email (jika fitur aktif)
    // atau tunggu approval admin (status pending).
    await client.auth.signOut();
  }
}

final registerServiceProvider = Provider<RegisterService>((ref) {
  return RegisterService(ref.read(supabaseClientProvider));
});
