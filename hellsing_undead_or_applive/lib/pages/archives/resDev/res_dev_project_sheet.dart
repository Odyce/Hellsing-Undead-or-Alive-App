import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class ResDevProjectSheetPage extends StatefulWidget {
  const ResDevProjectSheetPage({super.key});

  @override
  State<ResDevProjectSheetPage> createState() => _ResDevProjectSheetPageState();
}

class _ResDevProjectSheetPageState extends State<ResDevProjectSheetPage> {
  late ResDevProject _project;
  late String        _docId;

  // ─── Agents de l'utilisateur ─────────────────────────────────────────────────
  List<Agent> _userAgents  = [];
  bool        _agentsLoaded = false;

  // ─── Réclamations en attente (index prérequis → agent sélectionné) ───────────
  // Contient uniquement les NOUVELLES réclamations faites sur cette session
  final Map<int, Agent?> _pendingClaims = {};

  bool _saving = false;

  final ResDevProjectRepository _repository = ResDevProjectRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _project = args['project'] as ResDevProject;
    _docId   = args['docId']   as String;
    if (!_agentsLoaded) _loadUserAgents();
  }

  Future<void> _loadUserAgents() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('agents')
          .get();
      final agents = snapshot.docs
          .where((d) => d.id != '_meta_')
          .map((d) => Agent.fromMap(d.data()))
          .toList();
      if (mounted) {
        setState(() {
          _userAgents   = agents;
          _agentsLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _agentsLoaded = true);
    }
  }

  // ─── Logique de réclamation ───────────────────────────────────────────────────

  bool _isAlreadyClaimed(int i) =>
      _project.prerequisiteAgents[i] != null;

  bool get _hasPendingChanges => _pendingClaims.values.any((a) => a != null);

  Future<void> _save() async {
    if (!_hasPendingChanges) return;
    setState(() => _saving = true);

    try {
      // Construire la nouvelle liste prerequisiteAgents
      final newAgents = List<Agent?>.from(_project.prerequisiteAgents);
      for (final entry in _pendingClaims.entries) {
        if (entry.value != null) newAgents[entry.key] = entry.value;
      }

      // Construire la nouvelle liste benefactor (sans doublons par id)
      final newBenefactors = List<Agent>.from(_project.benefactor);
      for (final agent in _pendingClaims.values) {
        if (agent != null &&
            !newBenefactors.any((b) => b.id == agent.id)) {
          newBenefactors.add(agent);
        }
      }

      final allClaimed = newAgents.every((a) => a != null);

      await _repository.saveClaims(
        docId:                  _docId,
        prerequisiteAgents:     newAgents,
        benefactor:             newBenefactors,
        prerequisiteCompletes:  allClaimed,
      );

      // Mettre à jour l'état local
      setState(() {
        _project = _project.copyWith(
          prerequisiteAgents:    newAgents,
          benefactor:            newBenefactors,
          prerequisiteCompletes: allClaimed,
        );
        _pendingClaims.clear();
        _saving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prérequis sauvegardés.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final p = _project;

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: Text(p.name),
        actions: [
          if (_hasPendingChanges)
            TextButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Valider'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Illustration ─────────────────────────────────────────────────────
          if (p.picturePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(p.picturePath!,
                  height: 200, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
          ],

          // ── Statut ────────────────────────────────────────────────────────────
          _statusChip(p),
          const SizedBox(height: 16),

          // ── Description ───────────────────────────────────────────────────────
          _SectionTitle(label: 'Description'),
          const SizedBox(height: 6),
          Text(p.description),
          const SizedBox(height: 20),

          // ── Coût ──────────────────────────────────────────────────────────────
          _InfoRow(label: 'Coût', value: p.cost.toString()),
          const SizedBox(height: 20),

          // ── Bénéficiaires ─────────────────────────────────────────────────────
          _SectionTitle(label: 'Bénéficiaires'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: p.benefactor
                .map((a) => Chip(label: Text(a.name)))
                .toList(),
          ),
          const SizedBox(height: 20),

          // ── Prérequis ─────────────────────────────────────────────────────────
          _SectionTitle(label: 'Prérequis'),
          const SizedBox(height: 4),

          if (!_agentsLoaded)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ...List.generate(p.prerequisite.length, (i) {
              return _buildPrerequisiteRow(i);
            }),

          if (_userAgents.isEmpty && _agentsLoaded) ...[
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez aucun agent — impossible de réclamer un prérequis.',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── Ligne de prérequis ───────────────────────────────────────────────────────
  Widget _buildPrerequisiteRow(int i) {
    final text         = _project.prerequisite[i];
    final claimedAgent = _project.prerequisiteAgents[i];
    final alreadyClaimed = _isAlreadyClaimed(i);
    final pendingAgent   = _pendingClaims[i];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ligne checkbox + texte ──────────────────────────────────────────
            Row(
              children: [
                Checkbox(
                  value: alreadyClaimed || pendingAgent != null,
                  onChanged: (alreadyClaimed || _userAgents.isEmpty)
                      ? null
                      : (checked) {
                          setState(() {
                            if (checked == true) {
                              // Pré-sélectionner le premier agent si un seul
                              _pendingClaims[i] = _userAgents.length == 1
                                  ? _userAgents.first
                                  : null;
                            } else {
                              _pendingClaims.remove(i);
                            }
                          });
                        },
                ),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      decoration:
                          alreadyClaimed ? TextDecoration.lineThrough : null,
                      color: alreadyClaimed
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            // ── Agent déjà assigné ────────────────────────────────────────────
            if (alreadyClaimed) ...[
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(claimedAgent!.name,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
            ],

            // ── Dropdown de sélection d'agent (réclamation en cours) ──────────
            if (!alreadyClaimed && _pendingClaims.containsKey(i)) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(48, 4, 0, 4),
                child: DropdownButtonFormField<Agent>(
                  decoration: const InputDecoration(
                    labelText: 'Choisir un agent',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  initialValue: _pendingClaims[i],
                  items: _userAgents
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(a.name),
                          ))
                      .toList(),
                  onChanged: (agent) =>
                      setState(() => _pendingClaims[i] = agent),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(ResDevProject p) {
    String label;
    Color  color;

    if (p.completed) {
      label = 'Complété';
      color = Colors.grey;
    } else if (p.prerequisiteCompletes) {
      label = 'Prêt à être développé';
      color = Colors.green;
    } else {
      final claimed = p.prerequisiteAgents.where((a) => a != null).length;
      label = 'Prérequis : $claimed / ${p.prerequisite.length}';
      color = Colors.orange;
    }

    return Chip(
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
    );
  }
}

// ─── Widgets utilitaires ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13)),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}
