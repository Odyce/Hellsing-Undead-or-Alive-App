import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

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
                  Center(
                    child: CircleAvatar(
                      radius: 52,
                      backgroundImage: hasPic ? NetworkImage(pic) : null,
                      child: hasPic ? null : const Icon(Icons.person, size: 42),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: Text(
                      agent.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Background",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          agent.background,
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.bottomLeft,
                    child: TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/agentlist'),
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
}