import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class MissionSheetPage extends StatefulWidget {
  const MissionSheetPage({super.key});

  @override
  State<MissionSheetPage> createState() => _MissionSheetPageState();
}

class _MissionSheetPageState extends State<MissionSheetPage> {
  late Mission _mission;
  bool _isAdmin = false;
  bool _roleLoaded = false;
  bool _uploading = false;
  bool _initialized = false;

  final MissionRepository _repository = MissionRepository();

  // ─── Labels ────────────────────────────────────────────────────────────────
  static String _difficultyLabel(Difficulty d) => switch (d) {
        Difficulty.basse     => 'Basse',
        Difficulty.moyenne   => 'Moyenne',
        Difficulty.haute     => 'Haute',
        Difficulty.tresHaute => 'Maïca',
        Difficulty.inconnu   => 'Inconnue',
      };

  static String _cladeLabel(CladeName c) => switch (c) {
        CladeName.osiris          => 'Osiris',
        CladeName.blackOrchid     => 'Black Orchid',
        CladeName.pennyDreadful   => 'Penny Dreadful',
        CladeName.beginning       => 'The Beginning',
        CladeName.origins         => 'Origins',
        CladeName.unNeufTroisZero => '1930',
        CladeName.western         => 'Western',
        CladeName.arthur          => 'The Legend of King Arthur',
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _mission = ModalRoute.of(context)!.settings.arguments as Mission;
      _initialized = true;
      _checkRole();
    }
  }

  Future<void> _checkRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (mounted) {
      setState(() {
        _isAdmin = doc.data()?['role'] == 'admin';
        _roleLoaded = true;
      });
    }
  }

  // ─── Re-fetch mission depuis Firestore ─────────────────────────────────────
  Future<void> _refreshMission() async {
    final snap = await FirebaseFirestore.instance
        .collection('common')
        .doc('archives')
        .collection('missions')
        .where('id', isEqualTo: _mission.id)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty && mounted) {
      setState(() => _mission = Mission.fromMap(snap.docs.first.data()));
    }
  }

  // ─── Upload rapport PDF ────────────────────────────────────────────────────
  static const int _maxReportBytes = 1 * 1024 * 1024;

  Future<void> _uploadReport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty || result.files.first.path == null) return;

    final file = File(result.files.first.path!);
    final size = await file.length();
    if (size > _maxReportBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le fichier dépasse 1 Mo.')),
        );
      }
      return;
    }

    setState(() => _uploading = true);
    try {
      const cloudName = 'hellsingundeadapp';
      const uploadPreset = 'Mission_reports-unsigned';
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/raw/upload',
      );

      final request = MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Erreur upload : ${response.statusCode}');
      }
      final body = await response.stream.bytesToString();
      final url = jsonDecode(body)['secure_url'] as String;

      await _repository.appendReport(_mission.id, url);
      await _refreshMission();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapport ajouté avec succ\u00e8s.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ─── Navigation vers edit ──────────────────────────────────────────────────
  Future<void> _openEditForm() async {
    final updated = await Navigator.pushNamed(
      context,
      Routes.missionEdit,
      arguments: _mission,
    );
    if (updated == true) {
      await _refreshMission();
    }
  }

  // ─── Suppression définitive de la mission ─────────────────────────────────
  Future<void> _confirmAndDeleteMission() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // 1. Calculer l'aperçu de l'impact sur les agents
    final previews = await _repository.previewMissionDeletion(_mission.id);
    if (!mounted) return;

    // 2. Dialog de confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la mission ?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cette action supprimera définitivement la mission '
                '"${_mission.title}" et la retirera de tous les agents, PNJs '
                'et monstres impliqués.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              if (previews.where((p) => p.hasImpact).isEmpty)
                const Text(
                  'Aucun agent ne perdra de niveau.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                )
              else ...[
                const Text(
                  'Conséquences sur les niveaux :',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                ...previews.where((p) => p.hasImpact).map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _RollbackPreviewLine(preview: p),
                      ),
                    ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // 3. Suppression
    try {
      await _repository.deleteMission(_mission.id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Mission supprimée.')),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
            // ── En-t\u00eate ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
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
                  if (_roleLoaded && _isAdmin) ...[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Modifier la mission',
                      onPressed: _openEditForm,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red),
                      tooltip: 'Supprimer la mission',
                      onPressed: _confirmAndDeleteMission,
                    ),
                  ],
                ],
              ),
            ),

            // ── Contenu scrollable ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Illustration ──────────────────────────────────────────
                    if (_mission.illustrationPath != null)
                      Image.network(
                        _mission.illustrationPath!,
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
                            _mission.title,
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
                              if (_mission.urgent)
                                Chip(
                                  label: const Text('URGENT'),
                                  backgroundColor: Colors.red.shade100,
                                  side: BorderSide(color: Colors.red.shade400),
                                ),
                              Chip(label: Text(_cladeLabel(_mission.clade))),
                              Chip(
                                label: Text(
                                  'Difficulté : ${_difficultyLabel(_mission.difficulty)}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // ── Prime ──────────────────────────────────────────
                          if (_mission.bounty != null)
                            Text(
                              'Prime finale : ${_mission.bounty} \u00a3',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (_roleLoaded && _isAdmin)
                            Text(
                              'Fourchette : ${_mission.bountyMin} \u2013 ${_mission.bountyMax} \u00a3',
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),

                          const Divider(height: 32),

                          // ── Dates ──────────────────────────────────────────
                          _DateRow(label: 'Affichée le', date: _mission.postedAt),
                          if (_mission.playedAt != null)
                            _DateRow(label: 'Jouée le', date: _mission.playedAt!),
                          if (_mission.completedAt != null)
                            _DateRow(label: 'Terminée le', date: _mission.completedAt!),

                          const Divider(height: 32),

                          // ── Description intro ──────────────────────────────
                          _SectionTitle('Description'),
                          const SizedBox(height: 8),
                          Text(_mission.descriptionIntro,
                              style: const TextStyle(fontSize: 15)),

                          // ── Description outro ──────────────────────────────
                          if (_mission.descriptionOutro != null) ...[
                            const SizedBox(height: 24),
                            _SectionTitle('\u00c9pilogue'),
                            const SizedBox(height: 8),
                            Text(_mission.descriptionOutro!,
                                style: const TextStyle(fontSize: 15)),
                          ],

                          // ── Notes MJ ───────────────────────────────────────
                          if (_mission.notesForDM != null) ...[
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
                                _mission.notesForDM!,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                          ],

                          // ── Agents impliqués ─────────────────────────────
                          if (_mission.agentInvolved != null &&
                              _mission.agentInvolved!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _SectionTitle('Agents impliqués'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _mission.agentInvolved!
                                  .map((a) => Chip(label: Text(a.agent.name)))
                                  .toList(),
                            ),
                          ],

                          // ── PNJs impliqués ───────────────────────────────
                          if (_mission.pnjInvolved != null &&
                              _mission.pnjInvolved!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _SectionTitle('PNJs impliqués'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _mission.pnjInvolved!
                                  .map((p) => ActionChip(
                                        label: Text(p.name),
                                        onPressed: () => Navigator.pushNamed(
                                          context,
                                          Routes.npcSheet,
                                          arguments: p,
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],

                          // ── Monstres impliqués ───────────────────────────
                          if (_mission.monsterInvolved != null &&
                              _mission.monsterInvolved!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _SectionTitle('Monstres impliqués'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _mission.monsterInvolved!
                                  .map((m) => ActionChip(
                                        label: Text(m.name),
                                        onPressed: () => Navigator.pushNamed(
                                          context,
                                          Routes.bestiarySheet,
                                          arguments: m,
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],

                          // ── Agents décédés ─────────────────────────────
                          if (_mission.agentDeceased != null &&
                              _mission.agentDeceased!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            _SectionTitle('Agents décédés'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _mission.agentDeceased!
                                  .map((a) => Chip(
                                        label: Text(a.agent.name),
                                        backgroundColor: Colors.red.shade50,
                                      ))
                                  .toList(),
                            ),
                          ],

                          // ── Rapports PDF ───────────────────────────────────
                          const SizedBox(height: 24),
                          _SectionTitle('Rapports'),
                          const SizedBox(height: 8),

                          if (_mission.reportPaths != null &&
                              _mission.reportPaths!.isNotEmpty)
                            ...(_mission.reportPaths!.asMap().entries.map((e) {
                              final index = e.key + 1;
                              final url = e.value;
                              final name = Uri.tryParse(url)
                                      ?.pathSegments
                                      .lastOrNull ??
                                  'Rapport $index';
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.picture_as_pdf,
                                    color: Colors.red),
                                title: Text(name),
                                trailing: const Icon(Icons.open_in_new, size: 18),
                                onTap: () async {
                                  final uri = Uri.tryParse(url);
                                  if (uri != null && await canLaunchUrl(uri)) {
                                    await launchUrl(uri,
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
                              );
                            })),

                          if (_mission.reportPaths == null ||
                              _mission.reportPaths!.isEmpty)
                            const Text(
                              'Aucun rapport pour le moment.',
                              style: TextStyle(
                                  fontStyle: FontStyle.italic, color: Colors.grey),
                            ),

                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _uploading ? null : _uploadReport,
                            icon: _uploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload_file),
                            label: Text(
                              _uploading
                                  ? 'Upload en cours\u2026'
                                  : 'Ajouter un rapport (PDF)',
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bouton retour en bas ─────────────────────────────────────────
              ],
            ),
          ),
          const SafeBackButtonOverlay(),
        ],
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

class _RollbackPreviewLine extends StatelessWidget {
  final AgentRollbackPreview preview;
  const _RollbackPreviewLine({required this.preview});

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    if (preview.rolledBackLevels.isNotEmpty) {
      lines.add(
        'Niveau ${preview.currentLevel} → ${preview.newLevel} '
        '(annulés : ${preview.rolledBackLevels.join(", ")})',
      );
    }
    if (preview.orphanedLevels.isNotEmpty) {
      lines.add(
        'Niveau(x) ${preview.orphanedLevels.join(", ")} non annulable(s) '
        "(pas d'historique)",
      );
    }
    if (lines.isEmpty) {
      lines.add('Aucun changement de niveau');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ${preview.agentName}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        ...lines.map(
          (l) => Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(l, style: const TextStyle(fontSize: 12)),
          ),
        ),
      ],
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
