import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/goal.dart';

final hiveServiceProvider = Provider<HiveService>((ref) {
  throw UnimplementedError('Initialized in main');
});

class HiveService {
  static const String _transactionsBoxName = 'transactions';
  static const String _settingsBoxName = 'settings';
  static const String _goalsBoxName = 'goals';

  late Box<Transaction> _transactionsBox;
  late Box _settingsBox;
  late Box<Goal> _goalsBox;

  Future<void> init() async {
    _transactionsBox = await Hive.openBox<Transaction>(_transactionsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
    _goalsBox = await Hive.openBox<Goal>(_goalsBoxName);
  }

  // ─── Transactions ────────────────────────────────────────────────────────────

  List<Transaction> getTransactions() {
    return _transactionsBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _transactionsBox.put(transaction.id, transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsBox.delete(id);
  }

  // ─── Settings: Income ────────────────────────────────────────────────────────

  double getMonthlyIncome() {
    return _settingsBox.get('monthlyIncome', defaultValue: 0.0) as double;
  }

  Future<void> setMonthlyIncome(double income) async {
    await _settingsBox.put('monthlyIncome', income);
  }

  // ─── Goals ───────────────────────────────────────────────────────────────────

  List<Goal> getGoals() {
    return _goalsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> saveGoal(Goal goal) async {
    await _goalsBox.put(goal.id, goal);
  }

  Future<void> deleteGoal(String id) async {
    await _goalsBox.delete(id);
  }
}
