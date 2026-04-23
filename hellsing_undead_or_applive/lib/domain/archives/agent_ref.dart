import 'package:hellsing_undead_or_applive/domain/agents/agent.dart';

/// Wrapper autour d'[Agent] qui transporte son chemin Firestore.
/// Utilisé uniquement lors de la création/édition de missions pour pouvoir
/// mettre à jour les documents agents directement (users/{ownerUid}/agents/{agentDocId}).
class AgentRef {
  final String ownerUid;
  final String agentDocId;
  final Agent agent;

  const AgentRef({
    required this.ownerUid,
    required this.agentDocId,
    required this.agent,
  });
}
