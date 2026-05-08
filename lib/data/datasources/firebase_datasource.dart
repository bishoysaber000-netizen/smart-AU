import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../domain/entities/study_session.dart';

class FirebaseDataSource {
  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (e) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      return null;
    }
  }

  bool get _isInitialized {
    return Firebase.apps.isNotEmpty;
  }

  Future<void> saveSessionToCloud(StudySession session) async {
    if (!_isInitialized) return;

    final auth = _auth;
    final firestore = _firestore;

    final user = auth?.currentUser;
    if (user == null || firestore == null) return;

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(session.id)
        .set({
      'id': session.id,
      'query': session.query,
      'response': session.response,
      'timestamp': Timestamp.fromDate(session.timestamp),
      'threadId': session.threadId,
      'isDeleted': session.isDeleted,
      'updatedAt': FieldValue
          .serverTimestamp(), // Use server timestamp for reliable merging
    });
  }

  Stream<List<StudySession>> getCloudSessions() {
    if (!_isInitialized) return Stream.value([]);

    final auth = _auth;
    final firestore = _firestore;

    final user = auth?.currentUser;
    if (user == null || firestore == null) return Stream.value([]);

    return firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return StudySession(
                id: doc.id,
                query: data['query'] ?? '',
                response: data['response'] ?? '',
                timestamp: (data['timestamp'] as Timestamp).toDate(),
                updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
                threadId: data['threadId'],
                isDeleted: data['isDeleted'] ?? false,
              );
            }).toList());
  }

  Future<void> deleteCloudSession(String id) async {
    if (!_isInitialized) return;

    final auth = _auth;
    final firestore = _firestore;

    final user = auth?.currentUser;
    if (user == null || firestore == null) return;

    await firestore
        .collection('users')
        .doc(user.uid)
        .collection('sessions')
        .doc(id)
        .delete();
  }

  Stream<List<StudySession>> getSessionsStream(String userId) {
    final firestore = _firestore;
    if (firestore == null) return Stream.value([]);

    return firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return StudySession(
          id: doc.id,
          query: data['query'] ?? '',
          response: data['response'] ?? '',
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
          threadId: data['threadId'],
          isDeleted: data['isDeleted'] ?? false,
        );
      }).toList();
    });
  }
}
