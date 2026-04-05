import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Notification Channel ────────────────────────────────────────────────────

const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'rukunin_high_importance',
  'Notifikasi Rukunin',
  description: 'Tagihan, pengumuman, dan aktivitas komunitas.',
  importance: Importance.high,
);

// ─── FCM Service ─────────────────────────────────────────────────────────────

class FcmService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Callback navigasi — diset dari RukuninApp setelah router siap.
  static void Function(String route)? _navigate;

  static void setNavigate(void Function(String route) navigate) {
    _navigate = navigate;
  }

  /// Panggil sekali saat app start (setelah Firebase.initializeApp).
  static Future<void> initialize() async {
    // 1. Setup flutter_local_notifications
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 2. Buat Android notification channel bertipe high importance
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Tampilkan notifikasi saat app FOREGROUND
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // 4. App dibuka dari notifikasi saat BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

    // 5. App dibuka dari notifikasi saat TERMINATED
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleOpened(initial);
  }

  /// Simpan FCM token ke kolom `fcm_token` di tabel `profiles`.
  /// Panggil setelah user berhasil login.
  static Future<void> saveTokenToProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token}).eq('id', userId);

      // Pantau refresh token secara otomatis
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        final uid = Supabase.instance.client.auth.currentUser?.id;
        if (uid == null) return;
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': newToken}).eq('id', uid);
      });
    } catch (_) {
      // Token saving bersifat best-effort, tidak boleh crash app
    }
  }

  // ── Private handlers ───────────────────────────────────────────────────────

  static Future<void> _handleForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _handleOpened(RemoteMessage message) {
    _navigateFromData(message.data);
  }

  static void _onNotificationTap(NotificationResponse response) {
    try {
      final data = response.payload != null
          ? jsonDecode(response.payload!) as Map<String, dynamic>
          : <String, dynamic>{};
      _navigateFromData(data);
    } catch (_) {
      _navigate?.call('/resident/notifikasi');
    }
  }

  static void _navigateFromData(Map<String, dynamic> data) {
    if (_navigate == null) return;
    final type = data['type'] as String?;
    switch (type) {
      case 'payment' || 'invoice':
        _navigate!('/resident/tagihan');
      case 'announcement':
        _navigate!('/resident/pengumuman');
      default:
        _navigate!('/resident/notifikasi');
    }
  }
}
