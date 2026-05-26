import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:hellsing_undead_or_applive/domain/notifications/notification_service.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'package:hellsing_undead_or_applive/routes/app_routes.dart';
import 'package:hellsing_undead_or_applive/theme/app_theme.dart';


Future<void> main() async {
  // ensureInitialized ET runApp doivent être dans la même zone
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('=== FLUTTER ERROR ===');
    debugPrint('Exception: ${details.exception}');
    debugPrint('Stack:\n${details.stack}');
    debugPrint('====================');
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Désactiver la persistance Firestore sur Windows (contourne les bugs de threading)
  if (!kIsWeb && Platform.isWindows) {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
  }

  await NotificationService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  final remember = prefs.getBool('remember_me') ?? true;

  if (!kIsWeb && !remember) {
    await FirebaseAuth.instance.signOut();
  }

  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hellsing App',
      theme: AppTheme.light,

      routes: AppRoutes.all,

      // AuthGate décide quoi afficher
      home: const AuthGate(),
    );
  }
}
