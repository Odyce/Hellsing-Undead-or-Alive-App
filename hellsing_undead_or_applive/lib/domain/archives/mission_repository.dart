import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hellsing_undead_or_applive/domain/archives/missions_model.dart';

class MissionRepository {
  final FirebaseFirestore _firestore;

  MissionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calcule le prochain ID disponible dans common/archives/missions
  Future<int> _getNextMissionId() async {
    final snapshot = await _firestore
        .collection('common')
        .doc('archives')
        .collection('missions')
        .get();

    int maxId = -1;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final id = data['id'];
      if (id is int && id > maxId) maxId = id;
    }

    return maxId + 1; // → 0 si aucune mission
  }

  /// Crée une Mission dans common/archives/missions
  Future<void> createMission({
    required String title,
    String? notesForDM,
    required String descriptionIntro,
    String? descriptionOutro,
    String? illustrationPath,
    required Difficulty difficulty,
    required CladName clad,
    required DateTime postedAt,
    DateTime? playedAt,
    DateTime? completedAt,
    required int bounty,
    List<String>? reportPaths,
    required bool urgent,
  }) async {
    final nextId = await _getNextMissionId();

    final mission = Mission(
      id: nextId,
      title: title,
      notesForDM: notesForDM,
      descriptionIntro: descriptionIntro,
      descriptionOutro: descriptionOutro,
      illustrationPath: illustrationPath,
      difficulty: difficulty,
      clad: clad,
      postedAt: postedAt,
      playedAt: playedAt,
      completedAt: completedAt,
      agentInvolved: null,   // TODO: implémenter quand la DB sera prête
      pnjInvolved: null,     // TODO: implémenter quand la DB sera prête
      monsterInvolved: null, // TODO: implémenter quand la DB sera prête
      bounty: bounty,
      reportPaths: reportPaths,
      agentDeceased: null,   // TODO: implémenter quand la DB sera prête
      urgent: urgent,
    );

    await _firestore
        .collection('common')
        .doc('archives')
        .collection('missions')
        .add(mission.toMap());
  }
}
