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

  // ─── Sync : MissionRecord ─────────────────────────────────────────────────

  /// Ajoute ou met à jour un MissionRecord dans la liste missions d'un agent.
  Future<void> _upsertAgentMissionRecord(
      AgentRef ref, MissionRecord record) async {
    final agentDoc = _firestore
        .collection('users')
        .doc(ref.ownerUid)
        .collection('agents')
        .doc(ref.agentDocId);

    final snap = await agentDoc.get();
    if (!snap.exists) return;

    final raw = snap.data()!;
    final missions = (raw['missions'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();

    final idx = missions.indexWhere((m) => m['id'] == record.id);
    if (idx >= 0) {
      missions[idx] = record.toMap();
    } else {
      missions.add(record.toMap());
    }

    await agentDoc.update({'missions': missions});
  }

  /// Supprime un MissionRecord d'un agent.
  Future<void> _removeAgentMissionRecord(AgentRef ref, int missionId) async {
    final agentDoc = _firestore
        .collection('users')
        .doc(ref.ownerUid)
        .collection('agents')
        .doc(ref.agentDocId);

    final snap = await agentDoc.get();
    if (!snap.exists) return;

    final raw = snap.data()!;
    final missions = (raw['missions'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .where((m) => m['id'] != missionId)
        .toList();

    await agentDoc.update({'missions': missions});
  }

  /// Ajoute ou met à jour un MissionRecord dans un document de la collection [collRef]
  /// dont le champ 'id' vaut [entityId].
  Future<void> _upsertEntityMissionRecord(
    CollectionReference<Map<String, dynamic>> collRef,
    int entityId,
    MissionRecord record,
  ) async {
    final snap =
        await collRef.where('id', isEqualTo: entityId).limit(1).get();
    if (snap.docs.isEmpty) return;

    final docRef = snap.docs.first.reference;
    final raw = snap.docs.first.data();
    final missions = (raw['missions'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();

    final idx = missions.indexWhere((m) => m['id'] == record.id);
    if (idx >= 0) {
      missions[idx] = record.toMap();
    } else {
      missions.add(record.toMap());
    }

    await docRef.update({'missions': missions});
  }

  /// Supprime un MissionRecord d'un document de la collection [collRef]
  /// dont le champ 'id' vaut [entityId].
  Future<void> _removeEntityMissionRecord(
    CollectionReference<Map<String, dynamic>> collRef,
    int entityId,
    int missionId,
  ) async {
    final snap =
        await collRef.where('id', isEqualTo: entityId).limit(1).get();
    if (snap.docs.isEmpty) return;

    final docRef = snap.docs.first.reference;
    final raw = snap.docs.first.data();
    final missions = (raw['missions'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .where((m) => m['id'] != missionId)
        .toList();

    await docRef.update({'missions': missions});
  }

  CollectionReference<Map<String, dynamic>> get _npcsRef =>
      _firestore.collection('common').doc('archives').collection('npcs');

  CollectionReference<Map<String, dynamic>> get _bestiaryRef =>
      _firestore.collection('common').doc('archives').collection('bestiary');

  /// Synchronise les MissionRecords de toutes les entités impliquées.
  ///
  /// [added]   → entités nouvellement ajoutées à la mission (reçoivent un MissionRecord).
  /// [removed] → entités retirées de la mission (leur MissionRecord est supprimé).
  /// [kept]    → entités déjà présentes (leur MissionRecord est mis à jour).
  Future<void> _syncAllEntities({
    required List<AgentRef> agentsAdded,
    required List<AgentRef> agentsRemoved,
    required List<AgentRef> agentsKept,
    required List<PNJ> pnjsAdded,
    required List<PNJ> pnjsRemoved,
    required List<PNJ> pnjsKept,
    required List<Monster> monstersAdded,
    required List<Monster> monstersRemoved,
    required List<Monster> monstersKept,
    required MissionRecord record,
  }) async {
    final futures = <Future<void>>[];

    for (final ref in agentsAdded) {
      futures.add(_upsertAgentMissionRecord(ref, record));
    }
    for (final ref in agentsKept) {
      futures.add(_upsertAgentMissionRecord(ref, record));
    }
    for (final ref in agentsRemoved) {
      futures.add(_removeAgentMissionRecord(ref, record.id));
    }

    for (final pnj in pnjsAdded) {
      futures.add(_upsertEntityMissionRecord(_npcsRef, pnj.id, record));
    }
    for (final pnj in pnjsKept) {
      futures.add(_upsertEntityMissionRecord(_npcsRef, pnj.id, record));
    }
    for (final pnj in pnjsRemoved) {
      futures.add(_removeEntityMissionRecord(_npcsRef, pnj.id, record.id));
    }

    for (final m in monstersAdded) {
      futures.add(_upsertEntityMissionRecord(_bestiaryRef, m.id, record));
    }
    for (final m in monstersKept) {
      futures.add(_upsertEntityMissionRecord(_bestiaryRef, m.id, record));
    }
    for (final m in monstersRemoved) {
      futures.add(_removeEntityMissionRecord(_bestiaryRef, m.id, record.id));
    }

    await Future.wait(futures);
  }

  // ─── CRUD missions ────────────────────────────────────────────────────────

  /// Crée une Mission dans common/archives/missions et synchronise les
  /// MissionRecords sur chaque entité impliquée.
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
    List<AgentRef>? agentInvolved,
    List<PNJ>? pnjInvolved,
    List<Monster>? monsterInvolved,
    List<AgentRef>? agentDeceased,
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
      agentInvolved: agentInvolved?.map((r) => r.agent).toList(),
      pnjInvolved: pnjInvolved,
      monsterInvolved: monsterInvolved,
      bountyMin: bountyMin,
      bountyMax: bountyMax,
      reportPaths: reportPaths,
      agentDeceased: agentDeceased?.map((r) => r.agent).toList(),
      urgent: urgent,
    );

    await _missionsRef.add(mission.toMap());

    final record = MissionRecord(
      id: nextId,
      title: title,
      description: descriptionIntro,
      completedAt: completedAt,
    );

    await _syncAllEntities(
      agentsAdded: agentInvolved ?? [],
      agentsRemoved: [],
      agentsKept: [],
      pnjsAdded: pnjInvolved ?? [],
      pnjsRemoved: [],
      pnjsKept: [],
      monstersAdded: monsterInvolved ?? [],
      monstersRemoved: [],
      monstersKept: [],
      record: record,
    );

    StatsRepository.scheduleRebuild();
  }

  /// Trouve le docId Firestore d'une mission par son id métier
  Future<String?> _findMissionDocId(int missionId) async {
    final snap = await _missionsRef.where('id', isEqualTo: missionId).limit(1).get();
    return snap.docs.isEmpty ? null : snap.docs.first.id;
  }

  /// Met à jour les champs d'une mission existante (sans sync d'entités).
  /// Préférer [updateMissionFull] pour une mise à jour complète avec sync.
  Future<void> updateMission(int missionId, Map<String, dynamic> fields) async {
    final docId = await _findMissionDocId(missionId);
    if (docId == null) return;
    await _missionsRef.doc(docId).update(fields);
    StatsRepository.scheduleRebuild();
  }

  /// Met à jour une mission et synchronise les MissionRecords de toutes les
  /// entités (ajout, suppression, mise à jour selon le diff old → new).
  Future<void> updateMissionFull({
    required int missionId,
    required Map<String, dynamic> fields,
    required List<AgentRef> newAgentInvolved,
    required List<AgentRef> oldAgentInvolved,
    required List<PNJ> newPnjInvolved,
    required List<PNJ> oldPnjInvolved,
    required List<Monster> newMonsterInvolved,
    required List<Monster> oldMonsterInvolved,
    required String title,
    required String description,
    required DateTime? completedAt,
  }) async {
    await updateMission(missionId, fields);

    final oldAgentIds = oldAgentInvolved.map((r) => r.agent.id).toSet();
    final newAgentIds = newAgentInvolved.map((r) => r.agent.id).toSet();
    final agentsAdded =
        newAgentInvolved.where((r) => !oldAgentIds.contains(r.agent.id)).toList();
    final agentsRemoved =
        oldAgentInvolved.where((r) => !newAgentIds.contains(r.agent.id)).toList();
    final agentsKept =
        newAgentInvolved.where((r) => oldAgentIds.contains(r.agent.id)).toList();

    final oldPnjIds = oldPnjInvolved.map((p) => p.id).toSet();
    final newPnjIds = newPnjInvolved.map((p) => p.id).toSet();
    final pnjsAdded = newPnjInvolved.where((p) => !oldPnjIds.contains(p.id)).toList();
    final pnjsRemoved = oldPnjInvolved.where((p) => !newPnjIds.contains(p.id)).toList();
    final pnjsKept = newPnjInvolved.where((p) => oldPnjIds.contains(p.id)).toList();

    final oldMonsterIds = oldMonsterInvolved.map((m) => m.id).toSet();
    final newMonsterIds = newMonsterInvolved.map((m) => m.id).toSet();
    final monstersAdded =
        newMonsterInvolved.where((m) => !oldMonsterIds.contains(m.id)).toList();
    final monstersRemoved =
        oldMonsterInvolved.where((m) => !newMonsterIds.contains(m.id)).toList();
    final monstersKept =
        newMonsterInvolved.where((m) => oldMonsterIds.contains(m.id)).toList();

    final record = MissionRecord(
      id: missionId,
      title: title,
      description: description,
      completedAt: completedAt,
    );

    await _syncAllEntities(
      agentsAdded: agentsAdded,
      agentsRemoved: agentsRemoved,
      agentsKept: agentsKept,
      pnjsAdded: pnjsAdded,
      pnjsRemoved: pnjsRemoved,
      pnjsKept: pnjsKept,
      monstersAdded: monstersAdded,
      monstersRemoved: monstersRemoved,
      monstersKept: monstersKept,
      record: record,
    );
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
      modif: null,
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
