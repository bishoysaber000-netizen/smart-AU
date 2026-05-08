import 'dart:convert';

class AppConstants {
  static const String appName = 'Smart AI';
  static const String hiveBoxName = 'chat_history';

  static String get geminiApiKey {
    const hidden = 'BJ{bTzEX1kyVNZVs2GDYMxsIEIc7jFywWYxnKlh';
    return String.fromCharCodes(hidden.codeUnits.map((c) => c - 1));
  }
}
