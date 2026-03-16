import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'routes.dart';

/// Routes : liste des agents, création d'un agent.
const Map<String, WidgetBuilder> agentRoutes = {
  Routes.agentList   : _agentList,
  Routes.agentCreate : _agentCreate,
};

Widget _agentList   (BuildContext _) => const AgentsListPage();
Widget _agentCreate (BuildContext _) => const CreateAgentPage();
