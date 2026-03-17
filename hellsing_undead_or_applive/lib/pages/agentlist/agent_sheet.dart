import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class AgentSheetPage extends StatelessWidget {
  final String agentDocId;

  const AgentSheetPage({
    super.key,
    required this.agentDocId,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }

    final agentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('agents')
        .doc(agentDocId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Fiche de l'agent"),
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: agentRef.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text("Erreur lors du chargement de l'agent"),
              );
            }

            final doc = snapshot.data;
            if (doc == null || !doc.exists || doc.data() == null) {
              return const Center(child: Text("Agent introuvable"));
            }

            final agent = Agent.fromMap(doc.data()!);

            final pic = agent.profilPicturePath;
            final hasPic = pic != null && pic.trim().isNotEmpty;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- En-tête : infos à gauche, photo à droite ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Infos principales
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text("État : ${agent.state}"),
                            Text("Note : ${agent.note}"),
                            Text("Race : ${agent.race.name}"),
                            if (agent.powerScore != null)
                              Text("Power Score : ${agent.powerScore}"),
                            Text("Classe : ${agent.agentClass.name}"),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Cadre photo de profil
                      Container(
                        width: 100,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: hasPic
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(pic, fit: BoxFit.cover),
                              )
                            : const Center(
                                child: Icon(Icons.person, size: 42, color: Colors.grey),
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- Attributs ---
                  Row(
                    children: [
                      _attributeCell("Physique", agent.attributes[0]),
                      _attributeCell("Mental", agent.attributes[1]),
                      _attributeCell("Social", agent.attributes[2]),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // --- Pools ---
                  Row(
                    children: [
                      _poolCell("PV", agent.pools[0], agent.maxPools[0]),
                      _poolCell("PM", agent.pools[2], agent.maxPools[2]),
                      _poolCell("PE", agent.pools[1], agent.maxPools[1]),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.bottomLeft,
                    child: TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, Routes.agentList),
                      child: const Text("Retour"),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _attributeCell(String label, int value) {
    return Expanded(
      child: Center(
        child: Text(
          "$label : $value",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _poolCell(String label, int current, int max) {
    return Expanded(
      child: Center(
        child: Text(
          "$label : $current / $max",
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}