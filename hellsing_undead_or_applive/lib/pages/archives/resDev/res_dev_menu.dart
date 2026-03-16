import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class ResDevMenuPage extends StatelessWidget {
  const ResDevMenuPage({super.key});

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
                  'Menu R&D',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.resDev);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Liste R&D',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.resDevProjectCreate);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Créer un projet R&D',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, Routes.resDevCreate);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Créer un R&D développé',
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
                  child: const Text('Retour'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
