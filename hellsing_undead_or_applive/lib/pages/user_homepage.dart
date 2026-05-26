import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:hellsing_undead_or_applive/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _pseudo = '...';
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!mounted) return;
    final data = doc.data();
    if (data == null) return;
    setState(() {
      final pseudo = data['pseudo'];
      _pseudo = pseudo is String && pseudo.trim().isNotEmpty ? pseudo : 'Pseudo';
      final role = data['role'];
      _role = role is String && role.trim().isNotEmpty ? role : 'user';
    });
  }

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
          onTap: () => Navigator.pushNamed(context, b.route),
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
              Navigator.pushNamed(context, Routes.notifications),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _role == 'admin' ? AppColors.adminBadge : AppColors.userBadge,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _role == 'admin' ? 'Admin' : 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
                  child: Text(
                    'Bienvenue à $_pseudo',
                    style: GoogleFonts.cinzelDecorative(
                      textStyle: Theme.of(context).textTheme.headlineSmall,
                    ),
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StatsMenuPage(),
                    ),
                  );
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
              Text(label, textAlign: TextAlign.center, style: GoogleFonts.cinzelDecorative()),
            ],
          ),
        ),
      ),
    );
  }
}
