import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
      body: Padding(
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
                    label: 'Bouton 1',
                    icon: Icons.grid_view,
                    onTap: () {},
                  ),
                  _HomeButton(
                    label: 'Bouton 2',
                    icon: Icons.person,
                    onTap: () {},
                  ),
                  _HomeButton(
                    label: 'Bouton 3',
                    icon: Icons.settings,
                    onTap: () {},
                  ),
                  _HomeButton(
                    label: 'Bouton 4',
                    icon: Icons.info,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
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
