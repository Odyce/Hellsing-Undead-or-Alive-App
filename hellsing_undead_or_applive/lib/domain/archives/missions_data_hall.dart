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
Future<List<Mission>> getMissionByAgent(Agent agent) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(_missionsCollection)
      .get();

  return snapshot.docs
      .map((doc) => Mission.fromMap(doc.data()))
      .where((m) =>
          (m.agentInvolved?.any((a) => a.id == agent.id) ?? false) ||
          (m.agentDeceased?.any((a) => a.id == agent.id) ?? false))
      .toList();
}

Future<List<Mission>> getMissionByAgentName(String agentName) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(_missionsCollection)
      .get();

  return snapshot.docs
      .map((doc) => Mission.fromMap(doc.data()))
      .where((m) =>
          (m.agentInvolved?.any((a) => a.name == agentName) ?? false) ||
          (m.agentDeceased?.any((a) => a.name == agentName) ?? false))
      .toList();
}

Future<List<Mission>> getMissionByDifficulty(Difficulty difficulty) async {
  final snapshot = await FirebaseFirestore.instance
      .collection(_missionsCollection)
      .where('difficulty', isEqualTo: difficulty.name)
      .get();

  return snapshot.docs.map((doc) => Mission.fromMap(doc.data())).toList();
}
