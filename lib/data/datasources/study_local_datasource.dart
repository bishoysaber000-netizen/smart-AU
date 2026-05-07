import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/study_session.dart';
import '../../core/constants/constants.dart';

class StudyLocalDataSource {
  Future<void> saveSession(StudySession session) async {
    final box = Hive.box<StudySession>(AppConstants.hiveBoxName);
    await box.put(session.id, session);
  }

  Future<List<StudySession>> getSessions() async {
    final box = Hive.box<StudySession>(AppConstants.hiveBoxName);
    return box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> deleteSession(String id) async {
    final box = Hive.box<StudySession>(AppConstants.hiveBoxName);
    await box.delete(id);
  }
}
