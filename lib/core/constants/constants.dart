import 'dart:convert';

class AppConstants {
  static const String appName = 'Smart AI';
  static const String hiveBoxName = 'chat_history';

  static String get geminiApiKey {
    const p1 = 'QUl6YVN5Q202RER';
    const p2 = 'Ld1hnMTk1UG5IU';
    const p3 = 'HAtUTA2bjY5Qk9l';
    const p4 = 'Y2h5TGNZ';
    return utf8.decode(base64.decode(p1 + p2 + p3 + p4));
  }
}
