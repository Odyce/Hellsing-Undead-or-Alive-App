import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'routes.dart';

/// Routes : liste du bestiaire, fiche, création.
const Map<String, WidgetBuilder> bestiaryRoutes = {
  Routes.bestiary       : _list,
  Routes.bestiarySheet  : _sheet,
  Routes.bestiaryCreate : _create,
  Routes.bestiaryEdit   : _edit,
};

Widget _list   (BuildContext _) => const BestiaryListPage();
Widget _sheet  (BuildContext _) => const BestiarySheetPage();
Widget _create (BuildContext _) => const CreateBestiaryPage();
Widget _edit   (BuildContext _) => const EditBestiaryPage();
