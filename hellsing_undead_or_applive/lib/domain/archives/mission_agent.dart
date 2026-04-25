import 'package:hellsing_undead_or_applive/domain/agents/agent.dart';
import 'package:hellsing_undead_or_applive/domain/archives/agent_ref.dart';

/// Agent enregistré dans une mission : snapshot de l'[Agent] au moment de la
/// mission, complété par [ownerUid] + [agentDocId] pour retrouver avec
/// certitude l'agent source dans Firestore.
///
/// Les seuls `Agent.id` (générés par utilisateur) ne sont pas globalement
/// uniques : deux joueurs différents peuvent avoir des agents avec le même id
/// séquentiel. Stocker le chemin Firestore lève l'ambiguïté.
///
/// Les missions créées avant l'introduction de ce type n'ont que le snapshot
/// de l'Agent. [MissionAgent.fromMap]/[fromJson] lisent ces deux formats.
class MissionAgent {
  /// Chemin Firestore : users/{ownerUid}/agents/{agentDocId}.
  /// Vide pour les missions créées avant l'introduction de ce champ.
  final String ownerUid;
  final String agentDocId;
  final Agent agent;

  const MissionAgent({
    required this.ownerUid,
    required this.agentDocId,
    required this.agent,
  });

  factory MissionAgent.fromAgentRef(AgentRef ref) => MissionAgent(
        ownerUid: ref.ownerUid,
        agentDocId: ref.agentDocId,
        agent: ref.agent,
      );

  Map<String, dynamic> toMap() => {
        'ownerUid': ownerUid,
        'agentDocId': agentDocId,
        'agent': agent.toMap(),
      };

  factory MissionAgent.fromMap(Map<String, dynamic> map) {
    final nested = map['agent'];
    if (nested is Map) {
      return MissionAgent(
        ownerUid: map['ownerUid'] as String? ?? '',
        agentDocId: map['agentDocId'] as String? ?? '',
        agent: Agent.fromMap(Map<String, dynamic>.from(nested)),
      );
    }
    return MissionAgent(
      ownerUid: '',
      agentDocId: '',
      agent: Agent.fromMap(map),
    );
  }

  Map<String, dynamic> toJson() => {
        'ownerUid': ownerUid,
        'agentDocId': agentDocId,
        'agent': agent.toJson(),
      };

  factory MissionAgent.fromJson(Map<String, dynamic> json) {
    final nested = json['agent'];
    if (nested is Map) {
      return MissionAgent(
        ownerUid: json['ownerUid'] as String? ?? '',
        agentDocId: json['agentDocId'] as String? ?? '',
        agent: Agent.fromJson(Map<String, dynamic>.from(nested)),
      );
    }
    return MissionAgent(
      ownerUid: '',
      agentDocId: '',
      agent: Agent.fromJson(json),
    );
  }
}
