import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CareerProgressService {
  final FirebaseAuth auth = FirebaseAuth.instance;

  /// Fetches all progress documents for the current user.
  Future<Map<String, Map<String, dynamic>>> getFullUserProgress() async {
    final user = auth.currentUser;
    if (user == null) return {};

    final userProgressRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('career_progress');

    final snapshot = await userProgressRef.get();
    final Map<String, Map<String, dynamic>> progressMap = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      progressMap[doc.id] = {
        'completed': data['completed'] ?? false,
        'notes': data['notes'] ?? '',
        'lastUpdated': (data['lastUpdated'] as Timestamp?)?.toDate(),
        'firstAccessed': (data['firstAccessed'] as Timestamp?)?.toDate(),
      };
    }

    return progressMap;
  }

  /// Updates one or more fields (completed, notes).
  Future<void> updateUserProgress({
    required String step,
    bool? isCompleted,
    String? notes,
  }) async {
    final user = auth.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('career_progress')
        .doc(step);

    final doc = await docRef.get();
    final updates = {
      if (isCompleted != null) 'completed': isCompleted,
      if (notes != null) 'notes': notes,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    // On first write, stamp when they first accessed this step
    if (!doc.exists) {
      updates['firstAccessed'] = FieldValue.serverTimestamp();
    }

    await docRef.set(updates, SetOptions(merge: true));
  }
}
