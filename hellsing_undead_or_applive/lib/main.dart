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
        '/missionsheet': (_) => const MissionSheetPage(),
        '/missioncreate': (_) => const CreateMissionPage(),
        '/bestiary': (_) => const BestiaryListPage(),
        '/bestiarySheet': (_) => const BestiarySheetPage(),
        '/bestiaryCreate': (_) => const CreateBestiaryPage(),
        '/npcs': (_) => const NpcListPage(),
        '/npcSheet': (_) => const NpcSheetPage(),
        '/npcCreate': (_) => const CreateNpcPage(),
        '/artefacts': (_) => const ArtefactListPage(),
        '/artefactSheet': (_) => const ArtefactSheetPage(),
        '/artefactCreate': (_) => const CreateArtefactPage(),
        '/resDev': (_) => const ResDevListPage(),
        '/resDevSheet': (_) => const ResDevSheetPage(),
        '/resDevCreate': (_) => const CreateResDevPage(),
        '/resDevProjectSheet': (_) => const ResDevProjectSheetPage(),
        '/resDevProjectCreate': (_) => const ResDevProjectFormPage(),
        // '/settings': (_) => const SettingsPage(),
        // etc.
      },

      // AuthGate décide quoi afficher
      home: const AuthGate(),
    );
  }
}
