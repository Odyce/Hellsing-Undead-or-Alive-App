import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:hellsing_undead_or_applive/widgets/filter_bar.dart';

class DisplayMissionPage extends StatefulWidget {
  const DisplayMissionPage({super.key});

  @override
  State<DisplayMissionPage> createState() => _DisplayMissionPageState();
}

class _DisplayMissionPageState extends State<DisplayMissionPage> {
  // Agents de l'utilisateur courant, chargés une seule fois
  List<QueryDocumentSnapshot> _agents = [];

  Map<String, Set<dynamic>> _activeFilters = {};

  static String _difficultyLabel(Difficulty d) => switch (d) {
        Difficulty.basse     => 'Basse',
        Difficulty.moyenne   => 'Moyenne',
        Difficulty.haute     => 'Haute',
        Difficulty.tresHaute => 'Très haute',
        Difficulty.inconnu   => 'Inconnue',
      };

  static final _filterGroups = [
    FilterGroup<String>(
      label: 'Difficulté',
      options: [
        for (final d in Difficulty.values)
          FilterOption(label: _difficultyLabel(d), value: d.name),
      ],
    ),
    FilterGroup<bool>(
      label: 'Urgent',
      options: const [
        FilterOption(label: 'Urgent', value: true),
      ],
    ),
  ];

  bool _matchesFilters(Map<String, dynamic> data) {
    if (_activeFilters.isEmpty) return true;
    final diffFilter = _activeFilters['Difficulté'];
    if (diffFilter != null && diffFilter.isNotEmpty) {
      final diff = data['difficulty'] as String? ?? 'inconnu';
      if (!diffFilter.contains(diff)) return false;
    }
    final cladeFilter = _activeFilters['Clade'];
    if (cladeFilter != null && cladeFilter.isNotEmpty) {
      final clade = data['clade'] as String? ?? '';
      if (!cladeFilter.contains(clade)) return false;
    }
    final urgentFilter = _activeFilters['Urgent'];
    if (urgentFilter != null && urgentFilter.isNotEmpty) {
      final urgent = data['urgent'] as bool? ?? false;
      if (!urgent) return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('agents')
        .where(FieldPath.documentId, isNotEqualTo: '_meta_')
        .get();

    if (mounted) {
      setState(() => _agents = snapshot.docs);
    }
  }

  // ─── Inscription / désinscription d'un agent ─────────────────────────────────
  Future<void> _toggleRegistration({
    required String missionDocId,
    required String agentDocId,
    required String agentName,
    required String? agentPicture,
    required bool isRegistered,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final key = '${uid}_$agentDocId';
    final missionRef = FirebaseFirestore.instance
        .collection('common')
        .doc('archives')
        .collection('missions')
        .doc(missionDocId);

    if (isRegistered) {
      await missionRef.update({'registrations.$key': FieldValue.delete()});
    } else {
      await missionRef.update({
        'registrations.$key': {
          'userId': uid,
          'agentDocId': agentDocId,
          'agentName': agentName,
          'agentPicture': agentPicture,
        },
      });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── En-tête ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: const Text(
                  "Tableau d'affichage",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            // ── Filtres ──────────────────────────────────────────────────────
            FilterBar(
              groups: _filterGroups,
              activeFilters: _activeFilters,
              onChanged: (f) => setState(() => _activeFilters = f),
            ),

            // ── Liste des missions disponibles ───────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('common')
                    .doc('archives')
                    .collection('missions')
                    .where('completedAt', isNull: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erreur : ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final allDocs = snapshot.data?.docs ?? [];
                  final docs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _matchesFilters(data);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('Aucune mission disponible en ce moment.'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) =>
                        _buildMissionCard(docs[index]),
                  );
                },
              ),
            ),

            // ── Bouton retour ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, Routes.missions),
                  child: const Text('Retour'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Carte d'une mission ──────────────────────────────────────────────────────
  Widget _buildMissionCard(QueryDocumentSnapshot missionDoc) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final data = missionDoc.data() as Map<String, dynamic>;

    final title = data['title'] as String? ?? '';
    final description = data['descriptionIntro'] as String? ?? '';
    final illustrationPath = data['illustrationPath'] as String?;
    final urgent = data['urgent'] as bool? ?? false;
    final registrations =
        Map<String, dynamic>.from(data['registrations'] as Map? ?? {});

    final agentNames = registrations.values
        .map((r) => (r as Map<String, dynamic>)['agentName'] as String? ?? '')
        .where((n) => n.isNotEmpty)
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Agents inscrits (bandeau compact en haut) ──────────────────
          if (agentNames.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Text(
                agentNames.join(', '),
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // ── Corps : illustration + titre + urgence + bouton fiche ──────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (illustrationPath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      illustrationPath,
                      width: 60,
                      height: 60,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (urgent)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Urgente !',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Bouton fiche mission ─────────────────────────────────
                IconButton(
                  icon: const Icon(Icons.description_outlined),
                  tooltip: 'Voir la fiche',
                  onPressed: () => Navigator.pushNamed(
                    context,
                    Routes.missionSheet,
                    arguments: Mission.fromMap(data),
                  ),
                ),
              ],
            ),
          ),

          // ── Menu déroulant "S'inscrire" ─────────────────────────────────
          if (_agents.isNotEmpty)
            ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              title: const Text(
                "S'inscrire",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              children: _agents.map((agentDoc) {
                final agentData = agentDoc.data() as Map<String, dynamic>;
                final agentName =
                    agentData['name'] as String? ?? 'Agent sans nom';
                final agentPicture =
                    agentData['profilPicturePath'] as String?;
                final hasPic =
                    agentPicture != null && agentPicture.trim().isNotEmpty;

                final key = '${uid}_${agentDoc.id}';
                final isRegistered = registrations.containsKey(key);

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundImage: hasPic ? NetworkImage(agentPicture) : null,
                    child: hasPic ? null : const Icon(Icons.person),
                  ),
                  title: Text(agentName),
                  trailing: isRegistered
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.radio_button_unchecked),
                  onTap: () => _toggleRegistration(
                    missionDocId: missionDoc.id,
                    agentDocId: agentDoc.id,
                    agentName: agentName,
                    agentPicture: agentPicture,
                    isRegistered: isRegistered,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
