import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final prefs = await SharedPreferences.getInstance();
  final remember = prefs.getBool('remember_me') ?? true;

  // Sur mobile (non-web), si remember est false, on déconnecte à chaque démarrage
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
      theme: ThemeData(useMaterial3: true),

      // Routes pour plus tard
      routes: {
        '/login': (_) => const LoginPage(),
        '/home': (_) => const HomePage(),
        '/agentlist': (_) => const AgentsListPage(),
        '/agentcreate': (_) => const CreateAgentPage(),
        '/rulebook': (_) => const BookViewerPage(),
        '/calendar': (_) => const MoonCalendarPage(),
        '/archives': (_) => const ArchiveMenuPage(),
        '/missions': (_) => const MissionMenuPage(),
        '/chrono': (_) => const MissionChronologyPage(),
        '/missioncreate': (_) => const CreateMissionPage(),
        '/missionsheet': (_) => const MissionSheetPage(),
        '/bestiary': (_) => const BestiaryListPage(),
        '/bestiaryCreate': (_) => const CreateBestiaryPage(),
        // '/settings': (_) => const SettingsPage(),
        // etc.
      },

      // AuthGate décide quoi afficher
      home: const AuthGate(),
    );
  }
}
