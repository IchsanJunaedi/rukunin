import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/billing_type_model.dart';

class BillingTypesNotifier extends AsyncNotifier<List<BillingTypeModel>> {
  @override
  FutureOr<List<BillingTypeModel>> build() async {
    return _fetchBillingTypes();
  }

  Future<List<BillingTypeModel>> _fetchBillingTypes() async {
    final client = ref.read(supabaseClientProvider);
    final profile = await ref.read(currentProfileProvider.future);

    if (profile?['community_id'] == null) {
      return [];
    }

    final data = await client
        .from('billing_types')
        .select()
        .eq('community_id', profile!['community_id'])
        .order('created_at', ascending: true);

    return data.map((map) => BillingTypeModel.fromMap(map)).toList();
  }

  Future<void> addBillingType(BillingTypeModel type) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      final profile = await ref.read(currentProfileProvider.future);

      if (profile?['community_id'] == null) throw Exception('Community ID not found');

      final map = type.toMap();
      map['community_id'] = profile!['community_id'];

      await client.from('billing_types').insert(map);
      return _fetchBillingTypes();
    });
  }

  Future<void> updateBillingType(BillingTypeModel type) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      
      await client
          .from('billing_types')
          .update(type.toMap())
          .eq('id', type.id);
          
      return _fetchBillingTypes();
    });
  }

  Future<void> deleteBillingType(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      try {
        await client.from('billing_types').delete().eq('id', id);
      } on PostgrestException catch (e) {
        if (e.code == '23503') {
          throw Exception('Iuran ini tidak bisa dihapus karena telah digunakan pada Tagihan warga. Silakan ubah status iuran menjadi Nonaktif saja.');
        }
        rethrow;
      }
      return _fetchBillingTypes();
    });
  }
}

final billingTypesProvider =
    AsyncNotifierProvider<BillingTypesNotifier, List<BillingTypeModel>>(
        BillingTypesNotifier.new);
