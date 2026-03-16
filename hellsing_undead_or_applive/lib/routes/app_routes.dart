import 'package:flutter/material.dart';

import 'misc_routes.dart';
import 'agent_routes.dart';
import 'mission_routes.dart';
import 'bestiary_routes.dart';
import 'npc_routes.dart';
import 'artefact_routes.dart';
import 'res_dev_routes.dart';

/// Point d'entrée unique des routes de l'application.
///
/// Utilisation dans MaterialApp :
///   routes: AppRoutes.all,
class AppRoutes {
  AppRoutes._(); // non instanciable

  static Map<String, WidgetBuilder> get all => {
    ...miscRoutes,
    ...agentRoutes,
    ...missionRoutes,
    ...bestiaryRoutes,
    ...npcRoutes,
    ...artefactRoutes,
    ...resDevRoutes,
  };
}
