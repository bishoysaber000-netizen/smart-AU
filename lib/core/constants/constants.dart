import 'secrets.dart';

class AppConstants {
  static const String appName = 'Smart Study AI';
  static String get geminiApiKey => Secrets.geminiApiKey;
  static const String hiveBoxName = 'chat_history';
}
