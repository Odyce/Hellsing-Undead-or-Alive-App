import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

/// Section "Rencontré lors de :" affichée sur les fiches PNJ et Monstre.
/// Affiche les [MissionRecord] triés par [MissionRecord.completedAt] croissant
/// (les missions sans date apparaissent en dernier).
/// Chaque ligne est cliquable : on charge la [Mission] complète depuis Firestore
/// puis on navigue vers [Routes.missionSheet].
class MissionHistorySection extends StatelessWidget {
  final List<MissionRecord> missions;

  const MissionHistorySection({super.key, required this.missions});

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _openMission(BuildContext context, int missionId) async {
    final snap = await FirebaseFirestore.instance
        .collection('common')
        .doc('archives')
        .collection('missions')
        .where('id', isEqualTo: missionId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission introuvable.')),
        );
      }
      return;
    }

    final mission = Mission.fromMap(snap.docs.first.data());
    if (context.mounted) {
      Navigator.pushNamed(context, Routes.missionSheet, arguments: mission);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) return const SizedBox.shrink();

    final sorted = [...missions]
      ..sort((a, b) {
        if (a.completedAt == null && b.completedAt == null) return 0;
        if (a.completedAt == null) return 1;
        if (b.completedAt == null) return -1;
        return a.completedAt!.compareTo(b.completedAt!);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rencontré lors de :',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...sorted.map((record) {
          final dateLabel = record.completedAt != null
              ? _formatDate(record.completedAt!)
              : 'Date inconnue';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openMission(context, record.id),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: record.completedAt != null
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
