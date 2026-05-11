import 'package:hellsing_undead_or_applive/domain/models.dart';

class BagSlot {
  final int id;
  final bool empty;
  final SupportObject? support;

  const BagSlot({
    required this.id,
    required this.empty,
    this.support,
  });

  // --------------------
  // copyWith
  // --------------------
  BagSlot copyWith({
    int? id,
    bool? empty,
    SupportObject? support,
  }) {
    return BagSlot(
      id: id ?? this.id,
      empty: empty ?? this.empty,
      support: support ?? this.support,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "empty": empty,
      "support": support?.toMap(),
    };
  }

  factory BagSlot.fromMap(Map<String, dynamic> map) {
    return BagSlot(
      id: map["id"],
      empty: map["empty"],
      support: map["support"] != null ? SupportObject.fromJson(map["support"]) : null,
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "empty": empty,
      "support": support?.toJson(),
    };
  }

  factory BagSlot.fromJson(Map<String, dynamic> json) {
    return BagSlot(
      id: json["id"],
      empty: json["empty"],
      support: json["support"] != null ? SupportObject.fromJson(json["support"]) : null,
    );
  }
}

/// Le BankSlot ne contient plus que des armes ou des objets de sac.
/// Les munitions du coffre sont désormais regroupées dans [Agent.reserve].
/// L'ancien champ `muni` est ignoré ici — sa migration est traitée par
/// [Agent.fromMap], qui extrait les munis vers [Reserve].
class BankSlot {
  final int id;
  final bool empty;
  final BagSlot? bag;
  final WeaponSlot? weapon;

  const BankSlot({
    required this.id,
    required this.empty,
    this.bag,
    this.weapon,
  });

  // --------------------
  // copyWith
  // --------------------
  BankSlot copyWith({
    int? id,
    bool? empty,
    BagSlot? bag,
    WeaponSlot? weapon,
  }) {
    return BankSlot(
      id: id ?? this.id,
      empty: empty ?? this.empty,
      bag: bag ?? this.bag,
      weapon: weapon ?? this.weapon,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "empty": empty,
      "bag": bag?.toMap(),
      "weapon": weapon?.toMap(),
    };
  }

  factory BankSlot.fromMap(Map<String, dynamic> map) {
    final bag = map["bag"] != null ? BagSlot.fromMap(map["bag"]) : null;
    final weapon =
        map["weapon"] != null ? WeaponSlot.fromMap(map["weapon"]) : null;
    final empty = (bag == null && weapon == null)
        ? true
        : (map["empty"] as bool? ?? false);
    return BankSlot(
      id: map["id"],
      empty: empty,
      bag: bag,
      weapon: weapon,
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "empty": empty,
      "bag": bag?.toJson(),
      "weapon": weapon?.toJson(),
    };
  }

  factory BankSlot.fromJson(Map<String, dynamic> json) {
    final bag = json["bag"] != null ? BagSlot.fromJson(json["bag"]) : null;
    final weapon =
        json["weapon"] != null ? WeaponSlot.fromJson(json["weapon"]) : null;
    final empty = (bag == null && weapon == null)
        ? true
        : (json["empty"] as bool? ?? false);
    return BankSlot(
      id: json["id"],
      empty: empty,
      bag: bag,
      weapon: weapon,
    );
  }
}

/// Mode d'utilisation d'un [MuniSlot].
///
/// - [empty] : slot non utilisé. Calibre toujours [Calibre.empty].
/// - [munition] : contient une liste de [MuniObject] de la même MuniCateg.
///   Calibre figé au premier ajout, libéré à la dernière retrait.
/// - [support] : contient un seul type de [SupportObject] (1 à 6 unités).
/// - [magazine] : lié à une arme équipée. Calibre = celui de l'arme.
///   Reste lié même quand vide. Capacité = magazineSize/secondMagazineSize.
enum MuniSlotMode { empty, munition, support, magazine }

class MuniSlot {
  final int id;
  final MuniSlotMode mode;
  final Calibre calibre;
  final List<MuniObject> munis;
  final SupportObject? support;
  final int supportCount;
  final int? linkedWeaponSlotId;
  final int? magazineIndex; // 0 = principal, 1 = secondaire

  const MuniSlot._({
    required this.id,
    required this.mode,
    required this.calibre,
    required this.munis,
    this.support,
    required this.supportCount,
    this.linkedWeaponSlotId,
    this.magazineIndex,
  });

  // --------------------
  // Constructeurs nommés
  // --------------------
  factory MuniSlot.empty(int id) => MuniSlot._(
        id: id,
        mode: MuniSlotMode.empty,
        calibre: Calibre.empty,
        munis: const [],
        supportCount: 0,
      );

  factory MuniSlot.munition({
    required int id,
    required Calibre calibre,
    required List<MuniObject> munis,
  }) =>
      MuniSlot._(
        id: id,
        mode: MuniSlotMode.munition,
        calibre: calibre,
        munis: List.unmodifiable(munis),
        supportCount: 0,
      );

  factory MuniSlot.supportSlot({
    required int id,
    required SupportObject support,
    required int count,
  }) =>
      MuniSlot._(
        id: id,
        mode: MuniSlotMode.support,
        calibre: Calibre.empty,
        munis: const [],
        support: support,
        supportCount: count,
      );

  factory MuniSlot.magazine({
    required int id,
    required Calibre calibre,
    required int linkedWeaponSlotId,
    required int magazineIndex,
    List<MuniObject> munis = const [],
  }) =>
      MuniSlot._(
        id: id,
        mode: MuniSlotMode.magazine,
        calibre: calibre,
        munis: List.unmodifiable(munis),
        supportCount: 0,
        linkedWeaponSlotId: linkedWeaponSlotId,
        magazineIndex: magazineIndex,
      );

  // --------------------
  // Capacités / utilitaires
  // --------------------

  /// Capacité du slot pour les modes [empty], [munition] et [support].
  /// Pour le mode [magazine], la capacité dépend de l'arme liée et doit
  /// être calculée par l'appelant via le [Weapon.magazineSize] /
  /// [Weapon.secondMagazineSize] correspondant à [magazineIndex].
  int? get fixedCapacity {
    switch (mode) {
      case MuniSlotMode.empty:
        return 0;
      case MuniSlotMode.munition:
        return (calibre == Calibre.herb || calibre == Calibre.throwable)
            ? 6
            : 8;
      case MuniSlotMode.support:
        return 6;
      case MuniSlotMode.magazine:
        return null;
    }
  }

  int get used {
    switch (mode) {
      case MuniSlotMode.empty:
        return 0;
      case MuniSlotMode.munition:
      case MuniSlotMode.magazine:
        return munis.length;
      case MuniSlotMode.support:
        return supportCount;
    }
  }

  bool get isEmpty => mode == MuniSlotMode.empty;
  bool get isMagazine => mode == MuniSlotMode.magazine;

  // --------------------
  // copyWith
  // --------------------
  MuniSlot copyWith({
    int? id,
    MuniSlotMode? mode,
    Calibre? calibre,
    List<MuniObject>? munis,
    SupportObject? support,
    int? supportCount,
    int? linkedWeaponSlotId,
    int? magazineIndex,
    bool clearSupport = false,
    bool clearLink = false,
  }) {
    return MuniSlot._(
      id: id ?? this.id,
      mode: mode ?? this.mode,
      calibre: calibre ?? this.calibre,
      munis: munis ?? this.munis,
      support: clearSupport ? null : (support ?? this.support),
      supportCount: supportCount ?? this.supportCount,
      linkedWeaponSlotId:
          clearLink ? null : (linkedWeaponSlotId ?? this.linkedWeaponSlotId),
      magazineIndex: clearLink ? null : (magazineIndex ?? this.magazineIndex),
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "mode": mode.name,
      "calibre": calibre.name,
      "munis": munis.map((m) => m.toMap()).toList(),
      "support": support?.toMap(),
      "supportCount": supportCount,
      "linkedWeaponSlotId": linkedWeaponSlotId,
      "magazineIndex": magazineIndex,
    };
  }

  factory MuniSlot.fromMap(Map<String, dynamic> map) {
    // ── Migration de l'ancien format ────────────────────────────────────────
    if (!map.containsKey('mode')) {
      final id = map['id'] as int? ?? 0;
      final empty = map['empty'] as bool? ?? true;
      if (empty) return MuniSlot.empty(id);
      final qty = map['numberLeft'] as int? ?? 1;
      if (map['muni'] != null) {
        final muni = MuniObject.fromMap(Map<String, dynamic>.from(map['muni']));
        final calibre = _legacyDeduceCalibre(muni);
        return MuniSlot.munition(
          id: id,
          calibre: calibre,
          munis: List.filled(qty, muni),
        );
      }
      if (map['supp'] != null) {
        final supp =
            SupportObject.fromMap(Map<String, dynamic>.from(map['supp']));
        return MuniSlot.supportSlot(
          id: id,
          support: supp,
          count: qty,
        );
      }
      return MuniSlot.empty(id);
    }
    // ── Nouveau format ──────────────────────────────────────────────────────
    return MuniSlot._(
      id: map["id"],
      mode: MuniSlotMode.values.byName(map["mode"]),
      calibre: Calibre.values.byName(map["calibre"]),
      munis: (map["munis"] as List? ?? const [])
          .map((m) => MuniObject.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      support: map["support"] != null
          ? SupportObject.fromMap(Map<String, dynamic>.from(map["support"]))
          : null,
      supportCount: map["supportCount"] as int? ?? 0,
      linkedWeaponSlotId: map["linkedWeaponSlotId"] as int?,
      magazineIndex: map["magazineIndex"] as int?,
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "mode": mode.name,
      "calibre": calibre.name,
      "munis": munis.map((m) => m.toJson()).toList(),
      "support": support?.toJson(),
      "supportCount": supportCount,
      "linkedWeaponSlotId": linkedWeaponSlotId,
      "magazineIndex": magazineIndex,
    };
  }

  factory MuniSlot.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('mode')) {
      final id = json['id'] as int? ?? 0;
      final empty = json['empty'] as bool? ?? true;
      if (empty) return MuniSlot.empty(id);
      final qty = json['numberLeft'] as int? ?? 1;
      if (json['muni'] != null) {
        final muni =
            MuniObject.fromJson(Map<String, dynamic>.from(json['muni']));
        final calibre = _legacyDeduceCalibre(muni);
        return MuniSlot.munition(
          id: id,
          calibre: calibre,
          munis: List.filled(qty, muni),
        );
      }
      if (json['supp'] != null) {
        final supp =
            SupportObject.fromJson(Map<String, dynamic>.from(json['supp']));
        return MuniSlot.supportSlot(
          id: id,
          support: supp,
          count: qty,
        );
      }
      return MuniSlot.empty(id);
    }
    return MuniSlot._(
      id: json["id"],
      mode: MuniSlotMode.values.byName(json["mode"]),
      calibre: Calibre.values.byName(json["calibre"]),
      munis: (json["munis"] as List? ?? const [])
          .map((m) => MuniObject.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      support: json["support"] != null
          ? SupportObject.fromJson(Map<String, dynamic>.from(json["support"]))
          : null,
      supportCount: json["supportCount"] as int? ?? 0,
      linkedWeaponSlotId: json["linkedWeaponSlotId"] as int?,
      magazineIndex: json["magazineIndex"] as int?,
    );
  }
}

/// Pour les anciennes fiches : retrouve un calibre plausible à partir
/// d'un [MuniObject] migré (le calibre n'était pas stocké au niveau du slot).
/// On prend le premier calibre de la MuniCateg qui contient cette muni.
Calibre _legacyDeduceCalibre(MuniObject m) {
  for (final cat in MuniCategList().allMuniCateg) {
    if (cat.munis.any((mu) => mu.id == m.id)) {
      return cat.included.isNotEmpty ? cat.included.first : Calibre.empty;
    }
  }
  return Calibre.empty;
}

class WeaponSlot {
  final int id;
  final Weapon? weapon;
  final SupportObject? kit;
  final bool empty;

  const WeaponSlot._({
    required this.id,
    this.weapon,
    this.kit,
    required this.empty,
  }) : assert(
          empty
              ? ((weapon == null) && (kit == null))
              : ((weapon != null) ^ (kit != null)),
          "Erreur: Si l'emplacement n'est pas vide, il faut une arme ou un kit.",
        );

  // --------------------
  // Getter métier
  // --------------------
  double? get size => empty ? null : (weapon?.size ?? kit!.size);

  factory WeaponSlot.empty(int id) {
    return WeaponSlot._(
      id: id,
      weapon: null,
      kit: null,
      empty: true,
    );
  }

  // --------------------
  // copyWith
  // --------------------
  WeaponSlot copyWith({
    int? id,
    Weapon? weapon,
    SupportObject? kit,
    bool? empty,
  }) {
    return WeaponSlot._(
      id: id ?? this.id,
      weapon: weapon ?? this.weapon,
      kit: kit ?? this.kit,
      empty: empty ?? this.empty,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "weapon": weapon?.toMap(),
      "kit": kit?.toMap(),
      "empty": empty,
    };
  }

  factory WeaponSlot.fromMap(Map<String, dynamic> map) {
    return WeaponSlot._(
      id: map["id"],
      weapon:
          map["weapon"] != null ? Weapon.fromMap(map["weapon"]) : null,
      kit: map["kit"] != null ? SupportObject.fromMap(map["kit"]) : null,
      empty: map["empty"],
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "weapon": weapon?.toJson(),
      "kit": kit?.toJson(),
      "empty": empty,
    };
  }

  factory WeaponSlot.fromJson(Map<String, dynamic> json) {
    return WeaponSlot._(
      id: json["id"],
      weapon:
          json["weapon"] != null ? Weapon.fromJson(json["weapon"]) : null,
      kit: json["kit"] != null ? SupportObject.fromJson(json["kit"]) : null,
      empty: json["empty"],
    );
  }
}
