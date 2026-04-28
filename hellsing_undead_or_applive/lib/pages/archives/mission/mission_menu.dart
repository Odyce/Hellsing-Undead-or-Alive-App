import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class MissionMenuPage extends StatefulWidget {
  const MissionMenuPage({super.key});

  @override
  State<MissionMenuPage> createState() => _MissionMenuPageState();
}

class _MissionMenuPageState extends State<MissionMenuPage> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final role = doc.data()?['role'];
    if (mounted) {
      setState(() => _isAdmin = role == 'admin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      "Menu des missions",
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.missionBoard);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "Tableau d'affichage",
                        style: GoogleFonts.cinzelDecorative(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.missionChrono);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "Chronologie des missions",
                        style: GoogleFonts.cinzelDecorative(fontSize: 18),
                      ),
                    ),
                  ),

                  if (_isAdmin) ...[
                    const SizedBox(height: 16),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, Routes.missionCreate);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "Créer une mission",
                          style: GoogleFonts.cinzelDecorative(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SafeBackButtonOverlay(),
        ],
      ),
    );
  }
}
