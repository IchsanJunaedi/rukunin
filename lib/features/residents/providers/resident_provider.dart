import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/supabase/supabase_client.dart';
import '../models/resident_model.dart';
import '../models/family_member.dart';

const _uuid = Uuid();

final residentsProvider =
    FutureProvider.autoDispose<List<ResidentModel>>((ref) async {
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

  final data = await client
      .from('profiles')
      .select()
      .eq('community_id', communityId)
      .eq('role', 'resident')
      .neq('status', 'pending')
      .order('full_name');

  return data.map((e) => ResidentModel.fromMap(e)).toList();
});

/// Warga dengan status 'pending' — menunggu persetujuan admin
final pendingResidentsProvider =
    FutureProvider.autoDispose<List<ResidentModel>>((ref) async {
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

  final data = await client
      .from('profiles')
      .select()
      .eq('community_id', communityId)
      .eq('role', 'resident')
      .eq('status', 'pending')
      .order('created_at');

  return data.map((e) => ResidentModel.fromMap(e)).toList();
});

class ResidentNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addResident({
    required String fullName,
    required String unitNumber,
    required String phone,
    required String nik,
    required int rtNumber,
    required String block,
    int motorcycleCount = 0,
    int carCount = 0,
    List<FamilyMember> familyMembers = const [],
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Tidak terautentikasi');

      final profile = await client
          .from('profiles')
          .select('community_id')
          .eq('id', userId)
          .maybeSingle();
      final communityId = profile?['community_id'] as String?;
      if (communityId == null) throw Exception('Community tidak ditemukan');

      final newResidentId = _uuid.v4();
      await client.from('profiles').insert({
        'id': newResidentId,
        'community_id': communityId,
        'full_name': fullName,
        'unit_number': unitNumber,
        'phone': phone,
        'nik': nik.isEmpty ? null : nik,
        'rt_number': rtNumber,
        'block': block.toUpperCase(),
        'role': 'resident',
        'status': 'active',
        'motorcycle_count': motorcycleCount,
        'car_count': carCount,
      });

      if (familyMembers.isNotEmpty) {
        final familyData = familyMembers.map((m) => {
              'resident_id': newResidentId,
              'full_name': m.fullName,
              'nik': m.nik?.isEmpty == true ? null : m.nik,
              'relationship': m.relationship,
            }).toList();
        await client.from('family_members').insert(familyData);
      }
    });
    ref.invalidate(residentsProvider);
  }

  Future<void> updateResident({
    required String id,
    required String fullName,
    required String unitNumber,
    required String phone,
    required String nik,
    required String status,
    required int rtNumber,
    required String block,
    int motorcycleCount = 0,
    int carCount = 0,
    List<FamilyMember> familyMembers = const [],
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.from('profiles').update({
        'full_name': fullName,
        'unit_number': unitNumber,
        'phone': phone,
        'nik': nik.isEmpty ? null : nik,
        'status': status,
        'rt_number': rtNumber,
        'block': block.toUpperCase(),
        'motorcycle_count': motorcycleCount,
        'car_count': carCount,
      }).eq('id', id);

      // Sinkronisasi data anggota keluarga: hapus yg lama, insert yg baru 
      // (Bisa diperbaiki jadi upsert ke depannya, ini cara paling simple)
      await client.from('family_members').delete().eq('resident_id', id);
      
      if (familyMembers.isNotEmpty) {
        final familyData = familyMembers.map((m) => {
              'resident_id': id,
              'full_name': m.fullName,
              'nik': m.nik?.isEmpty == true ? null : m.nik,
              'relationship': m.relationship,
            }).toList();
        await client.from('family_members').insert(familyData);
      }
    });
    ref.invalidate(residentsProvider);
  }

  Future<void> deleteResident(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.from('profiles').delete().eq('id', id);
    });
    ref.invalidate(residentsProvider);
  }

  Future<void> approveResident(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client
          .from('profiles')
          .update({'status': 'active'})
          .eq('id', id);
    });
    ref.invalidate(residentsProvider);
    ref.invalidate(pendingResidentsProvider);
  }

  Future<void> rejectResident(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      // Hapus profil — user auth tetap ada tapi tidak bisa masuk ke komunitas
      await client.from('profiles').delete().eq('id', id);
    });
    ref.invalidate(pendingResidentsProvider);
  }

  Future<void> importCsv(List<Map<String, dynamic>> residents) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) throw Exception('Tidak terautentikasi');

      final profile = await client
          .from('profiles')
          .select('community_id')
          .eq('id', userId)
          .maybeSingle();
      final communityId = profile?['community_id'] as String?;
      if (communityId == null) throw Exception('Community tidak ditemukan');

      final recordsToInsert = residents.map((r) => {
            'id': _uuid.v4(),
            'community_id': communityId,
            'full_name': r['full_name'],
            'unit_number': r['unit_number'],
            'phone': r['phone'],
            'nik': r['nik'],
            'rt_number': r['rt_number'] ?? 1,
            'block': (r['block'] ?? '').toString().toUpperCase(),
            'role': 'resident',
            'status': 'active',
          }).toList();

      if (recordsToInsert.isNotEmpty) {
        await client.from('profiles').insert(recordsToInsert);
      }
    });
    ref.invalidate(residentsProvider);
  }
}

final residentNotifierProvider =
    AsyncNotifierProvider<ResidentNotifier, void>(ResidentNotifier.new);
