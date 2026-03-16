import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'routes.dart';

/// Routes : liste des artefacts, fiche, création.
const Map<String, WidgetBuilder> artefactRoutes = {
  Routes.artefacts      : _list,
  Routes.artefactSheet  : _sheet,
  Routes.artefactCreate : _create,
};

Widget _list   (BuildContext _) => const ArtefactListPage();
Widget _sheet  (BuildContext _) => const ArtefactSheetPage();
Widget _create (BuildContext _) => const CreateArtefactPage();
