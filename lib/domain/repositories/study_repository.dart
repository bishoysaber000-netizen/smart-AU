import 'dart:typed_data';
import '../entities/study_session.dart';

abstract class StudyRepository {
  Stream<String> getAIResponseStream(String prompt,
      {List<StudySession> history, Uint8List? fileBytes, String? mimeType});
  Stream<String> getShortSummaryStream(String prompt);
  Future<String> translateResponse(String text, String targetLanguage);
  Future<void> saveSession(StudySession session);
  Future<List<StudySession>> getSessions();
  Stream<List<StudySession>> getCloudSessions();
  Future<void> deleteSession(String id);
  Stream<List<StudySession>> getSessionsStream(String userId);
}
