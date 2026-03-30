import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/goal.dart';
import '../services/hive_service.dart';
import 'package:uuid/uuid.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final goalsProvider =
    StateNotifierProvider<GoalsNotifier, List<Goal>>((ref) {
  final hiveService = ref.read(hiveServiceProvider);
  return GoalsNotifier(hiveService)..init();
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
  final HiveService _hiveService;

  GoalsNotifier(this._hiveService) : super([]);

  void init() {
    state = _hiveService.getGoals();
  }

  Future<void> addGoal({
    required String title,
    required double targetAmount,
    required DateTime deadline,
  }) async {
    final goal = Goal(
      id: const Uuid().v4(),
      title: title,
      targetAmount: targetAmount,
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    await _hiveService.saveGoal(goal);
    state = [goal, ...state];
  }

  Future<void> addMoneyToGoal(String goalId, double amount) async {
    final updatedList = state.map((g) {
      if (g.id == goalId) {
        g.addMoney(amount);
      }
      return g;
    }).toList();
    // Persist the modified goal
    final goal = updatedList.firstWhere((g) => g.id == goalId);
    await _hiveService.saveGoal(goal);
    // Trigger rebuild
    state = [...updatedList];
  }

  Future<void> withdrawMoneyFromGoal(String goalId, double amount) async {
    final updatedList = state.map((g) {
      if (g.id == goalId) {
        g.withdrawMoney(amount);
      }
      return g;
    }).toList();
    final goal = updatedList.firstWhere((g) => g.id == goalId);
    await _hiveService.saveGoal(goal);
    state = [...updatedList];
  }

  Future<void> deleteGoal(String goalId) async {
    await _hiveService.deleteGoal(goalId);
    state = state.where((g) => g.id != goalId).toList();
  }
}
