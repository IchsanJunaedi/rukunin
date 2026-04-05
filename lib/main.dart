import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/services/fcm_service.dart';

// Background handler wajib top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Notifikasi sudah otomatis muncul dari OS, tidak perlu handling manual
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Firebase hanya untuk mobile (Android/iOS) — tidak support web
  if (!kIsWeb) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await FcmService.initialize();
  }

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await initializeDateFormatting('id_ID', null);

  runApp(
    const ProviderScope(
      child: RukuninApp(),
    ),
  );
}

class RukuninApp extends ConsumerStatefulWidget {
  const RukuninApp({super.key});

  @override
  ConsumerState<RukuninApp> createState() => _RukuninAppState();
}

class _RukuninAppState extends ConsumerState<RukuninApp> {
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    // Simpan FCM token setiap kali user login
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        FcmService.saveTokenToProfile();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Set navigate callback agar FCM bisa navigasi ke screen yang tepat
    FcmService.setNavigate((route) => router.go(route));

    return MaterialApp.router(
      title: 'Rukunin',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
