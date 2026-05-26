import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class NotificationMenuPage extends StatefulWidget {
  const NotificationMenuPage({super.key});

  @override
  State<NotificationMenuPage> createState() => _NotificationMenuPageState();
}

class _NotificationMenuPageState extends State<NotificationMenuPage> {
  final _repository = NotificationRepository();
  String? _uid;

  bool? _enabled;
  Future<List<AppNotification>>? _notifsFuture;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid != null) {
      _repository.markAllAsRead(_uid!);
      _loadEnabled();
      _notifsFuture = _repository.getNotifications(_uid!);
    }
  }

  Future<void> _loadEnabled() async {
    if (_uid == null) return;
    final val = await _repository.getNotificationsEnabled(_uid!);
    if (mounted) setState(() => _enabled = val);
  }

  Future<void> _toggleNotifications() async {
    if (_uid == null || _enabled == null) return;
    final next = !_enabled!;
    setState(() => _enabled = next);
    await _repository.setNotificationsEnabled(_uid!, next);
  }

  static String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    if (_uid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: Text('Notifications', style: GoogleFonts.cinzelDecorative()),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  (_enabled ?? true)
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  size: 18,
                  color: (_enabled ?? true) ? null : Colors.grey,
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _enabled ?? true,
                  onChanged: _enabled == null ? null : (_) => _toggleNotifications(),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

            // ── Liste des notifications ───────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _notifsFuture = _repository.getNotifications(_uid!);
                  });
                },
                child: FutureBuilder<List<AppNotification>>(
                  future: _notifsFuture,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final notifs = snap.data ?? [];
                    if (notifs.isEmpty) {
                      return ListView(
                        children: const [
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text(
                                'Aucune notification',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: notifs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => _NotifTile(
                        notif: notifs[i],
                        formatDate: _formatDate,
                      ),
                    );
                  },
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// ─── Tuile d'une notification ─────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  final String Function(DateTime) formatDate;

  const _NotifTile({required this.notif, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final unread = !notif.isRead;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: unread ? scheme.primaryContainer.withAlpha(80) : null,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Indicateur non-lu ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 10),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unread ? scheme.primary : Colors.transparent,
              ),
            ),
          ),

          // ── Titre + corps ───────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif.title,
                  style: TextStyle(
                    fontWeight:
                        unread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (notif.body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notif.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withAlpha(180),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Date ────────────────────────────────────────────────────────────
          const SizedBox(width: 8),
          Text(
            formatDate(notif.createdAt),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
