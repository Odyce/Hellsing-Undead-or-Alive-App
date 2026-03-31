import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'routes.dart';

/// Routes : menu missions, tableau d'affichage, chronologie, fiche, création.
const Map<String, WidgetBuilder> missionRoutes = {
  Routes.missions      : _menu,
  Routes.missionBoard  : _board,
  Routes.missionChrono : _chrono,
  Routes.missionSheet  : _sheet,
  Routes.missionCreate : _create,
  Routes.missionEdit   : _edit,
};

Widget _menu   (BuildContext _) => const MissionMenuPage();
Widget _board  (BuildContext _) => const DisplayMissionPage();
Widget _chrono (BuildContext _) => const MissionChronologyPage();
Widget _sheet  (BuildContext _) => const MissionSheetPage();
Widget _create (BuildContext _) => const CreateMissionPage();
Widget _edit   (BuildContext _) => const EditMissionPage();
