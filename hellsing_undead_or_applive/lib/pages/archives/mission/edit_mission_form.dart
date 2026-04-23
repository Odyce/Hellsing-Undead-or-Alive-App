import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

class EditMissionPage extends StatefulWidget {
  const EditMissionPage({super.key});

  @override
  State<EditMissionPage> createState() => _EditMissionPageState();
}

class _EditMissionPageState extends State<EditMissionPage> {
  // ─── Contr\u00f4leurs ──────────────────────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _notesForDMCtrl = TextEditingController();
  final _descriptionIntroCtrl = TextEditingController();
  final _descriptionOutroCtrl = TextEditingController();
  final _bountyMinCtrl = TextEditingController();
  final _bountyMaxCtrl = TextEditingController();
  final _bountyCtrl = TextEditingController();

  // ─── Champs enum & toggle ──────────────────────────────────────────────────
  Difficulty _difficulty = Difficulty.inconnu;
  CladeName _clade = CladeName.osiris;
  bool _urgent = false;

  // ─── Dates ─────────────────────────────────────────────────────────────────
  DateTime _postedAt = DateTime.now();
  DateTime? _playedAt;
  DateTime? _completedAt;

  // ─── Listes d'entités ─────────────────────────────────────────────────────
  List<AgentRef> _agentInvolved = [];
  List<PNJ> _pnjInvolved = [];
  List<Monster> _monsterInvolved = [];
  List<AgentRef> _agentDeceased = [];

  // ─── État original des entités (pour le diff lors de la sauvegarde) ────────
  List<AgentRef> _originalAgentInvolved = [];
  List<PNJ> _originalPnjInvolved = [];
  List<Monster> _originalMonsterInvolved = [];

  // ─── Données pour les pickers ──────────────────────────────────────────────
  List<AgentRef> _allAgentRefs = [];
  List<PNJ> _allPNJs = [];
  List<Monster> _allMonsters = [];
  bool _pickersLoaded = false;

  // ─── \u00c9tat ──────────────────────────────────────────────────────────────────
  late Mission _original;
  bool _initialized = false;
  String? _bountyMinError;
  String? _bountyMaxError;
  String? _error;
  bool _loading = false;

  final MissionRepository _repository = MissionRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _original = ModalRoute.of(context)!.settings.arguments as Mission;
      _initFields();
      _initialized = true;
      _loadPickerData();
    }
  }

  void _initFields() {
    _titleCtrl.text = _original.title;
    _notesForDMCtrl.text = _original.notesForDM ?? '';
    _descriptionIntroCtrl.text = _original.descriptionIntro;
    _descriptionOutroCtrl.text = _original.descriptionOutro ?? '';
    _bountyMinCtrl.text = _original.bountyMin.toString();
    _bountyMaxCtrl.text = _original.bountyMax.toString();
    _bountyCtrl.text = _original.bounty?.toString() ?? '';
    _difficulty = _original.difficulty;
    _clade = _original.clade;
    _urgent = _original.urgent;
    _postedAt = _original.postedAt;
    _playedAt = _original.playedAt;
    _completedAt = _original.completedAt;
    // Les listes d'AgentRef sont initialisées vides ici et remplies après
    // le chargement du picker (dans _loadPickerData) car on a besoin des
    // chemins Firestore (ownerUid, agentDocId) qui ne sont pas dans Mission.
    _pnjInvolved = List<PNJ>.from(_original.pnjInvolved ?? []);
    _monsterInvolved = List<Monster>.from(_original.monsterInvolved ?? []);
  }

  Future<void> _loadPickerData() async {
    final firestore = FirebaseFirestore.instance;

    // Charger PNJs et Monstres en parall\u00e8le
    final archiveRef = firestore.collection('common').doc('archives');
    final results = await Future.wait([
      archiveRef.collection('npcs').get(),
      archiveRef.collection('bestiary').get(),
    ]);

    final pnjs = results[0].docs.map((d) => PNJ.fromMap(d.data())).toList();
    final monsters = results[1].docs.map((d) => Monster.fromMap(d.data())).toList();

    // Charger tous les agents (parcourir tous les users)
    final allAgentRefs = <AgentRef>[];
    final usersSnap = await firestore.collection('users').get();
    for (final userDoc in usersSnap.docs) {
      final agentsSnap = await firestore
          .collection('users')
          .doc(userDoc.id)
          .collection('agents')
          .where('validated', isEqualTo: true)
          .get();
      for (final agentDoc in agentsSnap.docs) {
        allAgentRefs.add(AgentRef(
          ownerUid: userDoc.id,
          agentDocId: agentDoc.id,
          agent: Agent.fromMap(agentDoc.data()),
        ));
      }
    }

    // Reconstituer les listes d'AgentRef à partir des agents de la mission
    // originale, en les matchant par id dans la liste complète chargée.
    final originalAgentIds =
        _original.agentInvolved?.map((a) => a.id).toSet() ?? {};
    final originalDeceasedIds =
        _original.agentDeceased?.map((a) => a.id).toSet() ?? {};

    final matchedOriginalAgents = allAgentRefs
        .where((r) => originalAgentIds.contains(r.agent.id))
        .toList();
    final matchedOriginalDeceased = allAgentRefs
        .where((r) => originalDeceasedIds.contains(r.agent.id))
        .toList();

    if (mounted) {
      setState(() {
        _allPNJs = pnjs..sort((a, b) => a.name.compareTo(b.name));
        _allMonsters = monsters..sort((a, b) => a.name.compareTo(b.name));
        _allAgentRefs = allAgentRefs
          ..sort((a, b) => a.agent.name.compareTo(b.agent.name));

        // Initialiser les listes courantes et les originales pour le diff
        _agentInvolved = List<AgentRef>.from(matchedOriginalAgents);
        _agentDeceased = List<AgentRef>.from(matchedOriginalDeceased);
        _originalAgentInvolved = List<AgentRef>.from(matchedOriginalAgents);
        _originalPnjInvolved = List<PNJ>.from(_pnjInvolved);
        _originalMonsterInvolved = List<Monster>.from(_monsterInvolved);

        _pickersLoaded = true;
      });
    }
  }

  // ─── Validation ────────────────────────────────────────────────────────────
  bool get _canSave =>
      _titleCtrl.text.trim().isNotEmpty &&
      _descriptionIntroCtrl.text.trim().isNotEmpty &&
      _bountyMinError == null &&
      _bountyMaxError == null &&
      int.tryParse(_bountyMinCtrl.text) != null &&
      int.tryParse(_bountyMaxCtrl.text) != null &&
      !_loading;

  void _validateBounty() {
    final min = int.tryParse(_bountyMinCtrl.text);
    final max = int.tryParse(_bountyMaxCtrl.text);
    setState(() {
      _bountyMinError = min == null
          ? 'Nombre entier requis.'
          : min < 0
              ? 'Ne peut pas \u00eatre négatif.'
              : null;
      _bountyMaxError = max == null
          ? 'Nombre entier requis.'
          : max < 0
              ? 'Ne peut pas \u00eatre négatif.'
              : (min != null && max < min)
                  ? 'Doit \u00eatre \u2265 prime min.'
                  : null;
    });
  }

  // ─── Formatage date ────────────────────────────────────────────────────────
  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _pickDate({
    required DateTime initial,
    required void Function(DateTime) onPicked,
    DateTime? firstDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  // ─── Labels ────────────────────────────────────────────────────────────────
  String _difficultyLabel(Difficulty d) => switch (d) {
        Difficulty.basse     => 'Basse',
        Difficulty.moyenne   => 'Moyenne',
        Difficulty.haute     => 'Haute',
        Difficulty.inconnu   => 'Inconnue',
        Difficulty.tresHaute => 'Ma\u00efca',
      };

  String _cladeLabel(CladeName c) => switch (c) {
        CladeName.osiris          => 'Osiris',
        CladeName.blackOrchid     => 'Black Orchid',
        CladeName.pennyDreadful   => 'Penny Dreadful',
        CladeName.beginning       => 'The Beginning',
        CladeName.origins         => 'Origins',
        CladeName.unNeufTroisZero => '1930',
        CladeName.western         => 'Western',
        CladeName.arthur          => 'The Legend of King Arthur',
      };

  // ─── Pickers génériques ──────────────────────────────────────────────────
  Future<void> _showMultiPicker<T>({
    required String title,
    required List<T> allItems,
    required List<T> selected,
    required String Function(T) labelOf,
    required Object Function(T) idOf,
    required void Function(List<T>) onChanged,
  }) async {
    final currentIds = selected.map(idOf).toSet();
    final picked = Set<Object>.from(currentIds);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: allItems.length,
              itemBuilder: (_, i) {
                final item = allItems[i];
                final id = idOf(item);
                final isSelected = picked.contains(id);
                return CheckboxListTile(
                  title: Text(labelOf(item)),
                  value: isSelected,
                  onChanged: (v) {
                    setDialogState(() {
                      if (v == true) {
                        picked.add(id);
                      } else {
                        picked.remove(id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final result = allItems
                    .where((item) => picked.contains(idOf(item)))
                    .toList();
                onChanged(result);
                Navigator.pop(ctx);
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sauvegarde ────────────────────────────────────────────────────────────
  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bountyText = _bountyCtrl.text.trim();
      final bounty = bountyText.isNotEmpty ? int.tryParse(bountyText) : null;

      final fields = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'notesForDM': _notesForDMCtrl.text.trim().isEmpty
            ? null
            : _notesForDMCtrl.text.trim(),
        'descriptionIntro': _descriptionIntroCtrl.text.trim(),
        'descriptionOutro': _descriptionOutroCtrl.text.trim().isEmpty
            ? null
            : _descriptionOutroCtrl.text.trim(),
        'difficulty': _difficulty.name,
        'clade': _clade.name,
        'urgent': _urgent,
        'postedAt': Timestamp.fromDate(_postedAt),
        'playedAt': _playedAt != null ? Timestamp.fromDate(_playedAt!) : null,
        'completedAt':
            _completedAt != null ? Timestamp.fromDate(_completedAt!) : null,
        'bountyMin': int.parse(_bountyMinCtrl.text),
        'bountyMax': int.parse(_bountyMaxCtrl.text),
        'bounty': bounty,
        'agentInvolved': _agentInvolved.map((r) => r.agent.toMap()).toList(),
        'pnjInvolved': _pnjInvolved.map((p) => p.toMap()).toList(),
        'monsterInvolved': _monsterInvolved.map((m) => m.toMap()).toList(),
        'agentDeceased': _agentDeceased.map((r) => r.agent.toMap()).toList(),
      };

      await _repository.updateMissionFull(
        missionId: _original.id,
        fields: fields,
        newAgentInvolved: _agentInvolved,
        oldAgentInvolved: _originalAgentInvolved,
        newPnjInvolved: _pnjInvolved,
        oldPnjInvolved: _originalPnjInvolved,
        newMonsterInvolved: _monsterInvolved,
        oldMonsterInvolved: _originalMonsterInvolved,
        title: _titleCtrl.text.trim(),
        description: _descriptionIntroCtrl.text.trim(),
        completedAt: _completedAt,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Dispose ───────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesForDMCtrl.dispose();
    _descriptionIntroCtrl.dispose();
    _descriptionOutroCtrl.dispose();
    _bountyMinCtrl.dispose();
    _bountyMaxCtrl.dispose();
    _bountyCtrl.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la mission')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Titre ──────────────────────────────────────────────────────────
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Titre *'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // ── Difficulté ─────────────────────────────────────────────────────
          DropdownButtonFormField<Difficulty>(
            initialValue: _difficulty,
            decoration: const InputDecoration(labelText: 'Difficulté'),
            items: Difficulty.values
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(_difficultyLabel(d)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _difficulty = v);
            },
          ),
          const SizedBox(height: 16),

          // ── Clade ──────────────────────────────────────────────────────────
          DropdownButtonFormField<CladeName>(
            initialValue: _clade,
            decoration: const InputDecoration(labelText: 'Clade'),
            items: CladeName.values
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(_cladeLabel(c)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _clade = v);
            },
          ),
          const SizedBox(height: 8),

          // ── Urgente ────────────────────────────────────────────────────────
          SwitchListTile(
            title: const Text('Urgente'),
            value: _urgent,
            onChanged: (v) => setState(() => _urgent = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),

          // ── Fourchette de prime ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bountyMinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Prime min (\u00a3) *',
                    errorText: _bountyMinError,
                  ),
                  onChanged: (_) => _validateBounty(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _bountyMaxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Prime max (\u00a3) *',
                    errorText: _bountyMaxError,
                  ),
                  onChanged: (_) => _validateBounty(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Prime finale ───────────────────────────────────────────────────
          TextField(
            controller: _bountyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Prime finale (\u00a3) (optionnel)',
            ),
          ),
          const SizedBox(height: 24),

          // ── Dates ──────────────────────────────────────────────────────────
          Text('Dates', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date de publication *'),
            subtitle: Text(_formatDate(_postedAt)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(
              initial: _postedAt,
              onPicked: (d) => _postedAt = d,
            ),
          ),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date de jeu'),
            subtitle: Text(
              _playedAt != null ? _formatDate(_playedAt!) : 'Non renseignée',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_playedAt != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Effacer',
                    onPressed: () => setState(() => _playedAt = null),
                  ),
                const Icon(Icons.calendar_today),
              ],
            ),
            onTap: () => _pickDate(
              initial: _playedAt ?? DateTime.now(),
              onPicked: (d) => _playedAt = d,
            ),
          ),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date de complétion'),
            subtitle: Text(
              _completedAt != null
                  ? _formatDate(_completedAt!)
                  : 'Non renseignée',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_completedAt != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Effacer',
                    onPressed: () => setState(() => _completedAt = null),
                  ),
                const Icon(Icons.calendar_today),
              ],
            ),
            onTap: () => _pickDate(
              initial: _completedAt ?? DateTime(1877, 6, 1),
              onPicked: (d) => _completedAt = d,
              firstDate: DateTime(1800),
            ),
          ),
          const SizedBox(height: 24),

          // ── Descriptions ───────────────────────────────────────────────────
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          TextField(
            controller: _descriptionIntroCtrl,
            decoration: const InputDecoration(
              labelText: 'Introduction *',
              helperText: 'Description principale de la mission.',
            ),
            minLines: 3,
            maxLines: 12,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _descriptionOutroCtrl,
            decoration: const InputDecoration(
              labelText: 'Outro (optionnel)',
              helperText: 'Résumé ou conclusion apr\u00e8s la mission.',
            ),
            minLines: 2,
            maxLines: 8,
          ),
          const SizedBox(height: 24),

          // ── Notes MJ ───────────────────────────────────────────────────────
          Text('Notes MJ', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          TextField(
            controller: _notesForDMCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
              helperText: 'Informations réservées au MJ.',
            ),
            minLines: 2,
            maxLines: 8,
          ),
          const SizedBox(height: 24),

          // ── Pickers entités ────────────────────────────────────────────────
          Text('Entités liées',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          if (!_pickersLoaded)
            const Center(child: CircularProgressIndicator())
          else ...[
            // Agents impliqués
            _EntityPickerTile(
              label: 'Agents impliqués',
              count: _agentInvolved.length,
              chips: _agentInvolved.map((r) => r.agent.name).toList(),
              onTap: () => _showMultiPicker<AgentRef>(
                title: 'Agents impliqués',
                allItems: _allAgentRefs,
                selected: _agentInvolved,
                labelOf: (r) => r.agent.name,
                idOf: (r) => r.agent.id,
                onChanged: (list) => setState(() {
                  _agentInvolved = list;
                  final involvedIds = list.map((r) => r.agent.id).toSet();
                  _agentDeceased
                      .removeWhere((r) => !involvedIds.contains(r.agent.id));
                }),
              ),
            ),
            const SizedBox(height: 8),

            // Agents décédés (sous-ensemble des impliqués)
            _EntityPickerTile(
              label: 'Agents décédés',
              count: _agentDeceased.length,
              chips: _agentDeceased.map((r) => r.agent.name).toList(),
              chipColor: Colors.red.shade50,
              onTap: _agentInvolved.isEmpty
                  ? null
                  : () => _showMultiPicker<AgentRef>(
                        title: 'Agents décédés',
                        allItems: _agentInvolved,
                        selected: _agentDeceased,
                        labelOf: (r) => r.agent.name,
                        idOf: (r) => r.agent.id,
                        onChanged: (list) =>
                            setState(() => _agentDeceased = list),
                      ),
            ),
            const SizedBox(height: 8),

            // PNJs impliqués
            _EntityPickerTile(
              label: 'PNJs impliqués',
              count: _pnjInvolved.length,
              chips: _pnjInvolved.map((p) => p.name).toList(),
              onTap: () => _showMultiPicker<PNJ>(
                title: 'PNJs impliqués',
                allItems: _allPNJs,
                selected: _pnjInvolved,
                labelOf: (p) => p.name,
                idOf: (p) => p.id,
                onChanged: (list) => setState(() => _pnjInvolved = list),
              ),
            ),
            const SizedBox(height: 8),

            // Monstres impliqués
            _EntityPickerTile(
              label: 'Monstres impliqués',
              count: _monsterInvolved.length,
              chips: _monsterInvolved.map((m) => m.name).toList(),
              onTap: () => _showMultiPicker<Monster>(
                title: 'Monstres impliqués',
                allItems: _allMonsters,
                selected: _monsterInvolved,
                labelOf: (m) => m.name,
                idOf: (m) => m.id,
                onChanged: (list) => setState(() => _monsterInvolved = list),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // ── Erreur & bouton sauvegarde ──────────────────────────────────────
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSave ? _save : null,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Enregistrer les modifications'),
            ),
          ),

          Align(
            alignment: Alignment.bottomLeft,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget helper pour les pickers d'entités ─────────────────────────────────

class _EntityPickerTile extends StatelessWidget {
  final String label;
  final int count;
  final List<String> chips;
  final Color? chipColor;
  final VoidCallback? onTap;

  const _EntityPickerTile({
    required this.label,
    required this.count,
    required this.chips,
    this.chipColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$label ($count)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  Icons.edit,
                  size: 18,
                  color: onTap != null ? null : Colors.grey.shade400,
                ),
              ],
            ),
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: chips
                    .map((name) => Chip(
                          label: Text(name, style: const TextStyle(fontSize: 12)),
                          backgroundColor: chipColor,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
