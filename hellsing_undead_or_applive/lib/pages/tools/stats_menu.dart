import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hellsing_undead_or_applive/domain/stats/stats_repository.dart';

/// ─── Page menu des statistiques ──────────────────────────────────────────────
class StatsMenuPage extends StatefulWidget {
  const StatsMenuPage({super.key});

  @override
  State<StatsMenuPage> createState() => _StatsMenuPageState();
}

class _StatsMenuPageState extends State<StatsMenuPage> {
  final _repo = StatsRepository();
  late Future<_StatsData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  Future<_StatsData> _loadAll() async {
    _repo.clearCache();

    // Paralléliser les requêtes indépendantes
    final agentFutures = Future.wait([
      _repo.totalAgents(),           // 0
      _repo.agentsByRace(),          // 1
      _repo.agentsByClass(),         // 2
      _repo.averageLevel(),          // 3
      _repo.richestAgent(),          // 4
      _repo.agentsBySecondClass(),   // 5
      _repo.classComboFrequency(),   // 6
      _repo.agentsByClassType(),     // 7
    ]);
    final skillFutures = Future.wait([
      _repo.totalDistinctSkills(),    // 0
      _repo.averageSkillsPerAgent(),  // 1
      _repo.topSkills(),              // 2
      _repo.leastPopularSkills(),     // 3
      _repo.skillsByCostType(),       // 4
      _repo.agentWithMostSkills(),    // 5
      _repo.skillsPerClass(),         // 6
      _repo.skillsAccessiblePerRace(),// 7
    ]);
    final missionFutures = Future.wait([
      _repo.totalMissions(),         // 0
      _repo.missionsByDifficulty(),  // 1
      _repo.missionsByClade(),       // 2
      _repo.totalAgentsDeceased(),   // 3
    ]);
    final otherFutures = Future.wait([
      _repo.totalMonsters(),         // 0
      _repo.pnjsByRelation(),        // 1
      _repo.totalArtefacts(),        // 2
      _repo.resDevProgress(),        // 3
      _repo.weaponsByType(),         // 4
      _repo.averageBagItems(),       // 5
      _repo.topWeapons(),            // 6
      _repo.leastPopularWeapons(),   // 7
      _repo.muniByCalibr(),          // 8
      _repo.topSupportItems(),       // 9
      _repo.leastPopularSupportItems(), // 10
      _repo.averageEquipmentCost(),  // 11
    ]);

    final results = await Future.wait([
      agentFutures,  // 0
      skillFutures,  // 1
      missionFutures,// 2
      otherFutures,  // 3
    ]);

    final a = results[0] as List;
    final s = results[1] as List;
    final m = results[2] as List;
    final o = results[3] as List;

    return _StatsData(
      // Agents
      totalAgents: a[0] as int,
      agentsByRace: a[1] as Map<String, int>,
      agentsByClass: a[2] as Map<String, int>,
      averageLevel: a[3] as double,
      richestAgent: a[4] as (String, int),
      agentsBySecondClass: a[5] as Map<String, int>,
      classComboFrequency: a[6] as Map<String, int>,
      agentsByClassType: a[7] as Map<String, int>,
      // Compétences
      totalDistinctSkills: s[0] as int,
      averageSkillsPerAgent: s[1] as double,
      topSkills: s[2] as List<MapEntry<String, int>>,
      leastPopularSkills: s[3] as List<MapEntry<String, int>>,
      skillsByCostType: s[4] as Map<String, int>,
      agentWithMostSkills: s[5] as (String, int),
      skillsPerClass: s[6] as Map<String, int>,
      skillsAccessiblePerRace: s[7] as Map<String, int>,
      // Missions
      totalMissions: m[0] as int,
      missionsByDifficulty: m[1] as Map<String, int>,
      missionsByClade: m[2] as Map<String, int>,
      totalDeceased: m[3] as int,
      // Bestiaire & PNJ
      totalMonsters: o[0] as int,
      pnjsByRelation: o[1] as Map<String, int>,
      // Inventaire, Artefacts & R&D
      totalArtefacts: o[2] as int,
      resDevProgress: o[3] as (int, int),
      weaponsByType: o[4] as Map<String, int>,
      averageBagItems: o[5] as double,
      topWeapons: o[6] as List<MapEntry<String, int>>,
      leastPopularWeapons: o[7] as List<MapEntry<String, int>>,
      muniByCalibre: o[8] as Map<String, int>,
      topSupportItems: o[9] as List<MapEntry<String, int>>,
      leastPopularSupportItems: o[10] as List<MapEntry<String, int>>,
      averageEquipmentCost: o[11] as double,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Statistiques', style: GoogleFonts.cinzelDecorative())),
      body: FutureBuilder<_StatsData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Erreur : ${snap.error}',
                    textAlign: TextAlign.center),
              ),
            );
          }
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Agents ──────────────────────────────────────────────
              _buildCategory(
                context,
                title: 'Agents',
                icon: Icons.people,
                tiles: [
                  _SimpleStat('Nombre total d\'agents', '${d.totalAgents}'),
                  _MapStat('Répartition par race', d.agentsByRace),
                  _MapStat('Répartition par classe', d.agentsByClass),
                  _MapStat('Répartition par classe secondaire',
                      d.agentsBySecondClass),
                  _MapStat('Combinaisons classe + secondaire',
                      d.classComboFrequency),
                  _MapStat('Répartition par type de classe',
                      d.agentsByClassType),
                  _SimpleStat(
                      'Niveau moyen', d.averageLevel.toStringAsFixed(1)),
                  _SimpleStat('Agent le plus riche',
                      '${d.richestAgent.$1}  —  ${d.richestAgent.$2} \$'),
                ],
              ),
              const SizedBox(height: 12),

              // ── Compétences ─────────────────────────────────────────
              _buildCategory(
                context,
                title: 'Compétences',
                icon: Icons.auto_fix_high,
                tiles: [
                  _SimpleStat(
                      'Skills distincts totaux', '${d.totalDistinctSkills}'),
                  _SimpleStat('Nombre moyen par agent',
                      d.averageSkillsPerAgent.toStringAsFixed(1)),
                  _SimpleStat('Agent le plus polyvalent',
                      '${d.agentWithMostSkills.$1}  —  ${d.agentWithMostSkills.$2} skills'),
                  _RankStat('Top 5 skills populaires', d.topSkills),
                  _RankStat(
                      'Top 5 skills moins populaires', d.leastPopularSkills),
                  _MapStat('Skills par type de coût', d.skillsByCostType),
                  _MapStat('Skills par classe', d.skillsPerClass),
                  _MapStat(
                      'Skills accessibles par race', d.skillsAccessiblePerRace),
                ],
              ),
              const SizedBox(height: 12),

              // ── Missions ────────────────────────────────────────────
              _buildCategory(
                context,
                title: 'Missions',
                icon: Icons.map,
                tiles: [
                  _SimpleStat(
                      'Nombre total de missions', '${d.totalMissions}'),
                  _MapStat(
                      'Répartition par difficulté', d.missionsByDifficulty),
                  _MapStat('Répartition par clade', d.missionsByClade),
                  _SimpleStat(
                      'Agents tombés au combat', '${d.totalDeceased}'),
                ],
              ),
              const SizedBox(height: 12),

              // ── Bestiaire & PNJ ─────────────────────────────────────
              _buildCategory(
                context,
                title: 'Bestiaire & PNJ',
                icon: Icons.pets,
                tiles: [
                  _SimpleStat(
                      'Monstres répertoriés', '${d.totalMonsters}'),
                  _MapStat('PNJ par relation', d.pnjsByRelation),
                ],
              ),
              const SizedBox(height: 12),

              // ── Inventaire, Artefacts & R&D ─────────────────────────
              _buildCategory(
                context,
                title: 'Inventaire, Artefacts & R&D',
                icon: Icons.inventory_2,
                tiles: [
                  _SimpleStat(
                      'Artefacts découverts', '${d.totalArtefacts}'),
                  _SimpleStat('Projets R&D',
                      '${d.resDevProgress.$1} complétés / ${d.resDevProgress.$2} en cours'),
                  _MapStat('Armes par type (affinité)', d.weaponsByType),
                  _SimpleStat('Objets moyens en sac par agent',
                      d.averageBagItems.toStringAsFixed(1)),
                  _RankStat('Top 5 armes populaires', d.topWeapons),
                  _RankStat(
                      'Top 5 armes moins populaires', d.leastPopularWeapons),
                  _RankStat('Top 5 supports populaires', d.topSupportItems),
                  _RankStat('Top 5 supports moins populaires',
                      d.leastPopularSupportItems),
                  _MapStat('Munitions par type', d.muniByCalibre),
                  _SimpleStat('Coût moyen d\'équipement par agent',
                      '${d.averageEquipmentCost.toStringAsFixed(0)} \$'),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategory(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<_StatTile> tiles,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          '${tiles.length} statistiques',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        children: [
          const Divider(height: 1),
          ...tiles.map((tile) => tile.build(context)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Données chargées
// ═══════════════════════════════════════════════════════════════════════════════

class _StatsData {
  // Agents
  final int totalAgents;
  final Map<String, int> agentsByRace;
  final Map<String, int> agentsByClass;
  final double averageLevel;
  final (String, int) richestAgent;
  final Map<String, int> agentsBySecondClass;
  final Map<String, int> classComboFrequency;
  final Map<String, int> agentsByClassType;
  // Compétences
  final int totalDistinctSkills;
  final double averageSkillsPerAgent;
  final List<MapEntry<String, int>> topSkills;
  final List<MapEntry<String, int>> leastPopularSkills;
  final Map<String, int> skillsByCostType;
  final (String, int) agentWithMostSkills;
  final Map<String, int> skillsPerClass;
  final Map<String, int> skillsAccessiblePerRace;
  // Missions
  final int totalMissions;
  final Map<String, int> missionsByDifficulty;
  final Map<String, int> missionsByClade;
  final int totalDeceased;
  // Bestiaire & PNJ
  final int totalMonsters;
  final Map<String, int> pnjsByRelation;
  // Inventaire, Artefacts & R&D
  final int totalArtefacts;
  final (int, int) resDevProgress;
  final Map<String, int> weaponsByType;
  final double averageBagItems;
  final List<MapEntry<String, int>> topWeapons;
  final List<MapEntry<String, int>> leastPopularWeapons;
  final Map<String, int> muniByCalibre;
  final List<MapEntry<String, int>> topSupportItems;
  final List<MapEntry<String, int>> leastPopularSupportItems;
  final double averageEquipmentCost;

  const _StatsData({
    required this.totalAgents,
    required this.agentsByRace,
    required this.agentsByClass,
    required this.averageLevel,
    required this.richestAgent,
    required this.agentsBySecondClass,
    required this.classComboFrequency,
    required this.agentsByClassType,
    required this.totalDistinctSkills,
    required this.averageSkillsPerAgent,
    required this.topSkills,
    required this.leastPopularSkills,
    required this.skillsByCostType,
    required this.agentWithMostSkills,
    required this.skillsPerClass,
    required this.skillsAccessiblePerRace,
    required this.totalMissions,
    required this.missionsByDifficulty,
    required this.missionsByClade,
    required this.totalDeceased,
    required this.totalMonsters,
    required this.pnjsByRelation,
    required this.totalArtefacts,
    required this.resDevProgress,
    required this.weaponsByType,
    required this.averageBagItems,
    required this.topWeapons,
    required this.leastPopularWeapons,
    required this.muniByCalibre,
    required this.topSupportItems,
    required this.leastPopularSupportItems,
    required this.averageEquipmentCost,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Widgets de tuiles statistiques
// ═══════════════════════════════════════════════════════════════════════════════

sealed class _StatTile {
  Widget build(BuildContext context);
}

/// Stat simple : label -> valeur
class _SimpleStat extends _StatTile {
  final String label;
  final String value;
  _SimpleStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      leading: Icon(Icons.bar_chart, size: 18, color: cs.secondary),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: cs.primary,
        ),
      ),
    );
  }
}

/// Stat de répartition : label -> map de { clé: nombre } avec barres
class _MapStat extends _StatTile {
  final String label;
  final Map<String, int> data;
  _MapStat(this.label, this.data);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (acc, e) => acc + e.value);

    if (sorted.isEmpty) {
      return ListTile(
        dense: true,
        leading:
            Icon(Icons.pie_chart_outline, size: 18, color: cs.secondary),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        trailing: Text('Aucune donnée',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      );
    }

    return ExpansionTile(
      dense: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading:
          Icon(Icons.pie_chart_outline, size: 18, color: cs.secondary),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        '$total total',
        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
      ),
      children: sorted.map((entry) {
        final pct = total > 0 ? (entry.value / total * 100) : 0.0;
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child:
                    Text(entry.key, style: const TextStyle(fontSize: 13)),
              ),
              Expanded(
                flex: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: Text(
                  '${entry.value}  (${pct.toStringAsFixed(0)}%)',
                  style: TextStyle(
                      fontSize: 12, color: cs.onSurfaceVariant),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Stat de classement (top N) : label -> liste ordonnée
class _RankStat extends _StatTile {
  final String label;
  final List<MapEntry<String, int>> entries;
  _RankStat(this.label, this.entries);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (entries.isEmpty) {
      return ListTile(
        dense: true,
        leading:
            Icon(Icons.emoji_events, size: 18, color: cs.secondary),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        trailing: Text('Aucune donnée',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
      );
    }

    return ExpansionTile(
      dense: true,
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      leading:
          Icon(Icons.emoji_events, size: 18, color: cs.secondary),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      children: [
        for (var i = 0; i < entries.length; i++)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#${i + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: i == 0 ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(entries[i].key,
                      style: const TextStyle(fontSize: 13)),
                ),
                Text(
                  '${entries[i].value}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
