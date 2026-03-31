import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hellsing_undead_or_applive/domain/notifications/onesignal_guard.dart';

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

      if (isOneSignalSupported) {
        OneSignal.login(uid);
        OneSignal.User.addTagWithKey('role', role);
      }

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
      (label: 'Agents', icon: Icons.grid_view, route: Routes.agentList),
      (label: 'Livre de règles', icon: Icons.menu_book, route: Routes.rulebook),
      (label: 'Tableau d\'affichage', icon: Icons.dashboard, route: Routes.missionBoard),
      (label: 'Calendrier', icon: Icons.calendar_month, route: Routes.calendar),
      (label: 'Archives', icon: Icons.archive, route: Routes.archives),
    ];

    Widget buildButtons() {
      Widget buildBtn(({String label, IconData icon, String route}) b) {
        return _HomeButton(
          label: b.label,
          icon: b.icon,
          onTap: () => Navigator.pushReplacementNamed(context, b.route),
        );
      }

      if (isWide) {
        return SizedBox(
          height: 140,
          child: Row(
            children: [
              for (int i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(width: spacing),
                Expanded(child: buildBtn(buttons[i])),
              ],
            ],
          ),
        );
      } else {
        final side = (screenWidth - padding - spacing) / 2;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ligne 1 : 2 boutons
            SizedBox(
              height: side,
              child: Row(
                children: [
                  Expanded(child: buildBtn(buttons[0])),
                  const SizedBox(width: spacing),
                  Expanded(child: buildBtn(buttons[1])),
                ],
              ),
            ),
            const SizedBox(height: spacing),
            // Ligne 2 : 1 bouton centré (Tableau d'affichage)
            SizedBox(
              height: side,
              width: side,
              child: buildBtn(buttons[2]),
            ),
            const SizedBox(height: spacing),
            // Ligne 3 : 2 boutons
            SizedBox(
              height: side,
              child: Row(
                children: [
                  Expanded(child: buildBtn(buttons[3])),
                  const SizedBox(width: spacing),
                  Expanded(child: buildBtn(buttons[4])),
                ],
              ),
            ),
          ],
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, Routes.notifications),
        ),
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/Menu.png',
              // Cover : remplit tout l'écran sans déformer, quitte à recadrer les bords
              fit: BoxFit.cover, 
              // Center : garde le milieu de l'image toujours visible
              alignment: Alignment.center, 
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Intensité du flou
              child: Container(color: Colors.white.withValues(alpha: 0.2)),
            ),
          ),
          // ── Contenu principal ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Titre de bienvenue (en haut)
                Align(
                  alignment: Alignment.center,
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

          // ── Bouton Statistique (bas droite, rectangulaire arrondi) ─────
          Positioned(
            bottom: 12,
            right: 12,
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // TODO : naviguer vers les statistiques
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Icon(Icons.bar_chart, size: 22),
                ),
              ),
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
