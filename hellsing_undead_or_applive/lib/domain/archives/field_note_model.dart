class FieldNote {
  final String agentDocId;
  final String agentName;
  final String? agentPicturePath;
  final String content;
  final String date;

  const FieldNote({
    required this.agentDocId,
    required this.agentName,
    this.agentPicturePath,
    required this.content,
    required this.date,
  });

  // --------------------
  // copyWith
  // --------------------
  FieldNote copyWith({
    String? agentDocId,
    String? agentName,
    String? agentPicturePath,
    String? content,
    String? date,
  }) {
    return FieldNote(
      agentDocId: agentDocId ?? this.agentDocId,
      agentName: agentName ?? this.agentName,
      agentPicturePath: agentPicturePath ?? this.agentPicturePath,
      content: content ?? this.content,
      date: date ?? this.date,
    );
  }

  // --------------------
  // Firestore
  // --------------------
  // Note : agentDocId n'est pas stocké dans le document Firestore car il
  // correspond à l'ID du document lui-même.
  Map<String, dynamic> toMap() {
    return {
      "agentName": agentName,
      "agentPicturePath": agentPicturePath,
      "content": content,
      "date": date,
    };
  }

  factory FieldNote.fromMap(String docId, Map<String, dynamic> map) {
    return FieldNote(
      agentDocId: docId,
      agentName: map["agentName"] as String? ?? 'Agent',
      agentPicturePath: map["agentPicturePath"] as String?,
      content: map["content"] as String? ?? '',
      date: map["date"] as String? ?? '03/03/1877',
    );
  }

  // --------------------
  // JSON pur
  // --------------------
  Map<String, dynamic> toJson() {
    return {
      "agentDocId": agentDocId,
      "agentName": agentName,
      "agentPicturePath": agentPicturePath,
      "content": content,
      "date": date,
    };
  }

  factory FieldNote.fromJson(Map<String, dynamic> json) {
    return FieldNote(
      agentDocId: json["agentDocId"] as String? ?? '',
      agentName: json["agentName"] as String? ?? 'Agent',
      agentPicturePath: json["agentPicturePath"] as String?,
      content: json["content"] as String? ?? '',
      date: json["date"] as String? ?? '03/03/1877',
    );
  }
}
