import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:hellsing_undead_or_applive/widgets/filter_bar.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class BestiaryListPage extends StatefulWidget {
  const BestiaryListPage({super.key});

  @override
  State<BestiaryListPage> createState() => _BestiaryListPageState();
}

class _BestiaryListPageState extends State<BestiaryListPage> {
  List<Monster> _monsters = [];
  List<Mission> _missions = [];
  bool _loading = true;
  String? _error;

  Map<String, Set<dynamic>> _activeFilters = {};

  static final _filterGroups = [
    FilterGroup<Entitype>(
      label: 'Type',
      options: [
        for (final t in Entitype.values)
          FilterOption(label: _typeLabel(t), value: t),
      ],
    ),
  ];

  List<Monster> get _filteredMonsters {
    final typeFilter = _activeFilters['Type'];
    if (typeFilter == null || typeFilter.isEmpty) return _monsters;
    return _monsters.where((m) => typeFilter.contains(m.type)).toList();
  }

  // ─── Chargement ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final archiveRef = FirebaseFirestore.instance
          .collection('common')
          .doc('archives');

      // Chargement bestiaire + missions en parallèle
      final results = await Future.wait([
        archiveRef.collection('bestiary').get(),
        archiveRef.collection('missions').get(),
      ]);

      final monsters = results[0].docs
          .map((doc) => Monster.fromMap(doc.data()))
          .toList();

      final missions = results[1].docs
          .map((doc) => Mission.fromMap(doc.data()))
          .toList();

      setState(() {
        _monsters = monsters;
        _missions = missions;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Retourne les titres des missions qui contiennent ce monstre.
  List<String> _missionsFor(int monsterId) => _missions
      .where((m) =>
          m.monsterInvolved?.any((mon) => mon.id == monsterId) ?? false)
      .map((m) => m.title)
      .toList();

  static String _typeLabel(Entitype t) => switch (t) {
        Entitype.demon   => 'Démon',
        Entitype.angel   => 'Ange',
        Entitype.midian  => 'Midian',
        Entitype.beast   => 'Bête',
        Entitype.human   => 'Humain',
      };

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ── En-tête ───────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Text(
                  'Bestiaire collaboratif',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // ── Bouton nouvelle entrée ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, Routes.bestiaryCreate),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle entrée'),
                ),
              ),
            ),

            // ── Filtres ───────────────────────────────────────────────────────
            if (!_loading && _error == null && _monsters.isNotEmpty)
              FilterBar(
                groups: _filterGroups,
                activeFilters: _activeFilters,
                onChanged: (f) => setState(() => _activeFilters = f),
              ),

            // ── Tableau ───────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : _filteredMonsters.isEmpty
                          ? const Center(
                              child: Text('Aucune entrée dans le bestiaire.'),
                            )
                          : _buildTable(),
            ),

              ],
            ),
          ),
          const SafeBackButtonOverlay(),
        ],
      ),
    );
  }

  // ─── Tableau ─────────────────────────────────────────────────────────────────
  Widget _buildTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          dataRowMinHeight: 52,
          dataRowMaxHeight: double.infinity,
          headingRowColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          border: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          columns: const [
            DataColumn(
              label: Text('Name',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Type',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Image',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Missions',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: _filteredMonsters.map((monster) {
            final missionTitles = _missionsFor(monster.id);
            final firstImage = monster.illustrationPaths?.isNotEmpty == true
                ? monster.illustrationPaths!.first
                : null;

            return DataRow(
              onSelectChanged: (_) => Navigator.pushNamed(
                context,
                Routes.bestiarySheet,
                arguments: monster,
              ),
              cells: [
              // ── Race ──────────────────────────────────────────────────────
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(monster.name),
                ),
              ),

              // ── Type ──────────────────────────────────────────────────────
              DataCell(Text(_typeLabel(monster.type))),

              // ── Image ─────────────────────────────────────────────────────
              DataCell(
                firstImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          firstImage,
                          width: 52,
                          height: 52,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                        ),
                      )
                    : const Icon(Icons.close, color: Colors.red),
              ),

              // ── Missions ──────────────────────────────────────────────────
              DataCell(
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: missionTitles.isEmpty
                      ? const Icon(Icons.close, color: Colors.red)
                      : Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < missionTitles.length; i++) ...[
                                Text(
                                  missionTitles[i],
                                  style: const TextStyle(fontSize: 13),
                                ),
                                if (i < missionTitles.length - 1)
                                  Divider(
                                    height: 8,
                                    thickness: 1,
                                    color: Colors.grey.shade300,
                                  ),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
