import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

// Flag apakah sedang dalam mode recovery (reset password via link email)
class RecoveryModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setRecovery(bool value) => state = value;
}

final recoveryModeProvider =
    NotifierProvider<RecoveryModeNotifier, bool>(RecoveryModeNotifier.new);

// Stream auth state — dipakai router untuk redirect
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

// Data profil user yang sedang login
final currentProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;

  final data = await client
      .from('profiles')
      .select()
      .eq('id', userId)
      .maybeSingle();

  return data;
});

// Notifier untuk aksi login & logout
class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> _saveFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      final client = ref.read(supabaseClientProvider);
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      await client.from('profiles').update({'fcm_token': token}).eq('id', userId);
    } catch (_) {
      // FCM token save is best-effort
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      await _saveFcmToken();
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signOut();
    });
  }

  Future<void> sendPasswordReset({required String email}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'rukunin://reset-password',
      );
    });
  }

  Future<void> updatePassword({required String newPassword}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final client = ref.read(supabaseClientProvider);
      await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    });
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
