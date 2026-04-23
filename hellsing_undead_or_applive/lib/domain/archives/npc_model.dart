import 'package:hellsing_undead_or_applive/domain/agents/agent_bonus_data.dart';

enum Entitype { demon, angel, midian, beast, human }

enum Relationship { neutral, ally, enemy, trader }

class PNJ {
  final int id;
  final String name;
  final Entitype type;
  final String? picturePath;
  final String description;
  final Relationship relation;
  final bool alive;
  final List<MissionRecord> missions;

  const PNJ({
    required this.id,
    required this.name,
    required this.type,
    this.picturePath,
    required this.description,
    required this.relation,
    required this.alive,
    this.missions = const [],
  });

  // --------------------
  // copyWith
  // --------------------
  PNJ copyWith({
    int? id,
    String? name,
    Entitype? type,
    String? picturePath,
    String? description,
    Relationship? relation,
    bool? alive,
    List<MissionRecord>? missions,
  }) {
    return PNJ(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      picturePath: picturePath ?? this.picturePath,
      description: description ?? this.description,
      relation: relation ?? this.relation,
      alive: alive ?? this.alive,
      missions: missions ?? this.missions,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "type": type.name,
      "picturePath": picturePath,
      "description": description,
      "relation": relation.name,
      "alive": alive,
      "missions": missions.map((m) => m.toMap()).toList(),
    };
  }

  factory PNJ.fromMap(Map<String, dynamic> map) {
    return PNJ(
      id: map["id"],
      name: map["name"],
      type: Entitype.values.byName(map["type"]),
      picturePath: map["picturePath"],
      description: map["description"],
      relation: Relationship.values.byName(map["relation"]),
      alive: map["alive"],
      missions: map["missions"] != null
          ? (map["missions"] as List)
              .map((m) => MissionRecord.fromMap(m as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "type": type.name,
      "picturePath": picturePath,
      "description": description,
      "relation": relation.name,
      "alive": alive,
      "missions": missions.map((m) => m.toJson()).toList(),
    };
  }

  factory PNJ.fromJson(Map<String, dynamic> json) {
    return PNJ(
      id: json["id"],
      name: json["name"],
      type: Entitype.values.byName(json["type"]),
      picturePath: json["picturePath"],
      description: json["description"],
      relation: Relationship.values.byName(json["relation"]),
      alive: json["alive"],
      missions: json["missions"] != null
          ? (json["missions"] as List)
              .map((m) => MissionRecord.fromJson(m as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class Monster {
  final int id;
  final String name;
  final Entitype type;
  final String race;
  final List<String>? illustrationPaths;
  final String description;
  final String skills;
  final String weakness;
  final String location;
  final int hp;
  final List<int> hpScale;
  final List<MissionRecord> missions;

  const Monster({
    required this.id,
    required this.name,
    required this.type,
    required this.race,
    this.illustrationPaths,
    required this.description,
    required this.skills,
    required this.weakness,
    required this.location,
    required this.hp,
    required this.hpScale,
    this.missions = const [],
  });

  // --------------------
  // copyWith
  // --------------------
  Monster copyWith({
    int? id,
    String? name,
    Entitype? type,
    String? race,
    List<String>? illustrationPaths,
    String? description,
    String? skills,
    String? weakness,
    String? location,
    int? hp,
    List<int>? hpScale,
    List<MissionRecord>? missions,
  }) {
    return Monster(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      race: race ?? this.race,
      illustrationPaths: illustrationPaths ?? this.illustrationPaths,
      description: description ?? this.description,
      skills: skills ?? this.skills,
      weakness: weakness ?? this.weakness,
      location: location ?? this.location,
      hp: hp ?? this.hp,
      hpScale: hpScale ?? this.hpScale,
      missions: missions ?? this.missions,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "type": type.name,
      "race": race,
      "illustrationPaths": illustrationPaths,
      "description": description,
      "skills": skills,
      "weakness": weakness,
      "location": location,
      "hp": hp,
      "hpScale": hpScale,
      "missions": missions.map((m) => m.toMap()).toList(),
    };
  }

  factory Monster.fromMap(Map<String, dynamic> map) {
    return Monster(
      id: (map["id"] as num?)?.toInt() ?? 0,
      name: map["name"] ?? '',
      type: Entitype.values.byName(map["type"] ?? 'human'),
      race: map["race"] ?? '',
      illustrationPaths: map["illustrationPaths"] != null
          ? List<String>.from(map["illustrationPaths"])
          : null,
      description: map["description"] ?? '',
      skills: map["skills"] ?? '',
      weakness: map["weakness"] ?? '',
      location: map["location"] ?? '',
      hp: (map["hp"] as num?)?.toInt() ?? 0,
      hpScale: map["hpScale"] != null ? List<int>.from(map["hpScale"]) : [],
      missions: map["missions"] != null
          ? (map["missions"] as List)
              .map((m) => MissionRecord.fromMap(m as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "type": type.name,
      "race": race,
      "illustrationPaths": illustrationPaths,
      "description": description,
      "skills": skills,
      "weakness": weakness,
      "location": location,
      "hp": hp,
      "hpScale": hpScale,
      "missions": missions.map((m) => m.toJson()).toList(),
    };
  }

  factory Monster.fromJson(Map<String, dynamic> json) {
    return Monster(
      id: (json["id"] as num?)?.toInt() ?? 0,
      name: json["name"] ?? '',
      type: Entitype.values.byName(json["type"] ?? 'human'),
      race: json["race"] ?? '',
      illustrationPaths: json["illustrationPaths"] != null
          ? List<String>.from(json["illustrationPaths"])
          : null,
      description: json["description"] ?? '',
      skills: json["skills"] ?? '',
      weakness: json["weakness"] ?? '',
      location: json["location"] ?? '',
      hp: (json["hp"] as num?)?.toInt() ?? 0,
      hpScale: json["hpScale"] != null ? List<int>.from(json["hpScale"]) : [],
      missions: json["missions"] != null
          ? (json["missions"] as List)
              .map((m) => MissionRecord.fromJson(m as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
