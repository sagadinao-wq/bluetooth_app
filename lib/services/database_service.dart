import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  // Ленивые геттеры защищают от вызова Firestore до полной инициализации Firebase
  FirebaseFirestore get _db => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  // Получение UID текущего пользователя
  String? get currentUserId => _auth.currentUser?.uid;

  // Сохранение тренировки в Firestore
  Future<void> saveWorkout(Map<String, dynamic> workoutData) async {
    final uid = currentUserId;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('workouts')
        .add(workoutData);
  }

  // Получение списка тренировок пользователя в реальном времени
  Stream<List<Map<String, dynamic>>> getUserWorkouts() {
    final uid = currentUserId;
    if (uid == null) return const Stream.empty();

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
