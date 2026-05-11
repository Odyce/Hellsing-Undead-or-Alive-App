import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/domain/stats/stats_repository.dart';
import 'package:hellsing_undead_or_applive/pages/agentlist/agent_shop.dart';
import 'package:hellsing_undead_or_applive/pages/agentlist/level_up_page.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

// ─── Constantes upload Cloudinary photo de profil ─────────────────────────
const int _maxProfilPictureBytes = 10 * 1024 * 1024; // 10 Mo
const String _profilPictureSizeReminder =
    'Image au format classique (jpg, png…) — 10 Mo maximum.';

Future<String?> _uploadProfilPictureToCloudinary(File image) async {
  const cloudName = 'hellsingundeadapp';
  const uploadPreset = 'Agent_profiles-unsigned';
  final uri =
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
  final request = http.MultipartRequest('POST', uri)
    ..fields['upload_preset'] = uploadPreset
    ..files.add(await http.MultipartFile.fromPath('file', image.path));
  final response = await request.send();
  final body = await response.stream.bytesToString();
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception('Erreur upload Cloudinary ${response.statusCode}: $body');
  }
  return jsonDecode(body)['secure_url'] as String?;
}

class AgentSheetPage extends StatefulWidget {
  final String agentDocId;
  final String? ownerUid; // Si null, utilise l'utilisateur courant

  const AgentSheetPage({
    super.key,
    required this.agentDocId,
    this.ownerUid,
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
  Reserve? _localReserve;
  int? _localMoney;
  bool _inventoryDirty = false;

  static const double _maxWeaponCapacity = 6.0;

  // Upload de photo de profil en cours
  bool _uploadingPicture = false;

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
      _localReserve = agent.reserve;
      _localMoney = agent.money;
    }
  }

  /// Déduit le calibre approximatif pour un MuniObject en parcourant les
  /// MuniCateg. Utile quand on doit créer un slot munition sans connaître
  /// explicitement le calibre cible — on prend le 1er calibre de la categ.
  Calibre _findCalibreForMuni(MuniObject muni) {
    for (final cat in MuniCategList().allMuniCateg) {
      if (cat.munis.any((m) => m.id == muni.id)) {
        return cat.included.isNotEmpty ? cat.included.first : Calibre.empty;
      }
    }
    return Calibre.empty;
  }

  // --- Helpers d'inventaire (boutique) ---

  Set<Calibre> get _ownedCalibres {
    final calibres = <Calibre>{};
    for (final s in _weaponSlots ?? const <WeaponSlot>[]) {
      final c = s.weapon?.calibre;
      if (c != null) calibres.add(c);
    }
    return calibres;
  }

  List<MuniCateg> get _availableMuniCategs {
    final owned = _ownedCalibres;
    return MuniCategList().allMuniCateg
        .where((cat) => cat.included.any((c) => owned.contains(c)))
        .toList();
  }

  double get _usedWeaponCapacity =>
      (_weaponSlots ?? const <WeaponSlot>[])
          .fold(0.0, (s, slot) => s + (slot.size ?? 0.0));

  double get _remainingWeaponCapacity =>
      _maxWeaponCapacity - _usedWeaponCapacity;

  int get _freeBagSlots =>
      (_bagSlots ?? const <BagSlot>[]).where((s) => s.empty).length;

  int get _freeBankSlots =>
      (_bankSlots ?? const <BankSlot>[]).where((s) => s.empty).length;

  int _firstEmptyIndex<T>(List<T> list, bool Function(T) isEmpty) {
    for (int i = 0; i < list.length; i++) {
      if (isEmpty(list[i])) return i;
    }
    return -1;
  }

  void _placeWeaponInBank(Weapon? weapon, SupportObject? kit) {
    final bankIdx = _firstEmptyIndex(_bankSlots!, (b) => b.empty);
    if (bankIdx == -1) return;
    final wsId = _bankSlots![bankIdx].id;
    final ws = WeaponSlot.empty(wsId).copyWith(
      weapon: weapon,
      kit: kit,
      empty: false,
    );
    _bankSlots![bankIdx] = BankSlot(id: wsId, empty: false, weapon: ws);
  }

  // --- Achats : weaponSlot d'abord, sinon bankSlot ---

  void _buyWeaponSlot(Weapon w, {required bool toBank}) {
    setState(() {
      _localMoney = _localMoney! - w.price;
      if (toBank) {
        _placeWeaponInBank(w, null);
      } else {
        final idx = _firstEmptyIndex(_weaponSlots!, (s) => s.empty);
        if (idx == -1) {
          _placeWeaponInBank(w, null);
        } else {
          _weaponSlots![idx] = _weaponSlots![idx]
              .copyWith(weapon: w, empty: false);
        }
      }
      _inventoryDirty = true;
    });
  }

  void _buyKitSlot(SupportObject kit, {required bool toBank}) {
    setState(() {
      _localMoney = _localMoney! - kit.price;
      if (toBank) {
        _placeWeaponInBank(null, kit);
      } else {
        final idx = _firstEmptyIndex(_weaponSlots!, (s) => s.empty);
        if (idx == -1) {
          _placeWeaponInBank(null, kit);
        } else {
          _weaponSlots![idx] = _weaponSlots![idx]
              .copyWith(kit: kit, empty: false);
        }
      }
      _inventoryDirty = true;
    });
  }

  /// Place [quantity] munitions selon les règles Q5 :
  ///  - quantity == 1 : 1er slot compatible non plein → 1er slot vide → Réserve
  ///  - quantity == 6 : remplir 1er slot compatible (déborde Réserve) ;
  ///                    sinon 1er slot vide (déborde Réserve) ; sinon Réserve.
  ///
  /// Si [toBank] est `true`, on force tout en Réserve (achat depuis l'onglet
  /// Coffre). [wasFree] applique un coût nul.
  void _buyMuni(MuniObject muni, int quantity, bool wasFree,
      {required bool toBank}) {
    final cost = wasFree ? 0 : (quantity == 1 ? muni.price : muni.priceFor6);
    setState(() {
      _localMoney = _localMoney! - cost;
      if (toBank) {
        _localReserve = _localReserve!.addMunis(List.filled(quantity, muni));
        _inventoryDirty = true;
        return;
      }
      var remaining = quantity;
      // 1er slot compatible (non vide, non plein, calibre/categ matchent)
      final compatIdx = _firstNonEmptyCompatibleForMuni(muni);
      if (compatIdx != null) {
        final slot = _muniSlots![compatIdx];
        final cap = _slotCapacity(slot);
        final freeSpace = cap - slot.used;
        final n = remaining < freeSpace ? remaining : freeSpace;
        var next = slot;
        for (int i = 0; i < n; i++) {
          next = _addedMuniTo(next, muni);
        }
        _muniSlots![compatIdx] = next;
        remaining -= n;
        // Déborde directement en Réserve sans tenter un slot vide.
        if (remaining > 0) {
          _localReserve = _localReserve!.addMunis(List.filled(remaining, muni));
          remaining = 0;
        }
      } else {
        // Pas de compatible : tenter un slot vide
        final emptyIdx = _firstEmptyIndex(_muniSlots!, (s) => s.isEmpty);
        if (emptyIdx != -1) {
          final calibre = _findCalibreForMuni(muni);
          // Capacité d'un slot vide qui prend ce calibre
          final cap =
              (calibre == Calibre.herb || calibre == Calibre.throwable) ? 6 : 8;
          final n = remaining < cap ? remaining : cap;
          _muniSlots![emptyIdx] = MuniSlot.munition(
            id: _muniSlots![emptyIdx].id,
            calibre: calibre,
            munis: List.filled(n, muni),
          );
          remaining -= n;
        }
        if (remaining > 0) {
          _localReserve = _localReserve!.addMunis(List.filled(remaining, muni));
          remaining = 0;
        }
      }
      _inventoryDirty = true;
    });
  }

  /// 1er slot équipé non vide qui peut accepter cette muni (calibre/categ ok,
  /// pas plein, pas en mode support). Retourne null si aucun.
  int? _firstNonEmptyCompatibleForMuni(MuniObject m) {
    for (int i = 0; i < (_muniSlots ?? const <MuniSlot>[]).length; i++) {
      final s = _muniSlots![i];
      if (s.mode == MuniSlotMode.empty) continue;
      if (_canPushMuniToSlot(m, s)) return i;
    }
    return null;
  }

  /// Achat d'un SupportObject de stockage muni (Fumigène, Feu de Signal).
  /// Placement : 1er slot support du même type non plein → 1er slot vide → Réserve.
  void _buySupportMuni(SupportObject support, {required bool toBank}) {
    setState(() {
      _localMoney = _localMoney! - support.price;
      if (toBank) {
        _localReserve = _localReserve!.addSupport(support);
        _inventoryDirty = true;
        return;
      }
      // Slot support du même type non plein
      for (int i = 0; i < _muniSlots!.length; i++) {
        final s = _muniSlots![i];
        if (s.mode == MuniSlotMode.support &&
            s.support?.id == support.id &&
            s.supportCount < 6) {
          _muniSlots![i] = MuniSlot.supportSlot(
            id: s.id,
            support: support,
            count: s.supportCount + 1,
          );
          _inventoryDirty = true;
          return;
        }
      }
      // Slot vide
      final emptyIdx = _firstEmptyIndex(_muniSlots!, (s) => s.isEmpty);
      if (emptyIdx != -1) {
        _muniSlots![emptyIdx] = MuniSlot.supportSlot(
          id: _muniSlots![emptyIdx].id,
          support: support,
          count: 1,
        );
        _inventoryDirty = true;
        return;
      }
      // Sinon réserve
      _localReserve = _localReserve!.addSupport(support);
      _inventoryDirty = true;
    });
  }

  void _buyBagItem(SupportObject s, {required bool toBank}) {
    setState(() {
      _localMoney = _localMoney! - s.price;
      if (toBank) {
        final bankIdx = _firstEmptyIndex(_bankSlots!, (b) => b.empty);
        if (bankIdx == -1) return;
        final id = _bankSlots![bankIdx].id;
        final bs = BagSlot(id: id, empty: false, support: s);
        _bankSlots![bankIdx] = BankSlot(id: id, empty: false, bag: bs);
      } else {
        final idx = _firstEmptyIndex(_bagSlots!, (b) => b.empty);
        if (idx == -1) {
          final bankIdx = _firstEmptyIndex(_bankSlots!, (b) => b.empty);
          if (bankIdx == -1) return;
          final id = _bankSlots![bankIdx].id;
          final bs = BagSlot(id: id, empty: false, support: s);
          _bankSlots![bankIdx] = BankSlot(id: id, empty: false, bag: bs);
        } else {
          _bagSlots![idx] = BagSlot(id: _bagSlots![idx].id, empty: false, support: s);
        }
      }
      _inventoryDirty = true;
    });
  }

  // --- Revente avec remboursement ---

  void _sellWeaponSlot(int slotIndex) {
    final ws = _weaponSlots![slotIndex];
    if (ws.empty) return;
    final refund = ws.weapon?.price ?? ws.kit?.price ?? 0;
    setState(() {
      _localMoney = _localMoney! + refund;
      _unlinkAllMagazinesFor(ws.id);
      _weaponSlots![slotIndex] = WeaponSlot.empty(ws.id);
      _inventoryDirty = true;
    });
  }

  void _sellMuniSlot(int slotIndex) {
    final ms = _muniSlots![slotIndex];
    if (ms.isEmpty) return;
    int refund = 0;
    // Munitions empilées dans le slot : remboursement par unité au prix unitaire,
    // sauf groupes de 6 qui appliquent priceFor6.
    if (ms.munis.isNotEmpty) {
      // groupage par MuniObject pour appliquer le tarif × 6 si possible
      final byId = <int, ({MuniObject m, int qty})>{};
      for (final m in ms.munis) {
        final cur = byId[m.id];
        byId[m.id] = (m: m, qty: (cur?.qty ?? 0) + 1);
      }
      for (final entry in byId.values) {
        final groupsOf6 = entry.qty ~/ 6;
        final remainder = entry.qty - groupsOf6 * 6;
        refund += groupsOf6 * entry.m.priceFor6 + remainder * entry.m.price;
      }
    } else if (ms.support != null) {
      refund += ms.support!.price * ms.supportCount;
    }
    setState(() {
      _localMoney = _localMoney! + refund;
      _muniSlots![slotIndex] = MuniSlot.empty(ms.id);
      _inventoryDirty = true;
    });
  }

  void _sellBagSlot(int slotIndex) {
    final bs = _bagSlots![slotIndex];
    if (bs.empty || bs.support == null) return;
    final refund = bs.support!.price;
    setState(() {
      _localMoney = _localMoney! + refund;
      _bagSlots![slotIndex] = BagSlot(id: bs.id, empty: true);
      _inventoryDirty = true;
    });
  }

  void _sellBankSlot(int slotIndex) {
    final b = _bankSlots![slotIndex];
    if (b.empty) return;
    int refund = 0;
    if (b.weapon != null) {
      refund = b.weapon!.weapon?.price ?? b.weapon!.kit?.price ?? 0;
    } else if (b.bag != null) {
      refund = b.bag!.support?.price ?? 0;
    }
    setState(() {
      _localMoney = _localMoney! + refund;
      _bankSlots![slotIndex] = BankSlot(id: b.id, empty: true);
      _inventoryDirty = true;
    });
  }

  // --- Popups boutique ---

  void _openWeaponShop() {
    showDialog(
      context: context,
      builder: (_) => AgentShopWeaponPopup(
        initialMoney: _localMoney!,
        initialEquippedCapacity: _remainingWeaponCapacity,
        hasFreeBankSlot: _freeBankSlots > 0,
        hasFreeWeaponSlot: _firstEmptyIndex(_weaponSlots!, (s) => s.empty) != -1,
        onBuyWeapon: (w, toBank) => _buyWeaponSlot(w, toBank: toBank),
        onBuyKit: (k, toBank) => _buyKitSlot(k, toBank: toBank),
      ),
    );
  }

  void _openMuniShop() {
    showDialog(
      context: context,
      builder: (_) => AgentShopMuniPopup(
        initialMoney: _localMoney!,
        availableCategs: _availableMuniCategs,
        ownedCalibres: _ownedCalibres,
        onBuy: (m, qty, free) =>
            _buyMuni(m, qty, free, toBank: false),
        onBuySupport: (s) => _buySupportMuni(s, toBank: false),
      ),
    );
  }

  void _openBagShop() {
    showDialog(
      context: context,
      builder: (_) => AgentShopBagPopup(
        initialMoney: _localMoney!,
        initialFreeBagSlots: _freeBagSlots,
        hasFreeBankSlot: _freeBankSlots > 0,
        onBuy: (s, toBank) => _buyBagItem(s, toBank: toBank),
      ),
    );
  }

  void _openBankShop() {
    showDialog(
      context: context,
      builder: (_) => AgentShopBankPopup(
        initialMoney: _localMoney!,
        initialFreeBankSlots: _freeBankSlots,
        availableCategs: _availableMuniCategs,
        ownedCalibres: _ownedCalibres,
        onBuyWeapon: (w) => _buyWeaponSlot(w, toBank: true),
        onBuyKit: (k) => _buyKitSlot(k, toBank: true),
        onBuyMuni: (m, qty, free) =>
            _buyMuni(m, qty, free, toBank: true),
        onBuyMuniSupport: (s) => _buySupportMuni(s, toBank: true),
        onBuyBagItem: (s) => _buyBagItem(s, toBank: true),
      ),
    );
  }

  // --- Transferts vers le coffre ---

  void _moveWeaponToBank(int slotIndex) {
    final bankIdx = _bankSlots!.indexWhere((b) => b.empty);
    if (bankIdx == -1) return; // pas de place
    final ws = _weaponSlots![slotIndex];
    if (ws.empty) return;
    setState(() {
      _unlinkAllMagazinesFor(ws.id);
      _bankSlots![bankIdx] = BankSlot(
        id: _bankSlots![bankIdx].id,
        empty: false,
        weapon: ws,
      );
      _weaponSlots![slotIndex] = WeaponSlot.empty(ws.id);
      _inventoryDirty = true;
    });
  }

  /// Vide un MuniSlot et envoie son contenu en Réserve.
  /// Remplace l'ancien _moveMuniToBank (le coffre n'accepte plus de muni).
  void _moveMuniToReserve(int slotIndex) {
    final ms = _muniSlots![slotIndex];
    if (ms.isEmpty) return;
    setState(() {
      if (ms.munis.isNotEmpty) {
        // Réserve refuse herb/throwable : on filtre.
        final accepted = ms.munis
            .where((_) =>
                ms.calibre != Calibre.herb && ms.calibre != Calibre.throwable)
            .toList();
        if (accepted.isNotEmpty) {
          _localReserve = _localReserve!.addMunis(accepted);
        }
      } else if (ms.support != null) {
        for (int i = 0; i < ms.supportCount; i++) {
          _localReserve = _localReserve!.addSupport(ms.support!);
        }
      }
      // Magasin : reste lié, juste vidé.
      if (ms.isMagazine) {
        _muniSlots![slotIndex] = MuniSlot.magazine(
          id: ms.id,
          calibre: ms.calibre,
          linkedWeaponSlotId: ms.linkedWeaponSlotId!,
          magazineIndex: ms.magazineIndex!,
        );
      } else {
        _muniSlots![slotIndex] = MuniSlot.empty(ms.id);
      }
      _inventoryDirty = true;
    });
  }

  // ─── Helpers de logique munition (étape 3a) ─────────────────────────────

  /// MuniCateg du MuniObject, ou null s'il n'en a aucune.
  MuniCateg? _muniCategOf(MuniObject m) {
    for (final cat in MuniCategList().allMuniCateg) {
      if (cat.munis.any((mu) => mu.id == m.id)) return cat;
    }
    return null;
  }

  /// Capacité maximale du slot (calculée même pour le mode magasin via l'arme liée).
  int _slotCapacity(MuniSlot slot) {
    if (slot.mode == MuniSlotMode.magazine) {
      final weapon = _linkedWeaponOf(slot);
      if (weapon == null) return 0;
      return slot.magazineIndex == 1
          ? (weapon.secondMagazineSize ?? 0)
          : (weapon.magazineSize ?? 0);
    }
    return slot.fixedCapacity ?? 0;
  }

  Weapon? _linkedWeaponOf(MuniSlot slot) {
    final wsId = slot.linkedWeaponSlotId;
    if (wsId == null) return null;
    for (final ws in _weaponSlots ?? const <WeaponSlot>[]) {
      if (ws.id == wsId && !ws.empty) return ws.weapon;
    }
    return null;
  }

  /// Vrai si la munition donnée peut être ajoutée dans le slot, en tenant
  /// compte du mode, du calibre figé, de la MuniCateg et de la place restante.
  bool _canPushMuniToSlot(MuniObject m, MuniSlot slot) {
    if (slot.mode == MuniSlotMode.support) return false;
    final cap = _slotCapacity(slot);
    if (cap == 0) return false;
    if (slot.used >= cap) return false;
    final cat = _muniCategOf(m);
    if (cat == null) return false;
    if (slot.mode == MuniSlotMode.empty) {
      // Le calibre sera figé à l'ajout : on accepte tout calibre de la cat.
      return cat.included.isNotEmpty;
    }
    // munition / magazine : calibre figé, doit appartenir à la même cat.
    if (!cat.included.contains(slot.calibre)) return false;
    return true;
  }

  /// Liste des slots équipés compatibles avec la munition (hors source).
  List<int> _compatibleSlotsForMuni(MuniObject m, {int? excludeIndex}) {
    final slots = _muniSlots ?? const <MuniSlot>[];
    final result = <int>[];
    for (int i = 0; i < slots.length; i++) {
      if (i == excludeIndex) continue;
      if (_canPushMuniToSlot(m, slots[i])) result.add(i);
    }
    return result;
  }

  /// Couples (weaponSlotIdx, magazineIndex) pour les armes équipées qui
  /// peuvent recevoir un lien magasin de la part du slot donné.
  ///
  /// Conditions :
  ///  - arme avec magazineSize != null
  ///  - slot empty OU calibre du slot == calibre de l'arme
  ///  - le couple (weaponSlotId, magazineIndex) n'est pas déjà lié ailleurs
  List<({int weaponSlotIdx, int magazineIndex, Weapon weapon})>
      _linkableForSlot(MuniSlot slot) {
    final result = <({int weaponSlotIdx, int magazineIndex, Weapon weapon})>[];
    final weaponSlots = _weaponSlots ?? const <WeaponSlot>[];
    for (final ws in weaponSlots) {
      if (ws.empty) continue;
      final w = ws.weapon;
      if (w == null) continue;
      if (w.magazineSize == null) continue;
      // Compat de calibre
      if (slot.mode != MuniSlotMode.empty) {
        if (slot.calibre != w.calibre) continue;
      }
      for (int magIdx = 0; magIdx < 2; magIdx++) {
        if (magIdx == 1 && (w.secondMagazine != true)) continue;
        if (magIdx == 1 && w.secondMagazineSize == null) continue;
        if (_isMagazineAlreadyLinked(ws.id, magIdx)) continue;
        result.add((
          weaponSlotIdx: weaponSlots.indexOf(ws),
          magazineIndex: magIdx,
          weapon: w,
        ));
      }
    }
    return result;
  }

  bool _isMagazineAlreadyLinked(int weaponSlotId, int magazineIndex) {
    for (final s in _muniSlots ?? const <MuniSlot>[]) {
      if (s.mode != MuniSlotMode.magazine) continue;
      if (s.linkedWeaponSlotId == weaponSlotId &&
          s.magazineIndex == magazineIndex) {
        return true;
      }
    }
    return false;
  }

  // ── Actions par munition ──────────────────────────────────────────────────

  /// Tirer (supprime sans remboursement).
  void _fireMuni(int slotIndex, int muniIndex) {
    final ms = _muniSlots![slotIndex];
    setState(() {
      if (ms.mode == MuniSlotMode.support) {
        _muniSlots![slotIndex] = _decrementSupport(ms);
      } else {
        _muniSlots![slotIndex] = _removedMuniAt(ms, muniIndex);
      }
      _inventoryDirty = true;
    });
  }

  /// Envoyer 1 munition (ou 1 support) du slot vers la Réserve.
  /// Refusé si calibre herb/throwable pour les munitions.
  void _sendMuniToReserve(int slotIndex, int muniIndex) {
    final ms = _muniSlots![slotIndex];
    setState(() {
      if (ms.mode == MuniSlotMode.support && ms.support != null) {
        _localReserve = _localReserve!.addSupport(ms.support!);
        _muniSlots![slotIndex] = _decrementSupport(ms);
      } else {
        if (ms.calibre == Calibre.herb || ms.calibre == Calibre.throwable) {
          return;
        }
        final muni = ms.munis[muniIndex];
        _localReserve = _localReserve!.addMuni(muni);
        _muniSlots![slotIndex] = _removedMuniAt(ms, muniIndex);
      }
      _inventoryDirty = true;
    });
  }

  /// Remboursement d'une seule munition (ou d'un support).
  void _sellOneMuni(int slotIndex, int muniIndex) {
    final ms = _muniSlots![slotIndex];
    setState(() {
      if (ms.mode == MuniSlotMode.support && ms.support != null) {
        _localMoney = _localMoney! + ms.support!.price;
        _muniSlots![slotIndex] = _decrementSupport(ms);
      } else {
        final muni = ms.munis[muniIndex];
        _localMoney = _localMoney! + muni.price;
        _muniSlots![slotIndex] = _removedMuniAt(ms, muniIndex);
      }
      _inventoryDirty = true;
    });
  }

  /// Décrémente un slot support de 1. À 0 → repasse en mode empty.
  MuniSlot _decrementSupport(MuniSlot slot) {
    if (slot.mode != MuniSlotMode.support) return slot;
    final remaining = slot.supportCount - 1;
    if (remaining <= 0) return MuniSlot.empty(slot.id);
    return MuniSlot.supportSlot(
      id: slot.id,
      support: slot.support!,
      count: remaining,
    );
  }

  /// Déplacer 1 munition vers un autre MuniSlot équipé compatible.
  void _moveMuniBetweenSlots(int srcIdx, int muniIdx, int targetIdx) {
    final src = _muniSlots![srcIdx];
    if (muniIdx >= src.munis.length) return;
    final muni = src.munis[muniIdx];
    final target = _muniSlots![targetIdx];
    if (!_canPushMuniToSlot(muni, target)) return;
    setState(() {
      _muniSlots![srcIdx] = _removedMuniAt(src, muniIdx);
      _muniSlots![targetIdx] = _addedMuniTo(target, muni);
      _inventoryDirty = true;
    });
  }

  /// Lier ce slot à une arme équipée.
  void _linkMagazine(int slotIdx, int weaponSlotId, int magazineIndex,
      Calibre weaponCalibre) {
    final src = _muniSlots![slotIdx];
    setState(() {
      _muniSlots![slotIdx] = MuniSlot.magazine(
        id: src.id,
        calibre: weaponCalibre,
        linkedWeaponSlotId: weaponSlotId,
        magazineIndex: magazineIndex,
        munis: src.munis,
      );
      _inventoryDirty = true;
    });
  }

  /// Délier le magasin. Munis non vides → réserve.
  void _unlinkMagazine(int slotIdx) {
    final src = _muniSlots![slotIdx];
    if (src.mode != MuniSlotMode.magazine) return;
    setState(() {
      if (src.munis.isNotEmpty &&
          src.calibre != Calibre.herb &&
          src.calibre != Calibre.throwable) {
        _localReserve = _localReserve!.addMunis(src.munis);
      }
      _muniSlots![slotIdx] = MuniSlot.empty(src.id);
      _inventoryDirty = true;
    });
  }

  /// Délie tous les MuniSlot magasins liés à une arme donnée.
  /// Appelée automatiquement quand l'arme quitte les WeaponSlot équipés
  /// (envoi au coffre, vente). Munis présentes dans les magasins → réserve.
  /// Doit être appelée **dans** un setState parent.
  void _unlinkAllMagazinesFor(int weaponSlotId) {
    for (int i = 0; i < (_muniSlots ?? const <MuniSlot>[]).length; i++) {
      final s = _muniSlots![i];
      if (s.mode != MuniSlotMode.magazine) continue;
      if (s.linkedWeaponSlotId != weaponSlotId) continue;
      if (s.munis.isNotEmpty &&
          s.calibre != Calibre.herb &&
          s.calibre != Calibre.throwable) {
        _localReserve = _localReserve!.addMunis(s.munis);
      }
      _muniSlots![i] = MuniSlot.empty(s.id);
    }
  }

  /// Retire une muni à un index donné. Si le slot devient vide ET n'est pas
  /// un magasin, il repasse en mode empty (calibre = empty).
  MuniSlot _removedMuniAt(MuniSlot slot, int idx) {
    final next = List<MuniObject>.from(slot.munis)..removeAt(idx);
    if (next.isEmpty) {
      if (slot.mode == MuniSlotMode.magazine) {
        return MuniSlot.magazine(
          id: slot.id,
          calibre: slot.calibre,
          linkedWeaponSlotId: slot.linkedWeaponSlotId!,
          magazineIndex: slot.magazineIndex!,
        );
      }
      return MuniSlot.empty(slot.id);
    }
    if (slot.mode == MuniSlotMode.magazine) {
      return MuniSlot.magazine(
        id: slot.id,
        calibre: slot.calibre,
        linkedWeaponSlotId: slot.linkedWeaponSlotId!,
        magazineIndex: slot.magazineIndex!,
        munis: next,
      );
    }
    return MuniSlot.munition(id: slot.id, calibre: slot.calibre, munis: next);
  }

  // ── Actions sur la Réserve ────────────────────────────────────────────────

  /// Slots compatibles avec un SupportObject pour un transfert depuis la
  /// réserve : slot vide, ou slot support du même type non plein (count < 6).
  List<int> _compatibleSlotsForSupport(SupportObject support) {
    final result = <int>[];
    for (int i = 0; i < (_muniSlots ?? const <MuniSlot>[]).length; i++) {
      final s = _muniSlots![i];
      if (s.mode == MuniSlotMode.empty) {
        result.add(i);
      } else if (s.mode == MuniSlotMode.support &&
          s.support?.id == support.id &&
          s.supportCount < 6) {
        result.add(i);
      }
    }
    return result;
  }

  void _moveReserveMuniToSlot(int reserveIdx, int targetSlotIdx) {
    final muni = _localReserve!.munis[reserveIdx];
    final target = _muniSlots![targetSlotIdx];
    if (!_canPushMuniToSlot(muni, target)) return;
    setState(() {
      _localReserve = _localReserve!.copyWith(
        munis: List<MuniObject>.from(_localReserve!.munis)..removeAt(reserveIdx),
      );
      _muniSlots![targetSlotIdx] = _addedMuniTo(target, muni);
      _inventoryDirty = true;
    });
  }

  void _sellReserveMuni(int reserveIdx) {
    final muni = _localReserve!.munis[reserveIdx];
    setState(() {
      _localMoney = _localMoney! + muni.price;
      _localReserve = _localReserve!.copyWith(
        munis: List<MuniObject>.from(_localReserve!.munis)..removeAt(reserveIdx),
      );
      _inventoryDirty = true;
    });
  }

  void _moveReserveSupportToSlot(int entryIdx, int targetSlotIdx) {
    final entry = _localReserve!.supports[entryIdx];
    final target = _muniSlots![targetSlotIdx];
    setState(() {
      _localReserve = _localReserve!.removeSupportById(entry.support.id);
      if (target.mode == MuniSlotMode.empty) {
        _muniSlots![targetSlotIdx] = MuniSlot.supportSlot(
          id: target.id, support: entry.support, count: 1,
        );
      } else if (target.mode == MuniSlotMode.support &&
          target.support?.id == entry.support.id) {
        _muniSlots![targetSlotIdx] = MuniSlot.supportSlot(
          id: target.id,
          support: target.support!,
          count: target.supportCount + 1,
        );
      }
      _inventoryDirty = true;
    });
  }

  void _sellReserveSupport(int entryIdx) {
    final entry = _localReserve!.supports[entryIdx];
    setState(() {
      _localMoney = _localMoney! + entry.support.price;
      _localReserve = _localReserve!.removeSupportById(entry.support.id);
      _inventoryDirty = true;
    });
  }

  Future<void> _showReserveMuniMoveDialog(int reserveIdx) async {
    final muni = _localReserve!.munis[reserveIdx];
    final compatibles = _compatibleSlotsForMuni(muni);
    if (compatibles.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Vers un MuniSlot — ${muni.name}'),
        content: SizedBox(
          width: 320,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final i in compatibles)
                ListTile(
                  dense: true,
                  title: Text('Emplacement ${_muniSlots![i].id}'),
                  subtitle: Text(_describeSlot(_muniSlots![i]),
                      style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: () {
                    Navigator.pop(ctx);
                    _moveReserveMuniToSlot(reserveIdx, i);
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
        ],
      ),
    );
  }

  Future<void> _showReserveSupportMoveDialog(int entryIdx) async {
    final entry = _localReserve!.supports[entryIdx];
    final compatibles = _compatibleSlotsForSupport(entry.support);
    if (compatibles.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Vers un MuniSlot — ${entry.support.name}'),
        content: SizedBox(
          width: 320,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final i in compatibles)
                ListTile(
                  dense: true,
                  title: Text('Emplacement ${_muniSlots![i].id}'),
                  subtitle: Text(_describeSlot(_muniSlots![i]),
                      style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: () {
                    Navigator.pop(ctx);
                    _moveReserveSupportToSlot(entryIdx, i);
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
        ],
      ),
    );
  }

  // ── Popups d'action ───────────────────────────────────────────────────────

  /// Ouvre la popup "Lier ce slot à une arme".
  Future<void> _showLinkDialog(int slotIdx) async {
    final slot = _muniSlots![slotIdx];
    final candidates = _linkableForSlot(slot);
    if (candidates.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lier à une arme'),
        content: SizedBox(
          width: 320,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final c in candidates)
                ListTile(
                  dense: true,
                  title: Text(c.weapon.name),
                  subtitle: Text(
                    'Calibre : ${c.weapon.calibre?.name ?? "-"}'
                    '${c.weapon.secondMagazine == true ? "  •  Magasin ${c.magazineIndex + 1}/2" : ""}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: const Icon(Icons.link),
                  onTap: () {
                    Navigator.pop(ctx);
                    _linkMagazine(
                      slotIdx,
                      _weaponSlots![c.weaponSlotIdx].id,
                      c.magazineIndex,
                      c.weapon.calibre ?? Calibre.empty,
                    );
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
        ],
      ),
    );
  }

  /// Ouvre la popup "Déplacer cette munition vers un autre slot".
  Future<void> _showChangeMuniSlotDialog(int srcIdx, int muniIdx) async {
    final src = _muniSlots![srcIdx];
    if (muniIdx >= src.munis.length) return;
    final muni = src.munis[muniIdx];
    final compatibles = _compatibleSlotsForMuni(muni, excludeIndex: srcIdx);
    if (compatibles.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Déplacer ${muni.name}'),
        content: SizedBox(
          width: 320,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final i in compatibles)
                ListTile(
                  dense: true,
                  title: Text('Emplacement ${_muniSlots![i].id}'),
                  subtitle: Text(_describeSlot(_muniSlots![i]),
                      style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.swap_horiz),
                  onTap: () {
                    Navigator.pop(ctx);
                    _moveMuniBetweenSlots(srcIdx, muniIdx, i);
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
        ],
      ),
    );
  }

  String _describeSlot(MuniSlot s) {
    final cap = _slotCapacity(s);
    final mode = s.mode == MuniSlotMode.empty
        ? 'vide'
        : s.mode == MuniSlotMode.magazine
            ? 'magasin ${_linkedWeaponOf(s)?.name ?? "?"}'
            : s.mode == MuniSlotMode.support
                ? 'support'
                : 'munition';
    return '$mode · ${s.calibre.name} · ${s.used}/$cap';
  }

  /// Ajoute une muni dans un slot, en figeant le calibre si le slot était empty.
  MuniSlot _addedMuniTo(MuniSlot slot, MuniObject m) {
    final cat = _muniCategOf(m);
    final next = [...slot.munis, m];
    final calibre = slot.mode == MuniSlotMode.empty
        ? (cat?.included.first ?? Calibre.empty)
        : slot.calibre;
    if (slot.mode == MuniSlotMode.magazine) {
      return MuniSlot.magazine(
        id: slot.id,
        calibre: slot.calibre,
        linkedWeaponSlotId: slot.linkedWeaponSlotId!,
        magazineIndex: slot.magazineIndex!,
        munis: next,
      );
    }
    return MuniSlot.munition(id: slot.id, calibre: calibre, munis: next);
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

  // --- Changement de photo de profil (owner) ---

  Future<void> _changeProfilePicture(Agent agent) async {
    if (_uploadingPicture) return;

    final messenger = ScaffoldMessenger.of(context);

    // Rappel de taille avant ouverture du picker
    messenger.showSnackBar(
      const SnackBar(
        content: Text(_profilPictureSizeReminder),
        duration: Duration(seconds: 2),
      ),
    );

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    final file = File(picked.path);
    final size = await file.length();
    if (size > _maxProfilPictureBytes) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Image trop lourde (10 Mo maximum).'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _uploadingPicture = true);
    try {
      final url = await _uploadProfilPictureToCloudinary(file);
      if (url == null || url.isEmpty) throw Exception('URL invalide.');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté.');
      final uid = widget.ownerUid ?? user.uid;
      final agentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('agents')
          .doc(widget.agentDocId);

      // Push l'ancienne photo dans l'historique si non vide
      final oldPath = agent.profilPicturePath;
      final newHistory = List<String>.from(agent.profilPictureHistory);
      if (oldPath != null && oldPath.trim().isNotEmpty) {
        newHistory.add(oldPath);
      }

      await agentRef.update({
        'profilPicturePath': url,
        'profilPictureHistory': newHistory,
      });

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Photo de profil mise à jour.')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingPicture = false);
    }
  }

  // --- Sauvegarde Firestore à la sortie ---

  Future<void> _saveInventoryIfDirty() async {
    if (!_inventoryDirty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = widget.ownerUid ?? user.uid;
    final agentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('agents')
        .doc(widget.agentDocId);

    await agentRef.update({
      'weaponSlots': _weaponSlots!.map((s) => s.toMap()).toList(),
      'muniSlots': _muniSlots!.map((s) => s.toMap()).toList(),
      'bagSlots': _bagSlots!.map((s) => s.toMap()).toList(),
      'bankSlots': _bankSlots!.map((s) => s.toMap()).toList(),
      if (_localReserve != null) 'reserve': _localReserve!.toMap(),
      if (_localMoney != null) 'money': _localMoney,
    });

    StatsRepository.scheduleRebuild();
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

    final uid = widget.ownerUid ?? user.uid;
    final agentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('agents')
        .doc(widget.agentDocId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: agentRef.snapshots(),
      builder: (context, snapshot) {
        //print("debug code Vida Loca");
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
            leading: const SafeBackButton(),
            title: Text(
              agentName != null ? "Fiche de $agentName" : "Fiche de l'agent",
              style: GoogleFonts.cinzelDecorative(),
            ),
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
                                  if (agent.secondClass != null) ...[
                                    const SizedBox(height: 8),
                                    Text("Classe secondaire : ${agent.secondClass!.name}"),
                                    ...List.generate(
                                      agent.secondClass!.classBonus.length,
                                      (i) {
                                        final val = i < agent.secondClassBonuses.length ? agent.secondClassBonuses[i] : 0;
                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text("${agent.secondClass!.classBonus[i]} : $val / 6"),
                                            _diceButton(context, maxValue: 6, threshold: val),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade400,
                                        width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: hasPic
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.network(pic,
                                              fit: BoxFit.contain),
                                        )
                                      : const Center(
                                          child: Icon(Icons.person,
                                              size: 42,
                                              color: Colors.grey),
                                        ),
                                ),
                                if (FirebaseAuth.instance.currentUser?.uid ==
                                    uid)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: _uploadingPicture
                                        ? const SizedBox(
                                            height: 32,
                                            width: 32,
                                            child: Padding(
                                              padding: EdgeInsets.all(6),
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          )
                                        : IconButton(
                                            icon: const Icon(Icons.draw,
                                                size: 20),
                                            tooltip: hasPic
                                                ? 'Changer la photo de profil (10 Mo max)'
                                                : 'Ajouter une photo de profil (10 Mo max)',
                                            visualDensity:
                                                VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minHeight: 32,
                                              minWidth: 32,
                                            ),
                                            onPressed: () =>
                                                _changeProfilePicture(agent),
                                          ),
                                  ),
                              ],
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
                    money: _localMoney!,
                    onMoveWeaponToBank: _moveWeaponToBank,
                    onMoveMuniToBank: _moveMuniToReserve,
                    onMoveBagToBank: _moveBagToBank,
                    onMoveBankToOrigin: _moveBankToOrigin,
                    onSellWeapon: _sellWeaponSlot,
                    onSellMuni: _sellMuniSlot,
                    onSellBag: _sellBagSlot,
                    onSellBank: _sellBankSlot,
                    onOpenWeaponShop: _openWeaponShop,
                    onOpenMuniShop: _openMuniShop,
                    onOpenBagShop: _openBagShop,
                    onOpenBankShop: _openBankShop,
                    onFireMuni: _fireMuni,
                    onSendMuniToReserve: _sendMuniToReserve,
                    onSellOneMuni: _sellOneMuni,
                    onChangeMuniSlot: (slotIdx, muniIdx) =>
                        _showChangeMuniSlotDialog(slotIdx, muniIdx),
                    onLinkMagazine: (slotIdx) => _showLinkDialog(slotIdx),
                    onUnlinkMagazine: _unlinkMagazine,
                    lookupLinkedWeapon: (wsId) {
                      for (final ws in _weaponSlots!) {
                        if (ws.id == wsId && !ws.empty) return ws.weapon;
                      }
                      return null;
                    },
                    muniSlotCapacity: (slotIdx) =>
                        _slotCapacity(_muniSlots![slotIdx]),
                    canLinkSlot: (slotIdx) =>
                        _linkableForSlot(_muniSlots![slotIdx]).isNotEmpty,
                    canChangeMuniSlot: (slotIdx, muniIdx) {
                      final s = _muniSlots![slotIdx];
                      if (muniIdx >= s.munis.length) return false;
                      return _compatibleSlotsForMuni(s.munis[muniIdx],
                              excludeIndex: slotIdx)
                          .isNotEmpty;
                    },
                    reserve: _localReserve!,
                    onMoveReserveMuni: _showReserveMuniMoveDialog,
                    onSellReserveMuni: _sellReserveMuni,
                    onMoveReserveSupport: _showReserveSupportMoveDialog,
                    onSellReserveSupport: _sellReserveSupport,
                    muniCategOf: _muniCategOf,
                  ),
                  // -- Missions --
                  _MissionsSection(
                    agent: agent,
                    agentDocId: widget.agentDocId,
                    ownerUid: uid,
                  ),
                  // -- Lore --
                  _LoreSection(
                    agent: agent,
                    ownerUid: uid,
                    agentDocId: widget.agentDocId,
                  ),
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
  final int money;
  final void Function(int) onMoveWeaponToBank;
  final void Function(int) onMoveMuniToBank;
  final void Function(int) onMoveBagToBank;
  final void Function(int) onMoveBankToOrigin;
  final void Function(int) onSellWeapon;
  final void Function(int) onSellMuni;
  final void Function(int) onSellBag;
  final void Function(int) onSellBank;
  final VoidCallback onOpenWeaponShop;
  final VoidCallback onOpenMuniShop;
  final VoidCallback onOpenBagShop;
  final VoidCallback onOpenBankShop;
  // Nouveaux callbacks muni (étape 3)
  final void Function(int slotIdx, int muniIdx) onFireMuni;
  final void Function(int slotIdx, int muniIdx) onSendMuniToReserve;
  final void Function(int slotIdx, int muniIdx) onSellOneMuni;
  final void Function(int slotIdx, int muniIdx) onChangeMuniSlot;
  final void Function(int slotIdx) onLinkMagazine;
  final void Function(int slotIdx) onUnlinkMagazine;
  final Weapon? Function(int weaponSlotId) lookupLinkedWeapon;
  final int Function(int slotIdx) muniSlotCapacity;
  final bool Function(int slotIdx) canLinkSlot;
  final bool Function(int slotIdx, int muniIdx) canChangeMuniSlot;
  // Réserve (étape 4)
  final Reserve reserve;
  final void Function(int reserveIdx) onMoveReserveMuni;
  final void Function(int reserveIdx) onSellReserveMuni;
  final void Function(int entryIdx) onMoveReserveSupport;
  final void Function(int entryIdx) onSellReserveSupport;
  final MuniCateg? Function(MuniObject) muniCategOf;

  const _InventorySection({
    required this.agent,
    required this.weaponSlots,
    required this.muniSlots,
    required this.bagSlots,
    required this.bankSlots,
    required this.money,
    required this.onMoveWeaponToBank,
    required this.onMoveMuniToBank,
    required this.onMoveBagToBank,
    required this.onMoveBankToOrigin,
    required this.onSellWeapon,
    required this.onSellMuni,
    required this.onSellBag,
    required this.onSellBank,
    required this.onOpenWeaponShop,
    required this.onOpenMuniShop,
    required this.onOpenBagShop,
    required this.onOpenBankShop,
    required this.onFireMuni,
    required this.onSendMuniToReserve,
    required this.onSellOneMuni,
    required this.onChangeMuniSlot,
    required this.onLinkMagazine,
    required this.onUnlinkMagazine,
    required this.lookupLinkedWeapon,
    required this.muniSlotCapacity,
    required this.canLinkSlot,
    required this.canChangeMuniSlot,
    required this.reserve,
    required this.onMoveReserveMuni,
    required this.onSellReserveMuni,
    required this.onMoveReserveSupport,
    required this.onSellReserveSupport,
    required this.muniCategOf,
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
    _tab = TabController(length: 5, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  ({String label, VoidCallback action})? _shopButtonForCurrentTab() {
    switch (_tab.index) {
      case 0:
        return (label: "Acheter une arme", action: widget.onOpenWeaponShop);
      case 1:
        return (label: "Acheter des munitions", action: widget.onOpenMuniShop);
      case 2:
        return (label: "Acheter un objet", action: widget.onOpenBagShop);
      case 3:
        return (label: "Boutique (→ coffre)", action: widget.onOpenBankShop);
      case 4:
      default:
        // Onglet Réserve : pas de bouton boutique direct.
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final shopButton = _shopButtonForCurrentTab();
    return Column(
      children: [
        // --- Argent (visible dans tous les sous-onglets) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 6),
              Text(
                "${widget.money} £",
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
          isScrollable: true,
          tabs: const [
            Tab(text: "Armes"),
            Tab(text: "Munitions"),
            Tab(text: "Sac"),
            Tab(text: "Coffre"),
            Tab(text: "Réserve"),
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
                            onSell: () => widget.onSellWeapon(i),
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
                            slotIndex: i,
                            slot: widget.muniSlots[i],
                            capacity: widget.muniSlotCapacity(i),
                            linkedWeapon:
                                widget.muniSlots[i].linkedWeaponSlotId == null
                                    ? null
                                    : widget.lookupLinkedWeapon(
                                        widget.muniSlots[i].linkedWeaponSlotId!,
                                      ),
                            canLink: widget.canLinkSlot(i),
                            canChangeMuniSlot: (muniIdx) =>
                                widget.canChangeMuniSlot(i, muniIdx),
                            onClearToReserve: () => widget.onMoveMuniToBank(i),
                            onLink: () => widget.onLinkMagazine(i),
                            onUnlink: () => widget.onUnlinkMagazine(i),
                            onFireMuni: (muniIdx) =>
                                widget.onFireMuni(i, muniIdx),
                            onSendMuniToReserve: (muniIdx) =>
                                widget.onSendMuniToReserve(i, muniIdx),
                            onSellMuni: (muniIdx) =>
                                widget.onSellOneMuni(i, muniIdx),
                            onChangeMuniSlot: (muniIdx) =>
                                widget.onChangeMuniSlot(i, muniIdx),
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
                            onSell: () => widget.onSellBag(i),
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
                            onSell: () => widget.onSellBank(i),
                          ),
                    ),
              // Réserve
              _ReserveSection(
                reserve: widget.reserve,
                muniCategOf: widget.muniCategOf,
                onMoveMuni: widget.onMoveReserveMuni,
                onSellMuni: widget.onSellReserveMuni,
                onMoveSupport: widget.onMoveReserveSupport,
                onSellSupport: widget.onSellReserveSupport,
              ),
            ],
          ),
        ),

        // --- Bouton Boutique (s'adapte à l'onglet, masqué sur Réserve) ---
        if (shopButton != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: shopButton.action,
                  icon: const Icon(Icons.storefront_outlined),
                  label: Text(shopButton.label),
                ),
              ),
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
  final VoidCallback onSell;
  const _WeaponSlotCard({
    required this.slot,
    required this.physique,
    required this.onMoveToBank,
    required this.onSell,
  });

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sell_outlined, size: 20),
                        tooltip: "Revendre (remboursé)",
                        color: Colors.red,
                        onPressed: onSell,
                      ),
                      IconButton(
                        icon: const Icon(Icons.archive_outlined, size: 20),
                        tooltip: "Envoyer au coffre",
                        onPressed: onMoveToBank,
                      ),
                    ],
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
  final int slotIndex;
  final MuniSlot slot;
  final int capacity;
  final Weapon? linkedWeapon;
  final bool canLink;
  final bool Function(int muniIdx) canChangeMuniSlot;
  final VoidCallback onClearToReserve;
  final VoidCallback onLink;
  final VoidCallback onUnlink;
  final void Function(int muniIdx) onFireMuni;
  final void Function(int muniIdx) onSendMuniToReserve;
  final void Function(int muniIdx) onSellMuni;
  final void Function(int muniIdx) onChangeMuniSlot;

  const _MuniSlotCard({
    required this.slotIndex,
    required this.slot,
    required this.capacity,
    required this.linkedWeapon,
    required this.canLink,
    required this.canChangeMuniSlot,
    required this.onClearToReserve,
    required this.onLink,
    required this.onUnlink,
    required this.onFireMuni,
    required this.onSendMuniToReserve,
    required this.onSellMuni,
    required this.onChangeMuniSlot,
  });

  String _modeLabel() {
    switch (slot.mode) {
      case MuniSlotMode.empty:
        return 'Vide';
      case MuniSlotMode.munition:
        return 'Munitions';
      case MuniSlotMode.support:
        return 'Support';
      case MuniSlotMode.magazine:
        return 'Magasin';
    }
  }

  bool get _reserveAccepts =>
      slot.calibre != Calibre.herb && slot.calibre != Calibre.throwable;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 8),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final calibreLabel =
        slot.calibre == Calibre.empty ? '—' : slot.calibre.name;
    final capLabel = capacity == 0 ? '0' : '${slot.used}/$capacity';
    final subtitle = slot.mode == MuniSlotMode.magazine && linkedWeapon != null
        ? '${_modeLabel()} · $calibreLabel · $capLabel · ${linkedWeapon!.name}'
              '${slot.magazineIndex == 1 ? ' (mag. 2)' : ''}'
        : '${_modeLabel()} · $calibreLabel · $capLabel';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Emplacement ${slot.id}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        // Bouton Lier / Délier selon le mode
        if (slot.mode == MuniSlotMode.magazine)
          IconButton(
            icon: const Icon(Icons.link_off, size: 20),
            tooltip: 'Délier le magasin',
            onPressed: onUnlink,
          )
        else if (canLink)
          IconButton(
            icon: const Icon(Icons.link, size: 20),
            tooltip: 'Lier à une arme',
            onPressed: onLink,
          ),
        // Vider le slot vers la réserve (raccourci)
        if (!slot.isEmpty && _reserveAccepts)
          IconButton(
            icon: const Icon(Icons.archive_outlined, size: 20),
            tooltip: 'Vider vers la Réserve',
            onPressed: onClearToReserve,
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (slot.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Aucune munition.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      );
    }
    if (slot.mode == MuniSlotMode.support && slot.support != null) {
      return _SupportRow(
        support: slot.support!,
        count: slot.supportCount,
        onFire: () => onFireMuni(0),
        onToReserve: _reserveAccepts ? () => onSendMuniToReserve(0) : null,
        onSell: () => onSellMuni(0),
      );
    }
    // mode munition / magazine : 1 ligne par muni
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < slot.munis.length; i++)
          _MuniRow(
            muni: slot.munis[i],
            onFire: () => onFireMuni(i),
            onToReserve:
                _reserveAccepts ? () => onSendMuniToReserve(i) : null,
            onSell: () => onSellMuni(i),
            onChangeSlot:
                canChangeMuniSlot(i) ? () => onChangeMuniSlot(i) : null,
          ),
      ],
    );
  }
}

class _MuniRow extends StatelessWidget {
  final MuniObject muni;
  final VoidCallback onFire;
  final VoidCallback? onToReserve;
  final VoidCallback onSell;
  final VoidCallback? onChangeSlot;

  const _MuniRow({
    required this.muni,
    required this.onFire,
    required this.onToReserve,
    required this.onSell,
    required this.onChangeSlot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(muni.name,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              if (muni.effect != Effect.none)
                Text('Effet : ${muni.effect.name}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.local_fire_department, size: 18),
          tooltip: 'Tirer',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onFire,
        ),
        IconButton(
          icon: const Icon(Icons.archive_outlined, size: 18),
          tooltip: onToReserve == null
              ? 'Réserve indisponible (calibre)'
              : 'Vers la Réserve',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onToReserve,
        ),
        IconButton(
          icon: const Icon(Icons.swap_horiz, size: 18),
          tooltip: onChangeSlot == null
              ? 'Aucun slot compatible'
              : 'Changer de slot',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onChangeSlot,
        ),
        IconButton(
          icon: const Icon(Icons.sell_outlined, size: 18),
          tooltip: 'Revendre (remboursé)',
          color: Colors.red,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onSell,
        ),
      ]),
    );
  }
}

class _SupportRow extends StatelessWidget {
  final SupportObject support;
  final int count;
  final VoidCallback onFire;
  final VoidCallback? onToReserve;
  final VoidCallback onSell;

  const _SupportRow({
    required this.support,
    required this.count,
    required this.onFire,
    required this.onToReserve,
    required this.onSell,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${support.name}  ×$count',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text(support.description,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.local_fire_department, size: 18),
          tooltip: 'Utiliser 1 (consomme)',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onFire,
        ),
        IconButton(
          icon: const Icon(Icons.archive_outlined, size: 18),
          tooltip: onToReserve == null
              ? 'Réserve indisponible'
              : 'Vers la Réserve (1)',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onToReserve,
        ),
        IconButton(
          icon: const Icon(Icons.sell_outlined, size: 18),
          tooltip: 'Revendre 1 (remboursé)',
          color: Colors.red,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onSell,
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte BagSlot
// ---------------------------------------------------------------------------
class _BagSlotCard extends StatelessWidget {
  final BagSlot slot;
  final VoidCallback onMoveToBank;
  final VoidCallback onSell;
  const _BagSlotCard({
    required this.slot,
    required this.onMoveToBank,
    required this.onSell,
  });

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sell_outlined, size: 20),
                        tooltip: "Revendre (remboursé)",
                        color: Colors.red,
                        onPressed: onSell,
                      ),
                      IconButton(
                        icon: const Icon(Icons.archive_outlined, size: 20),
                        tooltip: "Envoyer au coffre",
                        onPressed: onMoveToBank,
                      ),
                    ],
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
  final VoidCallback onSell;
  const _BankSlotCard({
    required this.slot,
    required this.onMoveToOrigin,
    required this.onSell,
  });

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.sell_outlined, size: 20),
                        tooltip: "Revendre (remboursé)",
                        color: Colors.red,
                        onPressed: onSell,
                      ),
                      IconButton(
                        icon: const Icon(Icons.backpack_outlined, size: 20),
                        tooltip: "Remettre dans l'inventaire",
                        onPressed: onMoveToOrigin,
                      ),
                    ],
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
// Section Réserve — vrac de munitions et de supports munis
// ---------------------------------------------------------------------------
class _ReserveSection extends StatelessWidget {
  final Reserve reserve;
  final MuniCateg? Function(MuniObject) muniCategOf;
  final void Function(int reserveIdx) onMoveMuni;
  final void Function(int reserveIdx) onSellMuni;
  final void Function(int entryIdx) onMoveSupport;
  final void Function(int entryIdx) onSellSupport;

  const _ReserveSection({
    required this.reserve,
    required this.muniCategOf,
    required this.onMoveMuni,
    required this.onSellMuni,
    required this.onMoveSupport,
    required this.onSellSupport,
  });

  @override
  Widget build(BuildContext context) {
    if (reserve.munis.isEmpty && reserve.supports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Réserve vide.',
              style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    // Groupage des munis : MuniCateg → MuniObject.id → liste des indices réserve
    final byCateg = <MuniCateg, Map<int, List<int>>>{};
    final unknownCateg = <int, List<int>>{};
    for (int i = 0; i < reserve.munis.length; i++) {
      final m = reserve.munis[i];
      final cat = muniCategOf(m);
      final dest = cat == null
          ? unknownCateg
          : (byCateg[cat] ??= <int, List<int>>{});
      (dest[m.id] ??= <int>[]).add(i);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final entry in byCateg.entries) ...[
          _categHeader(context, entry.key.description),
          for (final groupEntry in entry.value.entries)
            ..._buildMuniLines(reserve, groupEntry.value),
          const SizedBox(height: 12),
        ],
        if (unknownCateg.isNotEmpty) ...[
          _categHeader(context, 'Sans catégorie'),
          for (final groupEntry in unknownCateg.entries)
            ..._buildMuniLines(reserve, groupEntry.value),
          const SizedBox(height: 12),
        ],
        if (reserve.supports.isNotEmpty) ...[
          _categHeader(context, 'Supports'),
          for (int i = 0; i < reserve.supports.length; i++)
            _supportRow(reserve.supports[i], i),
        ],
      ],
    );
  }

  Widget _categHeader(BuildContext context, String label) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      );

  List<Widget> _buildMuniLines(Reserve reserve, List<int> indices) {
    return [
      for (final i in indices)
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reserve.munis[i].name,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  if (reserve.munis[i].effect != Effect.none)
                    Text('Effet : ${reserve.munis[i].effect.name}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.swap_horiz, size: 18),
              tooltip: 'Vers un MuniSlot',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => onMoveMuni(i),
            ),
            IconButton(
              icon: const Icon(Icons.sell_outlined, size: 18),
              tooltip: 'Revendre (remboursé)',
              color: Colors.red,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => onSellMuni(i),
            ),
          ]),
        ),
    ];
  }

  Widget _supportRow(ReserveSupportEntry e, int idx) => Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${e.support.name}  ×${e.count}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(e.support.description,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, size: 18),
            tooltip: 'Vers un MuniSlot (1)',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => onMoveSupport(idx),
          ),
          IconButton(
            icon: const Icon(Icons.sell_outlined, size: 18),
            tooltip: 'Revendre 1 (remboursé)',
            color: Colors.red,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => onSellSupport(idx),
          ),
        ]),
      );
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
  final String agentDocId;
  final String ownerUid;

  const _MissionsSection({
    required this.agent,
    required this.agentDocId,
    required this.ownerUid,
  });

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
    ('Niveau 10', 11),
    ('Niveau Légendaire 1', 7),
    ('Niveau Légendaire 2', 7),
    ('Niveau Légendaire 3', 7),
    ('Niveau Légendaire 4', 7),
    ('Niveau Légendaire 5', 7),
    ('Niveau Légendaire 6', 7),
    ('Niveau Légendaire 7', 7),
    ('Niveau Légendaire 8', 7),
    ('Niveau Légendaire 9', 7),
    ('Niveau Légendaire 10', 7),
    ('Niveau Légendaire 11', 7),
    ('Niveau Légendaire 12', 7),
    ('Niveau Légendaire 13', 7),
    ('Niveau Légendaire 14', 7),
    ('Niveau Légendaire 15', 7),
    ('Niveau Légendaire 16', 7),
    ('Niveau Légendaire 17', 7),
    ('Niveau Légendaire 18', 7),
    ('Niveau Légendaire 19', 7),
    ('Niveau Légendaire 20', 7),
    ('Niveau Légendaire 21', 7),
    ('Niveau Légendaire 22', 7),
    ('Niveau Légendaire 23', 7),
    ('Niveau Légendaire 24', 7),
    ('Niveau Légendaire 25', 7),
    ('Niveau Légendaire 26', 7),
    ('Niveau Légendaire 27', 7),
    ('Niveau Légendaire 28', 7),
    ('Niveau Légendaire 29', 7),
    ('Niveau Légendaire 30', 7),
    ('Niveau Légendaire 31', 7),
    ('Niveau Légendaire 32', 7),
    ('Niveau Légendaire 33', 7),
  ];

  /// Dialog temporaire pour ajouter une mission depuis les archives.
  // TODO: Supprimer cette feature temporaire quand le vrai système sera en place
  Future<void> _showAddMissionDialog(BuildContext context) async {
    final missionsSnap = await FirebaseFirestore.instance
        .collection('common')
        .doc('archives')
        .collection('missions')
        .get();

    // IDs des missions déjà présentes sur cet agent
    final existingIds = agent.missions.map((m) => m.id).toSet();

    final archiveMissions = missionsSnap.docs
        .map((doc) => Mission.fromMap(doc.data()))
        .where((m) => !existingIds.contains(m.id))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    if (!context.mounted) return;

    if (archiveMissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune nouvelle mission à ajouter.'),
        ),
      );
      return;
    }

    final selected = await showDialog<Mission>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Ajouter une mission'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: archiveMissions.length,
              itemBuilder: (_, i) {
                final m = archiveMissions[i];
                return ListTile(
                  title: Text(m.title),
                  subtitle: Text('ID: ${m.id}'),
                  onTap: () => Navigator.pop(ctx, m),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );

    if (selected == null || !context.mounted) return;

    final record = MissionRecord(
      id: selected.id,
      title: selected.title,
      description: selected.descriptionIntro,
      completedAt: selected.completedAt ?? DateTime.now(),
    );

    final agentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .collection('agents')
        .doc(agentDocId);

    final newMissions = [
      ...agent.missions.map((m) => m.toMap()),
      record.toMap(),
    ];

    await agentRef.update({'missions': newMissions});
    StatsRepository.scheduleRebuild();
  }

  @override
  Widget build(BuildContext context) {
    // Filtrer les MissionRecord avec id -66, puis trier par completedAt croissant
    // (nulls en dernier). L'ordre chronologique détermine dans quelle tranche de
    // niveau chaque mission apparaît (la plus ancienne → niveau le plus bas).
    final missions = agent.missions.where((m) => m.id != -66).toList()
      ..sort((a, b) {
        if (a.completedAt == null && b.completedAt == null) return 0;
        if (a.completedAt == null) return 1;
        if (b.completedAt == null) return -1;
        return a.completedAt!.compareTo(b.completedAt!);
      });

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
            "${slice.length} / $capacity mission${slice.length > 1 ? 's' : ''}",
            style: const TextStyle(fontSize: 12),
          ),
          children: slice
              .map((m) => _MissionRecordTile(
                    mission: m,
                    agent: agent,
                    ownerUid: ownerUid,
                    agentDocId: agentDocId,
                  ))
              .toList(),
        ),
      );
      offset += capacity;
    }

    // TODO: Enlever le level up pour non-propriétaire plus tard
    final levelUps = availableLevelUps(agent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Niveau de l'agent ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                "Niveau : ${agent.level}",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // TODO: Supprimer ce bouton temporaire
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter une mission'),
                onPressed: () => _showAddMissionDialog(context),
              ),
            ],
          ),
        ),
        // --- Boutons de montée de niveau ---
        if (levelUps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: levelUps.map((lvl) {
                return ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_upward),
                  label: Text('Passer au niveau $lvl'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lvl >= 11
                        ? Colors.deepPurple
                        : Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LevelUpPage(
                          agent: agent,
                          agentDocId: agentDocId,
                          ownerUid: ownerUid,
                          targetLevel: lvl,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
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
  final Agent agent;
  final String ownerUid;
  final String agentDocId;

  const _MissionRecordTile({
    required this.mission,
    required this.agent,
    required this.ownerUid,
    required this.agentDocId,
  });

  Future<void> _openMission(BuildContext context) async {
    final snap = await FirebaseFirestore.instance
        .collection('common')
        .doc('archives')
        .collection('missions')
        .where('id', isEqualTo: mission.id)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission introuvable.')),
        );
      }
      return;
    }

    final full = Mission.fromMap(snap.docs.first.data());
    if (context.mounted) {
      Navigator.pushNamed(context, Routes.missionSheet, arguments: full);
    }
  }

  Future<void> _confirmAndRemove(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final preview = computeRollbackPreview(
      ownerUid: ownerUid,
      agentDocId: agentDocId,
      agent: agent,
      removedMissionId: mission.id,
    );

    final lines = <Widget>[
      Text(
        'Retirer la mission "${mission.title}" de la fiche de ${agent.name} ?',
        style: const TextStyle(fontSize: 14),
      ),
      const SizedBox(height: 8),
    ];

    if (preview.rolledBackLevels.isEmpty && preview.orphanedLevels.isEmpty) {
      lines.add(const Text(
        'Aucun changement de niveau.',
        style: TextStyle(fontSize: 13, color: Colors.grey),
      ));
    } else {
      if (preview.rolledBackLevels.isNotEmpty) {
        lines.add(Text(
          'L\'agent passera du niveau ${preview.currentLevel} au niveau '
          '${preview.newLevel}. Les changements opérés au(x) niveau(x) '
          '${preview.rolledBackLevels.join(", ")} seront annulés.',
          style: const TextStyle(fontSize: 13, color: Colors.orange),
        ));
      }
      if (preview.orphanedLevels.isNotEmpty) {
        lines.add(const SizedBox(height: 6));
        lines.add(Text(
          'Niveau(x) ${preview.orphanedLevels.join(", ")} non annulable(s) '
          "(pas d'historique disponible). L'agent restera à ce niveau.",
          style: const TextStyle(fontSize: 13, color: Colors.red),
        ));
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Retirer la mission de l'agent ?"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: lines,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await MissionRepository().removeAgentFromMission(
        ownerUid: ownerUid,
        agentDocId: agentDocId,
        missionId: mission.id,
      );
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Mission retirée de l\'agent.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = mission.completedAt;
    final dateLabel = date != null
        ? "Complétée le ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}"
        : "Non complétée";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openMission(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mission.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    tooltip: "Retirer cette mission de l'agent",
                    onPressed: () => _confirmAndRemove(context),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                ],
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Lore
// ---------------------------------------------------------------------------
class _LoreSection extends StatelessWidget {
  final Agent agent;
  final String ownerUid;
  final String agentDocId;

  const _LoreSection({
    required this.agent,
    required this.ownerUid,
    required this.agentDocId,
  });

  Future<void> _addPaidContact(BuildContext context) async {
    final result = await _showAddContactDialog(
      context,
      agent: agent,
      isFree: false,
    );
    if (result == null) return;

    final newContact = Contact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: result.name,
      description: result.description,
      contactPointsValue: result.cost,
    );

    final agentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .collection('agents')
        .doc(agentDocId);

    await agentRef.update({
      'contacts': [
        ...agent.contacts.map((c) => c.toMap()),
        newContact.toMap(),
      ],
      'pc': agent.pc - result.cost,
    });
    StatsRepository.scheduleRebuild();
  }

  Future<void> _addFreeContact(BuildContext context) async {
    final result = await _showAddContactDialog(
      context,
      agent: agent,
      isFree: true,
    );
    if (result == null) return;

    final newContact = Contact(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: result.name,
      description: result.description,
      contactPointsValue: 0,
    );

    final agentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .collection('agents')
        .doc(agentDocId);

    await agentRef.update({
      'contacts': [
        ...agent.contacts.map((c) => c.toMap()),
        newContact.toMap(),
      ],
      'validated': false,
      'pendingFreeContact': true,
    });
    StatsRepository.scheduleRebuild();

    // Notifier les admins du contact gratuit à valider
    await NotificationRepository().notifyAdmins(
      title: 'Contact gratuit à valider',
      body: 'Contact gratuit ${result.name} de l\'agent ${agent.name} à valider',
      data: {'type': 'agent_validation', 'agentName': agent.name},
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact gratuit ajouté. La fiche est en attente de validation.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = FirebaseAuth.instance.currentUser?.uid == ownerUid;

    final contacts = agent.contacts.where((c) => c.id != '-66').toList();

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

        // --- Boutons d'ajout de contact ---
        if (isOwner)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (agent.pc > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addPaidContact(context),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Ajouter un contact'),
                    ),
                  ),
                if (agent.pc > 0 && agent.validated)
                  const SizedBox(width: 8),
                if (agent.validated)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _addFreeContact(context),
                      icon: const Icon(Icons.card_giftcard, size: 18),
                      label: const Text('Contact gratuit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple,
                        side: const BorderSide(color: Colors.purple),
                      ),
                    ),
                  ),
              ],
            ),
          ),

        if (contacts.isEmpty)
          const Text("Aucun contact.", style: TextStyle(fontSize: 13, color: Colors.grey))
        else
          ...contacts.map((c) => _ContactCard(contact: c)),

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

        // --- Galerie des anciennes photos de profil ---
        if (agent.profilPictureHistory.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            "Anciennes photos de profil",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _ProfilePictureGallery(
            urls: agent.profilPictureHistory,
            isOwner: isOwner,
            onRestore: (url) => _restorePicture(context, url),
            onDelete: (url) => _deletePicture(context, url),
          ),
        ],
      ],
    );
  }

  Future<void> _restorePicture(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final agentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .collection('agents')
        .doc(agentDocId);

    final snap = await agentRef.get();
    final data = snap.data();
    if (data == null) return;
    final current = data['profilPicturePath'] as String?;
    final history = (data['profilPictureHistory'] as List?)
            ?.cast<String>()
            .toList() ??
        <String>[];

    history.remove(url);
    if (current != null && current.trim().isNotEmpty) {
      history.add(current);
    }

    await agentRef.update({
      'profilPicturePath': url,
      'profilPictureHistory': history,
    });

    if (context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Photo restaurée comme photo actuelle.')),
      );
    }
  }

  Future<void> _deletePicture(BuildContext context, String url) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette photo ?'),
        content: const Text(
          "L'image sera retirée définitivement de la galerie. Cette action "
          'est irréversible.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final agentRef = FirebaseFirestore.instance
        .collection('users')
        .doc(ownerUid)
        .collection('agents')
        .doc(agentDocId);

    await agentRef.update({
      'profilPictureHistory': FieldValue.arrayRemove([url]),
    });

    if (context.mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Photo supprimée.')),
      );
    }
  }
}

// ─── Galerie des anciennes photos ─────────────────────────────────────────
class _ProfilePictureGallery extends StatelessWidget {
  final List<String> urls;
  final bool isOwner;
  final Future<void> Function(String url) onRestore;
  final Future<void> Function(String url) onDelete;

  const _ProfilePictureGallery({
    required this.urls,
    required this.isOwner,
    required this.onRestore,
    required this.onDelete,
  });

  void _openViewer(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text("Image indisponible."),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isOwner)
                    TextButton.icon(
                      icon: const Icon(Icons.restore, size: 18),
                      label: const Text('Restaurer'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await onRestore(url);
                      },
                    ),
                  if (isOwner) const SizedBox(width: 4),
                  if (isOwner)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Supprimer'),
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await onDelete(url);
                      },
                    ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: urls
          .map(
            (url) => GestureDetector(
              onTap: () => _openViewer(context, url),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image,
                          size: 24, color: Colors.grey),
                    ),
                    loadingBuilder: (_, child, p) => p == null
                        ? child
                        : const Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog d'ajout de contact
// ---------------------------------------------------------------------------
class _ContactDialogResult {
  final String name;
  final String description;
  final int cost;

  const _ContactDialogResult({
    required this.name,
    required this.description,
    required this.cost,
  });
}

Future<_ContactDialogResult?> _showAddContactDialog(
  BuildContext context, {
  required Agent agent,
  required bool isFree,
}) {
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  int cost = isFree ? 0 : 1;
  final isVampire = agent.race.name.toLowerCase() == 'vampire';
  final maxCost = isVampire ? 5 : 4;

  return showDialog<_ContactDialogResult>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final availableCosts = List.generate(maxCost, (i) => i + 1)
              .where((v) => v <= agent.pc)
              .toList();

          return AlertDialog(
            title: Text(isFree ? 'Contact gratuit' : 'Ajouter un contact'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFree)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Ce contact ne coûte pas de PC, mais la fiche '
                        'sera remise en attente de validation.',
                        style: TextStyle(fontSize: 13, color: Colors.orange),
                      ),
                    ),
                  if (!isFree)
                    DropdownButtonFormField<int>(
                      initialValue: cost,
                      items: availableCosts
                          .map((v) => DropdownMenuItem(
                                value: v,
                                child: Text('$v PC'),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => cost = v);
                      },
                      decoration: const InputDecoration(labelText: 'Coût'),
                    ),
                  if (!isFree) const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
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
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(
                    ctx,
                    _ContactDialogResult(
                      name: name,
                      description: descCtrl.text.trim(),
                      cost: cost,
                    ),
                  );
                },
                child: const Text('Ajouter'),
              ),
            ],
          );
        },
      );
    },
  );
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
    if (skill.pendingCustom) return _buildPendingCustomCard();

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

  // ── Carte alternative pour une compétence custom en attente de MJ ──────
  Widget _buildPendingCustomCard() {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.deepOrange.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.deepOrange.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "À détailler par le MJ",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'En attente de validation : la compétence sera détaillée et '
              'utilisable une fois la fiche revalidée par le MJ.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
            ),
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
