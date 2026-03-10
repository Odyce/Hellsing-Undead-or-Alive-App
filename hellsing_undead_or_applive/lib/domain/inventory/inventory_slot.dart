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

class BankSlot {
  final int id;
  final bool empty;
  final BagSlot? bag;
  final MuniSlot? muni;
  final WeaponSlot? weapon;

  const BankSlot({
    required this.id,
    required this.empty,
    this.bag,
    this.muni,
    this.weapon,
  });

  // --------------------
  // copyWith
  // --------------------
  BankSlot copyWith({
    int? id,
    bool? empty,
    BagSlot? bag,
    MuniSlot? muni,
    WeaponSlot? weapon,
  }) {
    return BankSlot(
      id: id ?? this.id,
      empty: empty ?? this.empty,
      bag: bag ?? this.bag,
      muni: muni ?? this.muni,
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
      "muni": muni?.toMap(),
      "weapon": weapon?.toMap(),
    };
  }

  factory BankSlot.fromMap(Map<String, dynamic> map) {
    return BankSlot(
      id: map["id"],
      empty: map["empty"],
      bag: map["bag"] != null ? BagSlot.fromMap(map["bag"]) : null,
      muni:
          map["muni"] != null ? MuniSlot.fromMap(map["muni"]) : null,
      weapon: map["weapon"] != null
          ? WeaponSlot.fromMap(map["weapon"])
          : null,
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
      "muni": muni?.toJson(),
      "weapon": weapon?.toJson(),
    };
  }

  factory BankSlot.fromJson(Map<String, dynamic> json) {
    return BankSlot(
      id: json["id"],
      empty: json["empty"],
      bag:
          json["bag"] != null ? BagSlot.fromJson(json["bag"]) : null,
      muni:
          json["muni"] != null ? MuniSlot.fromJson(json["muni"]) : null,
      weapon: json["weapon"] != null
          ? WeaponSlot.fromJson(json["weapon"])
          : null,
    );
  }
}

class MuniSlot {
  final int id;
  final MuniObject? muni;
  final SupportObject? supp;
  final int numberLeft;
  final bool empty;

  const MuniSlot({
    required this.id,
    this.muni,
    this.supp,
    required this.numberLeft,
    required this.empty,
  });

  // --------------------
  // copyWith
  // --------------------
  MuniSlot copyWith({
    int? id,
    MuniObject? muni,
    SupportObject? supp,
    int? numberLeft,
    bool? empty,
  }) {
    return MuniSlot(
      id: id ?? this.id,
      muni: muni ?? this.muni,
      supp: supp ?? this.supp,
      numberLeft: numberLeft ?? this.numberLeft,
      empty: empty ?? this.empty,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "muni": muni?.toMap(),
      "supp": supp?.toMap(),
      "numberLeft": numberLeft,
      "empty": empty,
    };
  }

  factory MuniSlot.fromMap(Map<String, dynamic> map) {
    return MuniSlot(
      id: map["id"],
      muni:
          map["muni"] != null ? MuniObject.fromMap(map["muni"]) : null,
      supp:
          map["supp"] != null ? SupportObject.fromMap(map["supp"]) : null,
      numberLeft: map["numberLeft"],
      empty: map["empty"],
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "muni": muni?.toJson(),
      "supp": supp?.toJson(),
      "numberLeft": numberLeft,
      "empty": empty,
    };
  }

  factory MuniSlot.fromJson(Map<String, dynamic> json) {
    return MuniSlot(
      id: json["id"],
      muni:
          json["muni"] != null ? MuniObject.fromJson(json["muni"]) : null,
      supp:
          json["supp"] != null ? SupportObject.fromJson(json["supp"]) : null,
      numberLeft: json["numberLeft"],
      empty: json["empty"],
    );
  }
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
