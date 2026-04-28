import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/notifications/notification_service.dart';

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
        //print("debug code Anana");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          // Déconnecté → on réarme la transition et on coupe le listener.
          _needsTransition = true;
          NotificationService.instance.stopListening();
          return const LoginPage();
        }

        // Connecté → démarrer l'écoute des notifications
        NotificationService.instance.startListening(user.uid);

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
