import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  bool _initialized = false;

  // ─── Initialisation du plugin natif ────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // flutter_local_notifications ne supporte pas Windows
    if (!kIsWeb && Platform.isWindows) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Ouvrir',
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(initSettings);

    // Android 13+ : demander la permission notifications
    if (!kIsWeb && Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  // ─── Démarrer l'écoute Firestore pour un utilisateur ───────────────────────
  void startListening(String uid) {
    if (!kIsWeb && Platform.isWindows) return;
    _sub?.cancel();

    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('readAt', isNull: true)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;
          _showNotification(
            id: change.doc.id.hashCode,
            title: data['title'] as String? ?? '',
            body: data['body'] as String? ?? '',
          );
        }
      }
    });
  }

  // ─── Arrêter l'écoute (logout) ─────────────────────────────────────────────
  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  // ─── Afficher une notification native ──────────────────────────────────────
  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'hellsing_notifications',
      'Notifications Hellsing',
      channelDescription: 'Notifications de l\'application Hellsing',
      importance: Importance.high,
      priority: Priority.high,
    );

    const linuxDetails = LinuxNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      linux: linuxDetails,
    );

    await _plugin.show(id, title, body, details);
  }
}
