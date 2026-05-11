import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'routes.dart';

/// Routes : authentification, accueil, archives (menu), rulebook, calendrier.
const Map<String, WidgetBuilder> miscRoutes = {
  Routes.login          : _login,
  Routes.home           : _home,
  Routes.archives       : _archives,
  Routes.cartes         : _cartes,
  Routes.journal        : _journal,
  Routes.journalCreate  : _journalCreate,
  Routes.rulebook       : _rulebook,
  Routes.calendar       : _calendar,
  Routes.notifications  : _notifications,
};

Widget _login         (BuildContext _) => const LoginPage();
Widget _home          (BuildContext _) => const HomePage();
Widget _archives      (BuildContext _) => const ArchiveMenuPage();
Widget _cartes        (BuildContext _) => const CartesPage();
Widget _journal       (BuildContext _) => const JournalChronologyPage();
Widget _journalCreate (BuildContext _) => const CreateJournalEntryPage();
Widget _rulebook      (BuildContext _) => const BookViewerPage();
Widget _calendar      (BuildContext _) => const MoonCalendarPage();
Widget _notifications (BuildContext _) => const NotificationMenuPage();
