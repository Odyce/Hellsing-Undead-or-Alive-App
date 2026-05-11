import 'package:cloud_firestore/cloud_firestore.dart';

/// Une page du Journal in-universe.
///
/// Triée par [date] puis [pageNumber] dans la chronologie. Le numéro de page
/// permet de distinguer plusieurs entrées le même jour ; il est affiché dans
/// la chronologie uniquement quand au moins deux entrées partagent la date.
class JournalEntry {
  final int id;
  final String imageUrl;
  final DateTime date;
  final int pageNumber;
  final DateTime createdAt;

  const JournalEntry({
    required this.id,
    required this.imageUrl,
    required this.date,
    required this.pageNumber,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'imageUrl': imageUrl,
        'date': Timestamp.fromDate(date),
        'pageNumber': pageNumber,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.parse(v);
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return JournalEntry(
      id: (map['id'] as num).toInt(),
      imageUrl: map['imageUrl'] as String,
      date: parseDate(map['date']),
      pageNumber: (map['pageNumber'] as num).toInt(),
      createdAt: parseDate(map['createdAt']),
    );
  }
}
