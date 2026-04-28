import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:hellsing_undead_or_applive/widgets/filter_bar.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

// Wrapper pour transporter docId + projet ensemble
class _ProjectEntry {
  final String docId;
  final ResDevProject project;
  const _ProjectEntry(this.docId, this.project);
}

class ResDevListPage extends StatefulWidget {
  const ResDevListPage({super.key});

  @override
  State<ResDevListPage> createState() => _ResDevListPageState();
}

class _ResDevListPageState extends State<ResDevListPage> {
  bool _loading = true;
  bool _isAdmin = false;

  // Projets actifs (non complétés) + projets complétés séparés
  List<_ProjectEntry> _activeProjects   = [];
  List<_ProjectEntry> _completedProjects = [];

  // ResDev / ResDevWeapon (Object = l'un ou l'autre)
  List<Object> _resDevItems = [];

  Map<String, Set<dynamic>> _activeFilters = {};

  static const _filterGroups = [
    FilterGroup<String>(
      label: 'Type',
      options: [
        FilterOption(label: 'Item', value: 'item'),
        FilterOption(label: 'Arme', value: 'arme'),
      ],
    ),
  ];

  List<Object> get _filteredResDevItems {
    final typeFilter = _activeFilters['Type'];
    if (typeFilter == null || typeFilter.isEmpty) return _resDevItems;
    return _resDevItems.where((item) {
      final isWeapon = item is ResDevWeapon;
      if (typeFilter.contains('arme') && isWeapon) return true;
      if (typeFilter.contains('item') && !isWeapon) return true;
      return false;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    _loadData();
  }

  Future<void> _checkAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final role = doc.data()?['role'];
    if (mounted) {
      setState(() => _isAdmin = role == 'admin');
    }
  }

  Future<void> _loadData() async {
    try {
      final projectSnap = await FirebaseFirestore.instance
          .collection('common')
          .doc('archives')
          .collection('resdevproject')
          .get();

      final resdevSnap = await FirebaseFirestore.instance
          .collection('common')
          .doc('archives')
          .collection('resdev')
          .get();

      final active    = <_ProjectEntry>[];
      final completed = <_ProjectEntry>[];

      for (final doc in projectSnap.docs) {
        final p = ResDevProject.fromMap(doc.data());
        final entry = _ProjectEntry(doc.id, p);
        if (p.completed) {
          completed.add(entry);
        } else {
          active.add(entry);
        }
      }

      // Tri alphabétique
      active.sort((a, b) => a.project.name.compareTo(b.project.name));
      completed.sort((a, b) => a.project.name.compareTo(b.project.name));

      final items = resdevSnap.docs.map((doc) {
        final data = doc.data();
        if (data['isWeapon'] == true) {
          return ResDevWeapon.fromMap(data) as Object;
        } else {
          return ResDev.fromMap(data) as Object;
        }
      }).toList()
        ..sort((a, b) {
          final nameA = a is ResDev ? a.name : (a as ResDevWeapon).name;
          final nameB = b is ResDev ? b.name : (b as ResDevWeapon).name;
          return nameA.compareTo(nameB);
        });

      setState(() {
        _activeProjects    = active;
        _completedProjects = completed;
        _resDevItems       = items;
        _loading           = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // ─── Navigation vers la fiche projet ─────────────────────────────────────────
  void _openProject(_ProjectEntry entry) {
    Navigator.of(context).pushNamed(
      Routes.resDevProjectSheet,
      arguments: {'project': entry.project, 'docId': entry.docId},
    );
  }

  // Navigue vers la fiche d'un item ResDev / ResDevWeapon
  void _openResDevItem(Object item) {
    Navigator.of(context).pushNamed(Routes.resDevSheet, arguments: item);
  }

  // ─── Labels ───────────────────────────────────────────────────────────────────
  String _prereqProgress(ResDevProject p) {
    final claimed = p.prerequisiteAgents.where((a) => a != null).length;
    final total   = p.prerequisite.length;
    return '$claimed / $total';
  }

  String _statusLabel(ResDevProject p) {
    if (p.completed)              return 'Complété';
    if (p.prerequisiteCompletes)  return 'Prêt';
    return 'En cours';
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: const Text('R&D'),
      ),
      floatingActionButton: _isAdmin
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'newProject',
                  onPressed: () => Navigator.of(context).pushNamed(Routes.resDevProjectCreate),
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Nouveau projet R&D'),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: 'newResDev',
                  onPressed: () => Navigator.of(context).pushNamed(Routes.resDevCreate),
                  icon: const Icon(Icons.build_outlined),
                  label: const Text('Nouvelle finalisation R&D'),
                ),
              ],
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_resDevItems.isNotEmpty)
                  FilterBar(
                    groups: _filterGroups,
                    activeFilters: _activeFilters,
                    onChanged: (f) => setState(() => _activeFilters = f),
                  ),
                Expanded(child: _buildContent()),
              ],
            ),
    );
  }

  Widget _buildContent() {
    if (_activeProjects.isEmpty &&
        _completedProjects.isEmpty &&
        _filteredResDevItems.isEmpty) {
      return const Center(child: Text('Aucun projet R&D.'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Projets actifs ──────────────────────────────────────────────────
          if (_activeProjects.isNotEmpty) ...[
            _SectionHeader(label: 'Projets en cours',
                count: _activeProjects.length),
            const SizedBox(height: 8),
            ..._activeProjects.map((e) => _ProjectCard(
                  entry: e,
                  progress: _prereqProgress(e.project),
                  status: _statusLabel(e.project),
                  onTap: () => _openProject(e),
                )),
            const SizedBox(height: 24),
          ],

          // ── Items R&D ────────────────────────────────────────────────────────
          if (_filteredResDevItems.isNotEmpty) ...[
            _SectionHeader(label: 'R&D développés',
                count: _filteredResDevItems.length),
            const SizedBox(height: 8),
            ..._filteredResDevItems.map((item) => _ResDevCard(
                  item: item,
                  onTap: () => _openResDevItem(item),
                )),
            const SizedBox(height: 24),
          ],

          // ── Projets complétés (plus petits + grisés) ─────────────────────────
          if (_completedProjects.isNotEmpty) ...[
            _SectionHeader(label: 'Projets complétés',
                count: _completedProjects.length),
            const SizedBox(height: 8),
            ..._completedProjects.map((e) => _ProjectCard(
                  entry: e,
                  progress: _prereqProgress(e.project),
                  status: _statusLabel(e.project),
                  onTap: () => _openProject(e),
                  completed: true,
                )),
          ],
        ],
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Chip(
          label: Text('$count',
              style: const TextStyle(fontSize: 12)),
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final _ProjectEntry entry;
  final String progress;
  final String status;
  final VoidCallback onTap;
  final bool completed;

  const _ProjectCard({
    required this.entry,
    required this.progress,
    required this.status,
    required this.onTap,
    this.completed = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = entry.project;
    final textScale = completed ? 0.85 : 1.0;
    final opacity   = completed ? 0.45 : 1.0;

    return Opacity(
      opacity: opacity,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(completed ? 10 : 14),
            child: Row(
              children: [
                // Miniature
                if (p.picturePath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      p.picturePath!,
                      width: completed ? 36 : 48,
                      height: completed ? 36 : 48,
                      fit: BoxFit.contain,
                    ),
                  )
                else
                  Container(
                    width: completed ? 36 : 48,
                    height: completed ? 36 : 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.science_outlined,
                        size: completed ? 18 : 24,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                const SizedBox(width: 12),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontSize:
                                    (Theme.of(context).textTheme.titleSmall?.fontSize ?? 14) *
                                        textScale,
                              )),
                      const SizedBox(height: 2),
                      Text(
                        'Coût: ${p.cost}  ·  Prérequis: $progress  ·  $status',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize:
                                  (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) *
                                      textScale,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: completed ? 18 : 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResDevCard extends StatelessWidget {
  final Object item;
  final VoidCallback onTap;

  const _ResDevCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name        = item is ResDev
        ? (item as ResDev).name
        : (item as ResDevWeapon).name;
    final picturePath = item is ResDev
        ? (item as ResDev).picturePath
        : (item as ResDevWeapon).picturePath;
    final isWeapon = item is ResDevWeapon;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              if (picturePath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    picturePath,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isWeapon ? Icons.shield_outlined : Icons.build_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(name,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
