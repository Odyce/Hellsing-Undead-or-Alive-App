import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

class NpcListPage extends StatefulWidget {
  const NpcListPage({super.key});

  @override
  State<NpcListPage> createState() => _NpcListPageState();
}

class _NpcListPageState extends State<NpcListPage> {
  List<PNJ> _npcs = [];
  List<Mission> _missions = [];
  bool _loading = true;
  String? _error;

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

      // Chargement PNJs + missions en parallèle
      final results = await Future.wait([
        archiveRef.collection('npcs').get(),
        archiveRef.collection('missions').get(),
      ]);

      final npcs = results[0].docs
          .map((doc) => PNJ.fromMap(doc.data()))
          .toList();

      final missions = results[1].docs
          .map((doc) => Mission.fromMap(doc.data()))
          .toList();

      setState(() {
        _npcs = npcs;
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

  /// Retourne les titres des missions qui impliquent ce PNJ.
  List<String> _missionsFor(int pnjId) => _missions
      .where((m) =>
          m.pnjInvolved?.any((pnj) => pnj.id == pnjId) ?? false)
      .map((m) => m.title)
      .toList();

  static String _typeLabel(Entitype t) => switch (t) {
        Entitype.demon   => 'Démon',
        Entitype.angel   => 'Ange',
        Entitype.midian  => 'Midian',
        Entitype.beast   => 'Bête',
        Entitype.human   => 'Humain',
      };

  static String _relationLabel(Relationship r) => switch (r) {
        Relationship.neutral => 'Neutre',
        Relationship.ally    => 'Allié',
        Relationship.enemy   => 'Ennemi',
        Relationship.trader  => 'Marchand',
      };

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── En-tête ───────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Text(
                  'PNJs',
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
                      Navigator.pushNamed(context, '/npcCreate'),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau PNJ'),
                ),
              ),
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
                      : _npcs.isEmpty
                          ? const Center(
                              child: Text('Aucun PNJ enregistré.'),
                            )
                          : _buildTable(),
            ),

            // ── Bouton retour en bas ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/archives'),
                  child: const Text('Retour'),
                ),
              ),
            ),
          ],
        ),
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
              label: Text('Nom',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Type',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Relation',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            DataColumn(
              label: Text('Statut',
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
          rows: _npcs.map((pnj) {
            final missionTitles = _missionsFor(pnj.id);

            return DataRow(
              onSelectChanged: (_) => Navigator.pushNamed(
                context,
                '/npcSheet',
                arguments: pnj,
              ),
              cells: [
                // ── Nom ───────────────────────────────────────────────────────
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(pnj.name),
                  ),
                ),

                // ── Type ──────────────────────────────────────────────────────
                DataCell(Text(_typeLabel(pnj.type))),

                // ── Relation ──────────────────────────────────────────────────
                DataCell(Text(_relationLabel(pnj.relation))),

                // ── Statut ────────────────────────────────────────────────────
                DataCell(
                  Icon(
                    pnj.alive ? Icons.favorite : Icons.close,
                    color: pnj.alive ? Colors.green : Colors.red,
                  ),
                ),

                // ── Image ─────────────────────────────────────────────────────
                DataCell(
                  pnj.picturePath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            pnj.picturePath!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
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
                                for (int i = 0;
                                    i < missionTitles.length;
                                    i++) ...[
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
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
