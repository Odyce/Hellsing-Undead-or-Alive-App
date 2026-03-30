import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/pages/agentlist/agent_sheet.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

/// Données d'un agent non validé, enrichies avec les infos de son propriétaire.
class _PendingAgent {
  final String ownerUid;
  final String ownerPseudo;
  final String agentDocId;
  final String agentName;
  final String? picturePath;
  final String raceName;
  final List<String> bonuses;
  final List<String> maluses;

  const _PendingAgent({
    required this.ownerUid,
    required this.ownerPseudo,
    required this.agentDocId,
    required this.agentName,
    this.picturePath,
    required this.raceName,
    this.bonuses = const [],
    this.maluses = const [],
  });

  bool get isRaceAutre => raceName == 'Autre';
}

class AgentValidationListPage extends StatefulWidget {
  const AgentValidationListPage({super.key});

  @override
  State<AgentValidationListPage> createState() =>
      _AgentValidationListPageState();
}

class _AgentValidationListPageState extends State<AgentValidationListPage> {
  bool _loading = true;
  List<_PendingAgent> _pendingAgents = [];

  @override
  void initState() {
    super.initState();
    _loadPendingAgents();
  }

  Future<void> _loadPendingAgents() async {
    setState(() => _loading = true);

    try {
      // Récupérer tous les utilisateurs
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();

      final pending = <_PendingAgent>[];

      for (final userDoc in usersSnap.docs) {
        final pseudo = (userDoc.data()['pseudo'] as String?) ?? 'Inconnu';

        // Récupérer les agents non validés de cet utilisateur
        final agentsSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('agents')
            .where('validated', isEqualTo: false)
            .get();

        for (final agentDoc in agentsSnap.docs) {
          if (agentDoc.id == '_meta_') continue;
          final data = agentDoc.data();

          // Extraire les infos de race
          final raceMap = data['race'] as Map<String, dynamic>?;
          final raceName = raceMap?['name'] as String? ?? '';
          final bonuses = raceMap?['bonuses'] != null
              ? List<String>.from(raceMap!['bonuses'])
              : <String>[];
          final maluses = raceMap?['maluses'] != null
              ? List<String>.from(raceMap!['maluses'])
              : <String>[];

          pending.add(_PendingAgent(
            ownerUid: userDoc.id,
            ownerPseudo: pseudo,
            agentDocId: agentDoc.id,
            agentName: data['name'] ?? 'Agent sans nom',
            picturePath: data['profilPicturePath'] as String?,
            raceName: raceName,
            bonuses: bonuses,
            maluses: maluses,
          ));
        }
      }

      // Tri alphabétique par pseudo puis par nom d'agent
      pending.sort((a, b) {
        final cmp = a.ownerPseudo.compareTo(b.ownerPseudo);
        if (cmp != 0) return cmp;
        return a.agentName.compareTo(b.agentName);
      });

      if (mounted) {
        setState(() {
          _pendingAgents = pending;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Validation : race normale ──────────────────────────────────────────────
  Future<void> _confirmAndValidate(_PendingAgent agent) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la validation'),
        content: Text(
          'Voulez-vous valider l\'agent "${agent.agentName}" '
          '(${agent.raceName}) de ${agent.ownerPseudo} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _doValidate(agent);
  }

  // ─── Validation : race "Autre" (édition bonus/malus) ─────────────────────
  Future<void> _showAutreValidationDialog(_PendingAgent agent) async {
    final bonusCtrls = agent.bonuses
        .map((b) => TextEditingController(text: b))
        .toList();
    final malusCtrls = agent.maluses
        .map((m) => TextEditingController(text: m))
        .toList();

    // S'assurer qu'il y a au moins un champ
    if (bonusCtrls.isEmpty) bonusCtrls.add(TextEditingController());
    if (malusCtrls.isEmpty) malusCtrls.add(TextEditingController());

    final validated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AutreValidationDialog(
        agent: agent,
        bonusControllers: bonusCtrls,
        malusControllers: malusCtrls,
      ),
    );

    if (validated != true) {
      for (final c in bonusCtrls) { c.dispose(); }
      for (final c in malusCtrls) { c.dispose(); }
      return;
    }

    // Récupérer les valeurs finales
    final newBonuses = bonusCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final newMaluses = malusCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    for (final c in bonusCtrls) { c.dispose(); }
    for (final c in malusCtrls) { c.dispose(); }

    await _doValidateAutre(agent, newBonuses, newMaluses);
  }

  // ─── Écriture Firestore : validation simple ─────────────────────────────
  Future<void> _doValidate(_PendingAgent agent) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(agent.ownerUid)
          .collection('agents')
          .doc(agent.agentDocId)
          .update({'validated': true});

      // Retirer l'agent de la liste locale
      if (mounted) {
        setState(() {
          _pendingAgents.removeWhere((a) =>
              a.ownerUid == agent.ownerUid &&
              a.agentDocId == agent.agentDocId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${agent.agentName} validé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la validation : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ─── Écriture Firestore : validation race "Autre" ───────────────────────
  Future<void> _doValidateAutre(
    _PendingAgent agent,
    List<String> newBonuses,
    List<String> newMaluses,
  ) async {
    try {
      final agentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(agent.ownerUid)
          .collection('agents')
          .doc(agent.agentDocId);

      // 1. Mettre à jour les bonus/malus de la race + validated
      await agentRef.update({
        'validated': true,
        'race.bonuses': newBonuses.isEmpty ? null : newBonuses,
        'race.maluses': newMaluses.isEmpty ? null : newMaluses,
      });

      // 2. Mettre à jour le doc privateResources correspondant
      final privateSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(agent.ownerUid)
          .collection('privateResources')
          .where('type', isEqualTo: 'customRace')
          .where('agentName', isEqualTo: agent.agentName)
          .get();

      for (final doc in privateSnap.docs) {
        await doc.reference.update({
          'bonuses': newBonuses.isEmpty ? null : newBonuses,
          'maluses': newMaluses.isEmpty ? null : newMaluses,
        });
      }

      // 3. Retirer de la liste locale
      if (mounted) {
        setState(() {
          _pendingAgents.removeWhere((a) =>
              a.ownerUid == agent.ownerUid &&
              a.agentDocId == agent.agentDocId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${agent.agentName} validé avec succès.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la validation : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agents en attente de validation')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendingAgents.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun agent en attente de validation.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPendingAgents,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingAgents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final agent = _pendingAgents[index];
                      final hasPic = agent.picturePath != null &&
                          agent.picturePath!.trim().isNotEmpty;

                      return Card(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AgentSheetPage(
                                  agentDocId: agent.agentDocId,
                                  ownerUid: agent.ownerUid,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Photo de l'agent
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage:
                                      hasPic ? NetworkImage(agent.picturePath!) : null,
                                  child: hasPic
                                      ? null
                                      : const Icon(Icons.person),
                                ),
                                const SizedBox(width: 14),

                                // Nom agent + pseudo propriétaire + race
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        agent.agentName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Joueur : ${agent.ownerPseudo}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Race : ${agent.raceName}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: agent.isRaceAutre
                                              ? Colors.orange
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                          fontWeight: agent.isRaceAutre
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Bouton Valider
                                ElevatedButton.icon(
                                  onPressed: () => agent.isRaceAutre
                                      ? _showAutreValidationDialog(agent)
                                      : _confirmAndValidate(agent),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Valider'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.centerLeft,
          heightFactor: 1,
          child: TextButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, Routes.home),
            child: const Text('Retour'),
          ),
        ),
      ),
    );
  }
}

// ─── Dialog de validation pour race "Autre" ──────────────────────────────────

class _AutreValidationDialog extends StatefulWidget {
  final _PendingAgent agent;
  final List<TextEditingController> bonusControllers;
  final List<TextEditingController> malusControllers;

  const _AutreValidationDialog({
    required this.agent,
    required this.bonusControllers,
    required this.malusControllers,
  });

  @override
  State<_AutreValidationDialog> createState() => _AutreValidationDialogState();
}

class _AutreValidationDialogState extends State<_AutreValidationDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Valider "${widget.agent.agentName}"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Race : ${widget.agent.raceName}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            Text(
              'Joueur : ${widget.agent.ownerPseudo}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Vous pouvez modifier les bonus et malus de la race '
              'avant de valider l\'agent.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),

            // ── Bonus ──
            _buildEditableList(
              title: 'Bonus',
              color: Colors.green,
              controllers: widget.bonusControllers,
            ),
            const SizedBox(height: 12),

            // ── Malus ──
            _buildEditableList(
              title: 'Malus',
              color: Colors.red,
              controllers: widget.malusControllers,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Valider'),
        ),
      ],
    );
  }

  Widget _buildEditableList({
    required String title,
    required Color color,
    required List<TextEditingController> controllers,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () =>
                  setState(() => controllers.add(TextEditingController())),
            ),
          ],
        ),
        for (int i = 0; i < controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers[i],
                    decoration: InputDecoration(
                      hintText: '$title ${i + 1}',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                if (controllers.length > 1)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline,
                        size: 20, color: color),
                    onPressed: () => setState(() {
                      controllers[i].dispose();
                      controllers.removeAt(i);
                    }),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
