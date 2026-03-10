import 'package:hellsing_undead_or_applive/domain/models.dart';

enum Stockage { weapon, bag, muni }

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
