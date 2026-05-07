import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/constants/constants.dart';
import '../../domain/entities/study_session.dart';

class AIRemoteDataSource {
  final GenerativeModel _model;

  AIRemoteDataSource()
      : _model = GenerativeModel(
          model: 'gemini-2.0-flash-exp',
          apiKey: AppConstants.geminiApiKey,
        );

  Stream<String> fetchAIResponseStream(
    String prompt, {
    List<StudySession> history = const [],
    Uint8List? fileBytes,
    String? mimeType,
  }) async* {
    if (AppConstants.geminiApiKey == 'YOUR_API_KEY_HERE') {
      yield 'Please set your Gemini API Key.';
      return;
    }
    try {
      final chatHistory = history.map((s) => [
        Content.text(s.query),
        Content.model([TextPart(s.response)]),
      ]).expand((e) => e).toList();

      final chat = _model.startChat(history: chatHistory);
      
      final content = Content.multi([
        TextPart(prompt),
        if (fileBytes != null && mimeType != null) DataPart(mimeType, fileBytes),
      ]);

      final responseStream = chat.sendMessageStream(content);
      
      String fullText = '';
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          fullText += chunk.text!;
          yield fullText;
        }
      }
    } catch (e) {
      yield 'Failed to fetch AI response: $e';
    }
  }

  Stream<String> fetchShortSummaryStream(String prompt) async* {
    if (AppConstants.geminiApiKey == 'YOUR_API_KEY_HERE') {
      yield 'Please set your Gemini API Key.';
      return;
    }
    try {
      final content = [Content.text("Provide a very brief summary (maximum 1-2 sentences) for: $prompt")];
      final responseStream = _model.generateContentStream(content);
      
      String fullText = '';
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          fullText += chunk.text!;
          yield fullText;
        }
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }

  Future<String> translateResponse(String text, String targetLanguage) async {
    try {
      final content = [Content.text("Translate the following text to $targetLanguage: \n\n $text")];
      final response = await _model.generateContent(content);
      return response.text ?? 'Translation failed.';
    } catch (e) {
      return 'Error during translation: $e';
    }
  }
}
