import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Збереження виконаного тренування у Firestore
  Future<void> saveWorkout(Map<String, dynamic> workoutData) async {
    if (_userId == null) return;

    await _db
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .add({
      ...workoutData,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Отримання списку тренувань користувача
  Stream<List<Map<String, dynamic>>> getUserWorkouts() {
    if (_userId == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(_userId)
        .collection('workouts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}
