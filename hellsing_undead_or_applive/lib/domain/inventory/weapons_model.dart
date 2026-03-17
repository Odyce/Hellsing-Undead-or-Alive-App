import 'package:hellsing_undead_or_applive/domain/models.dart';

class WeaponModif {
  final String name;
  final String legend;
  final String feature;
  final String? damage;
  final int price;
  final SubAffinities type;
  final Effect? effect;
  final Firing? firing;

  const WeaponModif({
    required this.name,
    required this.legend,
    required this.feature,
    this.damage,
    required this.price,
    required this.type,
    this.effect,
    this.firing,
  });

  // --------------------
  // copyWith
  // --------------------
  WeaponModif copyWith({
    String? name,
    String? legend,
    String? feature,
    String? damage,
    int? price,
    SubAffinities? type,
    Effect? effect,
    Firing? firing,
  }) {
    return WeaponModif(
      name: name ?? this.name,
      legend: legend ?? this.legend,
      feature: feature ?? this.feature,
      damage: damage ?? this.damage,
      price: price ?? this.price,
      type: type ?? this.type,
      effect: effect ?? this.effect,
      firing: firing ?? this.firing,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "legend": legend,
      "feature": feature,
      "damage": damage,
      "price": price,
      "type": type.name,
      "effect": effect?.name,
      "firing": firing?.name,
    };
  }

  factory WeaponModif.fromMap(Map<String, dynamic> map) {
    return WeaponModif(
      name: map["name"],
      legend: map["legend"],
      feature: map["feature"],
      damage: map["damage"],
      price: map["price"],
      type: SubAffinities.values.byName(map["type"]),
      effect:
          map["effect"] != null ? Effect.values.byName(map["effect"]) : null,
      firing:
          map["firing"] != null ? Firing.values.byName(map["firing"]) : null,
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "legend": legend,
      "feature": feature,
      "damage": damage,
      "price": price,
      "type": type.name,
      "effect": effect?.name,
      "firing": firing?.name,
    };
  }

  factory WeaponModif.fromJson(Map<String, dynamic> json) {
    return WeaponModif(
      name: json["name"],
      legend: json["legend"],
      feature: json["feature"],
      damage: json["damage"],
      price: json["price"],
      type: SubAffinities.values.byName(json["type"]),
      effect:
          json["effect"] != null ? Effect.values.byName(json["effect"]) : null,
      firing:
          json["firing"] != null ? Firing.values.byName(json["firing"]) : null,
    );
  }
}

class Weapon {
  final int id;
  final String name;
  final String legend;
  final String damage;
  final String feature;
  final int price;
  final Affinities type;
  final SubAffinities subType;
  final List<Effect> effect;
  final List<WeaponModif>? modif;
  final double size;
  final bool fire;
  final Calibre? calibre;
  final double? reload;
  final int? magazineSize;
  final bool? secondMagazine;
  final int? secondMagazineSize;
  final Firing? firing;
  final bool startingWeapon;

  const Weapon({
    required this.id,
    required this.name,
    required this.legend,
    required this.damage,
    required this.feature,
    required this.price,
    required this.type,
    required this.subType,
    required this.effect,
    this.modif,
    required this.size,
    required this.fire,
    this.calibre,
    this.reload,
    this.magazineSize,
    this.secondMagazine,
    this.secondMagazineSize,
    this.firing,
    required this.startingWeapon,
  });

  // --------------------
  // copyWith
  // --------------------
  Weapon copyWith({
    int? id,
    String? name,
    String? legend,
    String? damage,
    String? feature,
    int? price,
    Affinities? type,
    SubAffinities? subType,
    List<Effect>? effect,
    List<WeaponModif>? modif,
    double? size,
    bool? fire,
    Calibre? calibre,
    double? reload,
    int? magazineSize,
    bool? secondMagazine,
    int? secondMagazineSize,
    Firing? firing,
    bool? startingWeapon,
  }) {
    return Weapon(
      id: id ?? this.id,
      name: name ?? this.name,
      legend: legend ?? this.legend,
      damage: damage ?? this.damage,
      feature: feature ?? this.feature,
      price: price ?? this.price,
      type: type ?? this.type,
      subType: subType ?? this.subType,
      effect: effect ?? this.effect,
      modif: modif ?? this.modif,
      size: size ?? this.size,
      fire: fire ?? this.fire,
      calibre: calibre ?? this.calibre,
      reload: reload ?? this.reload,
      magazineSize: magazineSize ?? this.magazineSize,
      secondMagazine: secondMagazine ?? this.secondMagazine,
      secondMagazineSize:
          secondMagazineSize ?? this.secondMagazineSize,
      firing: firing ?? this.firing,
      startingWeapon: startingWeapon ?? this.startingWeapon,
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
      "damage": damage,
      "feature": feature,
      "price": price,
      "type": type.name,
      "subType": subType.name,
      "effect": effect.map((e) => e.name).toList(),
      "modif": modif?.map((m) => m.toMap()).toList(),
      "size": size,
      "fire": fire,
      "calibre": calibre?.name,
      "reload": reload,
      "magazineSize": magazineSize,
      "secondMagazine": secondMagazine,
      "secondMagazineSize": secondMagazineSize,
      "firing": firing?.name,
      "startingWeapon": startingWeapon,
    };
  }

  factory Weapon.fromMap(Map<String, dynamic> map) {
    return Weapon(
      id: map["id"],
      name: map["name"],
      legend: map["legend"],
      damage: map["damage"],
      feature: map["feature"],
      price: map["price"],
      type: Affinities.values.byName(map["type"]),
      subType: SubAffinities.values.byName(map["subType"]),
      effect: (map["effect"] as List)
          .map((e) => Effect.values.byName(e))
          .toList(),
      modif: map["modif"] != null
          ? (map["modif"] as List)
              .map((m) => WeaponModif.fromMap(m))
              .toList()
          : null,
      size: (map["size"] as num).toDouble(),
      fire: map["fire"],
      calibre: map["calibre"] != null
          ? Calibre.values.byName(map["calibre"])
          : null,
      reload: (map["reload"] as num?)?.toDouble(),
      magazineSize: map["magazineSize"],
      secondMagazine: map["secondMagazine"],
      secondMagazineSize: map["secondMagazineSize"],
      firing:
          map["firing"] != null ? Firing.values.byName(map["firing"]) : null,
      startingWeapon: map["startingWeapon"],
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
      "damage": damage,
      "feature": feature,
      "price": price,
      "type": type.name,
      "subType": subType.name,
      "effect": effect.map((e) => e.name).toList(),
      "modif": modif?.map((m) => m.toJson()).toList(),
      "size": size,
      "fire": fire,
      "calibre": calibre?.name,
      "reload": reload,
      "magazineSize": magazineSize,
      "secondMagazine": secondMagazine,
      "secondMagazineSize": secondMagazineSize,
      "firing": firing?.name,
      "startingWeapon": startingWeapon,
    };
  }

  factory Weapon.fromJson(Map<String, dynamic> json) {
    return Weapon(
      id: json["id"],
      name: json["name"],
      legend: json["legend"],
      damage: json["damage"],
      feature: json["feature"],
      price: json["price"],
      type: Affinities.values.byName(json["type"]),
      subType: SubAffinities.values.byName(json["subType"]),
      effect: (json["effect"] as List)
          .map((e) => Effect.values.byName(e))
          .toList(),
      modif: json["modif"] != null
          ? (json["modif"] as List)
              .map((m) => WeaponModif.fromJson(m))
              .toList()
          : null,
      size: (json["size"] as num).toDouble(),
      fire: json["fire"],
      calibre: json["calibre"] != null
          ? Calibre.values.byName(json["calibre"])
          : null,
      reload: (json["reload"] as num?)?.toDouble(),
      magazineSize: json["magazineSize"],
      secondMagazine: json["secondMagazine"],
      secondMagazineSize: json["secondMagazineSize"],
      firing:
          json["firing"] != null ? Firing.values.byName(json["firing"]) : null,
      startingWeapon: json["startingWeapon"],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Weapon && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
