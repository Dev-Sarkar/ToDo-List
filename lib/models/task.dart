import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String title;
  String tag;
  Timestamp? dueDate;
  bool completed;

  Task({
    required this.id,
    required this.title,
    this.tag = 'Inbox',
    this.dueDate,
    this.completed = false,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      tag: map['tag'] ?? 'Inbox',
      dueDate: map['dueDate'] != null ? map['dueDate'] as Timestamp : null,
      completed: map['completed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'tag': tag,
      'dueDate': dueDate,
      'completed': completed,
    };
  }
}
