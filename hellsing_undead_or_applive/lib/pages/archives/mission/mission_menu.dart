import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class MissionMenuPage extends StatelessWidget {
  const MissionMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  "Menu des missions",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.missionBoard);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Tableau d'affichage",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.missionChrono);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Chronologie des missions",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.missionCreate);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    "Créer une mission",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const Spacer(),

              Align(
                alignment: Alignment.bottomLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, Routes.archives);
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
}
