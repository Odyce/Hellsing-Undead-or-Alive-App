import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

// ─── Référence légère à un agent ──────────────────────────────────────────────

class _AgentRef {
  final String docId;
  final String name;
  final String? picturePath;

  const _AgentRef(this.docId, this.name, this.picturePath);

  @override
  bool operator ==(Object other) => other is _AgentRef && other.docId == docId;

  @override
  int get hashCode => docId.hashCode;
}

// ─── Widget principal ─────────────────────────────────────────────────────────

/// Section "Notes des agents" à inclure dans une fiche PNJ ou Bestiaire.
///
/// [targetType] : 'npc' ou 'monster'
/// [targetId]   : l'identifiant entier de l'entité
class FieldNotesSection extends StatefulWidget {
  final String targetType;
  final int targetId;

  const FieldNotesSection({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  @override
  State<FieldNotesSection> createState() => _FieldNotesSectionState();
}

class _FieldNotesSectionState extends State<FieldNotesSection> {
  List<FieldNote> _notes = [];
  List<_AgentRef> _agents = [];
  bool _loading = true;

  /// Clé du document Firestore : "npc_42" ou "monster_7"
  String get _docKey => '${widget.targetType}_${widget.targetId}';

  /// Référence à la sous-collection d'entrées pour cette entité
  CollectionReference<Map<String, dynamic>> get _entriesRef =>
      FirebaseFirestore.instance
          .collection('common')
          .doc('archives')
          .collection('field_notes')
          .doc(_docKey)
          .collection('entries');

  // ─── Chargement ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final agentsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('agents')
        .where(FieldPath.documentId, isNotEqualTo: '_meta_')
        .get();

    final notesSnap = await _entriesRef.get();

    if (!mounted) return;

    setState(() {
      _agents = agentsSnap.docs.map((doc) {
        final pic = doc['profilPicturePath'] as String?;
        return _AgentRef(
          doc.id,
          doc['name'] as String? ?? 'Agent',
          (pic != null && pic.trim().isNotEmpty) ? pic : null,
        );
      }).toList();

      _notes = notesSnap.docs
          .map((doc) => FieldNote.fromMap(doc.id, doc.data()))
          .toList();

      _loading = false;
    });
  }

  // ─── Agents éligibles (sans note existante) ──────────────────────────────────

  List<_AgentRef> get _eligibleAgents {
    final usedIds = _notes.map((n) => n.agentDocId).toSet();
    return _agents.where((a) => !usedIds.contains(a.docId)).toList();
  }

  // ─── Dialogue d'ajout ────────────────────────────────────────────────────────

  Future<void> _showAddNoteDialog() async {
    final eligible = _eligibleAgents;
    if (eligible.isEmpty) return;

    _AgentRef selected = eligible.first;
    final noteCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: '03/03/1877');

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text('Laisser une note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sélection de l'agent ──────────────────────────────────────
                const Text('Agent :'),
                DropdownButton<_AgentRef>(
                  value: selected,
                  isExpanded: true,
                  items: eligible
                      .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(a.name),
                          ))
                      .toList(),
                  onChanged: (a) {
                    if (a != null) setDs(() => selected = a);
                  },
                ),
                const SizedBox(height: 12),

                // ── Contenu de la note ────────────────────────────────────────
                TextField(
                  controller: noteCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Date ──────────────────────────────────────────────────────
                TextField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Date (JJ/MM/AAAA)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final content = noteCtrl.text.trim();
                if (content.isEmpty) return;

                final date = dateCtrl.text.trim().isEmpty
                    ? '03/03/1877'
                    : dateCtrl.text.trim();

                // Le docId de l'agent est utilisé comme ID du document,
                // ce qui garantit une seule note par agent par entité.
                await _entriesRef.doc(selected.docId).set(
                  FieldNote(
                    agentDocId: selected.docId,
                    agentName: selected.name,
                    agentPicturePath: selected.picturePath,
                    content: content,
                    date: date,
                  ).toMap(),
                );

                if (ctx.mounted) Navigator.pop(ctx);
                await _load();
              },
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final eligible = _eligibleAgents;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── En-tête section ────────────────────────────────────────────────────
        Row(
          children: [
            Text(
              'Notes des agents',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (eligible.isNotEmpty)
              TextButton.icon(
                onPressed: _showAddNoteDialog,
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Laisser une note'),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // ── Liste des notes (scroll horizontal) ────────────────────────────────
        SizedBox(
          height: 130,
          child: _notes.isEmpty
              ? Center(
                  child: Text(
                    "Aucune note pour l'instant.",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _notes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _NoteCard(note: _notes[i]),
                ),
        ),
      ],
    );
  }
}

// ─── Carte d'une note ─────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final FieldNote note;
  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final hasPic =
        note.agentPicturePath != null && note.agentPicturePath!.isNotEmpty;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar de l'agent ────────────────────────────────────────────────
          CircleAvatar(
            radius: 22,
            backgroundImage:
                hasPic ? NetworkImage(note.agentPicturePath!) : null,
            child: hasPic ? null : const Icon(Icons.person, size: 22),
          ),
          const SizedBox(width: 10),

          // ── Texte : note + signature ─────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    '"${note.content}"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.fade,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${note.agentName}, ${note.date}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
