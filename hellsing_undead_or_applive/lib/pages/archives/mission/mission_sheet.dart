import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:url_launcher/url_launcher.dart';

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

  static String _cladeLabel(CladeName c) => switch (c) {
        CladeName.osiris            => 'Osiris',
        CladeName.blackOrchid       => 'Black Orchid',
        CladeName.pennyDreadful     => 'Penny Dreadful',
        CladeName.beginning         => 'The Beginning',
        CladeName.origins           => 'Origins',
        CladeName.unNeufTroisZero   => '1930',
        CladeName.western           => 'Western',
        CladeName.arthur            => 'The Legend of King Arthur',
      };

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['role'] == 'admin';
  }

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
                        fit: BoxFit.contain,
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
                              Chip(label: Text(_cladeLabel(mission.clade))),
                              Chip(
                                label: Text(
                                  'Difficulté : ${_difficultyLabel(mission.difficulty)}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // ── Prime ──────────────────────────────────────────
                          if (mission.bounty != null)
                            Text(
                              'Prime finale : ${mission.bounty} £',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          FutureBuilder<bool>(
                            future: _isAdmin(),
                            builder: (context, snapshot) {
                              if (snapshot.data != true) return const SizedBox.shrink();
                              return Text(
                                'Fourchette : ${mission.bountyMin} – ${mission.bountyMax} £',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              );
                            },
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
                                onTap: () async {
                                  final uri = Uri.tryParse(url);
                                  if (uri != null && await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
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
