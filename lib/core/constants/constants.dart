import 'secrets.dart';

class AppConstants {
  static const String appName = 'Smart Study Assistant';
  static const String hiveBoxName = 'chat_history';

  static String get geminiApiKey => Secrets.geminiApiKey;
}
