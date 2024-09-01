import 'package:cloud_firestore/cloud_firestore.dart';

class Habit {
  String id;
  String name;
  DateTime createdAt;

  Habit({required this.id, required this.name, required this.createdAt});

  factory Habit.fromFirestore(Map<String, dynamic> data, String id) {
    return Habit(
      id: id,
      name: data['name'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdAt': createdAt,
    };
  }
}
