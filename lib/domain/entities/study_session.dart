import 'package:hive/hive.dart';

part 'study_session.g.dart';

@HiveType(typeId: 0)
class StudySession extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String query;
  
  @HiveField(2)
  final String response;
  
  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final String? threadId; // لربط الرسائل ببعضها

  @HiveField(5)
  final bool isDeleted; // لسلة المحذوفات

  @HiveField(6)
  final DateTime updatedAt;

  StudySession({
    required this.id,
    required this.query,
    required this.response,
    required this.timestamp,
    this.threadId,
    this.isDeleted = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? timestamp;

  StudySession copyWith({
    String? id,
    String? query,
    String? response,
    DateTime? timestamp,
    DateTime? updatedAt,
    String? threadId,
    bool? isDeleted,
  }) {
    return StudySession(
      id: id ?? this.id,
      query: query ?? this.query,
      response: response ?? this.response,
      timestamp: timestamp ?? this.timestamp,
      updatedAt: updatedAt ?? this.updatedAt,
      threadId: threadId ?? this.threadId,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
