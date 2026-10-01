import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  // Безопасное получение экземпляров
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Получение UID с защитой
  String? get currentUserId {
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  // Сохранение тренировки
  Future<void> saveWorkout(Map<String, dynamic> workoutData) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .add(workoutData);
  }

  // Получение списка тренировок
  Stream<List<Map<String, dynamic>>> getUserWorkouts() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}
