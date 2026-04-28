import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class ResDevMenuPage extends StatelessWidget {
  const ResDevMenuPage({super.key});

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
                      'Menu R&D',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.resDevList);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Liste R&D',
                        style: GoogleFonts.cinzelDecorative(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.resDevProjectCreate);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Créer un projet R&D',
                        style: GoogleFonts.cinzelDecorative(fontSize: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.resDevCreate);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Créer un R&D développé',
                        style: GoogleFonts.cinzelDecorative(fontSize: 18),
                      ),
                    ),
                  ),
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
