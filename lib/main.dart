import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'domain/entities/study_session.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/providers/study_provider.dart';
import 'core/constants/constants.dart';
import 'core/localization/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // إعدادات الـ Web من Firebase Console
    // يمكنك الحصول عليها من Settings -> Project Settings -> Your Apps
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAV9_Hbb-lBroZ-L4qiDqsqpsIcCF9zmgM",
        appId: "1:513133394971:web:2e04301ac9b45217294cbe",
        messagingSenderId: "513133394971",
        projectId: "codecollab-ai-511a5",
        authDomain: "codecollab-ai-511a5.firebaseapp.com",
        storageBucket: "codecollab-ai-511a5.firebasestorage.app",
        measurementId: "G-45QH7QGCW1",
      ),
    );
    
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  } catch (e) {
    debugPrint('Firebase initialization skipped or failed: $e');
    // سنستمر في العمل باستخدام Hive فقط إذا فشل Firebase
  }
  
  await Hive.initFlutter();
  Hive.registerAdapter(StudySessionAdapter());
  await Hive.openBox<StudySession>(AppConstants.hiveBoxName);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authStateProvider);
    final locale = ref.watch(languageProvider);

    return MaterialApp(
      title: 'Smart Study Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authState.when(
        data: (user) => user != null ? const HomeScreen() : const LoginScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => Scaffold(body: Center(child: Text(e.toString()))),
      ),
    );
  }
}
