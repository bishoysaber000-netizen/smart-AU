import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const _localizedValues = {
    'en': {
      'appTitle': 'Smart Study Assistant',
      'welcome': 'Welcome back,',
      'student': 'Student',
      'searchHint': 'Ask anything...',
      'quickActions': 'Quick Actions',
      'recentThreads': 'Recent Threads',
      'trash': 'Trash',
      'clearAll': 'Clear All',
      'close': 'Close',
      'settings': 'Settings',
      'language': 'Language',
      'darkMode': 'Dark Mode',
      'logout': 'Logout',
      'typeMessage': 'Type your question...',
      'summarize': 'Summarize',
      'analyzeFile': 'Analyze the attached file',
      'forgotPassword': 'Forgot Password?',
      'signIn': 'Sign In',
      'signUp': 'Create Account',
      'email': 'Email Address',
      'password': 'Password',
      'username': 'Username',
    },
    'ar': {
      'appTitle': 'مساعد الدراسة الذكي',
      'welcome': 'مرحباً بك،',
      'student': 'طالب',
      'searchHint': 'اسأل أي شيء...',
      'quickActions': 'إجراءات سريعة',
      'recentThreads': 'المحادثات الأخيرة',
      'trash': 'سلة المحذوفات',
      'clearAll': 'مسح الكل',
      'close': 'إغلاق',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'darkMode': 'الوضع الداكن',
      'logout': 'تسجيل الخروج',
      'typeMessage': 'اكتب سؤالك هنا...',
      'summarize': 'تلخيص',
      'analyzeFile': 'تحليل الملف المرفق',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'signIn': 'تسجيل الدخول',
      'signUp': 'إنشاء حساب',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'username': 'اسم المستخدم',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
