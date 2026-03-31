import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.data,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      readAt: map['readAt'] != null
          ? (map['readAt'] as Timestamp).toDate()
          : null,
      data: map['data'] as Map<String, dynamic>?,
    );
  }
}

class NotificationRepository {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notifRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _firestore.collection('users').doc(uid);

  // ─── Stream : liste des notifications, plus récente en premier ───────────────
  Stream<List<AppNotification>> notificationsStream(String uid) {
    return _notifRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ─── Marquer toutes les notifs non lues comme lues ────────────────────────────
  Future<void> markAllAsRead(String uid) async {
    final snap = await _notifRef(uid)
        .where('readAt', isNull: true)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _firestore.batch();
    final now = Timestamp.now();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'readAt': now});
    }
    await batch.commit();
  }

  // ─── Stream : état du toggle notifications ────────────────────────────────────
  Stream<bool> notificationsEnabledStream(String uid) {
    return _userRef(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return true;
      return data['notificationsEnabled'] as bool? ?? true;
    });
  }

  // ─── Persistance du toggle ────────────────────────────────────────────────────
  Future<void> setNotificationsEnabled(String uid, bool enabled) async {
    await _userRef(uid).set(
      {'notificationsEnabled': enabled},
      SetOptions(merge: true),
    );
  }

  // ─── Appelé par OneSignal quand une notification est reçue ───────────────────
  Future<void> saveNotification(
    String uid, {
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final payload = <String, dynamic>{
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'readAt': null,
    };
    if (data != null) payload['data'] = data;
    await _notifRef(uid).add(payload);
  }
}
