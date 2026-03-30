import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'package:hellsing_undead_or_applive/pages/agentlist/agent_validation_list.dart';
import 'routes.dart';

/// Routes : liste des agents, création d'un agent, validation admin.
const Map<String, WidgetBuilder> agentRoutes = {
  Routes.agentList           : _agentList,
  Routes.agentCreate         : _agentCreate,
  Routes.agentValidationList : _agentValidationList,
};

Widget _agentList           (BuildContext _) => const AgentsListPage();
Widget _agentCreate         (BuildContext _) => const CreateAgentPage();
Widget _agentValidationList (BuildContext _) => const AgentValidationListPage();
