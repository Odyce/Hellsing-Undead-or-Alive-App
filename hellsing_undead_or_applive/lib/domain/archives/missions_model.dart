import 'package:hellsing_undead_or_applive/domain/models.dart';

enum Difficulty { basse, moyenne, haute, inconnu }

enum CladName { osiris, blackLotus, pennyDreadful }

class Mission {
  final int id;
  final String title;
  final String? notesForDM;
  final String descriptionIntro;
  final String? descriptionOutro;
  final String? illustrationPath;
  final Difficulty difficulty;
  final CladName clad;
  final DateTime postedAt;
  final DateTime? playedAt;
  final DateTime? completedAt;
  final List<Agent>? agentInvolved;
  final List<PNJ>? pnjInvolved;
  final List<Monster>? monsterInvolved;
  final int bounty;
  final List<String>? reportPaths;
  final List<Agent>? agentDeceased;
  final bool urgent;

  const Mission({
    required this.id,
    required this.title,
    this.notesForDM,
    required this.descriptionIntro,
    this.descriptionOutro,
    this.illustrationPath,
    required this.difficulty,
    required this.clad,
    required this.postedAt,
    this.playedAt,
    this.completedAt,
    this.agentInvolved,
    this.pnjInvolved,
    this.monsterInvolved,
    required this.bounty,
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
    CladName? clad,
    DateTime? postedAt,
    DateTime? playedAt,
    DateTime? completedAt,
    List<Agent>? agentInvolved,
    List<PNJ>? pnjInvolved,
    List<Monster>? monsterInvolved,
    int? bounty,
    List<String>? reportPaths,
    List<Agent>? agentDeceased,
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
      clad: clad ?? this.clad,
      postedAt: postedAt ?? this.postedAt,
      playedAt: playedAt ?? this.playedAt,
      completedAt: completedAt ?? this.completedAt,
      agentInvolved: agentInvolved ?? this.agentInvolved,
      pnjInvolved: pnjInvolved ?? this.pnjInvolved,
      monsterInvolved: monsterInvolved ?? this.monsterInvolved,
      bounty: bounty ?? this.bounty,
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
      "clad": clad.name,
      "postedAt": postedAt.toIso8601String(),
      "playedAt": playedAt?.toIso8601String(),
      "completedAt": completedAt?.toIso8601String(),
      "agentInvolved": agentInvolved?.map((a) => a.toMap()).toList(),
      "pnjInvolved": pnjInvolved?.map((a) => a.toMap()).toList(),
      "monsterInvolved": monsterInvolved?.map((a) => a.toMap()).toList(),
      "bounty": bounty,
      "reportPaths": reportPaths,
      "agentDeceased": agentDeceased?.map((a) => a.toMap()).toList(),
      "urgent": urgent,
    };
  }

  factory Mission.fromMap(Map<String, dynamic> map) {
    return Mission(
      id: map["id"],
      title: map["title"],
      notesForDM: map["notesForDM"],
      descriptionIntro: map["descriptionIntro"],
      descriptionOutro: map["descriptionOutro"],
      illustrationPath: map["illustrationPath"],
      difficulty: Difficulty.values.byName(map["difficulty"]),
      clad: CladName.values.byName(map["clad"]),
      postedAt: DateTime.parse(map["postedAt"]),
      playedAt: map["playedAt"] != null ? DateTime.parse(map["playedAt"]) : null,
      completedAt: map["completedAt"] != null ? DateTime.parse(map["completedAt"]) : null,
      agentInvolved: map["agentInvolved"] != null
          ? (map["agentInvolved"] as List).map((a) => Agent.fromMap(a)).toList()
          : null,
      pnjInvolved: map["pnjInvolved"] != null
          ? (map["pnjInvolved"] as List).map((a) => PNJ.fromMap(a)).toList()
          : null,
      monsterInvolved: map["monsterInvolved"] != null
          ? (map["monsterInvolved"] as List).map((a) => Monster.fromMap(a)).toList()
          : null,
      bounty: map["bounty"],
      reportPaths: map["reportPaths"] != null
          ? List<String>.from(map["reportPaths"])
          : null,
      agentDeceased: map["agentDeceased"] != null
          ? (map["agentDeceased"] as List).map((a) => Agent.fromMap(a)).toList()
          : null,
      urgent: map["urgent"],
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
      "clad": clad.name,
      "postedAt": postedAt.toIso8601String(),
      "playedAt": playedAt?.toIso8601String(),
      "completedAt": completedAt?.toIso8601String(),
      "agentInvolved": agentInvolved?.map((a) => a.toJson()).toList(),
      "pnjInvolved": pnjInvolved?.map((a) => a.toJson()).toList(),
      "monsterInvolved": monsterInvolved?.map((a) => a.toJson()).toList(),
      "bounty": bounty,
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
      clad: CladName.values.byName(json["clad"]),
      postedAt: DateTime.parse(json["postedAt"]),
      playedAt: json["playedAt"] != null ? DateTime.parse(json["playedAt"]) : null,
      completedAt: json["completedAt"] != null ? DateTime.parse(json["completedAt"]) : null,
      agentInvolved: json["agentInvolved"] != null
          ? (json["agentInvolved"] as List).map((a) => Agent.fromJson(a)).toList()
          : null,
      pnjInvolved: json["pnjInvolved"] != null
          ? (json["pnjInvolved"] as List).map((a) => PNJ.fromJson(a)).toList()
          : null,
      monsterInvolved: json["monsterInvolved"] != null
          ? (json["monsterInvolved"] as List).map((a) => Monster.fromJson(a)).toList()
          : null,
      bounty: json["bounty"],
      reportPaths: json["reportPaths"] != null
          ? List<String>.from(json["reportPaths"])
          : null,
      agentDeceased: json["agentDeceased"] != null
          ? (json["agentDeceased"] as List).map((a) => Agent.fromJson(a)).toList()
          : null,
      urgent: json["urgent"],
    );
  }
}

class Clad {
  final int id;
  final String name;
  final DateTime begunAt;
  final DateTime? endedAt;
  final List<Mission>? missionsWithin;

  const Clad({
    required this.id,
    required this.name,
    required this.begunAt,
    this.endedAt,
    this.missionsWithin,
  });

  // --------------------
  // copyWith
  // --------------------
  Clad copyWith({
    int? id,
    String? name,
    DateTime? begunAt,
    DateTime? endedAt,
    List<Mission>? missionsWithin,
  }) {
    return Clad(
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

  factory Clad.fromMap(Map<String, dynamic> map) {
    return Clad(
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

  factory Clad.fromJson(Map<String, dynamic> json) {
    return Clad(
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
