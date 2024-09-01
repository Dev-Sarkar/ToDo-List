import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile.dart';
import '../models/task.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get profiles from Firestore
  Stream<List<Profile>> getProfiles() {
    return _db.collection('profiles').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Profile.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  // Add a new profile to Firestore
  Future<void> addProfile(Profile profile) {
    return _db.collection('profiles').add(profile.toMap());
  }

  // Get tasks for a  profile
  Stream<List<Task>> getTasksForProfile(String profileId) {
    return _db
        .collection('profiles')
        .doc(profileId)
        .collection('tasks')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  // Add a new task to a specific profile
  Future<void> addTaskToProfile(String profileId, Task task) {
    return _db
        .collection('profiles')
        .doc(profileId)
        .collection('tasks')
        .add(task.toMap());
  }

  // Update a task in Firestore
  Future<void> updateTask(String profileId, Task task) {
    return _db
        .collection('profiles')
        .doc(profileId)
        .collection('tasks')
        .doc(task.id)
        .update(task.toMap());
  }

  // Delete a task from Firestore
  Future<void> deleteTask(String profileId, String taskId) {
    return _db
        .collection('profiles')
        .doc(profileId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  Stream<List<String>> getDistinctTags(String profileId) {
    try {
      CollectionReference taskCollection =
          _db.collection('profiles').doc(profileId).collection('tasks');

      return taskCollection.snapshots().map((snapshot) {
        Set<String> distinctTags = {};

        for (var doc in snapshot.docs) {
          String tag = doc['tag'] as String;
          distinctTags.add(tag);
        }

        List<String> tags = distinctTags.toList()..sort();
        tags.insert(0, 'Show All');
        return tags;
      });
    } catch (e) {
      print("Error getting tags: $e");
      return Stream.error("Error getting tags");
    }
  }

  Stream<List<Task>> getTasksByTag(String profileId, String tag) {
    return _db
        .collection('profiles')
        .doc(profileId)
        .collection('tasks')
        .where('tag', isEqualTo: tag)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Task.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
    });
  }

  // Method to increase XP for a user profile
  Future<void> xpIncrease(String profileId, int xp) async {
    try {
      // Reference the user's profile document
      DocumentReference profileDoc = _db.collection('users').doc(profileId);

      // Use a transaction to safely increment XP
      await _db.runTransaction((transaction) async {
        // Fetch the current document snapshot
        DocumentSnapshot snapshot = await transaction.get(profileDoc);

        if (snapshot.exists) {
          // Get the current XP value (default to 0 if not present)
          int currentXP = snapshot.get('xp') ?? 0;

          // Increment XP
          transaction.update(profileDoc, {'xp': currentXP + xp});
        }
      });

      print("XP successfully increased by $xp for profile: $profileId");
    } catch (e) {
      print("Failed to increase XP: $e");
      throw Exception("Error updating XP: $e");
    }
  }
}
