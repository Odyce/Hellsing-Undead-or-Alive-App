import 'package:hellsing_undead_or_applive/domain/models.dart';

class Artefacts {
  final int id;
  final String name;
  final String description;
  final String? picturePath;
  final String effect;
  final bool limitedUses;
  final int? usesLeft;
  final List<Agent>? owner;

  const Artefacts({
    required this.id,
    required this.name,
    required this.description,
    this.picturePath,
    required this.effect,
    required this.limitedUses,
    this.usesLeft,
    this.owner,
  });

  // --------------------
  // copyWith
  // --------------------
  Artefacts copyWith({
    int? id,
    String? name,
    String? description,
    String? picturePath,
    String? effect,
    bool? limitedUses,
    int? usesLeft,
    List<Agent>? owner,
  }) {
    return Artefacts(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      picturePath: picturePath ?? this.picturePath,
      effect: effect ?? this.effect,
      limitedUses: limitedUses ?? this.limitedUses,
      usesLeft: usesLeft ?? this.usesLeft,
      owner: owner ?? this.owner,
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
      "picturePath": picturePath,
      "effect": effect,
      "limitedUses": limitedUses,
      "usesLeft": usesLeft,
      "owner": owner?.map((a) => a.toMap()).toList(),
    };
  }

  factory Artefacts.fromMap(Map<String, dynamic> map) {
    return Artefacts(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      picturePath: map["picturePath"],
      effect: map["effect"],
      limitedUses: map["limitedUses"],
      usesLeft: map["usesLeft"],
      owner: map["owner"] != null
          ? (map["owner"] as List).map((a) => Agent.fromMap(a)).toList()
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
      "picturePath": picturePath,
      "effect": effect,
      "limitedUses": limitedUses,
      "usesLeft": usesLeft,
      "owner": owner?.map((a) => a.toJson()).toList(),
    };
  }

  factory Artefacts.fromJson(Map<String, dynamic> json) {
    return Artefacts(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      picturePath: json["picturePath"],
      effect: json["effect"],
      limitedUses: json["limitedUses"],
      usesLeft: json["usesLeft"],
      owner: json["owner"] != null
          ? (json["owner"] as List).map((a) => Agent.fromJson(a)).toList()
          : null,
    );
  }
}

class ArtefactWeapon {
  final int id;
  final String name;
  final String description;
  final String? picturePath;
  final String damage;
  final String feature;
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
  final bool limitedUses;
  final int? usesLeft;
  final List<Agent>? owner;

  const ArtefactWeapon({
    required this.id,
    required this.name,
    required this.description,
    this.picturePath,
    required this.damage,
    required this.feature,
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
    required this.limitedUses,
    this.usesLeft,
    this.owner,
  });

  // --------------------
  // copyWith
  // --------------------
  ArtefactWeapon copyWith({
    int? id,
    String? name,
    String? description,
    String? picturePath,
    String? damage,
    String? feature,
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
    bool? limitedUses,
    int? usesLeft,
    List<Agent>? owner,
  }) {
    return ArtefactWeapon(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      picturePath: picturePath ?? this.picturePath,
      damage: damage ?? this.damage,
      feature: feature ?? this.feature,
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
      secondMagazineSize: secondMagazineSize ?? this.secondMagazineSize,
      firing: firing ?? this.firing,
      limitedUses: limitedUses ?? this.limitedUses,
      usesLeft: usesLeft ?? this.usesLeft,
      owner: owner ?? this.owner,
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
      "picturePath": picturePath,
      "damage": damage,
      "feature": feature,
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
      "limitedUses": limitedUses,
      "usesLeft": usesLeft,
      "owner": owner?.map((a) => a.toMap()).toList(),
    };
  }

  factory ArtefactWeapon.fromMap(Map<String, dynamic> map) {
    return ArtefactWeapon(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      picturePath: map["picturePath"],
      damage: map["damage"],
      feature: map["feature"],
      type: Affinities.values.byName(map["type"]),
      subType: SubAffinities.values.byName(map["subType"]),
      effect: (map["effect"] as List).map((e) => Effect.values.byName(e)).toList(),
      modif: map["modif"] != null
          ? (map["modif"] as List).map((m) => WeaponModif.fromMap(m)).toList()
          : null,
      size: (map["size"] as num).toDouble(),
      fire: map["fire"],
      calibre: map["calibre"] != null ? Calibre.values.byName(map["calibre"]) : null,
      reload: (map["reload"] as num?)?.toDouble(),
      magazineSize: map["magazineSize"],
      secondMagazine: map["secondMagazine"],
      secondMagazineSize: map["secondMagazineSize"],
      firing: map["firing"] != null ? Firing.values.byName(map["firing"]) : null,
      limitedUses: map["limitedUses"],
      usesLeft: map["usesLeft"],
      owner: map["owner"] != null
          ? (map["owner"] as List).map((a) => Agent.fromMap(a)).toList()
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
      "picturePath": picturePath,
      "damage": damage,
      "feature": feature,
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
      "limitedUses": limitedUses,
      "usesLeft": usesLeft,
      "owner": owner?.map((a) => a.toJson()).toList(),
    };
  }

  factory ArtefactWeapon.fromJson(Map<String, dynamic> json) {
    return ArtefactWeapon(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      picturePath: json["picturePath"],
      damage: json["damage"],
      feature: json["feature"],
      type: Affinities.values.byName(json["type"]),
      subType: SubAffinities.values.byName(json["subType"]),
      effect: (json["effect"] as List).map((e) => Effect.values.byName(e)).toList(),
      modif: json["modif"] != null
          ? (json["modif"] as List).map((m) => WeaponModif.fromJson(m)).toList()
          : null,
      size: (json["size"] as num).toDouble(),
      fire: json["fire"],
      calibre: json["calibre"] != null ? Calibre.values.byName(json["calibre"]) : null,
      reload: (json["reload"] as num?)?.toDouble(),
      magazineSize: json["magazineSize"],
      secondMagazine: json["secondMagazine"],
      secondMagazineSize: json["secondMagazineSize"],
      firing: json["firing"] != null ? Firing.values.byName(json["firing"]) : null,
      limitedUses: json["limitedUses"],
      usesLeft: json["usesLeft"],
      owner: json["owner"] != null
          ? (json["owner"] as List).map((a) => Agent.fromJson(a)).toList()
          : null,
    );
  }
}

class ResDevProject {
  final int id;
  final String name;
  final String description;
  final String? picturePath;
  final List<Agent> benefactor;
  final List<String> prerequisite;
  final int cost;
  final bool prerequisiteCompletes;
  final bool completed;

  const ResDevProject({
    required this.id,
    required this.name,
    required this.description,
    this.picturePath,
    required this.benefactor,
    required this.prerequisite,
    required this.cost,
    required this.prerequisiteCompletes,
    required this.completed,
  });

  // --------------------
  // copyWith
  // --------------------
  ResDevProject copyWith({
    int? id,
    String? name,
    String? description,
    String? picturePath,
    List<Agent>? benefactor,
    List<String>? prerequisite,
    int? cost,
    bool? prerequisiteCompletes,
    bool? completed,
  }) {
    return ResDevProject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      picturePath: picturePath ?? this.picturePath,
      benefactor: benefactor ?? this.benefactor,
      prerequisite: prerequisite ?? this.prerequisite,
      cost: cost ?? this.cost,
      prerequisiteCompletes: prerequisiteCompletes ?? this.prerequisiteCompletes,
      completed: completed ?? this.completed,
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
      "picturePath": picturePath,
      "benefactor": benefactor.map((a) => a.toMap()).toList(),
      "prerequisite": prerequisite,
      "cost": cost,
      "prerequisiteCompletes": prerequisiteCompletes,
      "completed": completed,
    };
  }

  factory ResDevProject.fromMap(Map<String, dynamic> map) {
    return ResDevProject(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      picturePath: map["picturePath"],
      benefactor: (map["benefactor"] as List).map((a) => Agent.fromMap(a)).toList(),
      prerequisite: List<String>.from(map["prerequisite"]),
      cost: map["cost"],
      prerequisiteCompletes: map["prerequisiteCompletes"],
      completed: map["completed"],
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
      "picturePath": picturePath,
      "benefactor": benefactor.map((a) => a.toJson()).toList(),
      "prerequisite": prerequisite,
      "cost": cost,
      "prerequisiteCompletes": prerequisiteCompletes,
      "completed": completed,
    };
  }

  factory ResDevProject.fromJson(Map<String, dynamic> json) {
    return ResDevProject(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      picturePath: json["picturePath"],
      benefactor: (json["benefactor"] as List).map((a) => Agent.fromJson(a)).toList(),
      prerequisite: List<String>.from(json["prerequisite"]),
      cost: json["cost"],
      prerequisiteCompletes: json["prerequisiteCompletes"],
      completed: json["completed"],
    );
  }
}

class ResDev {
  final int id;
  final String name;
  final String description;
  final String? picturePath;
  final Stockage stockage;
  final double size;
  final double? number; // NONE = 1

  const ResDev({
    required this.id,
    required this.name,
    required this.description,
    this.picturePath,
    required this.stockage,
    required this.size,
    this.number,
  });

  // --------------------
  // copyWith
  // --------------------
  ResDev copyWith({
    int? id,
    String? name,
    String? description,
    String? picturePath,
    Stockage? stockage,
    double? size,
    double? number,
  }) {
    return ResDev(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      picturePath: picturePath ?? this.picturePath,
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
      "description": description,
      "picturePath": picturePath,
      "stockage": stockage.name,
      "size": size,
      "number": number,
    };
  }

  factory ResDev.fromMap(Map<String, dynamic> map) {
    return ResDev(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      picturePath: map["picturePath"],
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
      "description": description,
      "picturePath": picturePath,
      "stockage": stockage.name,
      "size": size,
      "number": number,
    };
  }

  factory ResDev.fromJson(Map<String, dynamic> json) {
    return ResDev(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      picturePath: json["picturePath"],
      stockage: Stockage.values.byName(json["stockage"]),
      size: (json["size"] as num).toDouble(),
      number: (json["number"] as num?)?.toDouble(),
    );
  }
}

class ResDevWeapon {
  final int id;
  final String name;
  final String description;
  final String? picturePath;
  final String damage;
  final String feature;
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

  const ResDevWeapon({
    required this.id,
    required this.name,
    required this.description,
    this.picturePath,
    required this.damage,
    required this.feature,
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
  });

  // --------------------
  // copyWith
  // --------------------
  ResDevWeapon copyWith({
    int? id,
    String? name,
    String? description,
    String? picturePath,
    String? damage,
    String? feature,
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
  }) {
    return ResDevWeapon(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      picturePath: picturePath ?? this.picturePath,
      damage: damage ?? this.damage,
      feature: feature ?? this.feature,
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
      secondMagazineSize: secondMagazineSize ?? this.secondMagazineSize,
      firing: firing ?? this.firing,
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
      "picturePath": picturePath,
      "damage": damage,
      "feature": feature,
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
    };
  }

  factory ResDevWeapon.fromMap(Map<String, dynamic> map) {
    return ResDevWeapon(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      picturePath: map["picturePath"],
      damage: map["damage"],
      feature: map["feature"],
      type: Affinities.values.byName(map["type"]),
      subType: SubAffinities.values.byName(map["subType"]),
      effect: (map["effect"] as List).map((e) => Effect.values.byName(e)).toList(),
      modif: map["modif"] != null
          ? (map["modif"] as List).map((m) => WeaponModif.fromMap(m)).toList()
          : null,
      size: (map["size"] as num).toDouble(),
      fire: map["fire"],
      calibre: map["calibre"] != null ? Calibre.values.byName(map["calibre"]) : null,
      reload: (map["reload"] as num?)?.toDouble(),
      magazineSize: map["magazineSize"],
      secondMagazine: map["secondMagazine"],
      secondMagazineSize: map["secondMagazineSize"],
      firing: map["firing"] != null ? Firing.values.byName(map["firing"]) : null,
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
      "picturePath": picturePath,
      "damage": damage,
      "feature": feature,
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
    };
  }

  factory ResDevWeapon.fromJson(Map<String, dynamic> json) {
    return ResDevWeapon(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      picturePath: json["picturePath"],
      damage: json["damage"],
      feature: json["feature"],
      type: Affinities.values.byName(json["type"]),
      subType: SubAffinities.values.byName(json["subType"]),
      effect: (json["effect"] as List).map((e) => Effect.values.byName(e)).toList(),
      modif: json["modif"] != null
          ? (json["modif"] as List).map((m) => WeaponModif.fromJson(m)).toList()
          : null,
      size: (json["size"] as num).toDouble(),
      fire: json["fire"],
      calibre: json["calibre"] != null ? Calibre.values.byName(json["calibre"]) : null,
      reload: (json["reload"] as num?)?.toDouble(),
      magazineSize: json["magazineSize"],
      secondMagazine: json["secondMagazine"],
      secondMagazineSize: json["secondMagazineSize"],
      firing: json["firing"] != null ? Firing.values.byName(json["firing"]) : null,
    );
  }
}
