import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../services/firestore_service.dart';
import 'goals_provider.dart';

// Provides monthly manual set income
final monthlyIncomeProvider =
    StateNotifierProvider<IncomeNotifier, double>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return IncomeNotifier(firestoreService)..init();
});

class IncomeNotifier extends StateNotifier<double> {
  final FirestoreService? _firestoreService;
  StreamSubscription? _sub;

  IncomeNotifier(this._firestoreService) : super(0.0);

  void init() {
    if (_firestoreService == null) return;
    _sub = _firestoreService!.getMonthlyIncomeStream().listen((income) {
      if (mounted) state = income;
    });
  }
  
  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void updateIncome(double income) {
    _firestoreService?.setMonthlyIncome(income);
    state = income; // Optimistic update
  }
}

// Provides list of all transactions
final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return TransactionsNotifier(firestoreService)..init();
});

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  final FirestoreService? _firestoreService;
  StreamSubscription? _sub;

  TransactionsNotifier(this._firestoreService) : super([]);

  void init() {
    if (_firestoreService == null) return;
    _sub = _firestoreService!.getTransactionsStream().listen((transactions) {
      final sorted = List<Transaction>.from(transactions)
        ..sort((a, b) => b.date.compareTo(a.date));
      if (mounted) state = sorted;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void addTransaction(Transaction t) {
    if (_firestoreService == null) return;
    _firestoreService!.addTransaction(t);
  }
  
  void deleteTransaction(String id) {
    if (_firestoreService == null) return;
    _firestoreService!.deleteTransaction(id);
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
    if (expenseRatio > 0.9) {
      score = 20;
    } else if (expenseRatio > 0.7) {
      score = 50;
    } else if (expenseRatio > 0.5) {
      score = 80;
    } else {
      score = 100;
    }
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
