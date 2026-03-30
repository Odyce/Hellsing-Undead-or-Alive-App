import 'package:hellsing_undead_or_applive/domain/models.dart';

class Agent {
  final String id;
  final String name;
  final String background;
  final String state;
  final String note;
  final String? profilPicturePath;

  final List<int> attributes; // Dans l'ordre Physique, puis Mental, puis Relationnel
  final List<int> pools; // Dans l'ordre PV, puis PE, puis PM
  final List<int> maxPools; // Dans l'ordre PV max, puis PE max, puis PM max

  final Race race;
  final int? powerScore;
  final AgentClass agentClass;
  final AgentClass? secondClass;
  final List<int> classBonuses;
  final List<int> secondClassBonuses;
  final List<Skill> skills;

  final List<BagSlot> bagSlots;
  final List<BankSlot> bankSlots;
  final List<MuniSlot> muniSlots;
  final List<WeaponSlot> weaponSlots;

  final int money;
  final List<MissionRecord> missions;
  final int level;

  final int pc;
  final List<Contact> contacts;

  final bool validated;

  const Agent({
    required this.id,
    required this.name,
    required this.background,
    required this.state,
    required this.note,
    this.profilPicturePath,
    required this.attributes,
    required this.pools,
    required this.maxPools,
    required this.race,
    this.powerScore,
    required this.agentClass,
    this.secondClass,
    required this.classBonuses,
    this.secondClassBonuses = const [],
    required this.skills,
    required this.bagSlots,
    required this.bankSlots,
    required this.muniSlots,
    required this.weaponSlots,
    required this.money,
    required this.missions,
    required this.level,
    required this.pc,
    required this.contacts,
    this.validated = false,
  });

  // --------------------
  // copyWith
  // --------------------
  Agent copyWith({
    String? id,
    String? name,
    String? background,
    String? state,
    String? note,
    String? profilPicturePath,
    List<int>? attributes,
    List<int>? pools,
    List<int>? maxPools,
    Race? race,
    int? powerScore,
    AgentClass? agentClass,
    AgentClass? secondClass,
    List<int>? classBonuses,
    List<int>? secondClassBonuses,
    List<Skill>? skills,
    List<BagSlot>? bagSlots,
    List<BankSlot>? bankSlots,
    List<MuniSlot>? muniSlots,
    List<WeaponSlot>? weaponSlots,
    int? money,
    List<MissionRecord>? missions,
    int? level,
    int? pc,
    List<Contact>? contacts,
    bool? validated,
  }) {
    return Agent(
      id: id ?? this.id,
      name: name ?? this.name,
      background: background ?? this.background,
      state: state ?? this.state,
      note: note ?? this.note,
      profilPicturePath: profilPicturePath ?? this.profilPicturePath,
      attributes: attributes ?? this.attributes,
      pools: pools ?? this.pools,
      maxPools: maxPools ?? this.maxPools,
      race: race ?? this.race,
      powerScore: powerScore ?? this.powerScore,
      agentClass: agentClass ?? this.agentClass,
      secondClass: secondClass ?? this.secondClass,
      classBonuses: classBonuses ?? this.classBonuses,
      secondClassBonuses: secondClassBonuses ?? this.secondClassBonuses,
      skills: skills ?? this.skills,
      bagSlots: bagSlots ?? this.bagSlots,
      bankSlots: bankSlots ?? this.bankSlots,
      muniSlots: muniSlots ?? this.muniSlots,
      weaponSlots: weaponSlots ?? this.weaponSlots,
      money: money ?? this.money,
      missions: missions ?? this.missions,
      level: level ?? this.level,
      pc: pc ?? this.pc,
      contacts: contacts ?? this.contacts,
      validated: validated ?? this.validated,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "background": background,
      "state": state,
      "note": note,
      "profilPicturePath": profilPicturePath,

      "attributes": attributes,
      "pools": pools,
      "maxPools": maxPools,

      "race": race.toMap(),
      "powerScore": powerScore,
      "agentClass": agentClass.toMap(),
      "secondClass": secondClass?.toMap(),
      "classBonuses": classBonuses,
      "secondClassBonuses": secondClassBonuses,
      "skills": skills.map((s) => s.toMap()).toList(),

      "bagSlots": bagSlots.map((b) => b.toMap()).toList(),
      "bankSlots": bankSlots.map((b) => b.toMap()).toList(),
      "muniSlots": muniSlots.map((m) => m.toMap()).toList(),
      "weaponSlots": weaponSlots.map((w) => w.toMap()).toList(),

      "money": money,
      "missions": missions.map((m) => m.toMap()).toList(),
      "level": level,

      "pc": pc,
      "contacts": contacts.map((c) => c.toMap()).toList(),
      "validated": validated,
    };
  }

  factory Agent.fromMap(Map<String, dynamic> map) {
    return Agent(
      id: map["id"],
      name: map["name"],
      background: map["background"],
      state: map["state"],
      note: map["note"],
      profilPicturePath: map["profilPicturePath"],

      attributes: List<int>.from(map["attributes"]),
      pools: List<int>.from(map["pools"]),
      maxPools: List<int>.from(map["maxPools"]),

      race: Race.fromMap(map["race"]),
      powerScore: map["powerScore"],
      agentClass: AgentClass.fromMap(map["agentClass"]),
      secondClass: map["secondClass"] != null
          ? AgentClass.fromMap(map["secondClass"])
          : null,
      classBonuses: List<int>.from(map["classBonuses"]),
      secondClassBonuses: map["secondClassBonuses"] != null
          ? List<int>.from(map["secondClassBonuses"])
          : const [],
      skills: (map["skills"] as List)
          .map((s) => Skill.fromMap(s))
          .toList(),

      bagSlots: (map["bagSlots"] as List)
          .map((b) => BagSlot.fromMap(b))
          .toList(),
      bankSlots: (map["bankSlots"] as List)
          .map((b) => BankSlot.fromMap(b))
          .toList(),
      muniSlots: (map["muniSlots"] as List)
          .map((m) => MuniSlot.fromMap(m))
          .toList(),
      weaponSlots: (map["weaponSlots"] as List)
          .map((w) => WeaponSlot.fromMap(w))
          .toList(),

      money: map["money"],
      missions: (map["missions"] as List)
          .map((m) => MissionRecord.fromMap(m))
          .toList(),
      level: map["level"],

      pc: map["pc"],
      contacts: (map["contacts"] as List)
          .map((c) => Contact.fromMap(c))
          .toList(),
      validated: map["validated"] ?? false,
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "background": background,
      "state": state,
      "note": note,
      "profilPicturePath": profilPicturePath,

      "attributes": attributes,
      "pools": pools,
      "maxPools": maxPools,

      "race": race.toJson(),
      "powerScore": powerScore,
      "agentClass": agentClass.toJson(),
      "secondClass": secondClass?.toJson(),
      "classBonuses": classBonuses,
      "secondClassBonuses": secondClassBonuses,
      "skills": skills.map((s) => s.toJson()).toList(),

      "bagSlots": bagSlots.map((b) => b.toJson()).toList(),
      "bankSlots": bankSlots.map((b) => b.toJson()).toList(),
      "muniSlots": muniSlots.map((m) => m.toJson()).toList(),
      "weaponSlots": weaponSlots.map((w) => w.toJson()).toList(),

      "money": money,
      "missions": missions.map((m) => m.toJson()).toList(),
      "level": level,

      "pc": pc,
      "contacts": contacts.map((c) => c.toJson()).toList(),
      "validated": validated,
    };
  }

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json["id"],
      name: json["name"],
      background: json["background"],
      state: json["state"],
      note: json["note"],
      profilPicturePath: json["profilPicturePath"],

      attributes: List<int>.from(json["attributes"]),
      pools: List<int>.from(json["pools"]),
      maxPools: List<int>.from(json["maxPools"]),

      race: Race.fromJson(json["race"]),
      powerScore: json["powerScore"],
      agentClass: AgentClass.fromJson(json["agentClass"]),
      secondClass: json["secondClass"] != null
          ? AgentClass.fromJson(json["secondClass"])
          : null,
      classBonuses: List<int>.from(json["classBonuses"]),
      secondClassBonuses: json["secondClassBonuses"] != null
          ? List<int>.from(json["secondClassBonuses"])
          : const [],
      skills: (json["skills"] as List)
          .map((s) => Skill.fromJson(s))
          .toList(),

      bagSlots: (json["bagSlots"] as List)
          .map((b) => BagSlot.fromJson(b))
          .toList(),
      bankSlots: (json["bankSlots"] as List)
          .map((b) => BankSlot.fromJson(b))
          .toList(),
      muniSlots: (json["muniSlots"] as List)
          .map((m) => MuniSlot.fromJson(m))
          .toList(),
      weaponSlots: (json["weaponSlots"] as List)
          .map((w) => WeaponSlot.fromJson(w))
          .toList(),

      money: json["money"],
      missions: (json["missions"] as List)
          .map((m) => MissionRecord.fromJson(m))
          .toList(),
      level: json["level"],

      pc: json["pc"],
      contacts: (json["contacts"] as List)
          .map((c) => Contact.fromJson(c))
          .toList(),
      validated: json["validated"] ?? false,
    );
  }
}
