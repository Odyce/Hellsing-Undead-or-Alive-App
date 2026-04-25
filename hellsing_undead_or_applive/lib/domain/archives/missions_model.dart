import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

enum Difficulty { basse, moyenne, haute, inconnu, tresHaute }

enum CladeName { origins, western, beginning, unNeufTroisZero, arthur, osiris, blackOrchid, pennyDreadful }

class Mission {
  final int id;
  final String title;
  final String? notesForDM;
  final String descriptionIntro;
  final String? descriptionOutro;
  final String? illustrationPath;
  final Difficulty difficulty;
  final CladeName clade;
  final DateTime postedAt;
  final DateTime? playedAt;
  final DateTime? completedAt;
  final List<MissionAgent>? agentInvolved;
  final List<PNJ>? pnjInvolved;
  final List<Monster>? monsterInvolved;
  final int? bounty;
  final int bountyMin;
  final int bountyMax;
  final List<String>? reportPaths;
  final List<MissionAgent>? agentDeceased;
  final bool urgent;

  const Mission({
    required this.id,
    required this.title,
    this.notesForDM,
    required this.descriptionIntro,
    this.descriptionOutro,
    this.illustrationPath,
    required this.difficulty,
    required this.clade,
    required this.postedAt,
    this.playedAt,
    this.completedAt,
    this.agentInvolved,
    this.pnjInvolved,
    this.monsterInvolved,
    this.bounty,
    required this.bountyMin,
    required this.bountyMax,
    this.reportPaths,
    this.agentDeceased,
    required this.urgent,
  });

  // --------------------
  // copyWith
  // --------------------
  Mission copyWith({
    int? id,
    String? title,
    String? notesForDM,
    String? descriptionIntro,
    String? descriptionOutro,
    String? illustrationPath,
    Difficulty? difficulty,
    CladeName? clade,
    DateTime? postedAt,
    DateTime? playedAt,
    DateTime? completedAt,
    List<MissionAgent>? agentInvolved,
    List<PNJ>? pnjInvolved,
    List<Monster>? monsterInvolved,
    int? bounty,
    int? bountyMin,
    int? bountyMax,
    List<String>? reportPaths,
    List<MissionAgent>? agentDeceased,
    bool? urgent,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      notesForDM: notesForDM ?? this.notesForDM,
      descriptionIntro: descriptionIntro ?? this.descriptionIntro,
      descriptionOutro: descriptionOutro ?? this.descriptionOutro,
      illustrationPath: illustrationPath ?? this.illustrationPath,
      difficulty: difficulty ?? this.difficulty,
      clade: clade ?? this.clade,
      postedAt: postedAt ?? this.postedAt,
      playedAt: playedAt ?? this.playedAt,
      completedAt: completedAt ?? this.completedAt,
      agentInvolved: agentInvolved ?? this.agentInvolved,
      pnjInvolved: pnjInvolved ?? this.pnjInvolved,
      monsterInvolved: monsterInvolved ?? this.monsterInvolved,
      bounty: bounty ?? this.bounty,
      bountyMin: bountyMin ?? this.bountyMin,
      bountyMax: bountyMax ?? this.bountyMax,
      reportPaths: reportPaths ?? this.reportPaths,
      agentDeceased: agentDeceased ?? this.agentDeceased,
      urgent: urgent ?? this.urgent,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "notesForDM": notesForDM,
      "descriptionIntro": descriptionIntro,
      "descriptionOutro": descriptionOutro,
      "illustrationPath": illustrationPath,
      "difficulty": difficulty.name,
      "clade": clade.name,
      "postedAt": Timestamp.fromDate(postedAt),
      "playedAt": playedAt != null ? Timestamp.fromDate(playedAt!) : null,
      "completedAt": completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      "agentInvolved": agentInvolved?.map((a) => a.toMap()).toList(),
      "pnjInvolved": pnjInvolved?.map((a) => a.toMap()).toList(),
      "monsterInvolved": monsterInvolved?.map((a) => a.toMap()).toList(),
      "bounty": bounty,
      "bountyMin": bountyMin,
      "bountyMax": bountyMax,
      "reportPaths": reportPaths,
      "agentDeceased": agentDeceased?.map((a) => a.toMap()).toList(),
      "urgent": urgent,
    };
  }

  /// Convertit un champ date Firestore, qu'il soit Timestamp ou String (anciens docs).
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: (map["id"] as num?)?.toInt() ?? 0,
      title: map["title"] as String? ?? '',
      notesForDM: map["notesForDM"] as String?,
      descriptionIntro: map["descriptionIntro"] as String? ?? '',
      descriptionOutro: map["descriptionOutro"] as String?,
      illustrationPath: map["illustrationPath"] as String?,
      difficulty: Difficulty.values.byName(map["difficulty"] as String? ?? 'inconnu'),
      clade: CladeName.values.byName(map["clade"] as String? ?? 'osiris'),
      postedAt: _parseDate(map["postedAt"]) ?? DateTime.now(),
      playedAt: _parseDate(map["playedAt"]),
      completedAt: _parseDate(map["completedAt"]),
      agentInvolved: map["agentInvolved"] != null
          ? (map["agentInvolved"] as List)
              .map((a) => MissionAgent.fromMap(Map<String, dynamic>.from(a as Map)))
              .toList()
          : null,
      pnjInvolved: map["pnjInvolved"] != null
          ? (map["pnjInvolved"] as List).map((a) => PNJ.fromMap(a)).toList()
          : null,
      monsterInvolved: map["monsterInvolved"] != null
          ? (map["monsterInvolved"] as List).map((a) => Monster.fromMap(a)).toList()
          : null,
      bounty: (map["bounty"] as num?)?.toInt(),
      bountyMin: (map["bountyMin"] as num?)?.toInt() ?? (map["bounty"] as num?)?.toInt() ?? 0,
      bountyMax: (map["bountyMax"] as num?)?.toInt() ?? (map["bounty"] as num?)?.toInt() ?? 0,
      reportPaths: map["reportPaths"] != null
          ? List<String>.from(map["reportPaths"])
          : null,
      agentDeceased: map["agentDeceased"] != null
          ? (map["agentDeceased"] as List)
              .map((a) => MissionAgent.fromMap(Map<String, dynamic>.from(a as Map)))
              .toList()
          : null,
      urgent: map["urgent"] as bool? ?? false,
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "notesForDM": notesForDM,
      "descriptionIntro": descriptionIntro,
      "descriptionOutro": descriptionOutro,
      "illustrationPath": illustrationPath,
      "difficulty": difficulty.name,
      "clade": clade.name,
      "postedAt": postedAt.toIso8601String(),
      "playedAt": playedAt?.toIso8601String(),
      "completedAt": completedAt?.toIso8601String(),
      "agentInvolved": agentInvolved?.map((a) => a.toJson()).toList(),
      "pnjInvolved": pnjInvolved?.map((a) => a.toJson()).toList(),
      "monsterInvolved": monsterInvolved?.map((a) => a.toJson()).toList(),
      "bounty": bounty,
      "bountyMin": bountyMin,
      "bountyMax": bountyMax,
      "reportPaths": reportPaths,
      "agentDeceased": agentDeceased?.map((a) => a.toJson()).toList(),
      "urgent": urgent,
    };
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json["id"],
      title: json["title"],
      notesForDM: json["notesForDM"],
      descriptionIntro: json["descriptionIntro"],
      descriptionOutro: json["descriptionOutro"],
      illustrationPath: json["illustrationPath"],
      difficulty: Difficulty.values.byName(json["difficulty"]),
      clade: CladeName.values.byName(json["clade"]),
      postedAt: DateTime.parse(json["postedAt"]),
      playedAt: json["playedAt"] != null ? DateTime.parse(json["playedAt"]) : null,
      completedAt: json["completedAt"] != null ? DateTime.parse(json["completedAt"]) : null,
      agentInvolved: json["agentInvolved"] != null
          ? (json["agentInvolved"] as List)
              .map((a) => MissionAgent.fromJson(Map<String, dynamic>.from(a as Map)))
              .toList()
          : null,
      pnjInvolved: json["pnjInvolved"] != null
          ? (json["pnjInvolved"] as List).map((a) => PNJ.fromJson(a)).toList()
          : null,
      monsterInvolved: json["monsterInvolved"] != null
          ? (json["monsterInvolved"] as List).map((a) => Monster.fromJson(a)).toList()
          : null,
      bounty: json["bounty"],
      bountyMin: json["bountyMin"] ?? json["bounty"] ?? 0,
      bountyMax: json["bountyMax"] ?? json["bounty"] ?? 0,
      reportPaths: json["reportPaths"] != null
          ? List<String>.from(json["reportPaths"])
          : null,
      agentDeceased: json["agentDeceased"] != null
          ? (json["agentDeceased"] as List)
              .map((a) => MissionAgent.fromJson(Map<String, dynamic>.from(a as Map)))
              .toList()
          : null,
      urgent: json["urgent"],
    );
  }
}

class Clade {
  final int id;
  final String name;
  final DateTime begunAt;
  final DateTime? endedAt;
  final List<Mission>? missionsWithin;

  const Clade({
    required this.id,
    required this.name,
    required this.begunAt,
    this.endedAt,
    this.missionsWithin,
  });

  // --------------------
  // copyWith
  // --------------------
  Clade copyWith({
    int? id,
    String? name,
    DateTime? begunAt,
    DateTime? endedAt,
    List<Mission>? missionsWithin,
  }) {
    return Clade(
      id: id ?? this.id,
      name: name ?? this.name,
      begunAt: begunAt ?? this.begunAt,
      endedAt: endedAt ?? this.endedAt,
      missionsWithin: missionsWithin ?? this.missionsWithin,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "name": name,
      "begunAt": begunAt.toIso8601String(),
      "endedAt": endedAt?.toIso8601String(),
      "missionsWithin": missionsWithin?.map((m) => m.toMap()).toList(),
    };
  }

  factory Clade.fromMap(Map<String, dynamic> map) {
    return Clade(
      id: map["id"],
      name: map["name"],
      begunAt: DateTime.parse(map["begunAt"]),
      endedAt: map["endedAt"] != null ? DateTime.parse(map["endedAt"]) : null,
      missionsWithin: map["missionsWithin"] != null
          ? (map["missionsWithin"] as List).map((m) => Mission.fromMap(m)).toList()
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
      "begunAt": begunAt.toIso8601String(),
      "endedAt": endedAt?.toIso8601String(),
      "missionsWithin": missionsWithin?.map((m) => m.toJson()).toList(),
    };
  }

  factory Clade.fromJson(Map<String, dynamic> json) {
    return Clade(
      id: json["id"],
      name: json["name"],
      begunAt: DateTime.parse(json["begunAt"]),
      endedAt: json["endedAt"] != null ? DateTime.parse(json["endedAt"]) : null,
      missionsWithin: json["missionsWithin"] != null
          ? (json["missionsWithin"] as List).map((m) => Mission.fromJson(m)).toList()
          : null,
    );
  }
}
