import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/hive_service.dart';
import 'goals_provider.dart';

// Provides monthly manual set income
final monthlyIncomeProvider =
    StateNotifierProvider<IncomeNotifier, double>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  return IncomeNotifier(hiveService)..init();
});

class IncomeNotifier extends StateNotifier<double> {
  final HiveService _hiveService;

  IncomeNotifier(this._hiveService) : super(0.0);

  void init() {
    state = _hiveService.getMonthlyIncome();
  }

  void updateIncome(double income) {
    _hiveService.setMonthlyIncome(income);
    state = income;
  }
}

// Provides list of all transactions
final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  return TransactionsNotifier(hiveService)..init();
});

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  final HiveService _hiveService;

  TransactionsNotifier(this._hiveService) : super([]);

  void init() {
    state = _hiveService.getTransactions();
  }

  void addTransaction(Transaction t) {
    _hiveService.addTransaction(t);
    state = [t, ...state]..sort((a, b) => b.date.compareTo(a.date));
  }
}

// Calculates dynamic balance: (Static Income + Income Transactions) - Expense Transactions - Goal Savings
final balanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final incomeSetting = ref.watch(monthlyIncomeProvider);
  final goalContributions = ref.watch(totalGoalContributionsProvider);

  double balance = incomeSetting;
  for (var t in transactions) {
    if (t.type == TransactionType.income) {
      balance += t.amount;
    } else {
      balance -= t.amount;
    }
  }
  // Subtract money moved to goal savings (internal transfer)
  return balance - goalContributions;
});

// Calculates total expenses for current month
final totalExpensesCurrentMonthProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final now = DateTime.now();

  return transactions
      .where((t) =>
          t.type == TransactionType.expense &&
          t.date.month == now.month &&
          t.date.year == now.year)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// Calculate total income for current month
final totalIncomeCurrentMonthProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionsProvider);
  final now = DateTime.now();
  final staticIncome = ref.watch(monthlyIncomeProvider);

  final transactionIncome = transactions
      .where((t) =>
          t.type == TransactionType.income &&
          t.date.month == now.month &&
          t.date.year == now.year)
      .fold(0.0, (sum, t) => sum + t.amount);

  return staticIncome + transactionIncome;
});

// Generates Financial Score (0 - 100)
final financialScoreProvider = Provider<int>((ref) {
  final income = ref.watch(totalIncomeCurrentMonthProvider);
  final expenses = ref.watch(totalExpensesCurrentMonthProvider);
  final goals = ref.watch(goalsProvider);

  int score = 100;

  if (income == 0 && expenses == 0) {
    score = 100; // Perfect score if idle
  } else if (income == 0 && expenses > 0) {
    score = 10;
  } else {
    final expenseRatio = expenses / income;
    if (expenseRatio > 0.9) score = 20; // Critical
    else if (expenseRatio > 0.7) score = 50; // Approaching limit
    else if (expenseRatio > 0.5) score = 80; // Good
    else score = 100; // Excellent
  }

  // Goal logic
  for (var goal in goals) {
    if (goal.isCompleted) {
      score += 10; // Completion bonus
    }

    if (goal.progress >= 1.0) {
      score += 20;
    } else if (goal.progress >= 0.5) {
      score += 15;
    } else if (goal.progress >= 0.2) {
      score += 10;
    } else {
      score += 5;
    }

    final elapsedDays = DateTime.now().difference(goal.createdAt).inDays;
    if (goal.progress == 0 && elapsedDays > 7) {
      score -= 3; // No progress for a long time
    }
  }

  return score.clamp(0, 100);
});
