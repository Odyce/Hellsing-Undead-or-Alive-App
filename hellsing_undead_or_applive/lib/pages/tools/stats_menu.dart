import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  bool _isAdmin = false;
  bool _isRebuilding = false;

  @override
  void initState() {
    super.initState();
    _future = _loadFromSummary();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted) {
      setState(() => _isAdmin = doc.data()?['role'] == 'admin');
    }
  }

  /// Lit le document pré-calculé. Si absent (premier lancement), déclenche un
  /// rebuild complet puis recharge.
  Future<_StatsData> _loadFromSummary() async {
    var raw = await _repo.loadSummary();
    if (raw == null) {
      await _repo.rebuildSummary();
      raw = await _repo.loadSummary();
    }
    return _StatsData.fromMap(raw!);
  }

  /// Rebuild manuel (admin) : attend la fin et affiche un SnackBar.
  Future<void> _adminRebuild() async {
    setState(() => _isRebuilding = true);
    try {
      await _repo.rebuildSummary();
      if (!mounted) return;
      setState(() {
        _isRebuilding = false;
        _future = _repo.loadSummary().then((raw) => _StatsData.fromMap(raw!));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statistiques mises à jour avec succès.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRebuilding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du recalcul : $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistiques', style: GoogleFonts.cinzelDecorative()),
        actions: [
          if (_isAdmin)
            _isRebuilding
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Recalculer les statistiques',
                    onPressed: _adminRebuild,
                  ),
        ],
      ),
      body: _isRebuilding
          ? _buildRebuildingOverlay()
          : FutureBuilder<_StatsData>(
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
                return _buildStatsList(context, d);
              },
            ),
    );
  }

  Widget _buildRebuildingOverlay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Recalcul des statistiques en cours…',
            style: GoogleFonts.cinzelDecorative(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 240,
            child: LinearProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsList(BuildContext context, _StatsData d) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Légende de fraîcheur
        if (d.lastUpdated != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Statistiques calculées le ${_formatDate(d.lastUpdated!)}',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),

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
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
        'à ${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
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
  // Méta
  final DateTime? lastUpdated;

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
    this.lastUpdated,
  });

  factory _StatsData.fromMap(Map<String, dynamic> d) {
    Map<String, int> toIntMap(dynamic v) {
      if (v is! Map) return {};
      return Map.fromEntries(
        v.entries.map((e) => MapEntry(e.key as String, (e.value as num).toInt())),
      );
    }

    List<MapEntry<String, int>> toEntries(dynamic v) {
      if (v is! List) return [];
      return v
          .whereType<Map>()
          .map((m) => MapEntry(m['key'] as String, (m['value'] as num).toInt()))
          .toList();
    }

    final richest = d['richestAgent'] as Map? ?? {};
    final bestSkill = d['agentWithMostSkills'] as Map? ?? {};
    final resDev = d['resDevProgress'] as Map? ?? {};

    final ts = d['lastUpdated'];
    final DateTime? lastUpdated =
        ts is Timestamp ? ts.toDate() : null;

    return _StatsData(
      totalAgents: (d['totalAgents'] as num?)?.toInt() ?? 0,
      agentsByRace: toIntMap(d['agentsByRace']),
      agentsByClass: toIntMap(d['agentsByClass']),
      averageLevel: (d['averageLevel'] as num?)?.toDouble() ?? 0,
      richestAgent: (
        (richest['name'] as String?) ?? 'Aucun',
        ((richest['count'] as num?)?.toInt()) ?? 0,
      ),
      agentsBySecondClass: toIntMap(d['agentsBySecondClass']),
      classComboFrequency: toIntMap(d['classComboFrequency']),
      agentsByClassType: toIntMap(d['agentsByClassType']),
      totalDistinctSkills: (d['totalDistinctSkills'] as num?)?.toInt() ?? 0,
      averageSkillsPerAgent:
          (d['averageSkillsPerAgent'] as num?)?.toDouble() ?? 0,
      topSkills: toEntries(d['topSkills']),
      leastPopularSkills: toEntries(d['leastPopularSkills']),
      skillsByCostType: toIntMap(d['skillsByCostType']),
      agentWithMostSkills: (
        (bestSkill['name'] as String?) ?? 'Aucun',
        ((bestSkill['count'] as num?)?.toInt()) ?? 0,
      ),
      skillsPerClass: toIntMap(d['skillsPerClass']),
      skillsAccessiblePerRace: toIntMap(d['skillsAccessiblePerRace']),
      totalMissions: (d['totalMissions'] as num?)?.toInt() ?? 0,
      missionsByDifficulty: toIntMap(d['missionsByDifficulty']),
      missionsByClade: toIntMap(d['missionsByClade']),
      totalDeceased: (d['totalDeceased'] as num?)?.toInt() ?? 0,
      totalMonsters: (d['totalMonsters'] as num?)?.toInt() ?? 0,
      pnjsByRelation: toIntMap(d['pnjsByRelation']),
      totalArtefacts: (d['totalArtefacts'] as num?)?.toInt() ?? 0,
      resDevProgress: (
        ((resDev['completed'] as num?)?.toInt()) ?? 0,
        ((resDev['inProgress'] as num?)?.toInt()) ?? 0,
      ),
      weaponsByType: toIntMap(d['weaponsByType']),
      averageBagItems: (d['averageBagItems'] as num?)?.toDouble() ?? 0,
      topWeapons: toEntries(d['topWeapons']),
      leastPopularWeapons: toEntries(d['leastPopularWeapons']),
      muniByCalibre: toIntMap(d['muniByCalibre']),
      topSupportItems: toEntries(d['topSupportItems']),
      leastPopularSupportItems: toEntries(d['leastPopularSupportItems']),
      averageEquipmentCost:
          (d['averageEquipmentCost'] as num?)?.toDouble() ?? 0,
      lastUpdated: lastUpdated,
    );
  }
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
