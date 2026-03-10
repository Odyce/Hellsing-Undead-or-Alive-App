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
