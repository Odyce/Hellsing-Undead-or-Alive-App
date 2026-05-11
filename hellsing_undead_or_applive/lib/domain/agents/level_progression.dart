import 'package:hellsing_undead_or_applive/domain/agents/agent.dart';
import 'package:hellsing_undead_or_applive/domain/agents/agent_bonus_data.dart';

// ---------------------------------------------------------------------------
// Seuils de missions par niveau
// ---------------------------------------------------------------------------

const List<int> _missionsPerLevel = [
  3, // Niveau 1 → 2
  3, // Niveau 2 → 3
  4, // Niveau 3 → 4
  5, // Niveau 4 → 5
  6, // Niveau 5 → 6
  7, // Niveau 6 → 7
  8, // Niveau 7 → 8
  9, // Niveau 8 → 9
  10, // Niveau 9 → 10
  11, // Niveau 10 → 11
];
const int _legendaryMissionsPerLevel = 7;

/// Missions cumulées requises pour atteindre [targetLevel].
int cumulativeMissionsRequired(int targetLevel) {
  int total = 0;
  for (int i = 0; i < targetLevel - 1; i++) {
    if (i < _missionsPerLevel.length) {
      total += _missionsPerLevel[i];
    } else {
      total += _legendaryMissionsPerLevel;
    }
  }
  return total;
}

/// Liste des niveaux auxquels l'agent peut monter compte tenu de ses missions.
List<int> availableLevelUps(Agent agent) {
  final result = <int>[];
  final missionCount = agent.missions.where((m) => m.id != -66).length;
  for (int nextLvl = agent.level + 1; nextLvl <= agent.level + 20; nextLvl++) {
    if (missionCount >= cumulativeMissionsRequired(nextLvl)) {
      result.add(nextLvl);
    } else {
      break;
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Rollback : aperçu et application
// ---------------------------------------------------------------------------

/// Aperçu de l'impact d'un retrait de mission sur un agent.
class AgentRollbackPreview {
  final String ownerUid;
  final String agentDocId;
  final String agentName;
  final int currentLevel;
  final int newLevel;

  /// Niveaux qui seront annulés (ordre décroissant).
  final List<int> rolledBackLevels;

  /// Niveaux qui auraient dû être annulés mais sans LevelUpRecord disponible.
  /// Le rollback s'arrête au premier niveau orphelin pour préserver la
  /// cohérence des stats (l'agent reste à ce niveau).
  final List<int> orphanedLevels;

  const AgentRollbackPreview({
    required this.ownerUid,
    required this.agentDocId,
    required this.agentName,
    required this.currentLevel,
    required this.newLevel,
    required this.rolledBackLevels,
    required this.orphanedLevels,
  });

  bool get hasImpact => rolledBackLevels.isNotEmpty || orphanedLevels.isNotEmpty;
}

/// Calcule l'aperçu du rollback pour un agent dont on retire la mission [removedMissionId].
AgentRollbackPreview computeRollbackPreview({
  required String ownerUid,
  required String agentDocId,
  required Agent agent,
  required int removedMissionId,
}) {
  final newMissionCount = agent.missions
      .where((m) => m.id != -66 && m.id != removedMissionId)
      .length;

  final rolledBack = <int>[];
  final orphaned = <int>[];
  int newLevel = agent.level;

  while (newLevel > 1 && newMissionCount < cumulativeMissionsRequired(newLevel)) {
    final hasRecord = agent.levelUpHistory.any((r) => r.level == newLevel);
    if (!hasRecord) {
      orphaned.add(newLevel);
      // On s'arrête : l'agent garde ce niveau (stats inflatées mais cohérentes).
      break;
    }
    rolledBack.add(newLevel);
    newLevel--;
  }

  return AgentRollbackPreview(
    ownerUid: ownerUid,
    agentDocId: agentDocId,
    agentName: agent.name,
    currentLevel: agent.level,
    newLevel: newLevel,
    rolledBackLevels: rolledBack,
    orphanedLevels: orphaned,
  );
}

/// Résultat d'un rollback : nouvelles données de l'agent + niveaux orphelins.
class RollbackResult {
  final Agent updatedAgent;
  final List<int> rolledBackLevels;
  final List<int> orphanedLevels;

  const RollbackResult({
    required this.updatedAgent,
    required this.rolledBackLevels,
    required this.orphanedLevels,
  });
}

/// Calcule l'agent après retrait de [removedMissionId] et rollback éventuel
/// des niveaux dont le seuil n'est plus atteint.
RollbackResult applyRollback({
  required Agent agent,
  required int removedMissionId,
}) {
  // Retire la mission
  final newMissions =
      agent.missions.where((m) => m.id != removedMissionId).toList();
  final newMissionCount = newMissions.where((m) => m.id != -66).length;

  // Snapshots mutables
  final newMaxPools = List<int>.from(agent.maxPools);
  final newPools = List<int>.from(agent.pools);
  final newAttributes = List<int>.from(agent.attributes);
  final newSkills = List.of(agent.skills);
  final newClassBonuses = List<int>.from(agent.classBonuses);
  final newSecondClassBonuses = List<int>.from(agent.secondClassBonuses);
  int newPc = agent.pc;
  int? newPowerScore = agent.powerScore;
  var newSecondClass = agent.secondClass;
  final newHistory = List<LevelUpRecord>.from(agent.levelUpHistory);

  final rolledBack = <int>[];
  final orphaned = <int>[];
  int newLevel = agent.level;

  while (newLevel > 1 &&
      newMissionCount < cumulativeMissionsRequired(newLevel)) {
    final recordIdx = newHistory.indexWhere((r) => r.level == newLevel);
    if (recordIdx < 0) {
      orphaned.add(newLevel);
      break;
    }
    final record = newHistory[recordIdx];

    // Inverse les deltas de pools / attributs
    for (int i = 0; i < 3; i++) {
      newMaxPools[i] -= record.deltaMaxPools[i];
      newPools[i] -= record.deltaPools[i];
      newAttributes[i] -= record.deltaAttributes[i];
    }

    // Retire les compétences ajoutées (par ID, une occurrence par ID)
    for (final id in record.addedSkillIds) {
      final idx = newSkills.indexWhere((s) => s.id == id);
      if (idx >= 0) newSkills.removeAt(idx);
    }

    // Inverse les bonus de classe
    for (int i = 0;
        i < record.deltaClassBonuses.length && i < newClassBonuses.length;
        i++) {
      newClassBonuses[i] -= record.deltaClassBonuses[i];
    }

    // Classe secondaire : si ce passage l'a introduite, on l'enlève
    if (record.addedSecondClass) {
      newSecondClass = null;
      newSecondClassBonuses.clear();
    } else {
      for (int i = 0;
          i < record.deltaSecondClassBonuses.length &&
              i < newSecondClassBonuses.length;
          i++) {
        newSecondClassBonuses[i] -= record.deltaSecondClassBonuses[i];
      }
    }

    newPc -= record.deltaPc;
    newPowerScore = (newPowerScore ?? 0) - record.deltaPowerScore;

    newHistory.removeAt(recordIdx);
    rolledBack.add(newLevel);
    newLevel--;
  }

  // Clamp pools dans [0, newMaxPools]
  for (int i = 0; i < 3; i++) {
    if (newMaxPools[i] < 0) newMaxPools[i] = 0;
    if (newPools[i] > newMaxPools[i]) newPools[i] = newMaxPools[i];
    if (newPools[i] < 0) newPools[i] = 0;
  }

  final updated = agent.copyWith(
    level: newLevel,
    missions: newMissions,
    maxPools: newMaxPools,
    pools: newPools,
    attributes: newAttributes,
    skills: newSkills,
    classBonuses: newClassBonuses,
    secondClass: newSecondClass,
    secondClassBonuses: newSecondClassBonuses,
    pc: newPc,
    powerScore: newPowerScore,
    levelUpHistory: newHistory,
  );

  return RollbackResult(
    updatedAgent: updated,
    rolledBackLevels: rolledBack,
    orphanedLevels: orphaned,
  );
}
