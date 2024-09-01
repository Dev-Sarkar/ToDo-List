import 'package:cloud_firestore/cloud_firestore.dart';

class CompletedDate {
  String id;
  DateTime date;

  CompletedDate({required this.id, required this.date});

  factory CompletedDate.fromFirestore(Map<String, dynamic> data, String id) {
    return CompletedDate(
      id: id,
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
    };
  }
}
