import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/domain/stats/stats_repository.dart';
import 'package:hellsing_undead_or_applive/pages/agentlist/agent_sheet.dart';
import 'package:hellsing_undead_or_applive/pages/agentlist/level_up_page.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

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
  final bool pendingFreeContact;

  /// Skills marquées `pendingCustom: true` que l'admin doit détailler.
  final List<Skill> pendingCustomSkills;

  /// Snapshot complet des skills de l'agent (pour pouvoir les remplacer
  /// proprement après détail des compétences custom).
  final List<Skill> allSkills;

  const _PendingAgent({
    required this.ownerUid,
    required this.ownerPseudo,
    required this.agentDocId,
    required this.agentName,
    this.picturePath,
    required this.raceName,
    this.bonuses = const [],
    this.maluses = const [],
    this.pendingFreeContact = false,
    this.pendingCustomSkills = const [],
    this.allSkills = const [],
  });

  bool get isRaceAutre => raceName == 'Autre';
  bool get hasPendingSkills => pendingCustomSkills.isNotEmpty;
}

/// Règle custom de montée de niveau, construite par l'admin dans le dialog.
class _CustomLevelUpRule {
  String label;
  List<String> optionIds;
  bool isAutomatic;

  _CustomLevelUpRule({
    required this.label,
    required this.optionIds,
    required this.isAutomatic,
  });
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

          // Skills (toutes + pending custom)
          final allSkills = (data['skills'] as List?)
                  ?.map((s) =>
                      Skill.fromMap(Map<String, dynamic>.from(s as Map)))
                  .toList() ??
              const <Skill>[];
          final pendingCustomSkills =
              allSkills.where((s) => s.pendingCustom).toList();

          pending.add(_PendingAgent(
            ownerUid: userDoc.id,
            ownerPseudo: pseudo,
            agentDocId: agentDoc.id,
            agentName: data['name'] ?? 'Agent sans nom',
            picturePath: data['profilPicturePath'] as String?,
            raceName: raceName,
            bonuses: bonuses,
            maluses: maluses,
            pendingFreeContact: data['pendingFreeContact'] as bool? ?? false,
            pendingCustomSkills: pendingCustomSkills,
            allSkills: allSkills,
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

  // ─── Dispatch principal ────────────────────────────────────────────────────
  Future<void> _routeValidation(_PendingAgent agent) async {
    // Cas 1 : race "Autre" + pending skills → dialog combiné
    // Cas 2 : pending skills uniquement → dialog skills
    // Cas 3 : race "Autre" uniquement → dialog Autre existant
    // Cas 4 : ni l'un ni l'autre → confirmation simple
    if (agent.hasPendingSkills) {
      await _showCustomSkillsValidationDialog(agent);
    } else if (agent.isRaceAutre) {
      await _showAutreValidationDialog(agent);
    } else {
      await _confirmAndValidate(agent);
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

  // ─── Validation : compétences custom (+ race "Autre" si applicable) ──────
  Future<void> _showCustomSkillsValidationDialog(_PendingAgent agent) async {
    final skillData = agent.pendingCustomSkills
        .map((s) => _CustomSkillData.fromPending(s))
        .toList();

    // Si race "Autre", on prépare aussi les champs bonus/malus + règles
    final isAutre = agent.isRaceAutre;
    final bonusCtrls = isAutre
        ? agent.bonuses.map((b) => TextEditingController(text: b)).toList()
        : <TextEditingController>[];
    final malusCtrls = isAutre
        ? agent.maluses.map((m) => TextEditingController(text: m)).toList()
        : <TextEditingController>[];
    if (isAutre) {
      if (bonusCtrls.isEmpty) bonusCtrls.add(TextEditingController());
      if (malusCtrls.isEmpty) malusCtrls.add(TextEditingController());
    }
    final levelUpRules = isAutre
        ? <_CustomLevelUpRule>[
            _CustomLevelUpRule(
                label: 'Choix 1', optionIds: [], isAutomatic: false),
          ]
        : <_CustomLevelUpRule>[];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _CustomSkillsValidationDialog(
        agent: agent,
        skillData: skillData,
        bonusControllers: bonusCtrls,
        malusControllers: malusCtrls,
        levelUpRules: levelUpRules,
      ),
    );

    if (confirmed != true) {
      _disposeSkillData(skillData);
      for (final c in bonusCtrls) { c.dispose(); }
      for (final c in malusCtrls) { c.dispose(); }
      return;
    }

    // Construire les nouvelles skills (fusion : on remplace les pending par
    // leurs versions détaillées, on garde les autres telles quelles).
    final newSkills = agent.allSkills.map((s) {
      if (!s.pendingCustom) return s;
      final data = skillData.firstWhere((d) => d.id == s.id);
      return data.toSkill();
    }).toList();

    // Race Autre : bonus/malus/rules
    final newBonuses = bonusCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final newMaluses = malusCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final rulesForFirestore = levelUpRules
        .where((r) => r.optionIds.isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((e) => {
              'id': 'custom_${e.key}',
              'label': e.value.label,
              'optionIds': e.value.optionIds,
              'isAutomatic': e.value.isAutomatic,
            })
        .toList();

    _disposeSkillData(skillData);
    for (final c in bonusCtrls) { c.dispose(); }
    for (final c in malusCtrls) { c.dispose(); }

    await _doValidateWithCustomSkills(
      agent: agent,
      newSkills: newSkills,
      newBonuses: isAutre ? newBonuses : null,
      newMaluses: isAutre ? newMaluses : null,
      customLevelUpRules: isAutre ? rulesForFirestore : null,
    );
  }

  void _disposeSkillData(List<_CustomSkillData> data) {
    for (final d in data) {
      d.dispose();
    }
  }

  Future<void> _doValidateWithCustomSkills({
    required _PendingAgent agent,
    required List<Skill> newSkills,
    List<String>? newBonuses,
    List<String>? newMaluses,
    List<Map<String, dynamic>>? customLevelUpRules,
  }) async {
    try {
      final agentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(agent.ownerUid)
          .collection('agents')
          .doc(agent.agentDocId);

      final updateData = <String, dynamic>{
        'validated': true,
        'pendingFreeContact': false,
        'pendingCustomSkill': false,
        'skills': newSkills.map((s) => s.toMap()).toList(),
      };
      if (newBonuses != null) {
        updateData['race.bonuses'] = newBonuses.isEmpty ? null : newBonuses;
      }
      if (newMaluses != null) {
        updateData['race.maluses'] = newMaluses.isEmpty ? null : newMaluses;
      }
      if (customLevelUpRules != null && customLevelUpRules.isNotEmpty) {
        updateData['customLevelUpRules'] = customLevelUpRules;
      }

      await agentRef.update(updateData);
      StatsRepository.scheduleRebuild();

      // Marquer les notifs admin liées à cet agent comme lues
      await NotificationRepository().markAgentNotifAsRead(agent.agentName);

      // privateResources pour race Autre
      if (newBonuses != null && newMaluses != null && agent.isRaceAutre) {
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
      }

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

  // ─── Validation : race "Autre" (édition bonus/malus + règles level-up) ────
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

    // Règles de montée de niveau custom
    final levelUpRules = <_CustomLevelUpRule>[
      _CustomLevelUpRule(label: 'Choix 1', optionIds: [], isAutomatic: false),
    ];

    final validated = await showDialog<bool>(
      context: context,
      builder: (ctx) => _AutreValidationDialog(
        agent: agent,
        bonusControllers: bonusCtrls,
        malusControllers: malusCtrls,
        levelUpRules: levelUpRules,
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

    // Convertir les règles en maps pour Firestore
    final rulesForFirestore = levelUpRules
        .where((r) => r.optionIds.isNotEmpty)
        .toList()
        .asMap()
        .entries
        .map((e) => {
              'id': 'custom_${e.key}',
              'label': e.value.label,
              'optionIds': e.value.optionIds,
              'isAutomatic': e.value.isAutomatic,
            })
        .toList();

    await _doValidateAutre(agent, newBonuses, newMaluses, rulesForFirestore);
  }

  // ─── Écriture Firestore : validation simple ─────────────────────────────
  Future<void> _doValidate(_PendingAgent agent) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(agent.ownerUid)
          .collection('agents')
          .doc(agent.agentDocId)
          .update({
            'validated': true,
            'pendingFreeContact': false,
          });
      StatsRepository.scheduleRebuild();

      // Marquer les notifs admin liées à cet agent comme lues
      await NotificationRepository().markAgentNotifAsRead(agent.agentName);

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
    List<Map<String, dynamic>> customLevelUpRules,
  ) async {
    try {
      final agentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(agent.ownerUid)
          .collection('agents')
          .doc(agent.agentDocId);

      // 1. Mettre à jour les bonus/malus de la race + validated + rules
      final updateData = <String, dynamic>{
        'validated': true,
        'pendingFreeContact': false,
        'race.bonuses': newBonuses.isEmpty ? null : newBonuses,
        'race.maluses': newMaluses.isEmpty ? null : newMaluses,
      };
      if (customLevelUpRules.isNotEmpty) {
        updateData['customLevelUpRules'] = customLevelUpRules;
      }
      await agentRef.update(updateData);
      StatsRepository.scheduleRebuild();

      // Marquer les notifs admin liées à cet agent comme lues
      await NotificationRepository().markAgentNotifAsRead(agent.agentName);

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
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: const Text('Agents en attente de validation'),
      ),
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
                                      if (agent.pendingFreeContact)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.purple,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'Contact Gratuit à vérifier',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (agent.hasPendingSkills)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.deepOrange,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '${agent.pendingCustomSkills.length} '
                                              'compétence(s) custom à détailler',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                // Bouton Valider
                                ElevatedButton.icon(
                                  onPressed: () => _routeValidation(agent),
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
    );
  }
}

// ─── Dialog de validation pour race "Autre" ──────────────────────────────────

class _AutreValidationDialog extends StatefulWidget {
  final _PendingAgent agent;
  final List<TextEditingController> bonusControllers;
  final List<TextEditingController> malusControllers;
  final List<_CustomLevelUpRule> levelUpRules;

  const _AutreValidationDialog({
    required this.agent,
    required this.bonusControllers,
    required this.malusControllers,
    required this.levelUpRules,
  });

  @override
  State<_AutreValidationDialog> createState() => _AutreValidationDialogState();
}

class _AutreValidationDialogState extends State<_AutreValidationDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Valider "${widget.agent.agentName}"'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
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

              const Divider(height: 32),

              // ── Règles de montée de niveau ──
              _buildLevelUpRulesSection(),
            ],
          ),
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

  // ── Liste éditable de bonus/malus ─────────────────────────────────────────

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

  // ── Section règles de montée de niveau ────────────────────────────────────

  Widget _buildLevelUpRulesSection() {
    final rules = widget.levelUpRules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Règles de montée de niveau',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              tooltip: 'Ajouter une règle',
              onPressed: () => setState(() {
                rules.add(_CustomLevelUpRule(
                  label: 'Choix ${rules.length + 1}',
                  optionIds: [],
                  isAutomatic: false,
                ));
              }),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Chaque règle est un choix présenté à l\'utilisateur lors '
          'de la montée de niveau. Une règle automatique (1 seule option) '
          's\'applique sans choix.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        for (int i = 0; i < rules.length; i++)
          _buildRuleCard(i, rules[i]),
      ],
    );
  }

  Widget _buildRuleCard(int index, _CustomLevelUpRule rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête : label + supprimer ──
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: rule.label),
                    decoration: const InputDecoration(
                      labelText: 'Nom de la règle',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => rule.label = v,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.levelUpRules.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                    tooltip: 'Supprimer cette règle',
                    onPressed: () => setState(() {
                      widget.levelUpRules.removeAt(index);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Toggle automatique ──
            Row(
              children: [
                const Text('Automatique', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Switch(
                  value: rule.isAutomatic,
                  onChanged: (v) => setState(() => rule.isAutomatic = v),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Options sélectionnées ──
            const Text('Options :', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final oid in rule.optionIds)
                  Chip(
                    label: Text(
                      levelUpOptionLabel(oid),
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() {
                      rule.optionIds.remove(oid);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Bouton ajouter une option ──
            PopupMenuButton<String>(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 4),
                    Text('Ajouter une option', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              itemBuilder: (_) => allLevelUpOptions
                  .where((opt) => !rule.optionIds.contains(opt.id))
                  .map((opt) => PopupMenuItem(
                        value: opt.id,
                        child: Text(opt.label),
                      ))
                  .toList(),
              onSelected: (optId) => setState(() {
                rule.optionIds.add(optId);
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Holder mutable pour l'édition d'une compétence custom ───────────────────

class _CustomSkillData {
  final int id;
  final TextEditingController nameCtrl;
  final TextEditingController costCtrl;
  CostType costType;
  bool hasSecondCost;
  final TextEditingController secondCostCtrl;
  CostType secondCostType;
  bool multiCost;
  final List<TextEditingController> costsCtrls;
  final List<TextEditingController> descsCtrls;
  bool limited;
  final TextEditingController descriptionCtrl;

  _CustomSkillData({
    required this.id,
    required String name,
    required this.costType,
    required this.hasSecondCost,
    required this.secondCostType,
    required this.multiCost,
    required this.limited,
    required String description,
  })  : nameCtrl = TextEditingController(text: name),
        costCtrl = TextEditingController(text: '0'),
        secondCostCtrl = TextEditingController(text: '0'),
        costsCtrls = [TextEditingController(text: '0')],
        descsCtrls = [TextEditingController()],
        descriptionCtrl = TextEditingController(text: description);

  factory _CustomSkillData.fromPending(Skill s) => _CustomSkillData(
        id: s.id,
        name: s.name,
        costType: CostType.pe,
        hasSecondCost: false,
        secondCostType: CostType.pm,
        multiCost: false,
        limited: false,
        description: '',
      );

  Skill toSkill() {
    final parsedCost = int.tryParse(costCtrl.text.trim()) ?? 0;
    final parsedSecondCost =
        int.tryParse(secondCostCtrl.text.trim()) ?? 0;
    final parsedCosts = costsCtrls
        .map((c) => int.tryParse(c.text.trim()) ?? 0)
        .toList();
    final parsedDescs = descsCtrls.map((c) => c.text.trim()).toList();

    return Skill(
      id: id,
      name: nameCtrl.text.trim(),
      cost: parsedCost,
      costType: costType,
      secondCost: hasSecondCost ? parsedSecondCost : null,
      secondCostType: hasSecondCost ? secondCostType : null,
      multiCost: multiCost,
      costs: multiCost ? parsedCosts : null,
      descriptions: multiCost ? parsedDescs : null,
      limited: limited,
      description: descriptionCtrl.text.trim(),
      pendingCustom: false,
    );
  }

  bool get isValid {
    if (nameCtrl.text.trim().isEmpty) return false;
    if (descriptionCtrl.text.trim().isEmpty) return false;
    if (multiCost) {
      if (costsCtrls.isEmpty) return false;
      if (costsCtrls.length != descsCtrls.length) return false;
      for (final c in costsCtrls) {
        if (int.tryParse(c.text.trim()) == null) return false;
      }
      for (final d in descsCtrls) {
        if (d.text.trim().isEmpty) return false;
      }
    } else {
      if (int.tryParse(costCtrl.text.trim()) == null) return false;
      if (hasSecondCost &&
          int.tryParse(secondCostCtrl.text.trim()) == null) {
        return false;
      }
    }
    return true;
  }

  void dispose() {
    nameCtrl.dispose();
    costCtrl.dispose();
    secondCostCtrl.dispose();
    descriptionCtrl.dispose();
    for (final c in costsCtrls) {
      c.dispose();
    }
    for (final c in descsCtrls) {
      c.dispose();
    }
  }
}

// ─── Dialog de validation : compétences custom (+ race "Autre" si besoin) ──

class _CustomSkillsValidationDialog extends StatefulWidget {
  final _PendingAgent agent;
  final List<_CustomSkillData> skillData;
  final List<TextEditingController> bonusControllers;
  final List<TextEditingController> malusControllers;
  final List<_CustomLevelUpRule> levelUpRules;

  const _CustomSkillsValidationDialog({
    required this.agent,
    required this.skillData,
    required this.bonusControllers,
    required this.malusControllers,
    required this.levelUpRules,
  });

  @override
  State<_CustomSkillsValidationDialog> createState() =>
      _CustomSkillsValidationDialogState();
}

class _CustomSkillsValidationDialogState
    extends State<_CustomSkillsValidationDialog> {
  bool get _allValid =>
      widget.skillData.every((d) => d.isValid);

  @override
  Widget build(BuildContext context) {
    final isAutre = widget.agent.isRaceAutre;

    return AlertDialog(
      title: Text('Valider "${widget.agent.agentName}"'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Joueur : ${widget.agent.ownerPseudo}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (isAutre)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Race : Autre',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // ── Race "Autre" : bonus / malus / règles ──
              if (isAutre) ...[
                _buildEditableList(
                  title: 'Bonus',
                  color: Colors.green,
                  controllers: widget.bonusControllers,
                ),
                const SizedBox(height: 12),
                _buildEditableList(
                  title: 'Malus',
                  color: Colors.red,
                  controllers: widget.malusControllers,
                ),
                const Divider(height: 32),
                _buildLevelUpRulesSection(),
                const Divider(height: 32),
              ],

              // ── Compétences custom ──
              const Text(
                'Compétences custom à détailler',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange),
              ),
              const SizedBox(height: 4),
              const Text(
                'Renseigne les détails de chaque compétence proposée par le joueur.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              for (final data in widget.skillData)
                _buildCustomSkillForm(data),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed:
              _allValid ? () => Navigator.pop(context, true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Valider'),
        ),
      ],
    );
  }

  // ── Formulaire d'une compétence custom ───────────────────────────────────
  Widget _buildCustomSkillForm(_CustomSkillData d) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nom
            TextField(
              controller: d.nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),

            // Limité
            Row(
              children: [
                const Text('Limité', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Switch(
                  value: d.limited,
                  onChanged: (v) => setState(() => d.limited = v),
                ),
              ],
            ),

            // Multi cost
            Row(
              children: [
                const Text('Coût multiple', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Switch(
                  value: d.multiCost,
                  onChanged: (v) => setState(() {
                    d.multiCost = v;
                    if (v) d.hasSecondCost = false;
                  }),
                ),
              ],
            ),

            if (!d.multiCost) ...[
              // Coût simple
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: d.costCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Coût',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<CostType>(
                      initialValue: d.costType,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: CostType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.name.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => d.costType = v ?? d.costType),
                    ),
                  ),
                ],
              ),

              // Second cost
              Row(
                children: [
                  const Text('Second coût',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Switch(
                    value: d.hasSecondCost,
                    onChanged: (v) =>
                        setState(() => d.hasSecondCost = v),
                  ),
                ],
              ),
              if (d.hasSecondCost)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: d.secondCostCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Second coût',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<CostType>(
                        initialValue: d.secondCostType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: CostType.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.name.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (v) => setState(
                            () => d.secondCostType = v ?? d.secondCostType),
                      ),
                    ),
                  ],
                ),
            ] else ...[
              // Multi cost : liste de paires (cost, description)
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text('Type de coût (commun) :',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  DropdownButton<CostType>(
                    value: d.costType,
                    items: CostType.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.name.toUpperCase()),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => d.costType = v ?? d.costType),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              for (int i = 0; i < d.costsCtrls.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: d.costsCtrls[i],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Coût',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: d.descsCtrls[i],
                          decoration: const InputDecoration(
                            labelText: 'Description niveau',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (d.costsCtrls.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 20, color: Colors.red),
                          onPressed: () => setState(() {
                            d.costsCtrls[i].dispose();
                            d.descsCtrls[i].dispose();
                            d.costsCtrls.removeAt(i);
                            d.descsCtrls.removeAt(i);
                          }),
                        ),
                    ],
                  ),
                ),
              TextButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Ajouter un palier'),
                onPressed: () => setState(() {
                  d.costsCtrls.add(TextEditingController(text: '0'));
                  d.descsCtrls.add(TextEditingController());
                }),
              ),
            ],

            const SizedBox(height: 8),

            // Description générale
            TextField(
              controller: d.descriptionCtrl,
              decoration: const InputDecoration(
                labelText: 'Description',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  // ── Liste éditable bonus/malus (race Autre) ──────────────────────────────
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

  // ── Section règles level-up (race Autre) — copie de _AutreValidationDialog
  Widget _buildLevelUpRulesSection() {
    final rules = widget.levelUpRules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Règles de montée de niveau',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              tooltip: 'Ajouter une règle',
              onPressed: () => setState(() {
                rules.add(_CustomLevelUpRule(
                  label: 'Choix ${rules.length + 1}',
                  optionIds: [],
                  isAutomatic: false,
                ));
              }),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Chaque règle est un choix présenté à l\'utilisateur lors '
          'de la montée de niveau. Une règle automatique (1 seule option) '
          's\'applique sans choix.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < rules.length; i++)
          _buildRuleCard(i, rules[i]),
      ],
    );
  }

  Widget _buildRuleCard(int index, _CustomLevelUpRule rule) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: rule.label),
                    decoration: const InputDecoration(
                      labelText: 'Nom de la règle',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => rule.label = v,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.levelUpRules.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                    tooltip: 'Supprimer cette règle',
                    onPressed: () => setState(() {
                      widget.levelUpRules.removeAt(index);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Automatique', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 8),
                Switch(
                  value: rule.isAutomatic,
                  onChanged: (v) => setState(() => rule.isAutomatic = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Options :',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final oid in rule.optionIds)
                  Chip(
                    label: Text(
                      levelUpOptionLabel(oid),
                      style: const TextStyle(fontSize: 12),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() {
                      rule.optionIds.remove(oid);
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            PopupMenuButton<String>(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16),
                    SizedBox(width: 4),
                    Text('Ajouter une option',
                        style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              itemBuilder: (_) => allLevelUpOptions
                  .where((opt) => !rule.optionIds.contains(opt.id))
                  .map((opt) => PopupMenuItem(
                        value: opt.id,
                        child: Text(opt.label),
                      ))
                  .toList(),
              onSelected: (optId) => setState(() {
                rule.optionIds.add(optId);
              }),
            ),
          ],
        ),
      ),
    );
  }
}
