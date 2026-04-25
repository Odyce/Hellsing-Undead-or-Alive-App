// ignore_for_file: dangling_library_doc_comments

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';


////////////////////////////////////////
//                                    //
// Fonctions utiles pour les missions //
//                                    //
////////////////////////////////////////

const _missionsCollection = 'missions';

Future<Mission?> getMissionByName(String name) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(_missionsCollection)
      .where('title', isEqualTo: name)
      .limit(1)
      .get();

  if (snapshot.docs.isEmpty) return null;
  return Mission.fromMap(snapshot.docs.first.data());
}

Future<List<Mission>> getMissionByClade(CladeName clade) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(_missionsCollection)
      .where('clade', isEqualTo: clade.name)
      .get();

  return snapshot.docs.map((doc) => Mission.fromMap(doc.data())).toList();
}

// Firestore ne supporte pas le filtrage direct dans des listes d'objets imbriqués,
// on récupère toutes les missions et on filtre côté client.
//
// On prend un AgentRef plutôt qu'un Agent car Agent.id seul n'est pas
// globalement unique (scopé par utilisateur). Fallback (id + name) pour les
// missions créées avant l'introduction de ownerUid/agentDocId.
Future<List<Mission>> getMissionByAgent(AgentRef ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(_missionsCollection)
      .get();

  bool matches(MissionAgent a) {
    if (a.agentDocId.isNotEmpty && a.ownerUid.isNotEmpty) {
      return a.ownerUid == ref.ownerUid && a.agentDocId == ref.agentDocId;
    }
    return a.agent.id == ref.agent.id && a.agent.name == ref.agent.name;
  }

  return snapshot.docs
      .map((doc) => Mission.fromMap(doc.data()))
      .where((m) =>
          (m.agentInvolved?.any(matches) ?? false) ||
          (m.agentDeceased?.any(matches) ?? false))
      .toList();
}

Future<List<Mission>> getMissionByAgentName(String agentName) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(_missionsCollection)
      .get();

  return snapshot.docs
      .map((doc) => Mission.fromMap(doc.data()))
      .where((m) =>
          (m.agentInvolved?.any((a) => a.agent.name == agentName) ?? false) ||
          (m.agentDeceased?.any((a) => a.agent.name == agentName) ?? false))
      .toList();
}

Future<List<Mission>> getMissionByDifficulty(Difficulty difficulty) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(_missionsCollection)
      .where('difficulty', isEqualTo: difficulty.name)
      .get();

  return snapshot.docs.map((doc) => Mission.fromMap(doc.data())).toList();
}
