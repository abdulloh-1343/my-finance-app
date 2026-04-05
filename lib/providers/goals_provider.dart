import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal.dart';
import '../services/firestore_service.dart';
import 'package:uuid/uuid.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, List<Goal>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return GoalsNotifier(firestoreService)..init();
});

// ─── Derived Providers ────────────────────────────────────────────────────────

final activeGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(goalsProvider).where((g) => !g.isCompleted).toList();
});

final completedGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(goalsProvider).where((g) => g.isCompleted).toList();
});

/// Returns the single most-urgent active goal for Home screen widget
final featuredGoalProvider = Provider<Goal?>((ref) {
  final active = ref.watch(activeGoalsProvider);
  if (active.isEmpty) return null;
  // Sort by days left ascending to surface most urgent goal
  final sorted = [...active]..sort((a, b) => a.daysLeft.compareTo(b.daysLeft));
  return sorted.first;
});

/// Total money currently allocated across ALL goals (internal savings)
final totalGoalContributionsProvider = Provider<double>((ref) {
  final goals = ref.watch(goalsProvider);
  return goals.fold(0.0, (sum, g) => sum + g.currentAmount);
});

// ─── Notifier ────────────────────────────────────────────────────────────────

class GoalsNotifier extends StateNotifier<List<Goal>> {
  final FirestoreService? _firestoreService;
  StreamSubscription? _sub;

  GoalsNotifier(this._firestoreService) : super([]);

  void init() {
    if (_firestoreService == null) return;
    _sub = _firestoreService!.getGoalsStream().listen((goals) {
      final sorted = List<Goal>.from(goals)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) state = sorted;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> addGoal({
    required String title,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    if (_firestoreService == null) return;
    final goal = Goal(
      id: const Uuid().v4(),
      title: title,
      targetAmount: targetAmount,
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    await _firestoreService!.saveGoal(goal);
  }

  Future<void> addMoneyToGoal(String goalId, double amount) async {
    if (_firestoreService == null) return;
    final updatedList = state.map((g) {
      if (g.id == goalId) {
        g.addMoney(amount);
      }
      return g;
    }).toList();
    // Persist the modified goal
    final goal = updatedList.firstWhere((g) => g.id == goalId);
    await _firestoreService!.saveGoal(goal);
    // Trigger optimistic rebuild
    state = [...updatedList];
  }

  Future<void> withdrawMoneyFromGoal(String goalId, double amount) async {
    if (_firestoreService == null) return;
    final updatedList = state.map((g) {
      if (g.id == goalId) {
        g.withdrawMoney(amount);
      }
      return g;
    }).toList();
    final goal = updatedList.firstWhere((g) => g.id == goalId);
    await _firestoreService!.saveGoal(goal);
    state = [...updatedList];
  }

  Future<void> deleteGoal(String goalId) async {
    if (_firestoreService == null) return;
    await _firestoreService!.deleteGoal(goalId);
  }
}
