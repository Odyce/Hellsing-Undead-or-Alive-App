import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'routes.dart';

/// Routes : authentification, accueil, archives (menu), rulebook, calendrier.
const Map<String, WidgetBuilder> miscRoutes = {
  Routes.login          : _login,
  Routes.home           : _home,
  Routes.archives       : _archives,
  Routes.rulebook       : _rulebook,
  Routes.calendar       : _calendar,
  Routes.notifications  : _notifications,
};

Widget _login         (BuildContext _) => const LoginPage();
Widget _home          (BuildContext _) => const HomePage();
Widget _archives      (BuildContext _) => const ArchiveMenuPage();
Widget _rulebook      (BuildContext _) => const BookViewerPage();
Widget _calendar      (BuildContext _) => const MoonCalendarPage();
Widget _notifications (BuildContext _) => const NotificationMenuPage();
