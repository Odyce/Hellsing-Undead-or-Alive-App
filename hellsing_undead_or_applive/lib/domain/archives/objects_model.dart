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
  final Mission? missionRetrievedAt;
  final DateTime? dateRetrievedAt;

  const Artefacts({
    required this.id,
    required this.name,
    required this.description,
    this.picturePath,
    required this.effect,
    required this.limitedUses,
    this.usesLeft,
    this.owner,
    this.missionRetrievedAt,
    this.dateRetrievedAt,
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
    Mission? missionRetrievedAt,
    DateTime? dateRetrievedAt,
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
      missionRetrievedAt: missionRetrievedAt ?? this.missionRetrievedAt,
      dateRetrievedAt: dateRetrievedAt ?? this.dateRetrievedAt,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "isWeapon": false,
      "id": id,
      "name": name,
      "description": description,
      "picturePath": picturePath,
      "effect": effect,
      "limitedUses": limitedUses,
      "usesLeft": usesLeft,
      "owner": owner?.map((a) => a.toMap()).toList(),
      "missionRetrievedAt": missionRetrievedAt?.toMap(),
      "dateRetrievedAt": dateRetrievedAt?.toIso8601String(),
    };
  }

  factory Artefacts.fromMap(Map<String, dynamic> map) {
    return Artefacts(
      id: (map["id"] as num?)?.toInt() ?? 0,
      name: map["name"] ?? '',
      description: map["description"] ?? '',
      picturePath: map["picturePath"],
      effect: map["effect"] ?? '',
      limitedUses: map["limitedUses"] ?? false,
      usesLeft: (map["usesLeft"] as num?)?.toInt(),
      owner: map["owner"] != null
          ? (map["owner"] as List).map((a) => Agent.fromMap(a)).toList()
          : null,
      missionRetrievedAt: map["missionRetrievedAt"] != null
          ? Mission.fromMap(map["missionRetrievedAt"])
          : null,
      dateRetrievedAt: map["dateRetrievedAt"] != null
          ? DateTime.tryParse(map["dateRetrievedAt"])
          : null,
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "isWeapon": false,
      "id": id,
      "name": name,
      "description": description,
      "picturePath": picturePath,
      "effect": effect,
      "limitedUses": limitedUses,
      "usesLeft": usesLeft,
      "owner": owner?.map((a) => a.toJson()).toList(),
      "missionRetrievedAt": missionRetrievedAt?.toJson(),
      "dateRetrievedAt": dateRetrievedAt?.toIso8601String(),
    };
  }

  factory Artefacts.fromJson(Map<String, dynamic> json) {
    return Artefacts(
      id: (json["id"] as num?)?.toInt() ?? 0,
      name: json["name"] ?? '',
      description: json["description"] ?? '',
      picturePath: json["picturePath"],
      effect: json["effect"] ?? '',
      limitedUses: json["limitedUses"] ?? false,
      usesLeft: (json["usesLeft"] as num?)?.toInt(),
      owner: json["owner"] != null
          ? (json["owner"] as List).map((a) => Agent.fromJson(a)).toList()
          : null,
      missionRetrievedAt: json["missionRetrievedAt"] != null
          ? Mission.fromJson(json["missionRetrievedAt"])
          : null,
      dateRetrievedAt: json["dateRetrievedAt"] != null
          ? DateTime.tryParse(json["dateRetrievedAt"])
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
  final Mission? missionRetrievedAt;
  final DateTime? dateRetrievedAt;

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
    this.missionRetrievedAt,
    this.dateRetrievedAt,
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
    Mission? missionRetrievedAt,
    DateTime? dateRetrievedAt,
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
      missionRetrievedAt: missionRetrievedAt ?? this.missionRetrievedAt,
      dateRetrievedAt: dateRetrievedAt ?? this.dateRetrievedAt,
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
      "missionRetrievedAt": missionRetrievedAt?.toMap(),
      "dateRetrievedAt": dateRetrievedAt?.toIso8601String(),
      "isWeapon": true,
    };
  }

  factory ArtefactWeapon.fromMap(Map<String, dynamic> map) {
    return ArtefactWeapon(
      id: (map["id"] as num?)?.toInt() ?? 0,
      name: map["name"] ?? '',
      description: map["description"] ?? '',
      picturePath: map["picturePath"],
      damage: map["damage"] ?? '',
      feature: map["feature"] ?? '',
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
      missionRetrievedAt: map["missionRetrievedAt"] != null
          ? Mission.fromMap(map["missionRetrievedAt"])
          : null,
      dateRetrievedAt: map["dateRetrievedAt"] != null
          ? DateTime.tryParse(map["dateRetrievedAt"])
          : null,
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "isWeapon": true,
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
      "missionRetrievedAt": missionRetrievedAt?.toJson(),
      "dateRetrievedAt": dateRetrievedAt?.toIso8601String(),
    };
  }

  factory ArtefactWeapon.fromJson(Map<String, dynamic> json) {
    return ArtefactWeapon(
      id: (json["id"] as num?)?.toInt() ?? 0,
      name: json["name"] ?? '',
      description: json["description"] ?? '',
      picturePath: json["picturePath"],
      damage: json["damage"] ?? '',
      feature: json["feature"] ?? '',
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
      missionRetrievedAt: json["missionRetrievedAt"] != null
          ? Mission.fromJson(json["missionRetrievedAt"])
          : null,
      dateRetrievedAt: json["dateRetrievedAt"] != null
          ? DateTime.tryParse(json["dateRetrievedAt"])
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
  final List<Agent?> prerequisiteAgents;
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
    required this.prerequisiteAgents,
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
    List<Agent?>? prerequisiteAgents,
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
      prerequisiteAgents: prerequisiteAgents ?? this.prerequisiteAgents,
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
      "prerequisiteAgents": prerequisiteAgents.map((a) => a?.toMap()).toList(),
      "cost": cost,
      "prerequisiteCompletes": prerequisiteCompletes,
      "completed": completed,
    };
  }

  factory ResDevProject.fromMap(Map<String, dynamic> map) {
    final prereqs = List<String>.from(map["prerequisite"]);
    return ResDevProject(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      picturePath: map["picturePath"],
      benefactor: (map["benefactor"] as List).map((a) => Agent.fromMap(a)).toList(),
      prerequisite: prereqs,
      prerequisiteAgents: map["prerequisiteAgents"] != null
          ? (map["prerequisiteAgents"] as List)
              .map((a) => a != null
                  ? Agent.fromMap(Map<String, dynamic>.from(a))
                  : null)
              .toList()
          : List<Agent?>.filled(prereqs.length, null),
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
      "prerequisiteAgents": prerequisiteAgents.map((a) => a?.toJson()).toList(),
      "cost": cost,
      "prerequisiteCompletes": prerequisiteCompletes,
      "completed": completed,
    };
  }

  factory ResDevProject.fromJson(Map<String, dynamic> json) {
    final prereqs = List<String>.from(json["prerequisite"]);
    return ResDevProject(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      picturePath: json["picturePath"],
      benefactor: (json["benefactor"] as List).map((a) => Agent.fromJson(a)).toList(),
      prerequisite: prereqs,
      prerequisiteAgents: json["prerequisiteAgents"] != null
          ? (json["prerequisiteAgents"] as List)
              .map((a) => a != null
                  ? Agent.fromJson(Map<String, dynamic>.from(a))
                  : null)
              .toList()
          : List<Agent?>.filled(prereqs.length, null),
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
  final int projectId;

  const ResDev({
    required this.id,
    required this.name,
    required this.description,
    this.picturePath,
    required this.stockage,
    required this.size,
    this.number,
    required this.projectId,
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
    int? projectId,
  }) {
    return ResDev(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      picturePath: picturePath ?? this.picturePath,
      stockage: stockage ?? this.stockage,
      size: size ?? this.size,
      number: number ?? this.number,
      projectId: projectId ?? this.projectId,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "isWeapon": false,
      "id": id,
      "name": name,
      "description": description,
      "picturePath": picturePath,
      "stockage": stockage.name,
      "size": size,
      "number": number,
      "projectId": projectId,
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
      projectId: map["projectId"] ?? 0,
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "isWeapon": false,
      "id": id,
      "name": name,
      "description": description,
      "picturePath": picturePath,
      "stockage": stockage.name,
      "size": size,
      "number": number,
      "projectId": projectId,
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
      projectId: json["projectId"] ?? 0,
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
  final int projectId;

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
    required this.projectId,
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
    int? projectId,
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
      projectId: projectId ?? this.projectId,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "isWeapon": true,
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
      "projectId": projectId,
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
      projectId: map["projectId"] ?? 0,
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "isWeapon": true,
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
      "projectId": projectId,
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
      projectId: json["projectId"] ?? 0,
    );
  }
}
