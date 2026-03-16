import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class AgentsListPage extends StatelessWidget {
  const AgentsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }

    final agentsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('agents')
        .where(FieldPath.documentId, isNotEqualTo: '_meta_');

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔹 Titre
              const Center(
                child: Text(
                  "Liste d'agents",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 🔹 Contenu principal
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: agentsRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Erreur lors du chargement des agents"),
                      );
                    }

                    final agents = snapshot.data!.docs;

                    // 🟡 Aucun agent
                    if (agents.isEmpty) {
                      return Center(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, Routes.agentCreate);
                          },
                          child: const Text("Créer un nouvel agent"),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: agents.length,
                            // ignore: unnecessary_underscores
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 18),
                            itemBuilder: (context, index) {
                              final agent = agents[index];
                              final name = agent['name'] ?? 'Agent sans nom';
                              final pic = agent['profilPicturePath'] as String?;
                              final hasPic = pic != null && pic.trim().isNotEmpty;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AgentSheetPage(
                                          agentDocId: agent.id,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 52,
                                        backgroundImage: hasPic ? NetworkImage(pic) : null,
                                        child: hasPic ? null : const Icon(Icons.person),
                                      ),
                                      const SizedBox(width: 36),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(fontSize: 26),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          _confirmDelete(context, agent.id, name);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CreateAgentPage(),
                                    ),
                                  );
                            },
                            child: const Text("Créer un nouvel agent"),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // 🔹 Bouton retour
              Align(
                alignment: Alignment.bottomLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, Routes.home);
                  },
                  child: const Text("Retour"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String docId,
    String name,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirmation"),
          content: Text(
            "Vous êtes certain de vouloir supprimer l'agent \"$name\" ?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Non"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Oui"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('agents')
          .doc(docId)
          .delete();
    }
  }
}
