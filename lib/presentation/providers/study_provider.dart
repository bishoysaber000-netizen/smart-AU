import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/study_session.dart';
import '../../domain/repositories/study_repository.dart';
import '../../data/repositories/study_repository_impl.dart';
import '../../data/datasources/ai_remote_datasource.dart';
import '../../data/datasources/study_local_datasource.dart';
import '../../data/datasources/firebase_datasource.dart';

class StudyState {
  final List<StudySession> sessions;
  final bool isLoading;
  final String? error;
  final String currentStreamingResponse;
  final String? currentThreadId;
  final bool isTrashMode;

  StudyState({
    this.sessions = const [],
    this.isLoading = false,
    this.error,
    this.currentStreamingResponse = '',
    this.currentThreadId,
    this.isTrashMode = false,
  });

  StudyState copyWith({
    List<StudySession>? sessions,
    bool? isLoading,
    String? error,
    String? currentStreamingResponse,
    String? Function()? currentThreadId,
    bool? isTrashMode,
  }) {
    return StudyState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentStreamingResponse:
          currentStreamingResponse ?? this.currentStreamingResponse,
      currentThreadId:
          currentThreadId != null ? currentThreadId() : this.currentThreadId,
      isTrashMode: isTrashMode ?? this.isTrashMode,
    );
  }
}

class StudyNotifier extends StateNotifier<StudyState> {
  final StudyRepository _repository;
  StreamSubscription? _sessionsSubscription;
  StreamSubscription? _authSubscription;

  StudyNotifier(this._repository) : super(StudyState()) {
    _listenToAuthChanges();
  }

  String? _lastUserId;

  void _listenToAuthChanges() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        if (_lastUserId != user.uid) {
          _lastUserId = user.uid;
          syncData();
        }
      } else {
        _lastUserId = null;
        _sessionsSubscription?.cancel();
        state = StudyState();
      }
    });
  }

  Future<void> syncData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _sessionsSubscription?.cancel();

    _sessionsSubscription =
        _repository.getSessionsStream(user.uid).listen((cloudSessions) {
      final Map<String, StudySession> mergedMap = {};

      // 1. إضافة كل الرسائل الحالية من الـ State (المحلية)
      for (var s in state.sessions) {
        mergedMap[s.id] = s;
      }

      // 2. دمج رسائل السحاب: إذا كانت أحدث (updatedAt) أو غير موجودة محلياً، نعتمدها
      for (var cloudS in cloudSessions) {
        if (!mergedMap.containsKey(cloudS.id) ||
            cloudS.updatedAt.isAfter(mergedMap[cloudS.id]!.updatedAt)) {
          mergedMap[cloudS.id] = cloudS;
        }
      }

      final List<StudySession> finalSessions = mergedMap.values.toList();
      finalSessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      state = state.copyWith(sessions: finalSessions);

      // التنظيف التلقائي لسلة المحذوفات (30 يوم)
      _cleanupExpiredTrash();
    });
  }

  void _cleanupExpiredTrash() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // تجميع الـ threadIds التي يجب مسحها بالكامل
    final Set<String> threadsToDelete = {};

    for (var s in state.sessions) {
      if (s.isDeleted && s.updatedAt.isBefore(thirtyDaysAgo)) {
        threadsToDelete.add(s.threadId ?? s.id);
      }
    }

    for (var threadId in threadsToDelete) {
      deleteThreadPermanently(threadId);
    }
  }

  @override
  void dispose() {
    _sessionsSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadSessions() async {
    // التحديث أصبح تلقائياً عبر Stream في _initAutoRefresh
  }

  void setCurrentThread(String? threadId) {
    state = state.copyWith(currentThreadId: () => threadId);
  }

  void toggleTrashMode(bool enabled) {
    state = state.copyWith(isTrashMode: enabled);
  }

  Future<void> askAI(String query,
      {String? threadId, Uint8List? fileBytes, String? mimeType}) async {
    final activeThreadId =
        threadId ?? state.currentThreadId ?? const Uuid().v4();
    final sessionId = const Uuid().v4();

    // 1. أضف الرسالة فوراً للقائمة مع رد فارغ
    final newSession = StudySession(
      id: sessionId,
      query: query,
      response: '',
      timestamp: DateTime.now(),
      threadId: activeThreadId,
    );

    state = state.copyWith(
      sessions: [newSession, ...state.sessions],
      isLoading: true,
      error: null,
      currentThreadId: () => activeThreadId,
    );

    try {
      final history = state.sessions
          .where((s) =>
              s.threadId == activeThreadId && !s.isDeleted && s.id != sessionId)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      String fullResponse = '';
      final stream = _repository.getAIResponseStream(
        query,
        history: history,
        fileBytes: fileBytes,
        mimeType: mimeType,
      );

      await for (final chunk in stream) {
        fullResponse = chunk;
        // تحديث نفس الرسالة في القائمة تدريجياً
        final updatedSessions = state.sessions.map((s) {
          if (s.id == sessionId) return s.copyWith(response: fullResponse);
          return s;
        }).toList();
        state = state.copyWith(
            sessions: updatedSessions, currentStreamingResponse: fullResponse);
      }

      // 2. حفظ النتيجة النهائية
      final finalSession = state.sessions.firstWhere((s) => s.id == sessionId);
      await _repository.saveSession(finalSession);

      state = state.copyWith(isLoading: false, currentStreamingResponse: '');
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> askAISummary(String query, {String? threadId}) async {
    final activeThreadId =
        threadId ?? state.currentThreadId ?? const Uuid().v4();
    final sessionId = const Uuid().v4();

    final newSession = StudySession(
      id: sessionId,
      query: query,
      response: '',
      timestamp: DateTime.now(),
      threadId: activeThreadId,
    );

    state = state.copyWith(
      sessions: [newSession, ...state.sessions],
      isLoading: true,
      error: null,
      currentThreadId: () => activeThreadId,
    );

    try {
      String fullResponse = '';
      final stream = _repository.getShortSummaryStream(query);

      await for (final chunk in stream) {
        fullResponse = chunk;
        final updatedSessions = state.sessions.map((s) {
          if (s.id == sessionId) return s.copyWith(response: fullResponse);
          return s;
        }).toList();
        state = state.copyWith(
            sessions: updatedSessions, currentStreamingResponse: fullResponse);
      }

      final finalSession = state.sessions.firstWhere((s) => s.id == sessionId);
      await _repository.saveSession(finalSession);

      state = state.copyWith(isLoading: false, currentStreamingResponse: '');
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> moveToTrash(String sessionId) async {
    final session = state.sessions.firstWhere((s) => s.id == sessionId);
    final threadId = session.threadId ?? session.id;

    // تحديث الواجهة فوراً
    final updatedSessions = state.sessions.map((s) {
      if ((s.threadId ?? s.id) == threadId) return s.copyWith(isDeleted: true);
      return s;
    }).toList();
    state = state.copyWith(sessions: updatedSessions);

    // حفظ في Firebase في الخلفية
    final threadSessions =
        state.sessions.where((s) => (s.threadId ?? s.id) == threadId).toList();
    for (var s in threadSessions) {
      await _repository.saveSession(s);
    }
  }

  Future<void> restoreFromThread(String threadId) async {
    // تحديث الواجهة فوراً
    final updatedSessions = state.sessions.map((s) {
      if ((s.threadId ?? s.id) == threadId) return s.copyWith(isDeleted: false);
      return s;
    }).toList();
    state = state.copyWith(sessions: updatedSessions);

    final threadSessions =
        state.sessions.where((s) => (s.threadId ?? s.id) == threadId).toList();
    for (var session in threadSessions) {
      await _repository.saveSession(session);
    }
  }

  Future<void> deleteThreadPermanently(String threadId) async {
    final threadSessions =
        state.sessions.where((s) => (s.threadId ?? s.id) == threadId).toList();

    // تحديث الواجهة فوراً
    final updatedSessions =
        state.sessions.where((s) => (s.threadId ?? s.id) != threadId).toList();
    state = state.copyWith(sessions: updatedSessions);

    for (var session in threadSessions) {
      await _repository.deleteSession(session.id);
    }
  }

  Future<void> clearAllTrash() async {
    final trashThreadIds = state.sessions
        .where((s) => s.isDeleted)
        .map((s) => s.threadId ?? s.id)
        .toSet();

    for (var threadId in trashThreadIds) {
      await deleteThreadPermanently(threadId);
    }
  }

  Future<void> translateSession(String sessionId, String targetLanguage) async {
    final sessionIndex = state.sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final session = state.sessions[sessionIndex];
    state = state.copyWith(isLoading: true);
    try {
      final translatedResponse =
          await _repository.translateResponse(session.response, targetLanguage);
      final updatedSession = session.copyWith(response: translatedResponse);
      await _repository.saveSession(updatedSession);
      await loadSessions();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final studyRepositoryProvider = Provider<StudyRepository>((ref) {
  return StudyRepositoryImpl(
    remoteDataSource: AIRemoteDataSource(),
    localDataSource: StudyLocalDataSource(),
    firebaseDataSource: FirebaseDataSource(),
  );
});

final studyProvider = StateNotifierProvider<StudyNotifier, StudyState>((ref) {
  final repository = ref.watch(studyRepositoryProvider);
  return StudyNotifier(repository);
});

final themeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final languageProvider = StateProvider<Locale>((ref) => const Locale('en'));

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
