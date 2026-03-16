import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', false); // empêche l’auto-login au prochain lancement

    await FirebaseAuth.instance.signOut();     // déconnecte maintenant (AuthGate fera le reste)

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }


  Stream<String> _pseudoStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Pas connecté -> on renvoie un flux “vide”
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) return 'Pseudo';
      final pseudo = data['pseudo'];
      if (pseudo is String && pseudo.trim().isNotEmpty) return pseudo;
      return 'Pseudo';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<String>(
                  stream: _pseudoStream(),
                  builder: (context, snapshot) {
                    final pseudo = snapshot.data ?? '...';
                    return Text(
                      'Bienvenue à $pseudo',
                      style: Theme.of(context).textTheme.headlineSmall,
                    );
                  },
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    children: [
                      _HomeButton(
                        label: 'AgentList',
                        icon: Icons.grid_view,
                        onTap: () {
                          Navigator.pushReplacementNamed(context, Routes.agentList);
                        },
                      ),
                      _HomeButton(
                        label: 'Livre de règles',
                        icon: Icons.person,
                        onTap: () {
                          Navigator.pushReplacementNamed(context, Routes.rulebook);
                        },
                      ),
                      _HomeButton(
                        label: 'Calendrier',
                        icon: Icons.calendar_month,
                        onTap: () {
                          Navigator.pushReplacementNamed(context, Routes.calendar);
                        },
                      ),
                      _HomeButton(
                        label: 'Archives',
                        icon: Icons.info,
                        onTap: () {
                          Navigator.pushReplacementNamed(context, Routes.archives);
                        },
                      ),
                    ],
                  ),
                ),

                Positioned(
                  left: 16,
                  bottom: 16,
                  child: InkWell(
                    onTap: () => _logout(context),
                    child: Text(
                      'Déconnexion',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 34),
              const SizedBox(height: 10),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
