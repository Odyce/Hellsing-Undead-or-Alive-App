import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// true tant que la transition de porte n'a pas encore été affichée
  /// pour cette session d'authentification.
  bool _needsTransition = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          // Déconnecté → on réarme la transition pour la prochaine connexion.
          _needsTransition = true;
          return const LoginPage();
        }

        // Connecté (login, signup, ou reconnexion automatique)
        if (_needsTransition) {
          _needsTransition = false;
          return const DoorTransitionPage();
        }

        return const HomePage();
      },
    );
  }
}
