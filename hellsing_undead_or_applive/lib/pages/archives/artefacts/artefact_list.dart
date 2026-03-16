import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class ArtefactListPage extends StatefulWidget {
  const ArtefactListPage({super.key});

  @override
  State<ArtefactListPage> createState() => _ArtefactListPageState();
}

class _ArtefactListPageState extends State<ArtefactListPage> {
  // Chaque entrée est soit un Artefacts soit un ArtefactWeapon
  List<Object> _items = [];
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
      final snapshot = await FirebaseFirestore.instance
          .collection('common')
          .doc('archives')
          .collection('artefacts')
          .get();

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        if (data['isWeapon'] == true) {
          return ArtefactWeapon.fromMap(data) as Object;
        } else {
          return Artefacts.fromMap(data) as Object;
        }
      }).toList();

      // Tri par nom
      items.sort((a, b) => _nameOf(a).compareTo(_nameOf(b)));

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _nameOf(Object item) => switch (item) {
        Artefacts a      => a.name,
        ArtefactWeapon w => w.name,
        _                => '',
      };

  String? _pictureOf(Object item) => switch (item) {
        Artefacts a      => a.picturePath,
        ArtefactWeapon w => w.picturePath,
        _                => null,
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
                  'Artefacts',
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
                      Navigator.pushNamed(context, Routes.artefactCreate),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvel artefact'),
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
                      : _items.isEmpty
                          ? const Center(
                              child: Text('Aucun artefact enregistré.'),
                            )
                          : _buildTable(),
            ),

            // ── Bouton retour ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, Routes.archives),
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
              label: Text('Image',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          rows: _items.map((item) {
            final picture = _pictureOf(item);

            return DataRow(
              onSelectChanged: (_) => Navigator.pushNamed(
                context,
                Routes.artefactSheet,
                arguments: item,
              ),
              cells: [
                // ── Nom ───────────────────────────────────────────────────────
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(_nameOf(item)),
                  ),
                ),

                // ── Image ─────────────────────────────────────────────────────
                DataCell(
                  picture != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            picture,
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
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
