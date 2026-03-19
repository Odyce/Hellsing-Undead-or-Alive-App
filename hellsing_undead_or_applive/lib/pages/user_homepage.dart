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
    await prefs.setBool('remember_me', false);
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  Stream<String> _pseudoStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
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

  Stream<String> _roleStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) return 'user';
      final role = data['role'];
      if (role is String && role.trim().isNotEmpty) return role;
      return 'user';
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 700;
    const spacing = 12.0;
    const padding = 32.0;

    final buttons = <({String label, IconData icon, String route})>[
      (label: 'AgentList', icon: Icons.grid_view, route: Routes.agentList),
      (label: 'Livre de règles', icon: Icons.menu_book, route: Routes.rulebook),
      (label: 'Calendrier', icon: Icons.calendar_month, route: Routes.calendar),
      (label: 'Archives', icon: Icons.archive, route: Routes.archives),
    ];

    Widget buildButtons() {
      if (isWide) {
        return SizedBox(
          height: 140,
          child: Row(
            children: [
              for (int i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(width: spacing),
                Expanded(
                  child: _HomeButton(
                    label: buttons[i].label,
                    icon: buttons[i].icon,
                    onTap: () => Navigator.pushReplacementNamed(
                        context, buttons[i].route),
                  ),
                ),
              ],
            ],
          ),
        );
      } else {
        final side = (screenWidth - padding - spacing) / 2;
        return SizedBox(
          width: screenWidth - padding,
          height: side * 2 + spacing,
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1.0,
            children: [
              for (final b in buttons)
                _HomeButton(
                  label: b.label,
                  icon: b.icon,
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, b.route),
                ),
            ],
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          StreamBuilder<String>(
            stream: _roleStream(),
            builder: (context, snap) {
              final role = snap.data;
              if (role == null) return const SizedBox.shrink();
              final isAdmin = role == 'admin';
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAdmin ? Colors.orange : Colors.blueGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isAdmin ? 'Admin' : 'User',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Titre de bienvenue (en haut)
            Align(
              alignment: Alignment.centerLeft,
              child: StreamBuilder<String>(
                stream: _pseudoStream(),
                builder: (context, snapshot) {
                  final pseudo = snapshot.data ?? '...';
                  return Text(
                    'Bienvenue à $pseudo',
                    style: Theme.of(context).textTheme.headlineSmall,
                  );
                },
              ),
            ),

            // Boutons centrés verticalement
            Expanded(
              child: Center(child: buildButtons()),
            ),

            // Déconnexion (en bas)
            Align(
              alignment: Alignment.centerLeft,
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
            const SizedBox(height: 8),
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
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 34),
              const SizedBox(height: 10),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
