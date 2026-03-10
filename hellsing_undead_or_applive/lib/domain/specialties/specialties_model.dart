import 'package:hellsing_undead_or_applive/domain/models.dart';

enum CostType { pe, pm, pv}

class Skill {
  final int id;
  final String name;
  final int cost;
  final CostType costType;
  final int? secondCost;
  final CostType? secondCostType;
  final bool multiCost;
  final List<int>? costs;
  final List<String>? descriptions;
  final bool limited;
  final String description;

  const Skill({
    required this.id,
    required this.name,
    required this.cost,
    required this.costType,
    this.secondCost,
    this.secondCostType,
    required this.multiCost,
    this.costs,
    this.descriptions,
    required this.limited,
    required this.description,
  });

  // --------------------
  // copyWith
  // --------------------
  Skill copyWith({
    int? id,
    String? name,
    int? cost,
    CostType? costType,
    int? secondCost,
    CostType? secondCostType,
    bool? multiCost,
    List<int>? costs,
    List<String>? descriptions,
    bool? limited,
    String? description,
  }) {
    return Skill(
      id: id ?? this.id,
      name: name ?? this.name,
      cost: cost ?? this.cost,
      costType: costType ?? this.costType,
      secondCost: secondCost ?? this.secondCost,
      secondCostType: secondCostType ?? this.secondCostType,
      multiCost: multiCost ?? this.multiCost,
      costs: costs ?? this.costs,
      descriptions: descriptions ?? this.descriptions,
      limited: limited ?? this.limited,
      description: description ?? this.description,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "cost": cost,
      "costType": costType.name,
      "secondCost": secondCost,
      "secondCostType": secondCostType?.name,
      "multiCost": multiCost,
      "costs": costs,
      "descriptions": descriptions,
      "limited": limited,
      "description": description,
    };
  }

  factory Skill.fromMap(Map<String, dynamic> map) {
    return Skill(
      id: map["id"],
      name: map["name"],
      cost: map["cost"],
      costType: CostType.values.byName(map["costType"]),
      secondCost: map["secondCost"],
      secondCostType: map["secondCostType"] != null
          ? CostType.values.byName(map["secondCostType"])
          : null,
      multiCost: map["multiCost"],
      costs: map["costs"] != null
          ? List<int>.from(map["costs"])
          : null,
      descriptions: map["descriptions"] != null
          ? List<String>.from(map["descriptions"])
          : null,
      limited: map["limited"],
      description: map["description"],
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "cost": cost,
      "costType": costType.name,
      "secondCost": secondCost,
      "secondCostType": secondCostType?.name,
      "multiCost": multiCost,
      "costs": costs,
      "descriptions": descriptions,
      "limited": limited,
      "description": description,
    };
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json["id"],
      name: json["name"],
      cost: json["cost"],
      costType: CostType.values.byName(json["costType"]),
      secondCost: json["secondCost"],
      secondCostType: json["secondCostType"] != null
          ? CostType.values.byName(json["secondCostType"])
          : null,
      multiCost: json["multiCost"],
      costs: json["costs"] != null
          ? List<int>.from(json["costs"])
          : null,
      descriptions: json["descriptions"] != null
          ? List<String>.from(json["descriptions"])
          : null,
      limited: json["limited"],
      description: json["description"],
    );
  }
}

enum Affinities { firearm, explosive, oneHandBlade, twoHandBlade, bow, throwable, none, choiceNonExplosive}

class AgentClass {
  final int id;
  final String name;
  final String quote;
  final List<String> classBonus;
  final List<Affinities> affinities;
  final int muniSlotNumber;
  final List<Skill> freeSkill;
  final String skillNumberReminder;
  final SkillNumberCases skillNumberCases;
  final CostType classType;
  final List<Skill> allSkills;

  const AgentClass({
    required this.id,
    required this.name,
    required this.quote,
    required this.classBonus,
    required this.affinities,
    required this.muniSlotNumber,
    required this.freeSkill,
    required this.skillNumberReminder,
    required this.skillNumberCases,
    required this.classType,
    required this.allSkills,
  });

  // --------------------
  // copyWith
  // --------------------
  AgentClass copyWith({
    int? id,
    String? name,
    String? quote,
    List<String>? classBonus,
    List<Affinities>? affinities,
    int? muniSlotNumber,
    List<Skill>? freeSkill,
    String? skillNumberReminder,
    SkillNumberCases? skillNumberCases,
    CostType? classType,
    List<Skill>? allSkills,
  }) {
    return AgentClass(
      id: id ?? this.id,
      name: name ?? this.name,
      quote: quote ?? this.quote,
      classBonus: classBonus ?? this.classBonus,
      affinities: affinities ?? this.affinities,
      muniSlotNumber: muniSlotNumber ?? this.muniSlotNumber,
      freeSkill: freeSkill ?? this.freeSkill,
      skillNumberReminder: skillNumberReminder ?? this.skillNumberReminder,
      skillNumberCases: skillNumberCases ?? this.skillNumberCases,
      classType: classType ?? this.classType,
      allSkills: allSkills ?? this.allSkills,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "quote": quote,
      "classBonus": classBonus,
      "affinities": affinities.map((a) => a.name).toList(),
      "muniSlotNumber": muniSlotNumber,
      "freeSkill": freeSkill.map((s) => s.toMap()).toList(),
      "skillNumberReminder": skillNumberReminder,
      "skillNumberCases": skillNumberCases.name,
      "classType": classType.name,
      "allSkills": allSkills.map((s) => s.toMap()).toList(),
    };
  }

  factory AgentClass.fromMap(Map<String, dynamic> map) {
    return AgentClass(
      id: map["id"],
      name: map["name"],
      quote: map["quote"],
      classBonus: List<String>.from(map["classBonus"]),
      affinities: (map["affinities"] as List)
          .map((a) => Affinities.values.byName(a))
          .toList(),
      muniSlotNumber: map["muniSlotNumber"],
      freeSkill: (map["freeSkill"] as List)
          .map((s) => Skill.fromMap(s))
          .toList(),
      skillNumberReminder: map["skillNumberReminder"],
      skillNumberCases: SkillNumberCases.values.byName(map["skillNumberCases"]),
      classType: CostType.values.byName(map["classType"]),
      allSkills: (map["allSkills"] as List)
          .map((s) => Skill.fromMap(s))
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
      "quote": quote,
      "classBonus": classBonus,
      "affinities": affinities.map((a) => a.name).toList(),
      "muniSlotNumber": muniSlotNumber,
      "freeSkill": freeSkill.map((s) => s.toJson()).toList(),
      "skillNumberReminder": skillNumberReminder,
      "skillNumberCases": skillNumberCases.name,
      "classType": classType.name,
      "allSkills": allSkills.map((s) => s.toJson()).toList(),
    };
  }

  factory AgentClass.fromJson(Map<String, dynamic> json) {
    return AgentClass(
      id: json["id"],
      name: json["name"],
      quote: json["quote"],
      classBonus: List<String>.from(json["classBonus"]),
      affinities: (json["affinities"] as List)
          .map((a) => Affinities.values.byName(a))
          .toList(),
      muniSlotNumber: json["muniSlotNumber"],
      freeSkill: (json["freeSkill"] as List)
          .map((s) => Skill.fromJson(s))
          .toList(),
      skillNumberReminder: json["skillNumberReminder"],
      skillNumberCases: SkillNumberCases.values.byName(json["skillNumberCases"]),
      classType: CostType.values.byName(json["classType"]),
      allSkills: (json["allSkills"] as List)
          .map((s) => Skill.fromJson(s))
          .toList(),
    );
  }
}

class Race {
  final int id;
  final String name;
  final String description;
  final List<String>? bonuses;
  final List<String>? maluses;
  final List<AgentClass> availableClasses;

  const Race({
    required this.id,
    required this.name,
    required this.description,
    this.bonuses,
    this.maluses,
    required this.availableClasses,
  });

  // --------------------
  // copyWith
  // --------------------
  Race copyWith({
    int? id,
    String? name,
    String? description,
    List<String>? bonuses,
    List<String>? maluses,
    List<AgentClass>? availableClasses,
  }) {
    return Race(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      bonuses: bonuses ?? this.bonuses,
      maluses: maluses ?? this.maluses,
      availableClasses:
          availableClasses ?? this.availableClasses,
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
      "bonuses": bonuses,
      "maluses": maluses,
      "availableClasses":
          availableClasses.map((c) => c.toMap()).toList(),
    };
  }

  factory Race.fromMap(Map<String, dynamic> map) {
    return Race(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      bonuses: map["bonuses"] != null
          ? List<String>.from(map["bonuses"])
          : null,
      maluses: map["maluses"] != null
          ? List<String>.from(map["maluses"])
          : null,
      availableClasses: (map["availableClasses"] as List)
          .map((c) => AgentClass.fromMap(c))
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
      "bonuses": bonuses,
      "maluses": maluses,
      "availableClasses":
          availableClasses.map((c) => c.toJson()).toList(),
    };
  }

  factory Race.fromJson(Map<String, dynamic> json) {
    return Race(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      bonuses: json["bonuses"] != null
          ? List<String>.from(json["bonuses"])
          : null,
      maluses: json["maluses"] != null
          ? List<String>.from(json["maluses"])
          : null,
      availableClasses: (json["availableClasses"] as List)
          .map((c) => AgentClass.fromJson(c))
          .toList(),
    );
  }
}
