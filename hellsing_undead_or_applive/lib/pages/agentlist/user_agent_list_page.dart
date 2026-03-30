import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class AgentsListPage extends StatefulWidget {
  const AgentsListPage({super.key});

  @override
  State<AgentsListPage> createState() => _AgentsListPageState();
}

class _AgentsListPageState extends State<AgentsListPage> {
  bool _isAdmin = false;
  bool _roleLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = doc.data()?['role'];
    if (mounted) {
      setState(() {
        _isAdmin = role == 'admin';
        _roleLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }

    if (!_roleLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text(
                  "Liste d'agents",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _isAdmin
                    ? _AdminAgentView(currentUid: user.uid)
                    : _UserAgentView(currentUid: user.uid),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, Routes.home);
                  },
                  child: const Text("Retour"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Vue utilisateur (inchangée) ─────────────────────────────────────────────

class _UserAgentView extends StatelessWidget {
  final String currentUid;
  const _UserAgentView({required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final agentsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('agents')
        .where(FieldPath.documentId, isNotEqualTo: '_meta_');

    return StreamBuilder<QuerySnapshot>(
      stream: agentsRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text("Erreur lors du chargement des agents"),
          );
        }

        final agents = snapshot.data!.docs;

        if (agents.isEmpty) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, Routes.agentCreate);
              },
              child: const Text("Créer un nouvel agent"),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: agents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final agent = agents[index];
                  return _AgentTile(
                    agentDoc: agent,
                    ownerUid: currentUid,
                    onDelete: () => _confirmDelete(
                        context, currentUid, agent.id, agent['name'] ?? ''),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateAgentPage()),
                  );
                },
                child: const Text("Créer un nouvel agent"),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Vue admin (tous les utilisateurs, regroupés par pseudo) ─────────────────

class _AdminAgentView extends StatefulWidget {
  final String currentUid;
  const _AdminAgentView({required this.currentUid});

  @override
  State<_AdminAgentView> createState() => _AdminAgentViewState();
}

class _AdminAgentViewState extends State<_AdminAgentView> {
  bool _loading = true;
  List<_UserGroup> _userGroups = [];

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    setState(() => _loading = true);

    try {
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();

      final groups = <_UserGroup>[];

      for (final userDoc in usersSnap.docs) {
        final pseudo =
            (userDoc.data()['pseudo'] as String?) ?? 'Inconnu';

        final agentsSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('agents')
            .where(FieldPath.documentId, isNotEqualTo: '_meta_')
            .get();

        if (agentsSnap.docs.isEmpty && userDoc.id != widget.currentUid) continue;

        groups.add(_UserGroup(
          uid: userDoc.id,
          pseudo: pseudo,
          agents: agentsSnap.docs,
        ));
      }

      // Tri : admin en premier, puis alphabétique par pseudo
      groups.sort((a, b) {
        if (a.uid == widget.currentUid) return -1;
        if (b.uid == widget.currentUid) return 1;
        return a.pseudo.toLowerCase().compareTo(b.pseudo.toLowerCase());
      });

      if (mounted) {
        setState(() {
          _userGroups = groups;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userGroups.isEmpty) {
      return const Center(child: Text('Aucun agent trouvé.'));
    }

    return RefreshIndicator(
      onRefresh: _loadAllUsers,
      child: ListView.builder(
        itemCount: _userGroups.length,
        itemBuilder: (context, index) {
          final group = _userGroups[index];
          final isCurrentUser = group.uid == widget.currentUid;

          return ExpansionTile(
            title: Text(
              group.pseudo,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCurrentUser ? Colors.orange : null,
              ),
            ),
            subtitle: Text(
              '${group.agents.length} agent${group.agents.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            initiallyExpanded: isCurrentUser,
            children: [
              ...group.agents.map((agentDoc) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: _AgentTile(
                    agentDoc: agentDoc,
                    ownerUid: group.uid,
                    onDelete: () => _confirmDeleteAndRefresh(
                      context,
                      group.uid,
                      agentDoc.id,
                      agentDoc['name'] ?? '',
                    ),
                  ),
                );
              }),

              // Bouton "Créer un nouvel agent" uniquement sous le pseudo de l'admin
              if (isCurrentUser)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CreateAgentPage()),
                      );
                    },
                    child: const Text("Créer un nouvel agent"),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteAndRefresh(
    BuildContext context,
    String ownerUid,
    String docId,
    String name,
  ) async {
    final deleted = await _confirmDelete(context, ownerUid, docId, name);
    if (deleted) _loadAllUsers();
  }
}

// ─── Modèle interne pour regrouper les agents par utilisateur ────────────────

class _UserGroup {
  final String uid;
  final String pseudo;
  final List<QueryDocumentSnapshot> agents;

  const _UserGroup({
    required this.uid,
    required this.pseudo,
    required this.agents,
  });
}

// ─── Tile d'un agent (réutilisé dans les deux vues) ──────────────────────────

class _AgentTile extends StatelessWidget {
  final QueryDocumentSnapshot agentDoc;
  final String ownerUid;
  final VoidCallback onDelete;

  const _AgentTile({
    required this.agentDoc,
    required this.ownerUid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = agentDoc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Agent sans nom';
    final pic = data['profilPicturePath'] as String?;
    final hasPic = pic != null && pic.trim().isNotEmpty;
    final validated = data['validated'] ?? false;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AgentSheetPage(
              agentDocId: agentDoc.id,
              ownerUid: ownerUid,
            ),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 52,
            backgroundImage: hasPic ? NetworkImage(pic) : null,
            child: hasPic ? null : const Icon(Icons.person),
          ),
          const SizedBox(width: 36),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 26),
                ),
                if (!validated)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'En attente de validation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

// ─── Dialog de confirmation de suppression ───────────────────────────────────

Future<bool> _confirmDelete(
  BuildContext context,
  String ownerUid,
  String docId,
  String name,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Confirmation"),
        content: Text(
          "Vous êtes certain de vouloir supprimer l'agent \"$name\" ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Non"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Oui"),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .collection('agents')
        .doc(docId)
        .delete();
    return true;
  }
  return false;
}
