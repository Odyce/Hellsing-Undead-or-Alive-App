import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class AgentSheetPage extends StatefulWidget {
  final String agentDocId;

  const AgentSheetPage({
    super.key,
    required this.agentDocId,
  });

  @override
  State<AgentSheetPage> createState() => _AgentSheetPageState();
}

class _AgentSheetPageState extends State<AgentSheetPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Pools locaux (jamais sauvegardés en Firestore)
  List<int>? _localPools;   // [PV, PE, PM]
  List<int>? _maxPools;     // pour le reset

  // Inventaire local (sauvegardé en Firestore à la sortie)
  List<WeaponSlot>? _weaponSlots;
  List<MuniSlot>? _muniSlots;
  List<BagSlot>? _bagSlots;
  List<BankSlot>? _bankSlots;
  bool _inventoryDirty = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Initialise les pools locaux à partir de l'agent (une seule fois)
  void _initPoolsIfNeeded(Agent agent) {
    if (_localPools == null) {
      _localPools = List<int>.from(agent.pools);
      _maxPools = List<int>.from(agent.maxPools);
    }
  }

  void _changePool(int index, int delta) {
    setState(() {
      final newVal = (_localPools![index] + delta).clamp(0, _maxPools![index]);
      _localPools![index] = newVal;
    });
  }

  void _resetPools() {
    setState(() {
      _localPools = List<int>.from(_maxPools!);
    });
  }

  /// Initialise l'inventaire local à partir de l'agent (une seule fois)
  void _initInventoryIfNeeded(Agent agent) {
    if (_weaponSlots == null) {
      _weaponSlots = List<WeaponSlot>.from(agent.weaponSlots);
      _muniSlots = List<MuniSlot>.from(agent.muniSlots);
      _bagSlots = List<BagSlot>.from(agent.bagSlots);
      _bankSlots = List<BankSlot>.from(agent.bankSlots);
    }
  }

  // --- Transferts vers le coffre ---

  void _moveWeaponToBank(int slotIndex) {
    final bankIdx = _bankSlots!.indexWhere((b) => b.empty);
    if (bankIdx == -1) return; // pas de place
    final ws = _weaponSlots![slotIndex];
    if (ws.empty) return;
    setState(() {
      _bankSlots![bankIdx] = BankSlot(
        id: _bankSlots![bankIdx].id,
        empty: false,
        weapon: ws,
      );
      _weaponSlots![slotIndex] = WeaponSlot.empty(ws.id);
      _inventoryDirty = true;
    });
  }

  void _moveMuniToBank(int slotIndex) {
    final bankIdx = _bankSlots!.indexWhere((b) => b.empty);
    if (bankIdx == -1) return;
    final ms = _muniSlots![slotIndex];
    if (ms.empty) return;
    setState(() {
      _bankSlots![bankIdx] = BankSlot(
        id: _bankSlots![bankIdx].id,
        empty: false,
        muni: ms,
      );
      _muniSlots![slotIndex] = MuniSlot(
        id: ms.id, numberLeft: 0, empty: true,
      );
      _inventoryDirty = true;
    });
  }

  void _moveBagToBank(int slotIndex) {
    final bankIdx = _bankSlots!.indexWhere((b) => b.empty);
    if (bankIdx == -1) return;
    final bs = _bagSlots![slotIndex];
    if (bs.empty) return;
    setState(() {
      _bankSlots![bankIdx] = BankSlot(
        id: _bankSlots![bankIdx].id,
        empty: false,
        bag: bs,
      );
      _bagSlots![slotIndex] = BagSlot(id: bs.id, empty: true);
      _inventoryDirty = true;
    });
  }

  // --- Transfert depuis le coffre vers le premier emplacement vide ---

  void _moveBankToOrigin(int bankIndex) {
    final bank = _bankSlots![bankIndex];
    if (bank.empty) return;

    bool moved = false;

    if (bank.weapon != null) {
      final idx = _weaponSlots!.indexWhere((w) => w.empty);
      if (idx == -1) return;
      setState(() {
        _weaponSlots![idx] = bank.weapon!;
        _bankSlots![bankIndex] = BankSlot(id: bank.id, empty: true);
        _inventoryDirty = true;
      });
      moved = true;
    } else if (bank.muni != null) {
      final idx = _muniSlots!.indexWhere((m) => m.empty);
      if (idx == -1) return;
      setState(() {
        _muniSlots![idx] = bank.muni!;
        _bankSlots![bankIndex] = BankSlot(id: bank.id, empty: true);
        _inventoryDirty = true;
      });
      moved = true;
    } else if (bank.bag != null) {
      final idx = _bagSlots!.indexWhere((b) => b.empty);
      if (idx == -1) return;
      setState(() {
        _bagSlots![idx] = bank.bag!;
        _bankSlots![bankIndex] = BankSlot(id: bank.id, empty: true);
        _inventoryDirty = true;
      });
      moved = true;
    }

    if (!moved) return;
  }

  // --- Sauvegarde Firestore à la sortie ---

  Future<void> _saveInventoryIfDirty() async {
    if (!_inventoryDirty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final agentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('agents')
        .doc(widget.agentDocId);

    await agentRef.update({
      'weaponSlots': _weaponSlots!.map((s) => s.toMap()).toList(),
      'muniSlots': _muniSlots!.map((s) => s.toMap()).toList(),
      'bagSlots': _bagSlots!.map((s) => s.toMap()).toList(),
      'bankSlots': _bankSlots!.map((s) => s.toMap()).toList(),
    });

    _inventoryDirty = false;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Utilisateur non connecté")),
      );
    }

    final agentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('agents')
        .doc(widget.agentDocId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: agentRef.snapshots(),
      builder: (context, snapshot) {
        // Titre dynamique — on le lit dès que possible
        final agentName = snapshot.data?.data()?['name'] as String?;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (_inventoryDirty) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              await _saveInventoryIfDirty();
              if (context.mounted) Navigator.of(context).pop(); // ferme le dialog
            }
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, Routes.agentList);
            }
          },
          child: Scaffold(
          appBar: AppBar(
            title: Text(agentName != null ? "Fiche de $agentName" : "Fiche de l'agent"),
          ),
          body: SafeArea(
            child: Builder(builder: (context) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text("Erreur lors du chargement de l'agent"),
              );
            }

            final doc = snapshot.data;
            if (doc == null || !doc.exists || doc.data() == null) {
              return const Center(child: Text("Agent introuvable"));
            }

            final agent = Agent.fromMap(doc.data()!);
            _initPoolsIfNeeded(agent);
            _initInventoryIfNeeded(agent);

            final pic = agent.profilPicturePath;
            final hasPic = pic != null && pic.trim().isNotEmpty;

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Photo + infos
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    agent.name,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text("État : ${agent.state}"),
                                  Text("Note : ${agent.note}"),
                                  Text("Race : ${agent.race.name}"),
                                  if (agent.powerScore != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text("Power Score : ${agent.powerScore}"),
                                        _diceButton(context, maxValue: 100, threshold: agent.powerScore! % 100),
                                      ],
                                    ),
                                  Text("Classe : ${agent.agentClass.name}"),
                                  ...List.generate(
                                    agent.agentClass.classBonus.length,
                                    (i) {
                                      final val = i < agent.classBonuses.length ? agent.classBonuses[i] : 0;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text("${agent.agentClass.classBonus[i]} : $val / 6"),
                                          _diceButton(context, maxValue: 6, threshold: val),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 100,
                              height: 200,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Colors.grey.shade400, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: hasPic
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(pic,
                                          fit: BoxFit.contain),
                                    )
                                  : const Center(
                                      child: Icon(Icons.person,
                                          size: 42, color: Colors.grey),
                                    ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Attributs
                        Row(
                          children: [
                            _attributeCell(context, "Physique", agent.attributes[0]),
                            _attributeCell(context, "Mental", agent.attributes[1]),
                            _attributeCell(context, "Social", agent.attributes[2]),
                          ],
                        ),

                        const SizedBox(height: 4),

                        // Pools (éditables localement)
                        Row(
                          children: [
                            _poolCell("PV", 0),
                            _poolCell("PM", 2),
                            _poolCell("PE", 1),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _resetPools,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text("Reset pools", style: TextStyle(fontSize: 12)),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Bouton retour
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () async {
                              if (_inventoryDirty) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (_) => const Center(child: CircularProgressIndicator()),
                                );
                                await _saveInventoryIfDirty();
                                if (context.mounted) Navigator.of(context).pop();
                              }
                              if (context.mounted) {
                                Navigator.pushReplacementNamed(context, Routes.agentList);
                              }
                            },
                            child: const Text("Retour"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- TabBar épinglé ---
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: "Compétences"),
                        Tab(text: "Inventaire"),
                        Tab(text: "Missions"),
                        Tab(text: "Lore"),
                      ],
                    ),
                  ),
                ),
              ],

              // --- Contenu des onglets ---
              body: TabBarView(
                controller: _tabController,
                children: [
                  // -- Compétences --
                  agent.skills.isEmpty
                      ? const Center(child: Text("Aucune compétence."))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: agent.skills.length,
                          itemBuilder: (context, index) =>
                              _SkillCard(
                                skill: agent.skills[index],
                                attributes: agent.attributes,
                              ),
                        ),
                  // -- Inventaire --
                  _InventorySection(
                    agent: agent,
                    weaponSlots: _weaponSlots!,
                    muniSlots: _muniSlots!,
                    bagSlots: _bagSlots!,
                    bankSlots: _bankSlots!,
                    onMoveWeaponToBank: _moveWeaponToBank,
                    onMoveMuniToBank: _moveMuniToBank,
                    onMoveBagToBank: _moveBagToBank,
                    onMoveBankToOrigin: _moveBankToOrigin,
                  ),
                  // -- Missions --
                  _MissionsSection(agent: agent),
                  // -- Lore --
                  _LoreSection(agent: agent),
                ],
              ),
            );
          },  // fin Builder callback
        ),  // fin Builder
      ),  // fin SafeArea
    ),  // fin Scaffold
  );  // fin PopScope
      },  // fin StreamBuilder builder
    );  // fin StreamBuilder
  }

  Widget _attributeCell(BuildContext ctx, String label, int value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label : $value",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          _diceButton(ctx, maxValue: 100, threshold: value),
        ],
      ),
    );
  }

  Widget _poolCell(String label, int index) {
    final current = _localPools![index];
    final max = _maxPools![index];
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _changePool(index, -1),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.remove_circle_outline, size: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              "$label : $current / $max",
              style: const TextStyle(fontSize: 13),
            ),
          ),
          InkWell(
            onTap: () => _changePool(index, 1),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.add_circle_outline, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Inventaire (sous-onglets Armes / Munitions / Sac / Coffre)
// ---------------------------------------------------------------------------
class _InventorySection extends StatefulWidget {
  final Agent agent;
  final List<WeaponSlot> weaponSlots;
  final List<MuniSlot> muniSlots;
  final List<BagSlot> bagSlots;
  final List<BankSlot> bankSlots;
  final void Function(int) onMoveWeaponToBank;
  final void Function(int) onMoveMuniToBank;
  final void Function(int) onMoveBagToBank;
  final void Function(int) onMoveBankToOrigin;

  _InventorySection({
    required this.agent,
    required this.weaponSlots,
    required this.muniSlots,
    required this.bagSlots,
    required this.bankSlots,
    required this.onMoveWeaponToBank,
    required this.onMoveMuniToBank,
    required this.onMoveBagToBank,
    required this.onMoveBankToOrigin,
  });

  @override
  State<_InventorySection> createState() => _InventorySectionState();
}

class _InventorySectionState extends State<_InventorySection>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    return Column(
      children: [
        // --- Argent (visible dans tous les sous-onglets) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 6),
              Text(
                "${agent.money} £",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // --- Sous-onglets ---
        TabBar(
          controller: _tab,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: "Armes"),
            Tab(text: "Munitions"),
            Tab(text: "Sac"),
            Tab(text: "Coffre"),
          ],
        ),

        // --- Contenu ---
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              // Armes
              widget.weaponSlots.isEmpty
                  ? const Center(child: Text("Aucun emplacement arme."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: widget.weaponSlots.length,
                      itemBuilder: (_, i) =>
                          _WeaponSlotCard(
                            slot: widget.weaponSlots[i],
                            physique: agent.attributes[0],
                            onMoveToBank: () => widget.onMoveWeaponToBank(i),
                          ),
                    ),
              // Munitions
              widget.muniSlots.isEmpty
                  ? const Center(child: Text("Aucun emplacement munition."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: widget.muniSlots.length,
                      itemBuilder: (_, i) =>
                          _MuniSlotCard(
                            slot: widget.muniSlots[i],
                            onMoveToBank: () => widget.onMoveMuniToBank(i),
                          ),
                    ),
              // Sac
              widget.bagSlots.isEmpty
                  ? const Center(child: Text("Aucun emplacement sac."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: widget.bagSlots.length,
                      itemBuilder: (_, i) =>
                          _BagSlotCard(
                            slot: widget.bagSlots[i],
                            onMoveToBank: () => widget.onMoveBagToBank(i),
                          ),
                    ),
              // Coffre
              widget.bankSlots.isEmpty
                  ? const Center(child: Text("Aucun emplacement coffre."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: widget.bankSlots.length,
                      itemBuilder: (_, i) =>
                          _BankSlotCard(
                            slot: widget.bankSlots[i],
                            onMoveToOrigin: () => widget.onMoveBankToOrigin(i),
                          ),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Carte WeaponSlot
// ---------------------------------------------------------------------------
class _WeaponSlotCard extends StatelessWidget {
  final WeaponSlot slot;
  final int physique;
  final VoidCallback onMoveToBank;
  const _WeaponSlotCard({required this.slot, required this.physique, required this.onMoveToBank});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: slot.empty
            ? _emptyRow("Emplacement ${slot.id} — Vide")
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  slot.weapon != null
                      ? _weaponContent(context, slot.weapon!)
                      : _kitContent(slot.kit!),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.archive_outlined, size: 20),
                      tooltip: "Envoyer au coffre",
                      onPressed: onMoveToBank,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _weaponContent(BuildContext context, Weapon w) {
    final effects = w.effect.where((e) => e != Effect.none).map((e) => e.name).join(", ");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _slotHeader("Emplacement ${slot.id}", w.name)),
            _diceButton(context, maxValue: 100, threshold: physique),
          ],
        ),
        const SizedBox(height: 4),
        Text("Dégâts : ${w.damage}", style: const TextStyle(fontSize: 13)),
        Text("Particularité : ${w.feature}", style: const TextStyle(fontSize: 13)),
        if (w.calibre != null)
          Text("Calibre : ${w.calibre!.name}", style: const TextStyle(fontSize: 13)),
        if (w.firing != null && w.firing != Firing.none)
          Text("Mode de tir : ${w.firing!.name}", style: const TextStyle(fontSize: 13)),
        if (w.magazineSize != null)
          Text("Chargeur : ${w.magazineSize}", style: const TextStyle(fontSize: 13)),
        Text("Taille : ${w.size}", style: const TextStyle(fontSize: 13)),
        if (effects.isNotEmpty)
          Text("Effets : $effects", style: const TextStyle(fontSize: 13)),
        if (w.modif != null && w.modif!.isNotEmpty)
          Text(
            "Modifs : ${w.modif!.map((m) => m.name).join(', ')}",
            style: const TextStyle(fontSize: 13),
          ),
      ],
    );
  }

  Widget _kitContent(SupportObject kit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slotHeader("Emplacement ${slot.id}", kit.name),
        const SizedBox(height: 4),
        Text(kit.legend, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
        Text(kit.description, style: const TextStyle(fontSize: 13)),
        Text("Taille : ${kit.size}", style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Carte MuniSlot
// ---------------------------------------------------------------------------
class _MuniSlotCard extends StatelessWidget {
  final MuniSlot slot;
  final VoidCallback onMoveToBank;
  const _MuniSlotCard({required this.slot, required this.onMoveToBank});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: slot.empty
            ? _emptyRow("Emplacement ${slot.id} — Vide")
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  slot.muni != null
                      ? _muniContent(slot.muni!)
                      : _suppContent(slot.supp!),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.archive_outlined, size: 20),
                      tooltip: "Envoyer au coffre",
                      onPressed: onMoveToBank,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _muniContent(MuniObject m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slotHeader("Emplacement ${slot.id}", "${m.name}  ×${slot.numberLeft}"),
        const SizedBox(height: 4),
        Text(m.description, style: const TextStyle(fontSize: 13)),
        if (m.effect != Effect.none)
          Text("Effet : ${m.effect.name}", style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  Widget _suppContent(SupportObject s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slotHeader("Emplacement ${slot.id}", "${s.name}  ×${slot.numberLeft}"),
        const SizedBox(height: 4),
        Text(s.legend, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
        Text(s.description, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Carte BagSlot
// ---------------------------------------------------------------------------
class _BagSlotCard extends StatelessWidget {
  final BagSlot slot;
  final VoidCallback onMoveToBank;
  const _BagSlotCard({required this.slot, required this.onMoveToBank});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: slot.empty || slot.support == null
            ? _emptyRow("Emplacement ${slot.id} — Vide")
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _supportContent(slot.support!),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.archive_outlined, size: 20),
                      tooltip: "Envoyer au coffre",
                      onPressed: onMoveToBank,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _supportContent(SupportObject s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _slotHeader("Emplacement ${slot.id}", s.name),
        const SizedBox(height: 4),
        Text(s.legend, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
        Text(s.description, style: const TextStyle(fontSize: 13)),
        Text("Taille : ${s.size}", style: const TextStyle(fontSize: 13)),
        if (s.number != null)
          Text("Quantité : ${s.number}", style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Carte BankSlot
// ---------------------------------------------------------------------------
class _BankSlotCard extends StatelessWidget {
  final BankSlot slot;
  final VoidCallback onMoveToOrigin;
  const _BankSlotCard({required this.slot, required this.onMoveToOrigin});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: slot.empty
            ? _emptyRow("Emplacement ${slot.id} — Vide")
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _filledContent(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.backpack_outlined, size: 20),
                      tooltip: "Remettre dans l'inventaire",
                      onPressed: onMoveToOrigin,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _filledContent() {
    if (slot.weapon != null) {
      final w = slot.weapon!;
      final label = w.empty ? "Vide" : (w.weapon?.name ?? w.kit?.name ?? "?");
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _slotHeader("Emplacement ${slot.id}", label),
          const SizedBox(height: 2),
          const Text("Type : Arme", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }
    if (slot.muni != null) {
      final m = slot.muni!;
      final label = m.empty ? "Vide" : (m.muni?.name ?? m.supp?.name ?? "?");
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _slotHeader("Emplacement ${slot.id}", "$label  ×${m.numberLeft}"),
          const SizedBox(height: 2),
          const Text("Type : Munition", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }
    if (slot.bag != null) {
      final b = slot.bag!;
      final label = b.empty ? "Vide" : (b.support?.name ?? "?");
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _slotHeader("Emplacement ${slot.id}", label),
          const SizedBox(height: 2),
          const Text("Type : Objet", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }
    return _emptyRow("Emplacement ${slot.id} — Vide");
  }
}

// ---------------------------------------------------------------------------
// Delegate pour épingler le TabBar dans le NestedScrollView
// ---------------------------------------------------------------------------
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}

// ---------------------------------------------------------------------------
// Helpers partagés
// ---------------------------------------------------------------------------
Widget _slotHeader(String slotLabel, String itemName) {
  return Row(
    children: [
      Text(
        "$slotLabel  —  ",
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      Expanded(
        child: Text(
          itemName,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
    ],
  );
}

Widget _emptyRow(String label) {
  return Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey));
}

Widget _diceButton(BuildContext context,
    {required int maxValue, required int threshold}) {
  return InkWell(
    onTap: () => showDiceThrow(context, maxValue: maxValue, threshold: threshold),
    borderRadius: BorderRadius.circular(12),
    child: const Padding(
      padding: EdgeInsets.all(4),
      child: Icon(Icons.casino, size: 18),
    ),
  );
}

// ---------------------------------------------------------------------------
// Section Missions
// ---------------------------------------------------------------------------
class _MissionsSection extends StatelessWidget {
  final Agent agent;

  const _MissionsSection({required this.agent});

  // Capacité de chaque sous-section (label, nb de missions max)
  static const List<(String, int)> _sections = [
    ('Niveau 1', 3),
    ('Niveau 2', 3),
    ('Niveau 3', 4),
    ('Niveau 4', 5),
    ('Niveau 5', 6),
    ('Niveau 6', 7),
    ('Niveau 7', 8),
    ('Niveau 8', 9),
    ('Niveau 9', 10),
    ('Niveau Légendaire 1', 10),
    ('Niveau Légendaire 2', 10),
    ('Niveau Légendaire 3', 10),
    ('Niveau Légendaire 4', 10),
    ('Niveau Légendaire 5', 10),
    ('Niveau Légendaire 6', 10),
    ('Niveau Légendaire 7', 10),
    ('Niveau Légendaire 8', 10),
    ('Niveau Légendaire 9', 10),
    ('Niveau Légendaire 10', 10),
    ('Niveau Légendaire 11', 10),
    ('Niveau Légendaire 12', 10),
    ('Niveau Légendaire 13', 10),
    ('Niveau Légendaire 14', 10),
    ('Niveau Légendaire 15', 10),
    ('Niveau Légendaire 16', 10),
    ('Niveau Légendaire 17', 10),
    ('Niveau Légendaire 18', 10),
    ('Niveau Légendaire 19', 10),
    ('Niveau Légendaire 20', 10),
    ('Niveau Légendaire 21', 10),
    ('Niveau Légendaire 22', 10),
    ('Niveau Légendaire 23', 10),
    ('Niveau Légendaire 24', 10),
    ('Niveau Légendaire 25', 10),
    ('Niveau Légendaire 26', 10),
    ('Niveau Légendaire 27', 10),
    ('Niveau Légendaire 28', 10),
    ('Niveau Légendaire 29', 10),
    ('Niveau Légendaire 30', 10),
    ('Niveau Légendaire 31', 10),
    ('Niveau Légendaire 32', 10),
    ('Niveau Légendaire 33', 10),
  ];

  @override
  Widget build(BuildContext context) {
    final missions = agent.missions;

    // Construire les sous-sections visibles
    final tiles = <Widget>[];
    int offset = 0;
    for (final (label, capacity) in _sections) {
      if (offset >= missions.length) break;
      final slice = missions.skip(offset).take(capacity).toList();
      tiles.add(
        ExpansionTile(
          title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            "${slice.length} / $capacity missions${slice.length > 1 ? 's' : ''}",
            style: const TextStyle(fontSize: 12),
          ),
          children: slice
              .map((m) => _MissionRecordTile(mission: m))
              .toList(),
        ),
      );
      offset += capacity;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Niveau de l'agent ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            "Niveau : ${agent.level}",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        // --- Sous-sections ---
        if (missions.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: Text("Aucune mission enregistrée."),
          ))
        else
          Expanded(
            child: ListView(
              children: tiles,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tuile d'un MissionRecord
// ---------------------------------------------------------------------------
class _MissionRecordTile extends StatelessWidget {
  final MissionRecord mission;

  const _MissionRecordTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    final date = mission.completedAt;
    final dateLabel = date != null
        ? "Complétée le ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}"
        : "Non complétée";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mission.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(mission.description, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              dateLabel,
              style: TextStyle(
                fontSize: 12,
                color: date != null ? Colors.green.shade700 : Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Lore
// ---------------------------------------------------------------------------
class _LoreSection extends StatelessWidget {
  final Agent agent;

  const _LoreSection({required this.agent});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // --- Background ---
        Text(
          "Background",
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          agent.background.isNotEmpty ? agent.background : "Aucun background renseigné.",
          style: const TextStyle(fontSize: 13),
        ),

        const SizedBox(height: 20),

        // --- Contacts + Points de Contacts ---
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Contacts",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              "Points de Contacts restant : ${agent.pc}",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (agent.contacts.isEmpty)
          const Text("Aucun contact.", style: TextStyle(fontSize: 13, color: Colors.grey))
        else
          ...agent.contacts.map((c) => _ContactCard(contact: c)),

        // --- Bonus / Malus de race ---
        if (agent.race.bonuses != null && agent.race.bonuses!.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            "Bonus de race",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...agent.race.bonuses!.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text("• $b", style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],

        if (agent.race.maluses != null && agent.race.maluses!.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            "Malus de race",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          ...agent.race.maluses!.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text("• $m", style: const TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Carte Contact
// ---------------------------------------------------------------------------
class _ContactCard extends StatelessWidget {
  final Contact contact;

  const _ContactCard({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${contact.contactPointsValue} PC",
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (contact.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(contact.description, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte de compétence
// ---------------------------------------------------------------------------
class _SkillCard extends StatelessWidget {
  final Skill skill;
  final List<int> attributes;

  const _SkillCard({required this.skill, required this.attributes});

  String _costTypeLabel(CostType type) {
    switch (type) {
      case CostType.pe:
        return "PE";
      case CostType.pm:
        return "PM";
      case CostType.pv:
        return "PV";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Ligne titre + dé + badge(s) de coût ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    skill.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (skill.costType == CostType.pe || skill.costType == CostType.pm)
                  _diceButton(
                    context,
                    maxValue: 100,
                    threshold: skill.costType == CostType.pm
                        ? attributes[1]
                        : attributes[0],
                  ),
                const SizedBox(width: 8),
                _buildCostBadges(),
              ],
            ),

            // --- Description ---
            const SizedBox(height: 6),
            if (skill.multiCost && skill.costs != null && skill.descriptions != null)
              ..._buildMultiCostDescriptions()
            else
              Text(skill.description, style: const TextStyle(fontSize: 13)),

            // --- Badge "Limité" ---
            if (skill.limited) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade400),
                ),
                child: Text(
                  "Limité",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCostBadges() {
    if (skill.multiCost && skill.costs != null) {
      // Plusieurs niveaux de coût : affiche le min → max
      final min = skill.costs!.first;
      final max = skill.costs!.last;
      return _costChip("$min–$max ${_costTypeLabel(skill.costType)}");
    }

    if (skill.secondCost != null && skill.secondCostType != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _costChip("${skill.cost} ${_costTypeLabel(skill.costType)}"),
          const SizedBox(width: 4),
          _costChip(
              "${skill.secondCost} ${_costTypeLabel(skill.secondCostType!)}"),
        ],
      );
    }

    return _costChip("${skill.cost} ${_costTypeLabel(skill.costType)}");
  }

  Widget _costChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  List<Widget> _buildMultiCostDescriptions() {
    final costs = skill.costs!;
    final descs = skill.descriptions!;
    final count = costs.length < descs.length ? costs.length : descs.length;
    return List.generate(count, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${costs[i]} ${_costTypeLabel(skill.costType)} : ",
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Expanded(
              child: Text(descs[i], style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
    });
  }
}
