import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class ArchiveMenuPage extends StatelessWidget {
  const ArchiveMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/Archives.jpg',
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      "Archives",
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, Routes.missions);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "Missions",
                        style: GoogleFonts.cinzelDecorative(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, Routes.bestiary);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "Bestiaire",
                        style: GoogleFonts.cinzelDecorative(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, Routes.artefacts);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "Artéfacts",
                        style: GoogleFonts.cinzelDecorative(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, Routes.npcs);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "PNJs",
                        style: GoogleFonts.cinzelDecorative(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, Routes.resDev);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        "R&D",
                        style: GoogleFonts.cinzelDecorative(fontSize: 18),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
          const SafeBackButtonOverlay(),
        ]
      ),
    );
  }
}
