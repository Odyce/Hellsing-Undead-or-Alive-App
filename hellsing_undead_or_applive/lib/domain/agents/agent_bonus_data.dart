import 'package:cloud_firestore/cloud_firestore.dart';

class MissionRecord {
  final int id;
  final String title;
  final String description;
  final DateTime? completedAt;

  const MissionRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.completedAt,
  });

  // --------------------
  // copyWith
  // --------------------
  MissionRecord copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? completedAt,
  }) {
    return MissionRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "completedAt":
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory MissionRecord.fromMap(Map<String, dynamic> map) {
    return MissionRecord(
      id: map["id"],
      title: map["title"],
      description: map["description"],
      completedAt: map["completedAt"] != null
          ? (map["completedAt"] as Timestamp).toDate()
          : null,
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "completedAt": completedAt?.toIso8601String(),
    };
  }

  factory MissionRecord.fromJson(Map<String, dynamic> json) {
    return MissionRecord(
      id: json["id"],
      title: json["title"],
      description: json["description"],
      completedAt: json["completedAt"] != null
          ? DateTime.parse(json["completedAt"])
          : null,
    );
  }
}

/// Trace des modifications appliquées à un agent lors d'un passage de niveau.
/// Sert à annuler le passage si une mission est retirée a posteriori.
class LevelUpRecord {
  /// Niveau atteint par ce passage (le nouveau niveau, pas l'ancien).
  final int level;

  /// Δ [PV, PE, PM] appliqué sur maxPools.
  final List<int> deltaMaxPools;

  /// Δ [PV, PE, PM] appliqué sur les pools courants au moment du passage.
  final List<int> deltaPools;

  /// Δ [Physique, Mental, Relationnel].
  final List<int> deltaAttributes;

  /// IDs des compétences ajoutées (incl. freeSkills de la classe secondaire au niv. 5).
  final List<int> addedSkillIds;

  /// Δ par index sur classBonuses.
  final List<int> deltaClassBonuses;

  /// Δ par index sur secondClassBonuses (vide si pas de classe secondaire).
  final List<int> deltaSecondClassBonuses;

  /// Δ sur les Points de Contacts.
  final int deltaPc;

  /// Δ sur le powerScore.
  final int deltaPowerScore;

  /// True si ce passage a introduit la classe secondaire (niv. 5).
  final bool addedSecondClass;

  const LevelUpRecord({
    required this.level,
    required this.deltaMaxPools,
    required this.deltaPools,
    required this.deltaAttributes,
    required this.addedSkillIds,
    required this.deltaClassBonuses,
    required this.deltaSecondClassBonuses,
    required this.deltaPc,
    required this.deltaPowerScore,
    required this.addedSecondClass,
  });

  Map<String, dynamic> toMap() => {
        'level': level,
        'deltaMaxPools': deltaMaxPools,
        'deltaPools': deltaPools,
        'deltaAttributes': deltaAttributes,
        'addedSkillIds': addedSkillIds,
        'deltaClassBonuses': deltaClassBonuses,
        'deltaSecondClassBonuses': deltaSecondClassBonuses,
        'deltaPc': deltaPc,
        'deltaPowerScore': deltaPowerScore,
        'addedSecondClass': addedSecondClass,
      };

  factory LevelUpRecord.fromMap(Map<String, dynamic> map) => LevelUpRecord(
        level: map['level'] as int,
        deltaMaxPools: List<int>.from(map['deltaMaxPools'] ?? const [0, 0, 0]),
        deltaPools: List<int>.from(map['deltaPools'] ?? const [0, 0, 0]),
        deltaAttributes:
            List<int>.from(map['deltaAttributes'] ?? const [0, 0, 0]),
        addedSkillIds: List<int>.from(map['addedSkillIds'] ?? const []),
        deltaClassBonuses:
            List<int>.from(map['deltaClassBonuses'] ?? const []),
        deltaSecondClassBonuses:
            List<int>.from(map['deltaSecondClassBonuses'] ?? const []),
        deltaPc: map['deltaPc'] as int? ?? 0,
        deltaPowerScore: map['deltaPowerScore'] as int? ?? 0,
        addedSecondClass: map['addedSecondClass'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => toMap();

  factory LevelUpRecord.fromJson(Map<String, dynamic> json) =>
      LevelUpRecord.fromMap(json);
}

class Contact {
  final String id;
  final String name;
  final String description;
  final int contactPointsValue;

  const Contact({
    required this.id,
    required this.name,
    required this.description,
    required this.contactPointsValue,
  });

  // --------------------
  // copyWith
  // --------------------
  Contact copyWith({
    String? id,
    String? name,
    String? description,
    int? contactPointsValue,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      contactPointsValue:
          contactPointsValue ?? this.contactPointsValue,
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
      "contactPointsValue": contactPointsValue,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map["id"],
      name: map["name"],
      description: map["description"],
      contactPointsValue: map["contactPointsValue"],
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
      "contactPointsValue": contactPointsValue,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json["id"],
      name: json["name"],
      description: json["description"],
      contactPointsValue: json["contactPointsValue"],
    );
  }
}
