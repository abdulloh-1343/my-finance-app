import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/transaction.dart';
import 'models/goal.dart';
import 'screens/main_screen.dart';
import 'services/hive_service.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive storage
  await Hive.initFlutter();
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(GoalAdapter());

  final hiveService = HiveService();
  await hiveService.init();

  // Initialize Russian locale for intl formatting
  await initializeDateFormatting('ru_RU', null);

  runApp(
    ProviderScope(
      overrides: [
        hiveServiceProvider.overrideWithValue(hiveService),
      ],
      child: const FinanceApp(),
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
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
