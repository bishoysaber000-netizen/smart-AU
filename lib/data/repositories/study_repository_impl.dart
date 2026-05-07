import 'dart:typed_data';
import '../../domain/entities/study_session.dart';
import '../../domain/repositories/study_repository.dart';
import '../datasources/ai_remote_datasource.dart';
import '../datasources/study_local_datasource.dart';
import '../datasources/firebase_datasource.dart';

class StudyRepositoryImpl implements StudyRepository {
  final AIRemoteDataSource remoteDataSource;
  final StudyLocalDataSource localDataSource;
  final FirebaseDataSource firebaseDataSource;

  StudyRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.firebaseDataSource,
  });

  @override
  Stream<String> getAIResponseStream(
    String prompt, {
    List<StudySession> history = const [],
    Uint8List? fileBytes,
    String? mimeType,
  }) {
    return remoteDataSource.fetchAIResponseStream(
      prompt,
      history: history,
      fileBytes: fileBytes,
      mimeType: mimeType,
    );
  }

  @override
  Stream<String> getShortSummaryStream(String prompt) {
    return remoteDataSource.fetchShortSummaryStream(prompt);
  }

  @override
  Future<String> translateResponse(String text, String targetLanguage) async {
    return await remoteDataSource.translateResponse(text, targetLanguage);
  }

  @override
  Future<void> saveSession(StudySession session) async {
    await localDataSource.saveSession(session);
    await firebaseDataSource.saveSessionToCloud(session);
  }

  @override
  Future<List<StudySession>> getSessions() async {
    return await localDataSource.getSessions();
  }

  @override
  Stream<List<StudySession>> getCloudSessions() {
    return firebaseDataSource.getCloudSessions();
  }

  @override
  Future<void> deleteSession(String id) async {
    await localDataSource.deleteSession(id);
    await firebaseDataSource.deleteCloudSession(id);
  }

  @override
  Stream<List<StudySession>> getSessionsStream(String userId) {
    return firebaseDataSource.getSessionsStream(userId);
  }
}
