import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:http/http.dart';


/////////////////////////////////////////////////////////////////////
// Helpers                                                          //
/////////////////////////////////////////////////////////////////////
String _subAffinityLabel(SubAffinities sub) {
  switch (sub) {
    case SubAffinities.smallOneHandBlade: return 'Petites lames (1 main)';
    case SubAffinities.bigOneHandBlade:   return 'Grandes lames (1 main)';
    case SubAffinities.smallTwoHandBlade: return 'Petites lames (2 mains)';
    case SubAffinities.bigTwoHandBlade:   return 'Grandes lames (2 mains)';
    case SubAffinities.bow:               return 'Arcs & Arbalètes';
    case SubAffinities.throwable:         return 'Armes de jet';
    case SubAffinities.smallHandgun:      return 'Petits pistolets';
    case SubAffinities.bigHandgun:        return 'Gros pistolets';
    case SubAffinities.dispersion:        return 'Tromblons';
    case SubAffinities.smallRifle:        return 'Petits fusils';
    case SubAffinities.bigRifle:          return 'Grands fusils';
  }
}

String _formatSize(double size) =>
    size % 1 == 0 ? size.toInt().toString() : size.toString();


/////////////////////////////////////////////////////////////////////
// État UI d'un emplacement de munitions                            //
/////////////////////////////////////////////////////////////////////
class _MuniSlotData {
  final MuniObject muni;
  final int quantity; // 1 ou 6
  final bool wasFree;

  _MuniSlotData({
    required this.muni,
    required this.quantity,
    required this.wasFree,
  });

  int get refundAmount =>
      wasFree ? 0 : (quantity == 1 ? muni.price : muni.priceFor6);
}


/////////////////////////////////////////////////////////////////////
// Pop-up armes : carousel SubAffinities + Kits                    //
/////////////////////////////////////////////////////////////////////
class _WeaponBuyPopup extends StatefulWidget {
  final int initialMoney;
  final double initialCapacity;
  final void Function(Weapon) onBuyWeapon;
  final void Function(SupportObject) onBuyKit;

  const _WeaponBuyPopup({
    required this.initialMoney,
    required this.initialCapacity,
    required this.onBuyWeapon,
    required this.onBuyKit,
  });

  @override
  State<_WeaponBuyPopup> createState() => _WeaponBuyPopupState();
}

class _WeaponBuyPopupState extends State<_WeaponBuyPopup> {
  late int _money;
  late double _capacity;
  late PageController _pageController;
  int _currentCategory = 0;

  static final int _kitsIndex = SubAffinities.values.length;
  int get _totalCategories => SubAffinities.values.length + 1;

  String _categoryLabel(int i) =>
      i == _kitsIndex ? 'Kits' : _subAffinityLabel(SubAffinities.values[i]);

  @override
  void initState() {
    super.initState();
    _money    = widget.initialMoney;
    _capacity = widget.initialCapacity;
    _pageController = PageController(initialPage: _totalCategories * 500);
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  List<Weapon> _weaponsFor(int cat) {
    if (cat == _kitsIndex) return [];
    final sub = SubAffinities.values[cat];
    return WeaponsList().allWeapons
        .where((w) => w.subType == sub && w.price <= _money && w.size <= _capacity)
        .toList();
  }

  List<SupportObject> _kitsFor() => SupportObjectList().allSupportObject
      .where((s) => s.stockage == Stockage.weapon && s.price <= _money && s.size <= _capacity)
      .toList();

  void _buy(Weapon w) {
    setState(() { _money -= w.price; _capacity -= w.size; });
    widget.onBuyWeapon(w);
  }

  void _buyKit(SupportObject s) {
    setState(() { _money -= s.price; _capacity -= s.size; });
    widget.onBuyKit(s);
  }

  Widget _weaponCard(Weapon w) => Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(w.damage, style: const TextStyle(fontSize: 12)),
          if (w.feature.isNotEmpty)
            Text(w.feature, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Prix : ${w.price}  •  Taille : ${_formatSize(w.size)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: () => _buy(w), child: const Text('Acheter')),
      ]),
    ),
  );

  Widget _kitCard(SupportObject s) => Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(s.description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Prix : ${s.price}  •  Taille : ${_formatSize(s.size)}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: () => _buyKit(s), child: const Text('Acheter')),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(children: [
          const Icon(Icons.attach_money, size: 18),
          const SizedBox(width: 4),
          Text('$_money', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          const Icon(Icons.inventory_2_outlined, size: 18),
          const SizedBox(width: 4),
          Text('Place restante : ${_formatSize(_capacity)} / 6',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 250), curve: Curves.easeInOut),
          ),
          Expanded(child: Column(children: [
            Text(_categoryLabel(_currentCategory),
                style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
            Text('${_currentCategory + 1} / $_totalCategories',
                style: Theme.of(context).textTheme.bodySmall),
          ])),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 250), curve: Curves.easeInOut),
          ),
        ]),
      ),
      const Divider(height: 1),
      SizedBox(
        height: 360,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: (p) => setState(() { _currentCategory = p % _totalCategories; }),
          itemBuilder: (context, page) {
            final cat = page % _totalCategories;
            final cards = cat == _kitsIndex
                ? _kitsFor().map(_kitCard).toList()
                : _weaponsFor(cat).map(_weaponCard).toList();
            if (cards.isEmpty) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Aucun item disponible\n(budget insuffisant ou inventaire plein)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600)),
              ));
            }
            return ListView(padding: const EdgeInsets.all(8), children: cards);
          },
        ),
      ),
      const Divider(height: 1),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
    ]),
  );
}


/////////////////////////////////////////////////////////////////////
// Pop-up munitions : carousel MuniCateg                           //
/////////////////////////////////////////////////////////////////////
class _MuniBuyPopup extends StatefulWidget {
  final int initialMoney;
  final int remainingSlots;
  final List<MuniCateg> availableCategs;
  final Set<Calibre> ownedCalibres;
  final void Function(MuniObject muni, int quantity, bool wasFree) onBuy;

  const _MuniBuyPopup({
    required this.initialMoney,
    required this.remainingSlots,
    required this.availableCategs,
    required this.ownedCalibres,
    required this.onBuy,
  });

  @override
  State<_MuniBuyPopup> createState() => _MuniBuyPopupState();
}

class _MuniBuyPopupState extends State<_MuniBuyPopup> {
  late int _money;
  late int _remainingSlots;
  late PageController _pageController;
  int _currentCategory = 0;

  int get _totalCategories => widget.availableCategs.length;

  @override
  void initState() {
    super.initState();
    _money = widget.initialMoney;
    _remainingSlots = widget.remainingSlots;
    _pageController = PageController(
        initialPage: _totalCategories > 0 ? _totalCategories * 500 : 0);
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  bool _isFree(MuniObject m) =>
      m.free != null && m.free!.any((c) => widget.ownedCalibres.contains(c));

  int _cost(MuniObject m, int qty) =>
      _isFree(m) ? 0 : (qty == 1 ? m.price : m.priceFor6);

  void _buy(MuniObject m, int qty) {
    final isFree = _isFree(m);
    setState(() { _money -= _cost(m, qty); _remainingSlots--; });
    widget.onBuy(m, qty, isFree);
  }

  Widget _muniCard(MuniObject m) {
    final isFree = _isFree(m);
    final c1 = _cost(m, 1);
    final c6 = _cost(m, 6);
    final hasSlot = _remainingSlots > 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (isFree)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(4)),
                child: Text('Gratuit',
                    style: TextStyle(color: Colors.green.shade800,
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ),
          ]),
          if (m.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(m.description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: (hasSlot && _money >= c1) ? () => _buy(m, 1) : null,
                child: Text('×1  —  ${isFree ? "Gratuit" : "${c1}p"}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: (hasSlot && _money >= c6) ? () => _buy(m, 6) : null,
                child: Text('×6  —  ${isFree ? "Gratuit" : "${c6}p"}'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_totalCategories == 0) {
      return Dialog(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Aucune munition disponible.\nVous ne possédez pas d\'arme à munitions.',
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ]),
      ));
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(children: [
            const Icon(Icons.attach_money, size: 18),
            const SizedBox(width: 4),
            Text('$_money', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('Emplacements : $_remainingSlots restant(s)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _totalCategories > 1
                  ? () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
                  : null,
            ),
            Expanded(child: Column(children: [
              Text(widget.availableCategs[_currentCategory].description,
                  style: Theme.of(context).textTheme.titleSmall, textAlign: TextAlign.center),
              Text('${_currentCategory + 1} / $_totalCategories',
                  style: Theme.of(context).textTheme.bodySmall),
            ])),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _totalCategories > 1
                  ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 250), curve: Curves.easeInOut)
                  : null,
            ),
          ]),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (p) => setState(() { _currentCategory = p % _totalCategories; }),
            itemBuilder: (context, page) {
              final cat = widget.availableCategs[page % _totalCategories];
              final munis = cat.munis
                  .where((m) => _isFree(m) || _money >= _cost(m, 1))
                  .toList();
              if (munis.isEmpty || _remainingSlots <= 0) {
                return Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _remainingSlots <= 0
                        ? 'Tous les emplacements sont remplis.'
                        : 'Aucune munition disponible\n(budget insuffisant)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ));
              }
              return ListView(padding: const EdgeInsets.all(8),
                  children: munis.map(_muniCard).toList());
            },
          ),
        ),
        const Divider(height: 1),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
      ]),
    );
  }
}


/////////////////////////////////////////////////////////////////////
// Pop-up objets de sac                                             //
/////////////////////////////////////////////////////////////////////
class _BagBuyPopup extends StatefulWidget {
  final int initialMoney;
  final int remainingSlots;
  final void Function(SupportObject) onBuy;

  const _BagBuyPopup({
    required this.initialMoney,
    required this.remainingSlots,
    required this.onBuy,
  });

  @override
  State<_BagBuyPopup> createState() => _BagBuyPopupState();
}

class _BagBuyPopupState extends State<_BagBuyPopup> {
  late int _money;
  late int _remainingSlots;

  @override
  void initState() {
    super.initState();
    _money = widget.initialMoney;
    _remainingSlots = widget.remainingSlots;
  }

  List<SupportObject> get _available => SupportObjectList().allSupportObject
      .where((s) => s.stockage == Stockage.bag && s.price <= _money && _remainingSlots > 0)
      .toList();

  void _buy(SupportObject s) {
    setState(() { _money -= s.price; _remainingSlots--; });
    widget.onBuy(s);
  }

  Widget _bagCard(SupportObject s) => Card(
    margin: const EdgeInsets.symmetric(vertical: 4),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(s.description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Prix : ${s.price}p',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ])),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: () => _buy(s), child: const Text('Acheter')),
      ]),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final items = _available;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(children: [
            const Icon(Icons.attach_money, size: 18),
            const SizedBox(width: 4),
            Text('$_money', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('Places : $_remainingSlots / 10',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 360,
          child: items.isEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _remainingSlots <= 0
                        ? 'Le sac est plein.'
                        : 'Aucun objet disponible\n(budget insuffisant)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ))
              : ListView(padding: const EdgeInsets.all(8),
                  children: items.map(_bagCard).toList()),
        ),
        const Divider(height: 1),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
      ]),
    );
  }
}


/////////////////////////////////////////////////////////////////////
// Page 2 de création d'agent : inventaire initial                  //
/////////////////////////////////////////////////////////////////////
class CreateAgentInventoryPage extends StatefulWidget {
  final String name;
  final String background;
  final String state;
  final String note;
  final File? selectedImage;
  final List<int> attributes;
  final List<int> pools;
  final List<int> maxPools;
  final Race race;
  final int powerScore;
  final AgentClass agentClass;
  final List<int> classBonuses;
  final List<Skill> skills;
  final int money;
  final int pc;
  final List<Contact> contacts;

  const CreateAgentInventoryPage({
    super.key,
    required this.name,
    required this.background,
    required this.state,
    required this.note,
    this.selectedImage,
    required this.attributes,
    required this.pools,
    required this.maxPools,
    required this.race,
    required this.powerScore,
    required this.agentClass,
    required this.classBonuses,
    required this.skills,
    required this.money,
    required this.pc,
    required this.contacts,
  });

  @override
  State<CreateAgentInventoryPage> createState() =>
      _CreateAgentInventoryPageState();
}

class _CreateAgentInventoryPageState extends State<CreateAgentInventoryPage> {
  Weapon? _selectedStartingWeapon;
  late int _remainingMoney;

  final List<WeaponSlot>    _purchasedWeaponSlots = [];
  final List<_MuniSlotData> _filledMuniSlots      = [];
  final List<BagSlot>       _purchasedBagSlots    = [];

  bool _loading = false;
  String? _error;
  final AgentRepository _repository = AgentRepository();

  static const double _maxWeaponCapacity = 6.0;
  static const int    _maxBagSlots       = 10;

  @override
  void initState() {
    super.initState();
    _remainingMoney = widget.money;
  }

  // ── Calibres possédés ─────────────────────────────────────────────────────
  Set<Calibre> get _ownedCalibres {
    final calibres = <Calibre>{};
    for (final slot in _allWeaponSlots) {
      final c = slot.weapon?.calibre;
      if (c != null) calibres.add(c);
    }
    return calibres;
  }

  // ── Catégories de munitions disponibles ──────────────────────────────────
  List<MuniCateg> get _availableMuniCategs {
    final owned = _ownedCalibres;
    return MuniCategList().allMuniCateg
        .where((cat) => cat.included.any((c) => owned.contains(c)))
        .toList();
  }

  // ── Slots munitions ───────────────────────────────────────────────────────
  int get _cartouchiereCount =>
      _purchasedBagSlots.where((s) => s.support?.id == 16).length;

  int get _totalMuniSlots =>
      widget.agentClass.muniSlotNumber + _cartouchiereCount;

  int get _freeMuniSlots => _totalMuniSlots - _filledMuniSlots.length;

  // ── Armes ─────────────────────────────────────────────────────────────────
  List<WeaponSlot> _getStartingWeaponSlots() {
    final slots = <WeaponSlot>[];
    if (_selectedStartingWeapon != null) {
      slots.add(WeaponSlot.empty(0).copyWith(
          weapon: _selectedStartingWeapon, empty: false));
    }
    // EXTENSIBLE : ajouter un 2e paramètre d'arme de départ ici si nécessaire
    return slots;
  }

  List<WeaponSlot> get _allWeaponSlots {
    final starting = _getStartingWeaponSlots();
    final result = <WeaponSlot>[...starting];
    for (int i = 0; i < _purchasedWeaponSlots.length; i++) {
      result.add(_purchasedWeaponSlots[i].copyWith(id: starting.length + i));
    }
    return result;
  }

  double get _usedCapacity =>
      _allWeaponSlots.fold(0.0, (s, slot) => s + (slot.size ?? 0.0));

  double get _remainingCapacity => _maxWeaponCapacity - _usedCapacity;

  List<Weapon> get _startingWeapons {
    final affinities = widget.agentClass.affinities;
    return WeaponsList().allWeapons.where((w) {
      if (!w.startingWeapon) return false;
      for (final a in affinities) {
        if (a == Affinities.none) continue;
        if (a == Affinities.choiceNonExplosive) {
          if (w.type != Affinities.explosive && w.type != Affinities.none) return true;
        } else {
          if (w.type == a) return true;
        }
      }
      return false;
    }).toList();
  }

  bool get _hasWeaponChoice =>
      widget.agentClass.affinities.any((a) => a != Affinities.none);

  // ── Achat / retrait : Armes ───────────────────────────────────────────────
  void _onBuyWeapon(Weapon w) {
    setState(() {
      _remainingMoney -= w.price;
      _purchasedWeaponSlots.add(
          WeaponSlot.empty(_purchasedWeaponSlots.length).copyWith(weapon: w, empty: false));
    });
  }

  void _onBuyKit(SupportObject s) {
    setState(() {
      _remainingMoney -= s.price;
      _purchasedWeaponSlots.add(
          WeaponSlot.empty(_purchasedWeaponSlots.length).copyWith(kit: s, empty: false));
    });
  }

  void _removeWeaponSlot(int purchasedIndex) {
    final slot = _purchasedWeaponSlots[purchasedIndex];
    final refund = slot.weapon?.price ?? slot.kit?.price ?? 0;
    setState(() {
      _remainingMoney += refund;
      _purchasedWeaponSlots.removeAt(purchasedIndex);
      _cleanOrphanedMuniSlots(); // cascade
    });
  }

  // Retire les munitions dont l'arme associée n'existe plus
  void _cleanOrphanedMuniSlots() {
    final remaining = _ownedCalibres;
    for (int i = _filledMuniSlots.length - 1; i >= 0; i--) {
      if (!_muniStillValid(_filledMuniSlots[i].muni, remaining)) {
        _remainingMoney += _filledMuniSlots[i].refundAmount;
        _filledMuniSlots.removeAt(i);
      }
    }
  }

  bool _muniStillValid(MuniObject muni, Set<Calibre> calibres) =>
      MuniCategList().allMuniCateg.any((cat) =>
          cat.munis.any((m) => m.id == muni.id) &&
          cat.included.any((c) => calibres.contains(c)));

  // ── Achat / retrait : Munitions ───────────────────────────────────────────
  void _onBuyMuni(MuniObject muni, int quantity, bool wasFree) {
    final cost = wasFree ? 0 : (quantity == 1 ? muni.price : muni.priceFor6);
    setState(() {
      _remainingMoney -= cost;
      _filledMuniSlots.add(_MuniSlotData(muni: muni, quantity: quantity, wasFree: wasFree));
    });
  }

  void _removeMuniSlot(int index) {
    setState(() {
      _remainingMoney += _filledMuniSlots[index].refundAmount;
      _filledMuniSlots.removeAt(index);
    });
  }

  // ── Achat / retrait : Sac ─────────────────────────────────────────────────
  void _onBuyBagItem(SupportObject s) {
    setState(() {
      _remainingMoney -= s.price;
      _purchasedBagSlots.add(
          BagSlot(id: _purchasedBagSlots.length, empty: false, support: s));
    });
  }

  void _removeBagSlot(int index) {
    final slot = _purchasedBagSlots[index];
    final refund    = slot.support?.price ?? 0;
    final isCartou  = slot.support?.id == 16;
    setState(() {
      _remainingMoney += refund;
      _purchasedBagSlots.removeAt(index);
      // Cascade : si c'est une Cartouchière, retirer le dernier slot de muni si nécessaire
      if (isCartou) {
        final newTotal = _totalMuniSlots; // recalculé après suppression
        while (_filledMuniSlots.length > newTotal) {
          _remainingMoney += _filledMuniSlots.last.refundAmount;
          _filledMuniSlots.removeLast();
        }
      }
    });
  }

  // ── Popups ────────────────────────────────────────────────────────────────
  void _showBuyWeaponPopup() => showDialog(
    context: context,
    builder: (_) => _WeaponBuyPopup(
      initialMoney: _remainingMoney,
      initialCapacity: _remainingCapacity,
      onBuyWeapon: _onBuyWeapon,
      onBuyKit: _onBuyKit,
    ),
  );

  void _showBuyMuniPopup() => showDialog(
    context: context,
    builder: (_) => _MuniBuyPopup(
      initialMoney:    _remainingMoney,
      remainingSlots:  _freeMuniSlots,
      availableCategs: _availableMuniCategs,
      ownedCalibres:   _ownedCalibres,
      onBuy:           _onBuyMuni,
    ),
  );

  void _showBuyBagPopup() => showDialog(
    context: context,
    builder: (_) => _BagBuyPopup(
      initialMoney:   _remainingMoney,
      remainingSlots: _maxBagSlots - _purchasedBagSlots.length,
      onBuy:          _onBuyBagItem,
    ),
  );

  // ── Construction pour la sauvegarde ──────────────────────────────────────
  List<WeaponSlot> _buildWeaponSlotsForSave() {
    final slots = _allWeaponSlots;
    return slots.isEmpty ? [WeaponSlot.empty(0)] : slots;
  }

  List<MuniSlot> _buildMuniSlotsForSave() {
    final total = _totalMuniSlots;
    final count = total > 0 ? total : 1;
    return List.generate(count, (i) {
      if (i < _filledMuniSlots.length) {
        final d = _filledMuniSlots[i];
        return MuniSlot(id: i, muni: d.muni, numberLeft: d.quantity, empty: false);
      }
      return MuniSlot(id: i, empty: true, numberLeft: 0);
    });
  }

  List<BagSlot> _buildBagSlotsForSave() => List.generate(10, (i) {
    if (i < _purchasedBagSlots.length) return _purchasedBagSlots[i].copyWith(id: i);
    return BagSlot(id: i, empty: true);
  });

  List<BankSlot> _initBankSlots() =>
      List.generate(50, (i) => BankSlot(id: i, empty: true));

  List<MissionRecord> _initMissions() => [
    MissionRecord(
      id: -66,
      title: 'Foundation Training',
      description: "Fausse mission d'entraînement pour que la liste ne soit pas vide, ne doit pas être visible.",
      completedAt: null,
    ),
  ];

  // ── Sauvegarde Firestore ──────────────────────────────────────────────────
  Future<void> _createAgent() async {
    setState(() { _loading = true; _error = null; });
    try {
      String? imageUrl;
      if (widget.selectedImage != null) {
        imageUrl = await _uploadToCloudinary(widget.selectedImage!);
      }
      await _repository.createAgent(
        name:              widget.name,
        background:        widget.background,
        state:             widget.state,
        note:              widget.note,
        profilPicturePath: imageUrl ?? '',
        attributes:        widget.attributes,
        pools:             widget.pools,
        maxPools:          widget.maxPools,
        race:              widget.race,
        powerScore:        widget.powerScore,
        agentClass:        widget.agentClass,
        classBonuses:      widget.classBonuses,
        skills:            widget.skills,
        bagSlots:          _buildBagSlotsForSave(),
        bankSlots:         _initBankSlots(),
        muniSlots:         _buildMuniSlotsForSave(),
        weaponSlots:       _buildWeaponSlotsForSave(),
        money:             _remainingMoney,
        missions:          _initMissions(),
        level:             1,
        pc:                widget.pc,
        contacts:          widget.contacts,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.agentList);
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<String> _uploadToCloudinary(File image) async {
    const cloudName    = 'hellsingundeadapp';
    const uploadPreset = 'Agent_profiles-unsigned';
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await MultipartFile.fromPath('file', image.path));
    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erreur upload Cloudinary: ${response.statusCode}');
    }
    final body = await response.stream.bytesToString();
    final data = jsonDecode(body);
    return data['secure_url'];
  }

  // ── Build principal ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final startingCount   = _getStartingWeaponSlots().length;
    final allWeaponSlots  = _allWeaponSlots;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventaire de départ')),
      body: Column(children: [

        // Header sticky argent
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.attach_money),
            const SizedBox(width: 6),
            Text(
              'Argent restant : $_remainingMoney',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ]),
        ),

        Expanded(
          child: ListView(padding: const EdgeInsets.all(16), children: [

            // ── Équipement de base ──────────────────────────────────────────
            Text('Équipement de base', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.inventory_2_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(
                "Nombre d'emplacements de munitions : ${widget.agentClass.muniSlotNumber}",
                style: Theme.of(context).textTheme.bodyMedium,
              )),
            ]),
            const SizedBox(height: 20),

            if (_hasWeaponChoice) ...[
              DropdownButtonFormField<Weapon>(
                initialValue: _selectedStartingWeapon,
                items: _startingWeapons.map((w) =>
                    DropdownMenuItem(value: w, child: Text(w.name))).toList(),
                onChanged: (v) => setState(() { _selectedStartingWeapon = v; }),
                decoration: const InputDecoration(labelText: 'Arme de départ'),
              ),
              if (_selectedStartingWeapon != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _selectedStartingWeapon!.feature.isNotEmpty
                        ? _selectedStartingWeapon!.feature
                        : _selectedStartingWeapon!.legend,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],

            // ── Inventaire d'armes ──────────────────────────────────────────
            const Divider(thickness: 2),
            const SizedBox(height: 16),
            _buildWeaponSection(startingCount, allWeaponSlots),

            // ── Inventaire de munitions ─────────────────────────────────────
            const SizedBox(height: 24),
            const Divider(thickness: 2),
            const SizedBox(height: 16),
            _buildMuniSection(),

            // ── Inventaire d'objets ─────────────────────────────────────────
            const SizedBox(height: 24),
            const Divider(thickness: 2),
            const SizedBox(height: 16),
            _buildBagSection(),

            const SizedBox(height: 32),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _createAgent,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text("Créer l'agent"),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Section armes ─────────────────────────────────────────────────────────
  Widget _buildWeaponSection(int startingCount, List<WeaponSlot> allSlots) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Inventaire d'armes", style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: LinearProgressIndicator(
          value: (_usedCapacity / _maxWeaponCapacity).clamp(0.0, 1.0),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: _usedCapacity > _maxWeaponCapacity
              ? Colors.red : Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.grey.shade300,
        )),
        const SizedBox(width: 12),
        Text(
          '${_formatSize(_usedCapacity)} / ${_formatSize(_maxWeaponCapacity)}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _usedCapacity > _maxWeaponCapacity ? Colors.red : null,
          ),
        ),
      ]),
      const SizedBox(height: 12),
      if (allSlots.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('Aucune arme pour le moment.',
              style: TextStyle(color: Colors.grey.shade600)),
        ),
      for (int i = 0; i < allSlots.length; i++) ...[
        _buildWeaponSlotTile(
          slot: allSlots[i],
          isStarting: i < startingCount,
          purchasedIndex: i < startingCount ? null : i - startingCount,
        ),
        const SizedBox(height: 6),
      ],
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _remainingCapacity <= 0 ? null : _showBuyWeaponPopup,
          icon: const Icon(Icons.add),
          label: const Text('Nouvelle arme'),
        ),
      ),
    ]);
  }

  // ── Section munitions ─────────────────────────────────────────────────────
  Widget _buildMuniSection() {
    final total  = _totalMuniSlots;
    final filled = _filledMuniSlots.length;
    final hasCompatible = _availableMuniCategs.isNotEmpty;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Inventaire de munitions', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text('$filled / $total emplacement(s) rempli(s)',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      const SizedBox(height: 12),
      if (total == 0)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('Aucun emplacement de munitions disponible.',
              style: TextStyle(color: Colors.grey.shade600)),
        ),
      for (int i = 0; i < filled; i++) ...[
        _buildFilledMuniTile(i),
        const SizedBox(height: 6),
      ],
      for (int i = filled; i < total; i++) ...[
        _buildEmptyMuniTile(i),
        const SizedBox(height: 6),
      ],
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: (!hasCompatible || filled >= total) ? null : _showBuyMuniPopup,
          icon: const Icon(Icons.add),
          label: Text(
            !hasCompatible
                ? 'Aucune arme à munitions'
                : filled >= total
                    ? 'Tous les emplacements sont remplis'
                    : 'Nouvelles munitions',
          ),
        ),
      ),
    ]);
  }

  // ── Section sac ───────────────────────────────────────────────────────────
  Widget _buildBagSection() {
    final filled = _purchasedBagSlots.length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Inventaire d'objets", style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 4),
      Text('$filled / $_maxBagSlots emplacement(s) rempli(s)',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      const SizedBox(height: 12),
      if (_purchasedBagSlots.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text('Aucun objet pour le moment.',
              style: TextStyle(color: Colors.grey.shade600)),
        ),
      for (int i = 0; i < _purchasedBagSlots.length; i++) ...[
        _buildBagSlotTile(i),
        const SizedBox(height: 6),
      ],
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: filled >= _maxBagSlots ? null : _showBuyBagPopup,
          icon: const Icon(Icons.add),
          label: const Text('Nouvel objet'),
        ),
      ),
    ]);
  }

  // ── Tuiles ────────────────────────────────────────────────────────────────
  Widget _buildWeaponSlotTile({
    required WeaponSlot slot,
    required bool isStarting,
    required int? purchasedIndex,
  }) {
    final title    = slot.weapon?.name ?? slot.kit?.name ?? '—';
    final subtitle = slot.weapon?.damage ?? slot.kit?.description;
    final size     = slot.size ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isStarting
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)
              : Colors.grey.shade400,
        ),
        borderRadius: BorderRadius.circular(8),
        color: isStarting
            ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2)
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          slot.weapon != null ? Icons.security : Icons.medical_services_outlined,
          size: 20),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 11)) : null,
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Taille : ${_formatSize(size)}', style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 8),
          if (isStarting)
            Tooltip(
              message: 'Arme de départ (non retirable)',
              child: Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade500),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18),
              color: Colors.red,
              tooltip: 'Retirer (remboursé)',
              onPressed: () => _removeWeaponSlot(purchasedIndex!),
            ),
        ]),
      ),
    );
  }

  Widget _buildFilledMuniTile(int index) {
    final d = _filledMuniSlots[index];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.shield_outlined, size: 20),
        title: Text(d.muni.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${d.quantity == 1 ? "1 unité" : "6 unités"}  •  '
          "${d.wasFree ? 'Obtenu gratuitement' : '${d.muni.price}p l\'unité'}",
          style: const TextStyle(fontSize: 11),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          color: Colors.red,
          tooltip: d.wasFree ? 'Retirer (non remboursé)' : 'Retirer (remboursé)',
          onPressed: () => _removeMuniSlot(index),
        ),
      ),
    );
  }

  Widget _buildEmptyMuniTile(int index) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
      color: Colors.grey.shade50,
    ),
    child: ListTile(
      dense: true,
      leading: Icon(Icons.radio_button_unchecked, size: 20, color: Colors.grey.shade400),
      title: Text('Emplacement ${index + 1} — vide',
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
    ),
  );

  Widget _buildBagSlotTile(int index) {
    final s = _purchasedBagSlots[index].support!;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          s.id == 16 ? Icons.add_box_outlined : Icons.inventory_outlined,
          size: 20),
        title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(s.description, style: const TextStyle(fontSize: 11)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('${s.price}p', style: const TextStyle(fontSize: 11)),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: Colors.red,
            tooltip: 'Retirer (remboursé)',
            onPressed: () => _removeBagSlot(index),
          ),
        ]),
      ),
    );
  }
}
