import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/domain/stats/stats_repository.dart';

// ─── MissionRepository ────────────────────────────────────────────────────────

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

    return maxId + 1;
  }

  /// Référence vers la collection missions
  CollectionReference<Map<String, dynamic>> get _missionsRef =>
      _firestore.collection('common').doc('archives').collection('missions');

  /// Crée une Mission dans common/archives/missions
  Future<void> createMission({
    required String title,
    String? notesForDM,
    required String descriptionIntro,
    String? descriptionOutro,
    String? illustrationPath,
    required Difficulty difficulty,
    required CladeName clade,
    required DateTime postedAt,
    DateTime? playedAt,
    DateTime? completedAt,
    List<Agent>? agentInvolved,
    List<PNJ>? pnjInvolved,
    List<Monster>? monsterInvolved,
    List<Agent>? agentDeceased,
    required int bountyMin,
    required int bountyMax,
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
      clade: clade,
      postedAt: postedAt,
      playedAt: playedAt,
      completedAt: completedAt,
      agentInvolved: agentInvolved,
      pnjInvolved: pnjInvolved,
      monsterInvolved: monsterInvolved,
      bountyMin: bountyMin,
      bountyMax: bountyMax,
      reportPaths: reportPaths,
      agentDeceased: agentDeceased,
      urgent: urgent,
    );

    await _missionsRef.add(mission.toMap());
    StatsRepository.scheduleRebuild();
  }

  /// Trouve le docId Firestore d'une mission par son id métier
  Future<String?> _findMissionDocId(int missionId) async {
    final snap = await _missionsRef.where('id', isEqualTo: missionId).limit(1).get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }

  /// Met à jour les champs d'une mission existante
  Future<void> updateMission(int missionId, Map<String, dynamic> fields) async {
    final docId = await _findMissionDocId(missionId);
    if (docId == null) return;
    await _missionsRef.doc(docId).update(fields);
    StatsRepository.scheduleRebuild();
  }

  /// Ajoute un rapport PDF à une mission existante
  Future<void> appendReport(int missionId, String reportUrl) async {
    final docId = await _findMissionDocId(missionId);
    if (docId == null) return;
    await _missionsRef.doc(docId).update({
      'reportPaths': FieldValue.arrayUnion([reportUrl]),
    });
  }
}

// ─── PNJRepository ────────────────────────────────────────────────────────────

class PNJRepository {
  final FirebaseFirestore _firestore;

  PNJRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calcule le prochain ID disponible dans common/archives/npcs
  Future<int> _getNextPNJId() async {
    final snapshot = await _firestore
        .collection('common')
        .doc('archives')
        .collection('npcs')
        .get();

    int maxId = -1;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final id = data['id'];
      if (id is int && id > maxId) maxId = id;
    }

    return maxId + 1;
  }

  /// Référence vers la collection npcs
  CollectionReference<Map<String, dynamic>> get _npcsRef =>
      _firestore.collection('common').doc('archives').collection('npcs');

  /// Trouve le docId Firestore d'un PNJ par son id métier
  Future<String?> _findPNJDocId(int pnjId) async {
    final snap = await _npcsRef.where('id', isEqualTo: pnjId).limit(1).get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }

  /// Met à jour les champs d'un PNJ existant
  Future<void> updatePNJ(int pnjId, Map<String, dynamic> fields) async {
    final docId = await _findPNJDocId(pnjId);
    if (docId == null) return;
    await _npcsRef.doc(docId).update(fields);
    StatsRepository.scheduleRebuild();
  }

  /// Crée un PNJ dans common/archives/npcs
  Future<void> createPNJ({
    required String name,
    required Entitype type,
    String? picturePath,
    required String description,
    required Relationship relation,
    required bool alive,
  }) async {
    final nextId = await _getNextPNJId();

    final pnj = PNJ(
      id: nextId,
      name: name,
      type: type,
      picturePath: picturePath,
      description: description,
      relation: relation,
      alive: alive,
    );

    await _npcsRef.add(pnj.toMap());
    StatsRepository.scheduleRebuild();
  }
}

// ─── MonsterRepository ────────────────────────────────────────────────────────

class MonsterRepository {
  final FirebaseFirestore _firestore;

  MonsterRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calcule le prochain ID disponible dans common/archives/bestiary
  Future<int> _getNextMonsterId() async {
    final snapshot = await _firestore
        .collection('common')
        .doc('archives')
        .collection('bestiary')
        .get();

    int maxId = -1;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final id = data['id'];
      if (id is int && id > maxId) maxId = id;
    }

    return maxId + 1;
  }

  /// Référence vers la collection bestiary
  CollectionReference<Map<String, dynamic>> get _bestiaryRef =>
      _firestore.collection('common').doc('archives').collection('bestiary');

  /// Trouve le docId Firestore d'un monstre par son id métier
  Future<String?> _findMonsterDocId(int monsterId) async {
    final snap = await _bestiaryRef.where('id', isEqualTo: monsterId).limit(1).get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }

  /// Met à jour les champs d'un monstre existant
  Future<void> updateMonster(int monsterId, Map<String, dynamic> fields) async {
    final docId = await _findMonsterDocId(monsterId);
    if (docId == null) return;
    await _bestiaryRef.doc(docId).update(fields);
  }

  /// Ajoute une illustration à un monstre existant
  Future<void> appendIllustration(int monsterId, String imageUrl) async {
    final docId = await _findMonsterDocId(monsterId);
    if (docId == null) return;
    await _bestiaryRef.doc(docId).update({
      'illustrationPaths': FieldValue.arrayUnion([imageUrl]),
    });
  }

  /// Crée un Monster dans common/archives/bestiary
  Future<void> createMonster({
    required String name,
    required Entitype type,
    required String race,
    List<String>? illustrationPaths,
    required String description,
    required String skills,
    required String weakness,
    required String location,
    required List<int> hpScale,
  }) async {
    final nextId = await _getNextMonsterId();

    final monster = Monster(
      id: nextId,
      name: name,
      type: type,
      race: race,
      illustrationPaths: illustrationPaths,
      description: description,
      skills: skills,
      weakness: weakness,
      location: location,
      hp: 0, // non utilisé, toujours 0
      hpScale: hpScale,
    );

    await _bestiaryRef.add(monster.toMap());
    StatsRepository.scheduleRebuild();
  }
}

// ─── ArtefactRepository ───────────────────────────────────────────────────────

class ArtefactRepository {
  final FirebaseFirestore _firestore;

  ArtefactRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calcule le prochain ID disponible dans common/archives/artefacts
  Future<int> _getNextArtefactId() async {
    final snapshot = await _firestore
        .collection('common')
        .doc('archives')
        .collection('artefacts')
        .get();

    int maxId = -1;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final id = data['id'];
      if (id is int && id > maxId) maxId = id;
    }

    return maxId + 1;
  }

  /// Crée un Artefacts dans common/archives/artefacts
  Future<void> createArtefact({
    required String name,
    required String description,
    String? picturePath,
    required String effect,
    required bool limitedUses,
    int? usesLeft,
    Mission? missionRetrievedAt,
    DateTime? dateRetrievedAt,
  }) async {
    final nextId = await _getNextArtefactId();

    final artefact = Artefacts(
      id: nextId,
      name: name,
      description: description,
      picturePath: picturePath,
      effect: effect,
      limitedUses: limitedUses,
      usesLeft: usesLeft,
      owner: null, // TODO: implémenter quand la DB sera prête
      missionRetrievedAt: missionRetrievedAt,
      dateRetrievedAt: dateRetrievedAt,
    );

    await _firestore
        .collection('common')
        .doc('archives')
        .collection('artefacts')
        .add(artefact.toMap());
    StatsRepository.scheduleRebuild();
  }

  /// Crée un ArtefactWeapon dans common/archives/artefacts
  Future<void> createArtefactWeapon({
    required String name,
    required String description,
    String? picturePath,
    required String damage,
    required String feature,
    required Affinities type,
    required SubAffinities subType,
    required List<Effect> effect,
    required double size,
    required bool fire,
    Calibre? calibre,
    double? reload,
    int? magazineSize,
    bool? secondMagazine,
    int? secondMagazineSize,
    Firing? firing,
    required bool limitedUses,
    int? usesLeft,
    Mission? missionRetrievedAt,
    DateTime? dateRetrievedAt,
  }) async {
    final nextId = await _getNextArtefactId();

    final weapon = ArtefactWeapon(
      id: nextId,
      name: name,
      description: description,
      picturePath: picturePath,
      damage: damage,
      feature: feature,
      type: type,
      subType: subType,
      effect: effect,
      modif: null, // TODO: implémenter quand la DB sera prête
      size: size,
      fire: fire,
      calibre: calibre,
      reload: reload,
      magazineSize: magazineSize,
      secondMagazine: secondMagazine,
      secondMagazineSize: secondMagazineSize,
      firing: firing,
      limitedUses: limitedUses,
      usesLeft: usesLeft,
      owner: null, // TODO: implémenter quand la DB sera prête
      missionRetrievedAt: missionRetrievedAt,
      dateRetrievedAt: dateRetrievedAt,
    );

    await _firestore
        .collection('common')
        .doc('archives')
        .collection('artefacts')
        .add(weapon.toMap());
    StatsRepository.scheduleRebuild();
  }
}

// ─── ResDevProjectRepository ──────────────────────────────────────────────────

class ResDevProjectRepository {
  final FirebaseFirestore _firestore;

  ResDevProjectRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calcule le prochain ID disponible dans common/archives/resdevproject
  Future<int> _getNextProjectId() async {
    final snapshot = await _firestore
        .collection('common')
        .doc('archives')
        .collection('resdevproject')
        .get();

    int maxId = -1;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final id = data['id'];
      if (id is int && id > maxId) maxId = id;
    }

    return maxId + 1;
  }

  /// Crée un ResDevProject dans common/archives/resdevproject
  Future<void> createProject({
    required String name,
    required String description,
    String? picturePath,
    required List<Agent> benefactor,
    required List<String> prerequisite,
    required int cost,
  }) async {
    final nextId = await _getNextProjectId();

    final project = ResDevProject(
      id: nextId,
      name: name,
      description: description,
      picturePath: picturePath,
      benefactor: benefactor,
      prerequisite: prerequisite,
      prerequisiteAgents: List<Agent?>.filled(prerequisite.length, null),
      cost: cost,
      prerequisiteCompletes: false,
      completed: false,
    );

    await _firestore
        .collection('common')
        .doc('archives')
        .collection('resdevproject')
        .add(project.toMap());
    StatsRepository.scheduleRebuild();
  }

  /// Sauvegarde les réclamations de prérequis depuis la fiche projet
  Future<void> saveClaims({
    required String docId,
    required List<Agent?> prerequisiteAgents,
    required List<Agent> benefactor,
    required bool prerequisiteCompletes,
  }) async {
    await _firestore
        .collection('common')
        .doc('archives')
        .collection('resdevproject')
        .doc(docId)
        .update({
      'prerequisiteAgents': prerequisiteAgents.map((a) => a?.toMap()).toList(),
      'benefactor': benefactor.map((a) => a.toMap()).toList(),
      'prerequisiteCompletes': prerequisiteCompletes,
    });
  }

  /// Marque un projet comme complété (après création d'un ResDev associé)
  Future<void> setCompleted(String docId) async {
    await _firestore
        .collection('common')
        .doc('archives')
        .collection('resdevproject')
        .doc(docId)
        .update({'completed': true});
    StatsRepository.scheduleRebuild();
  }
}

// ─── ResDevRepository ─────────────────────────────────────────────────────────

class ResDevRepository {
  final FirebaseFirestore _firestore;

  ResDevRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Calcule le prochain ID disponible dans common/archives/resdev
  Future<int> _getNextResDevId() async {
    final snapshot = await _firestore
        .collection('common')
        .doc('archives')
        .collection('resdev')
        .get();

    int maxId = -1;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final id = data['id'];
      if (id is int && id > maxId) maxId = id;
    }

    return maxId + 1;
  }

  /// Crée un ResDev dans common/archives/resdev
  Future<void> createResDev({
    required String name,
    required String description,
    String? picturePath,
    required Stockage stockage,
    required double size,
    double? number,
    required int projectId,
  }) async {
    final nextId = await _getNextResDevId();

    final item = ResDev(
      id: nextId,
      name: name,
      description: description,
      picturePath: picturePath,
      stockage: stockage,
      size: size,
      number: number,
      projectId: projectId,
    );

    await _firestore
        .collection('common')
        .doc('archives')
        .collection('resdev')
        .add(item.toMap());
  }

  /// Crée un ResDevWeapon dans common/archives/resdev
  Future<void> createResDevWeapon({
    required String name,
    required String description,
    String? picturePath,
    required String damage,
    required String feature,
    required Affinities type,
    required SubAffinities subType,
    required List<Effect> effect,
    required double size,
    required bool fire,
    Calibre? calibre,
    double? reload,
    int? magazineSize,
    bool? secondMagazine,
    int? secondMagazineSize,
    Firing? firing,
    required int projectId,
  }) async {
    final nextId = await _getNextResDevId();

    final weapon = ResDevWeapon(
      id: nextId,
      name: name,
      description: description,
      picturePath: picturePath,
      damage: damage,
      feature: feature,
      type: type,
      subType: subType,
      effect: effect,
      modif: null,
      size: size,
      fire: fire,
      calibre: calibre,
      reload: reload,
      magazineSize: magazineSize,
      secondMagazine: secondMagazine,
      secondMagazineSize: secondMagazineSize,
      firing: firing,
      projectId: projectId,
    );

    await _firestore
        .collection('common')
        .doc('archives')
        .collection('resdev')
        .add(weapon.toMap());
  }
}
