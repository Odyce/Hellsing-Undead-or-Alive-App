import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'routes.dart';

/// Routes : menu R&D, liste, fiches projet, formulaires.
const Map<String, WidgetBuilder> resDevRoutes = {
  Routes.resDev              : _menu,
  Routes.resDevList          : _list,
  Routes.resDevSheet         : _sheet,
  Routes.resDevCreate        : _create,
  Routes.resDevProjectSheet  : _projectSheet,
  Routes.resDevProjectCreate : _projectCreate,
};

Widget _menu          (BuildContext _) => const ResDevMenuPage();
Widget _list          (BuildContext _) => const ResDevListPage();
Widget _sheet         (BuildContext _) => const ResDevSheetPage();
Widget _create        (BuildContext _) => const CreateResDevPage();
Widget _projectSheet  (BuildContext _) => const ResDevProjectSheetPage();
Widget _projectCreate (BuildContext _) => const ResDevProjectFormPage();
