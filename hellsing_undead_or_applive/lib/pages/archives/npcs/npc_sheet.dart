import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/pages/archives/widgets/field_notes_section.dart';
import 'package:hellsing_undead_or_applive/pages/archives/widgets/mission_history_section.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class NpcSheetPage extends StatefulWidget {
  const NpcSheetPage({super.key});

  @override
  State<NpcSheetPage> createState() => _NpcSheetPageState();
}

class _NpcSheetPageState extends State<NpcSheetPage> {
  late PNJ _pnj;
  bool _initialized = false;

  final PNJRepository _repository = PNJRepository();

  static String _typeLabel(Entitype t) => switch (t) {
        Entitype.demon  => 'Démon',
        Entitype.angel  => 'Semi-Ange',
        Entitype.midian => 'Midian',
        Entitype.beast  => 'B\u00eate',
        Entitype.human  => 'Humain',
      };

  static String _relationLabel(Relationship r) => switch (r) {
        Relationship.neutral => 'Neutre',
        Relationship.ally    => 'Allié',
        Relationship.enemy   => 'Ennemi',
        Relationship.trader  => "Allié tant qu'il y a des bénéfices",
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _pnj = ModalRoute.of(context)!.settings.arguments as PNJ;
      _initialized = true;
    }
  }

  Future<void> _refreshPNJ() async {
    final snap = await FirebaseFirestore.instance
        .collection('common')
        .doc('archives')
        .collection('npcs')
        .where('id', isEqualTo: _pnj.id)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty && mounted) {
      setState(() => _pnj = PNJ.fromMap(snap.docs.first.data()));
    }
  }

  // ─── Dialog : modifier la relation ─────────────────────────────────────────
  Future<void> _editRelation() async {
    Relationship? picked = _pnj.relation;

    final result = await showDialog<Relationship>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Modifier la relation'),
          content: RadioGroup<Relationship>(
            groupValue: picked,
            onChanged: (v) => setDialogState(() => picked = v),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: Relationship.values.map((r) {
                return RadioListTile<Relationship>(
                  title: Text(_relationLabel(r)),
                  value: r,
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, picked),
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != _pnj.relation) {
      await _repository.updatePNJ(_pnj.id, {'relation': result.name});
      await _refreshPNJ();
    }
  }

  // ─── Dialog : modifier alive ───────────────────────────────────────────────
  Future<void> _editAlive() async {
    bool? alive = _pnj.alive;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Modifier le statut'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(alive! ? 'Vivant' : 'Décédé',
                  style: TextStyle(
                    color: alive! ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(width: 12),
              Switch(
                value: alive!,
                onChanged: (v) => setDialogState(() => alive = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, alive),
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );

    if (result != null && result != _pnj.alive) {
      await _repository.updatePNJ(_pnj.id, {'alive': result});
      await _refreshPNJ();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: Text(_pnj.name),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Illustration ──────────────────────────────────────────────────
            if (_pnj.picturePath != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _pnj.picturePath!,
                    height: 220,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            if (_pnj.picturePath != null) const SizedBox(height: 24),

            // ── Nom & statut ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    _pnj.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(
                  _pnj.alive ? Icons.favorite : Icons.close,
                  color: _pnj.alive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  _pnj.alive ? 'Vivant' : 'Décédé',
                  style: TextStyle(
                    color: _pnj.alive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Modifier le statut',
                  onPressed: _editAlive,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Badges type + relation ────────────────────────────────────────
            Row(
              children: [
                Chip(label: Text(_typeLabel(_pnj.type))),
                const SizedBox(width: 8),
                Chip(label: Text(_relationLabel(_pnj.relation))),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Modifier la relation',
                  onPressed: _editRelation,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Description ───────────────────────────────────────────────────
            Text(
              'Description',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_pnj.description),
            const SizedBox(height: 32),

            // ── Missions ──────────────────────────────────────────────────────
            MissionHistorySection(missions: _pnj.missions),
            if (_pnj.missions.isNotEmpty) const SizedBox(height: 32),

            // ── Notes des agents ──────────────────────────────────────────────
            FieldNotesSection(targetType: 'npc', targetId: _pnj.id),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
