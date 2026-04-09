import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/domain/stats/stats_repository.dart';

class AgentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AgentRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Calcule le prochain ID disponible dans users/{uid}/agents
  Future<int> _getNextAgentId(String uid) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('agents')
        .get();

    int maxId = -1;

    for (final doc in snapshot.docs) {
      if (doc.id == '_meta_') continue;

      final data = doc.data();
      final idStr = data['id'];

      if (idStr is String) {
        final parsed = int.tryParse(idStr);
        if (parsed != null && parsed > maxId) {
          maxId = parsed;
        }
      }
    }

    return maxId + 1; // → 0 si aucun agent
  }

  /// Crée un Agent
  Future<void> createAgent({
    required String name,
    required String background, 
    required String state,
    required String note,
    required String? profilPicturePath,
    required List<int> attributes,
    required List<int> pools,
    required List<int> maxPools,
    required Race race,
    required int? powerScore,
    required AgentClass agentClass,
    required List<int> classBonuses,
    required List<Skill> skills,
    required List<BagSlot> bagSlots,
    required List<BankSlot> bankSlots,
    required List<MuniSlot> muniSlots,
    required List<WeaponSlot> weaponSlots,
    required int money,
    required List<MissionRecord> missions,
    required int level,
    required int pc,
    required List<Contact> contacts
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }

    final uid = user.uid;
    final nextId = await _getNextAgentId(uid);

    final agent = Agent(
      id: nextId.toString(),
      name: name,
      background: background,
      state: state,
      note: note,
      profilPicturePath: profilPicturePath ?? '',
      attributes: attributes,
      pools: pools,
      maxPools: maxPools,
      race: race,
      powerScore: powerScore,
      agentClass: agentClass,
      classBonuses: classBonuses,
      skills: skills,
      bagSlots: bagSlots, 
      bankSlots: bankSlots, 
      muniSlots: muniSlots, 
      weaponSlots: weaponSlots, 
      money: money, 
      missions: missions, 
      level: level,
      pc: pc,
      contacts: contacts,
    );

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('agents')
        .add(agent.toMap());

    StatsRepository.scheduleRebuild();
  }
}
