import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'routes.dart';

/// Routes : liste des PNJs, fiche, création.
const Map<String, WidgetBuilder> npcRoutes = {
  Routes.npcs      : _list,
  Routes.npcSheet  : _sheet,
  Routes.npcCreate : _create,
};

Widget _list   (BuildContext _) => const NpcListPage();
Widget _sheet  (BuildContext _) => const NpcSheetPage();
Widget _create (BuildContext _) => const CreateNpcPage();
