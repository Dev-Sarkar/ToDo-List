import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/habit.dart';
import '../model/completed_date.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user document reference
  DocumentReference getUserDoc(String userId) {
    return _firestore.collection('profiles').doc(userId);
  }

  // Create or update a habit for a user
  Future<void> createOrUpdateHabit(String userId, Habit habit) async {
    final habitDoc = getUserDoc(userId).collection('habits').doc(habit.id);
    await habitDoc.set(habit.toMap());
  }

  // Retrieve all habits for a user
  Future<List<Habit>> getHabits(String userId) async {
    final habitSnapshot = await getUserDoc(userId).collection('habits').get();
    return habitSnapshot.docs
        .map((doc) => Habit.fromFirestore(doc.data(), doc.id))
        .toList();
  }
/*
  // Add completed date to a habit
  Future<void> addCompletedDate(
      String userId, String habitId, DateTime date) async {
    final completedDateDoc = getUserDoc(userId)
        .collection('habits')
        .doc(habitId)
        .collection('completedDates')
        .doc(date.toIso8601String());

    await completedDateDoc.set({'date': Timestamp.fromDate(date)});
  }
*/

  Future<void> addCompletedDate(
      String userId, String habitId, DateTime date) async {
    final completedDateRef = FirebaseFirestore.instance
        .collection('profiles')
        .doc(userId)
        .collection('habits')
        .doc(habitId)
        .collection('completedDates')
        .doc(date.toIso8601String()); // Use ISO string for unique ID

    await completedDateRef.set({
      'date': Timestamp.fromDate(date), // Store the date
    });
  }

/*
  Future<List<String>> getCompletedDates(String userId, String habitId) async {
    print('User ID: $userId, Habit ID: $habitId');

    final snapshot = await _firestore
        .collection('profiles')  // Use the 'profiles' collection based on your structure
        .doc(userId)
        .collection('habits')
        .doc(habitId)
        .collection('completedDates')
        .get();

    if (snapshot.docs.isEmpty) {
      print('No completed dates found.');
      return [];
    } else {
      // Retrieve the 'date' field, convert it to DateTime, and format as a string
      final dateStrings = snapshot.docs.map((doc) {
        final date = (doc['date'] as Timestamp).toDate();
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }).toList();

      print('Completed dates: $dateStrings');
      return dateStrings;
    }
  }
  */
  // todo new getcompleted dates
  Future<List<DateTime>> getCompletedDates(
      String userId, String habitId) async {
    try {
      // Query the 'completedDates' subcollection for the given habit
      final completedDatesQuery = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(userId)
          .collection('habits')
          .doc(habitId)
          .collection('completedDates')
          .get();

      // Map the documents to a list of DateTime objects
      return completedDatesQuery.docs.map((doc) {
        final data = doc.data();
        final timestamp = data['date'] as Timestamp;
        return timestamp.toDate();
      }).toList();
    } catch (e) {
      // Handle any errors that may occur
      print('Error fetching completed dates: $e');
      return [];
    }
  }

  Future<void> updateHighScore(String userId, String game, int newScore) async {
    try {
      // Get reference to the user's game collection
      final gameCollection = getUserDoc(userId).collection(game);

      // Get the current high score
      final currentHighScoreSnapshot = await gameCollection
          .orderBy('score', descending: true)
          .limit(1)
          .get();

      // Check if the new score is higher than the current high score
      if (currentHighScoreSnapshot.docs.isNotEmpty) {
        final currentHighScore =
            currentHighScoreSnapshot.docs.first['score'] as int;

        // If the new score is higher, delete the old high score
        if (newScore > currentHighScore) {
          // Delete the current high score document
          await currentHighScoreSnapshot.docs.first.reference.delete();

          // Add the new high score as a document
          await gameCollection.add({'score': newScore});
          print('High score updated for game $game: $newScore');
        } else {
          print('New score is not higher than the current high score.');
        }
      } else {
        // If no high score exists, just add the new score
        await gameCollection.add({'score': newScore});
        print('High score updated for game $game: $newScore');
      }
    } catch (e) {
      print('Error updating high score: $e');
    }
  }

  Future<int> getHighScore(String userId, String game) async {
    try {
      // Get the highest score document within the specific game collection
      final highScoreDoc = await getUserDoc(userId)
          .collection(game)
          .orderBy('score', descending: true)
          .limit(1)
          .get();

      if (highScoreDoc.docs.isNotEmpty) {
        // Return the score if it exists
        return highScoreDoc.docs.first['score'] as int;
      } else {
        // Return 0 if no scores are found
        return 0;
      }
    } catch (e) {
      print('Error getting high score: $e');
      return 0;
    }
  }
}
