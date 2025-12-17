import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'repositories/tasks_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Ініціалізація Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Налаштування Firebase Crashlytics
  // Передача Flutter помилок в Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Передача помилок з Dart в Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Репозиторій для завдань
        Provider<TasksRepository>(create: (_) => FirestoreTasksRepository()),
        // Provider для керування станом завдань
        ChangeNotifierProxyProvider<TasksRepository, TaskProvider>(
          create: (context) => TaskProvider(context.read<TasksRepository>()),
          update: (context, repository, previous) =>
              previous ?? TaskProvider(repository),
        ),
      ],
      child: MaterialApp(
        title: 'To-Do App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasData) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        ),
        navigatorObservers: <NavigatorObserver>[observer],
      ),
    );
  }
}
