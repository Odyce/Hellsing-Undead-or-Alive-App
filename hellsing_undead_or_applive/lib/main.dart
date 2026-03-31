import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'firebase_options.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/domain/notifications/onesignal_guard.dart';
import 'package:hellsing_undead_or_applive/routes/app_routes.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (isOneSignalSupported) {
    OneSignal.initialize('9172b979-dbb3-48e9-8369-041a4e1856be');
    await OneSignal.Notifications.requestPermission(true);

    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });

    OneSignal.Notifications.addClickListener((event) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final notif = event.notification;
      NotificationRepository().saveNotification(
        uid,
        title: notif.title ?? '',
        body: notif.body ?? '',
        data: notif.additionalData,
      );
    });
  }
  
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

      routes: AppRoutes.all,

      // AuthGate décide quoi afficher
      home: const AuthGate(),
    );
  }
}
