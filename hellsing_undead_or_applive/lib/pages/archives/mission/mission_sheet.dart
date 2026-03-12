import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class MissionSheetPage extends StatelessWidget {
  const MissionSheetPage({super.key});

  // ─── Labels ────────────────────────────────────────────────────────────────
  static String _difficultyLabel(Difficulty d) => switch (d) {
        Difficulty.basse      => 'Basse',
        Difficulty.moyenne    => 'Moyenne',
        Difficulty.haute      => 'Haute',
        Difficulty.tresHaute  => 'Maïca',
        Difficulty.inconnu    => 'Inconnue',
      };

  static String _cladLabel(CladName c) => switch (c) {
        CladName.osiris         => 'Osiris',
        CladName.blackLotus     => 'Black Lotus',
        CladName.pennyDreadful  => 'Penny Dreadful',
      };

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mission = ModalRoute.of(context)!.settings.arguments as Mission;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── En-tête (titre uniquement) ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Text(
                  'Fiche de mission',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ── Contenu scrollable ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Illustration ──────────────────────────────────────────
                    if (mission.illustrationPath != null)
                      Image.network(
                        mission.illustrationPath!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : const SizedBox(
                                height: 220,
                                child: Center(child: CircularProgressIndicator()),
                              ),
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Titre ──────────────────────────────────────────
                          Text(
                            mission.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Badges ─────────────────────────────────────────
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (mission.urgent)
                                Chip(
                                  label: const Text('URGENT'),
                                  backgroundColor: Colors.red.shade100,
                                  side: BorderSide(color: Colors.red.shade400),
                                ),
                              Chip(label: Text(_cladLabel(mission.clad))),
                              Chip(
                                label: Text(
                                  'Difficulté : ${_difficultyLabel(mission.difficulty)}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // ── Prime ──────────────────────────────────────────
                          Text(
                            'Prime : ${mission.bounty} £',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const Divider(height: 32),

                          // ── Dates ──────────────────────────────────────────
                          _DateRow(label: 'Affichée le', date: mission.postedAt),
                          if (mission.playedAt != null)
                            _DateRow(label: 'Jouée le', date: mission.playedAt!),
                          if (mission.completedAt != null)
                            _DateRow(label: 'Terminée le', date: mission.completedAt!),

                          const Divider(height: 32),

                          // ── Description intro ──────────────────────────────
                          _SectionTitle('Description'),
                          const SizedBox(height: 8),
                          Text(mission.descriptionIntro,
                              style: const TextStyle(fontSize: 15)),

                          // ── Description outro ──────────────────────────────
                          if (mission.descriptionOutro != null) ...[
                            const SizedBox(height: 24),
                            _SectionTitle('Épilogue'),
                            const SizedBox(height: 8),
                            Text(mission.descriptionOutro!,
                                style: const TextStyle(fontSize: 15)),
                          ],

                          // ── Notes MJ ───────────────────────────────────────
                          if (mission.notesForDM != null) ...[
                            const SizedBox(height: 24),
                            _SectionTitle('Notes MJ'),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                border: Border.all(color: Colors.amber.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                mission.notesForDM!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ],

                          // ── Rapports PDF ───────────────────────────────────
                          if (mission.reportPaths != null &&
                              mission.reportPaths!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _SectionTitle('Rapports'),
                            const SizedBox(height: 8),
                            ...mission.reportPaths!.asMap().entries.map((e) {
                              final index = e.key + 1;
                              final url   = e.value;
                              final name  = Uri.tryParse(url)
                                      ?.pathSegments
                                      .lastOrNull ??
                                  'Rapport $index';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.picture_as_pdf,
                                    color: Colors.red),
                                title: Text(name),
                                trailing: const Icon(Icons.open_in_new,
                                    size: 18),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _PdfReportViewer(
                                      url: url,
                                      name: name,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bouton retour en bas ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Retour'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PDF Viewer ───────────────────────────────────────────────────────────────

class _PdfReportViewer extends StatelessWidget {
  final String url;
  final String name;

  const _PdfReportViewer({required this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name, overflow: TextOverflow.ellipsis),
      ),
      body: SfPdfViewer.network(url),
    );
  }
}

// ─── Widgets helpers ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime date;
  const _DateRow({required this.label, required this.date});

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(_fmt(date)),
        ],
      ),
    );
  }
}
