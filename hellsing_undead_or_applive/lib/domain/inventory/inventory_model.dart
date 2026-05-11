import 'package:hellsing_undead_or_applive/domain/models.dart';

enum Stockage { weapon, bag, muni }

/// Réserve de munitions et de supports munis d'un agent.
///
/// Apparait dans le coffre comme une section dédiée. Les calibres
/// [Calibre.herb] et [Calibre.throwable] ne sont pas stockés en réserve.
/// Les transferts sont bidirectionnels entre la réserve et les MuniSlot.
class Reserve {
  final List<MuniObject> munis;
  final List<ReserveSupportEntry> supports;

  const Reserve({
    this.munis = const [],
    this.supports = const [],
  });

  factory Reserve.empty() => const Reserve();

  Reserve copyWith({
    List<MuniObject>? munis,
    List<ReserveSupportEntry>? supports,
  }) =>
      Reserve(
        munis: munis ?? this.munis,
        supports: supports ?? this.supports,
      );

  /// Ajoute une munition (sauf calibres herb / throwable, ignorés).
  Reserve addMuni(MuniObject m) =>
      copyWith(munis: [...munis, m]);

  /// Ajoute plusieurs munitions d'un coup.
  Reserve addMunis(Iterable<MuniObject> ms) =>
      copyWith(munis: [...munis, ...ms]);

  /// Retire la première munition correspondant à l'id donné.
  Reserve removeMuniById(int muniId) {
    final idx = munis.indexWhere((m) => m.id == muniId);
    if (idx == -1) return this;
    final next = List<MuniObject>.from(munis)..removeAt(idx);
    return copyWith(munis: next);
  }

  /// Ajoute une unité du support indiqué (groupe par id).
  Reserve addSupport(SupportObject s) {
    final idx = supports.indexWhere((e) => e.support.id == s.id);
    if (idx == -1) {
      return copyWith(
        supports: [...supports, ReserveSupportEntry(support: s, count: 1)],
      );
    }
    final next = List<ReserveSupportEntry>.from(supports);
    next[idx] = next[idx].copyWith(count: next[idx].count + 1);
    return copyWith(supports: next);
  }

  /// Retire une unité du support indiqué. L'entrée disparaît à 0.
  Reserve removeSupportById(int supportId) {
    final idx = supports.indexWhere((e) => e.support.id == supportId);
    if (idx == -1) return this;
    final next = List<ReserveSupportEntry>.from(supports);
    final remaining = next[idx].count - 1;
    if (remaining <= 0) {
      next.removeAt(idx);
    } else {
      next[idx] = next[idx].copyWith(count: remaining);
    }
    return copyWith(supports: next);
  }

  Map<String, dynamic> toMap() => {
        "munis": munis.map((m) => m.toMap()).toList(),
        "supports": supports.map((e) => e.toMap()).toList(),
      };

  factory Reserve.fromMap(Map<String, dynamic> map) => Reserve(
        munis: (map["munis"] as List? ?? const [])
            .map((m) => MuniObject.fromMap(Map<String, dynamic>.from(m)))
            .toList(),
        supports: (map["supports"] as List? ?? const [])
            .map((e) =>
                ReserveSupportEntry.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        "munis": munis.map((m) => m.toJson()).toList(),
        "supports": supports.map((e) => e.toJson()).toList(),
      };

  factory Reserve.fromJson(Map<String, dynamic> json) => Reserve(
        munis: (json["munis"] as List? ?? const [])
            .map((m) => MuniObject.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
        supports: (json["supports"] as List? ?? const [])
            .map((e) =>
                ReserveSupportEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// Une entrée de support dans la réserve : un type [SupportObject]
/// regroupé avec son nombre d'unités.
class ReserveSupportEntry {
  final SupportObject support;
  final int count;

  const ReserveSupportEntry({
    required this.support,
    required this.count,
  });

  ReserveSupportEntry copyWith({SupportObject? support, int? count}) =>
      ReserveSupportEntry(
        support: support ?? this.support,
        count: count ?? this.count,
      );

  Map<String, dynamic> toMap() => {
        "support": support.toMap(),
        "count": count,
      };

  factory ReserveSupportEntry.fromMap(Map<String, dynamic> map) =>
      ReserveSupportEntry(
        support:
            SupportObject.fromMap(Map<String, dynamic>.from(map["support"])),
        count: map["count"] as int,
      );

  Map<String, dynamic> toJson() => {
        "support": support.toJson(),
        "count": count,
      };

  factory ReserveSupportEntry.fromJson(Map<String, dynamic> json) =>
      ReserveSupportEntry(
        support:
            SupportObject.fromJson(Map<String, dynamic>.from(json["support"])),
        count: json["count"] as int,
      );
}

class MuniCateg {
  final int id;
  final String name;
  final String description;
  final List<Calibre> included;
  final List<MuniObject> munis;

  const MuniCateg({
    required this.id,
    required this.name,
    required this.description,
    required this.included,
    required this.munis,
  });

  // --------------------
  // copyWith
  // --------------------
  MuniCateg copyWith({
    int? id,
    String? name,
    String? description,
    List<Calibre>? included,
    List<MuniObject>? munis,
  }) {
    return MuniCateg(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      included: included ?? this.included,
      munis: munis ?? this.munis,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "included": included.map((c) => c.name).toList(),
      "munis": munis.map((m) => m.toMap()).toList(),
    };
  }

  factory MuniCateg.fromMap(Map<String, dynamic> map) {
    return MuniCateg(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      included: (map["included"] as List)
          .map((c) => Calibre.values.byName(c))
          .toList(),
      munis: (map["munis"] as List)
          .map((m) => MuniObject.fromMap(m))
          .toList(),
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "included": included.map((c) => c.name).toList(),
      "munis": munis.map((m) => m.toJson()).toList(),
    };
  }

  factory MuniCateg.fromJson(Map<String, dynamic> json) {
    return MuniCateg(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      included: (json["included"] as List)
          .map((c) => Calibre.values.byName(c))
          .toList(),
      munis: (json["munis"] as List)
          .map((m) => MuniObject.fromJson(m))
          .toList(),
    );
  }
}

class MuniObject {
  final int id;
  final String name;
  final String description;
  final Effect effect;
  final int price;
  final int priceFor6;
  final List<Calibre>? free;

  const MuniObject({
    required this.id,
    required this.name,
    required this.description,
    required this.effect,
    required this.price,
    required this.priceFor6,
    this.free,
  });

  // --------------------
  // copyWith
  // --------------------
  MuniObject copyWith({
    int? id,
    String? name,
    String? description,
    Effect? effect,
    int? price,
    int? priceFor6,
    List<Calibre>? free,
  }) {
    return MuniObject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      effect: effect ?? this.effect,
      price: price ?? this.price,
      priceFor6: priceFor6 ?? this.priceFor6,
      free: free ?? this.free,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "effect": effect.name,
      "price": price,
      "priceFor6": priceFor6,
      "free": free?.map((c) => c.name).toList(),
    };
  }

  factory MuniObject.fromMap(Map<String, dynamic> map) {
    return MuniObject(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      effect: Effect.values.byName(map["effect"]),
      price: map["price"],
      priceFor6: map["priceFor6"],
      free: map["free"] != null
          ? (map["free"] as List)
              .map((c) => Calibre.values.byName(c))
              .toList()
          : null,
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "effect": effect.name,
      "price": price,
      "priceFor6": priceFor6,
      "free": free?.map((c) => c.name).toList(),
    };
  }

  factory MuniObject.fromJson(Map<String, dynamic> json) {
    return MuniObject(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      effect: Effect.values.byName(json["effect"]),
      price: json["price"],
      priceFor6: json["priceFor6"],
      free: json["free"] != null
          ? (json["free"] as List)
              .map((c) => Calibre.values.byName(c))
              .toList()
          : null,
    );
  }
}

class SupportObject {
  final int id;
  final String name;
  final String legend;
  final String description;
  final int price;
  final Stockage stockage;
  final double size;
  final double? number; // NONE = 1

  const SupportObject({
    required this.id,
    required this.name,
    required this.legend,
    required this.description,
    required this.price,
    required this.stockage,
    required this.size,
    this.number,
  });

  // --------------------
  // copyWith
  // --------------------
  SupportObject copyWith({
    int? id,
    String? name,
    String? legend,
    String? description,
    int? price,
    Stockage? stockage,
    double? size,
    double? number,
  }) {
    return SupportObject(
      id: id ?? this.id,
      name: name ?? this.name,
      legend: legend ?? this.legend,
      description: description ?? this.description,
      price: price ?? this.price,
      stockage: stockage ?? this.stockage,
      size: size ?? this.size,
      number: number ?? this.number,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "legend": legend,
      "description": description,
      "price": price,
      "stockage": stockage.name,
      "size": size,
      "number": number,
    };
  }

  factory SupportObject.fromMap(Map<String, dynamic> map) {
    return SupportObject(
      id: map["id"],
      name: map["name"],
      legend: map["legend"],
      description: map["description"],
      price: map["price"],
      stockage: Stockage.values.byName(map["stockage"]),
      size: (map["size"] as num).toDouble(),
      number: (map["number"] as num?)?.toDouble(),
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "legend": legend,
      "description": description,
      "price": price,
      "stockage": stockage.name,
      "size": size,
      "number": number,
    };
  }

  factory SupportObject.fromJson(Map<String, dynamic> json) {
    return SupportObject(
      id: json["id"],
      name: json["name"],
      legend: json["legend"],
      description: json["description"],
      price: json["price"],
      stockage: Stockage.values.byName(json["stockage"]),
      size: (json["size"] as num).toDouble(),
      number: (json["number"] as num?)?.toDouble(),
    );
  }
}
