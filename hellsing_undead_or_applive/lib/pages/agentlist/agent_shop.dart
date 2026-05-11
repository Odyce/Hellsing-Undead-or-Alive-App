import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

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
// Popup armes : carrousel SubAffinities + Kits                    //
/////////////////////////////////////////////////////////////////////
class AgentShopWeaponPopup extends StatefulWidget {
  final int initialMoney;

  /// Capacité encore disponible parmi les armes équipées (max 6).
  /// Permet d'afficher "Place restante" et de rediriger vers le coffre.
  final double initialEquippedCapacity;

  /// True si au moins un BankSlot est vide (pour autoriser l'achat
  /// quand l'inventaire équipé ne peut plus accueillir l'item).
  final bool hasFreeBankSlot;

  /// True si au moins un WeaponSlot équipé est vide (rangement direct).
  final bool hasFreeWeaponSlot;

  final void Function(Weapon weapon, bool toBank) onBuyWeapon;
  final void Function(SupportObject kit, bool toBank) onBuyKit;

  const AgentShopWeaponPopup({
    super.key,
    required this.initialMoney,
    required this.initialEquippedCapacity,
    required this.hasFreeBankSlot,
    required this.hasFreeWeaponSlot,
    required this.onBuyWeapon,
    required this.onBuyKit,
  });

  @override
  State<AgentShopWeaponPopup> createState() => _AgentShopWeaponPopupState();
}

class _AgentShopWeaponPopupState extends State<AgentShopWeaponPopup> {
  late int _money;
  late double _capacity;
  late bool _hasFreeBank;
  late bool _hasFreeWeaponSlot;
  late PageController _pageController;
  int _currentCategory = 0;

  static final int _kitsIndex = SubAffinities.values.length;
  int get _totalCategories => SubAffinities.values.length + 1;

  String _categoryLabel(int i) =>
      i == _kitsIndex ? 'Kits' : _subAffinityLabel(SubAffinities.values[i]);

  @override
  void initState() {
    super.initState();
    _money              = widget.initialMoney;
    _capacity           = widget.initialEquippedCapacity;
    _hasFreeBank        = widget.hasFreeBankSlot;
    _hasFreeWeaponSlot  = widget.hasFreeWeaponSlot;
    _pageController = PageController(initialPage: _totalCategories * 500);
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  bool _goesToBank(double size) =>
      !_hasFreeWeaponSlot || size > _capacity;

  bool _canAfford(int price, double size) =>
      _money >= price && (_goesToBank(size) ? _hasFreeBank : true);

  List<Weapon> _weaponsFor(int cat) {
    if (cat == _kitsIndex) return [];
    final sub = SubAffinities.values[cat];
    return WeaponsList().allWeapons
        .where((w) => w.subType == sub)
        .toList();
  }

  List<SupportObject> _kitsFor() => SupportObjectList().allSupportObject
      .where((s) => s.stockage == Stockage.weapon)
      .toList();

  void _buy(Weapon w) {
    final toBank = _goesToBank(w.size);
    setState(() {
      _money -= w.price;
      if (!toBank) {
        _capacity -= w.size;
        // après cet achat, on doit savoir s'il reste un slot d'arme libre
        // — on laisse la décision au caller (cf. callback) ; on ne maintient
        // ici qu'une approximation pour les achats suivants dans la même session.
        _hasFreeWeaponSlot = false; // pessimiste : recalculé par le caller via setState parent
      } else {
        _hasFreeBank = false; // idem, le caller met à jour le vrai état
      }
    });
    widget.onBuyWeapon(w, toBank);
  }

  void _buyKit(SupportObject s) {
    final toBank = _goesToBank(s.size);
    setState(() {
      _money -= s.price;
      if (!toBank) {
        _capacity -= s.size;
        _hasFreeWeaponSlot = false;
      } else {
        _hasFreeBank = false;
      }
    });
    widget.onBuyKit(s, toBank);
  }

  Widget _weaponCard(Weapon w) {
    final affordable = _canAfford(w.price, w.size);
    final toBank     = _goesToBank(w.size);
    return Card(
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
            Text('Prix : ${w.price}p  •  Taille : ${_formatSize(w.size)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            if (affordable && toBank)
              Text('→ ira au coffre',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
          ])),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: affordable ? () => _buy(w) : null,
            child: const Text('Acheter'),
          ),
        ]),
      ),
    );
  }

  Widget _kitCard(SupportObject s) {
    final affordable = _canAfford(s.price, s.size);
    final toBank     = _goesToBank(s.size);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(s.description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Text('Prix : ${s.price}p  •  Taille : ${_formatSize(s.size)}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            if (affordable && toBank)
              Text('→ ira au coffre',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
          ])),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: affordable ? () => _buyKit(s) : null,
            child: const Text('Acheter'),
          ),
        ]),
      ),
    );
  }

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
          Text('Place équipée : ${_formatSize(_capacity.clamp(0, 6))} / 6',
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
                child: Text('Aucun item dans cette catégorie',
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
// Popup munitions : carrousel MuniCateg + Supports                 //
/////////////////////////////////////////////////////////////////////
class AgentShopMuniPopup extends StatefulWidget {
  final int initialMoney;
  final List<MuniCateg> availableCategs;
  final Set<Calibre> ownedCalibres;
  final void Function(MuniObject muni, int quantity, bool wasFree) onBuy;
  final void Function(SupportObject support) onBuySupport;

  const AgentShopMuniPopup({
    super.key,
    required this.initialMoney,
    required this.availableCategs,
    required this.ownedCalibres,
    required this.onBuy,
    required this.onBuySupport,
  });

  @override
  State<AgentShopMuniPopup> createState() => _AgentShopMuniPopupState();
}

class _AgentShopMuniPopupState extends State<AgentShopMuniPopup> {
  late int _money;
  late PageController _pageController;
  int _currentCategory = 0;

  /// Pages : N MuniCateg puis 1 page "Supports".
  int get _supportsIndex => widget.availableCategs.length;
  int get _totalCategories => widget.availableCategs.length + 1;

  @override
  void initState() {
    super.initState();
    _money = widget.initialMoney;
    _pageController = PageController(initialPage: _totalCategories * 500);
  }

  @override
  void dispose() { _pageController.dispose(); super.dispose(); }

  bool _isFree(MuniObject m) =>
      m.free != null && m.free!.any((c) => widget.ownedCalibres.contains(c));

  int _cost(MuniObject m, int qty) =>
      _isFree(m) ? 0 : (qty == 1 ? m.price : m.priceFor6);

  String _categoryLabel(int i) => i == _supportsIndex
      ? 'Supports'
      : widget.availableCategs[i].description;

  void _buy(MuniObject m, int qty) {
    final isFree = _isFree(m);
    setState(() => _money -= _cost(m, qty));
    widget.onBuy(m, qty, isFree);
  }

  void _buySupport(SupportObject s) {
    setState(() => _money -= s.price);
    widget.onBuySupport(s);
  }

  Widget _muniCard(MuniObject m) {
    final isFree = _isFree(m);
    final c1 = _cost(m, 1);
    final c6 = _cost(m, 6);

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
                onPressed: _money >= c1 ? () => _buy(m, 1) : null,
                child: Text('×1  —  ${isFree ? "Gratuit" : "${c1}p"}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: _money >= c6 ? () => _buy(m, 6) : null,
                child: Text('×6  —  ${isFree ? "Gratuit" : "${c6}p"}'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _emptyMessage(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600)),
        ),
      );

  Widget _supportCard(SupportObject s) => Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(s.description,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('Prix : ${s.price}p',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _money >= s.price ? () => _buySupport(s) : null,
              child: const Text('Acheter'),
            ),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
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
            Text('Placement auto : slot ou Réserve',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey.shade700)),
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
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut)
                  : null,
            ),
            Expanded(child: Column(children: [
              Text(_categoryLabel(_currentCategory),
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center),
              Text('${_currentCategory + 1} / $_totalCategories',
                  style: Theme.of(context).textTheme.bodySmall),
            ])),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _totalCategories > 1
                  ? () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut)
                  : null,
            ),
          ]),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (p) =>
                setState(() => _currentCategory = p % _totalCategories),
            itemBuilder: (context, page) {
              final cat = page % _totalCategories;
              if (cat == _supportsIndex) {
                final supports = SupportObjectList()
                    .allSupportObject
                    .where((s) => s.stockage == Stockage.muni)
                    .toList();
                if (supports.isEmpty) {
                  return _emptyMessage('Aucun support disponible');
                }
                return ListView(
                  padding: const EdgeInsets.all(8),
                  children: supports.map(_supportCard).toList(),
                );
              }
              if (cat >= widget.availableCategs.length) {
                return _emptyMessage(
                    "Aucune catégorie de munitions compatible.\n"
                    "Vous ne possédez pas d'arme à munitions.");
              }
              final category = widget.availableCategs[cat];
              final munis = category.munis.toList();
              if (munis.isEmpty) {
                return _emptyMessage('Aucune munition dans cette catégorie');
              }
              return ListView(
                padding: const EdgeInsets.all(8),
                children: munis.map(_muniCard).toList(),
              );
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
// Popup objets de sac                                              //
/////////////////////////////////////////////////////////////////////
class AgentShopBagPopup extends StatefulWidget {
  final int initialMoney;
  final int initialFreeBagSlots;
  final bool hasFreeBankSlot;
  final void Function(SupportObject s, bool toBank) onBuy;

  const AgentShopBagPopup({
    super.key,
    required this.initialMoney,
    required this.initialFreeBagSlots,
    required this.hasFreeBankSlot,
    required this.onBuy,
  });

  @override
  State<AgentShopBagPopup> createState() => _AgentShopBagPopupState();
}

class _AgentShopBagPopupState extends State<AgentShopBagPopup> {
  late int _money;
  late int _freeBagSlots;
  late bool _hasFreeBank;

  @override
  void initState() {
    super.initState();
    _money        = widget.initialMoney;
    _freeBagSlots = widget.initialFreeBagSlots;
    _hasFreeBank  = widget.hasFreeBankSlot;
  }

  bool _goesToBank() => _freeBagSlots <= 0;
  bool _canBuy(int price) =>
      _money >= price && (_freeBagSlots > 0 || _hasFreeBank);

  void _buy(SupportObject s) {
    final toBank = _goesToBank();
    setState(() {
      _money -= s.price;
      if (toBank) {
        _hasFreeBank = false;
      } else {
        _freeBagSlots--;
      }
    });
    widget.onBuy(s, toBank);
  }

  Widget _bagCard(SupportObject s) {
    final canBuy = _canBuy(s.price);
    final toBank = _goesToBank();
    return Card(
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
            if (canBuy && toBank)
              Text('→ ira au coffre',
                  style: TextStyle(fontSize: 10, color: Colors.orange.shade700)),
          ])),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: canBuy ? () => _buy(s) : null,
            child: const Text('Acheter'),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = SupportObjectList().allSupportObject
        .where((s) => s.stockage == Stockage.bag)
        .toList();
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
            Text('Sac : $_freeBagSlots place(s)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 360,
          child: items.isEmpty
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Aucun objet disponible',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600)),
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
// Popup unifié pour le coffre : armes / munitions / objets         //
//                                                                  //
// Armes / kits / objets de sac → BankSlot (consomment 1 place).    //
// Munitions et supports munis → Réserve (illimitée).               //
/////////////////////////////////////////////////////////////////////
class AgentShopBankPopup extends StatefulWidget {
  final int initialMoney;
  final int initialFreeBankSlots;
  final List<MuniCateg> availableCategs;
  final Set<Calibre> ownedCalibres;
  final void Function(Weapon w) onBuyWeapon;
  final void Function(SupportObject kit) onBuyKit;
  final void Function(MuniObject muni, int quantity, bool wasFree) onBuyMuni;
  final void Function(SupportObject support) onBuyMuniSupport;
  final void Function(SupportObject s) onBuyBagItem;

  const AgentShopBankPopup({
    super.key,
    required this.initialMoney,
    required this.initialFreeBankSlots,
    required this.availableCategs,
    required this.ownedCalibres,
    required this.onBuyWeapon,
    required this.onBuyKit,
    required this.onBuyMuni,
    required this.onBuyMuniSupport,
    required this.onBuyBagItem,
  });

  @override
  State<AgentShopBankPopup> createState() => _AgentShopBankPopupState();
}

class _AgentShopBankPopupState extends State<AgentShopBankPopup>
    with SingleTickerProviderStateMixin {
  late int _money;
  late int _freeBankSlots;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _money         = widget.initialMoney;
    _freeBankSlots = widget.initialFreeBankSlots;
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  bool _hasSlot() => _freeBankSlots > 0;
  bool _isFree(MuniObject m) =>
      m.free != null && m.free!.any((c) => widget.ownedCalibres.contains(c));
  int _muniCost(MuniObject m, int qty) =>
      _isFree(m) ? 0 : (qty == 1 ? m.price : m.priceFor6);

  void _buyWeapon(Weapon w) {
    setState(() { _money -= w.price; _freeBankSlots--; });
    widget.onBuyWeapon(w);
  }

  void _buyKit(SupportObject s) {
    setState(() { _money -= s.price; _freeBankSlots--; });
    widget.onBuyKit(s);
  }

  /// Munis et supports muni vont en Réserve : pas de décompte BankSlot.
  void _buyMuni(MuniObject m, int qty) {
    final free = _isFree(m);
    setState(() => _money -= _muniCost(m, qty));
    widget.onBuyMuni(m, qty, free);
  }

  void _buyMuniSupport(SupportObject s) {
    setState(() => _money -= s.price);
    widget.onBuyMuniSupport(s);
  }

  void _buyBagItem(SupportObject s) {
    setState(() { _money -= s.price; _freeBankSlots--; });
    widget.onBuyBagItem(s);
  }

  Widget _weaponsTab() {
    final weapons = WeaponsList().allWeapons;
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final w in weapons)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(w.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${_subAffinityLabel(w.subType)}  •  ${w.damage}',
                      style: const TextStyle(fontSize: 11)),
                  if (w.feature.isNotEmpty)
                    Text(w.feature, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text('Prix : ${w.price}p  •  Taille : ${_formatSize(w.size)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ])),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_money >= w.price && _hasSlot()) ? () => _buyWeapon(w) : null,
                  child: const Text('Acheter'),
                ),
              ]),
            ),
          ),
        for (final s in SupportObjectList().allSupportObject
            .where((s) => s.stockage == Stockage.weapon))
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s.name}  (kit)', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(s.description,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text('Prix : ${s.price}p  •  Taille : ${_formatSize(s.size)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ])),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_money >= s.price && _hasSlot()) ? () => _buyKit(s) : null,
                  child: const Text('Acheter'),
                ),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _munisTab() {
    final supportItems = SupportObjectList()
        .allSupportObject
        .where((s) => s.stockage == Stockage.muni)
        .toList();
    if (widget.availableCategs.isEmpty && supportItems.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          "Aucune munition disponible.\nVous ne possédez pas d'arme à munitions.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ));
    }
    final munis = widget.availableCategs.expand((cat) => cat.munis).toList();
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final m in munis)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(m.name,
                      style: const TextStyle(fontWeight: FontWeight.bold))),
                  if (_isFree(m))
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
                if (m.description.isNotEmpty)
                  Text(m.description,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed:
                        _money >= _muniCost(m, 1) ? () => _buyMuni(m, 1) : null,
                    child: Text('×1  —  ${_isFree(m) ? "Gratuit" : "${_muniCost(m, 1)}p"}'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(
                    onPressed:
                        _money >= _muniCost(m, 6) ? () => _buyMuni(m, 6) : null,
                    child: Text('×6  —  ${_isFree(m) ? "Gratuit" : "${_muniCost(m, 6)}p"}'),
                  )),
                ]),
              ]),
            ),
          ),
        if (supportItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text('Supports',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
          for (final s in supportItems)
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text(s.description,
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey.shade600)),
                          Text('Prix : ${s.price}p',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed:
                          _money >= s.price ? () => _buyMuniSupport(s) : null,
                      child: const Text('Acheter'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _bagTab() {
    final items = SupportObjectList().allSupportObject
        .where((s) => s.stockage == Stockage.bag)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final s in items)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(s.description,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text('Prix : ${s.price}p',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ])),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (_money >= s.price && _hasSlot()) ? () => _buyBagItem(s) : null,
                  child: const Text('Acheter'),
                ),
              ]),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.all(16),
    child: SizedBox(
      height: 520,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(children: [
            const Icon(Icons.attach_money, size: 18),
            const SizedBox(width: 4),
            Text('$_money', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('Coffre : $_freeBankSlots place(s)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
        ),
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Armes'),
            Tab(text: 'Munitions'),
            Tab(text: 'Sac'),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [_weaponsTab(), _munisTab(), _bagTab()],
          ),
        ),
        const Divider(height: 1),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
      ]),
    ),
  );
}
