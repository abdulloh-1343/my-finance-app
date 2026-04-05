import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ИМПОРТИРУЙТЕ ЭТОТ ФАЙЛ ПОСЛЕ ЕГО ГЕНЕРАЦИИ:
// 1. Установите FlutterFire CLI: dart pub global activate flutterfire_cli
// 2. Запустите: flutterfire configure
// 3. После этого раскомментируйте строку ниже:
import 'firebase_options.dart';

import 'screens/main_screen.dart';
import 'screens/auth_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Правильная инициализация для всех платформ (включая Web)
  // Для работы этого кода должен существовать файл lib/firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Инициализация русской локали
  await initializeDateFormatting('ru_RU', null);

  runApp(
    const ProviderScope(
      child: FinanceApp(),
    ),
  );
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Личные Финансы',
      theme: appTheme,
      // Используем StreamBuilder для отслеживания состояния авторизации
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // Если пользователь вошел — показываем главный экран
          if (snapshot.hasData && snapshot.data != null) {
             return const MainScreen();
          }
          
          // Если не вошел — экран авторизации с Google Sign-In
          return const AuthScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

/*
Пример работы Google Sign-In (логика обычно выносится в AuthService):

Future<UserCredential?> signInWithGoogle() async {
  // 1. Создаем экземпляр GoogleSignIn
  GoogleSignIn googleSignIn = GoogleSignIn();
  
  // 2. Запускаем поток авторизации
  final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
  
  if (googleUser == null) return null; // Пользователь отменил вход

  // 3. Получаем детали авторизации
  final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

  // 4. Создаем учетные данные для Firebase
  final AuthCredential credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );

  // 5. Входим в Firebase
  return await FirebaseAuth.instance.signInWithCredential(credential);
}
*/
