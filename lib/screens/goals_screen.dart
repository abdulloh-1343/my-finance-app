import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../providers/finance_provider.dart';
import '../providers/goals_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/theme.dart';
import 'goal_details_screen.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeGoals = ref.watch(activeGoalsProvider);
    final completedGoals = ref.watch(completedGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Цели'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Активные (${activeGoals.length})'),
            Tab(text: 'Выполненные (${completedGoals.length})'),
          ],
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          indicatorColor: primaryBlue,
          labelColor: primaryBlue,
          unselectedLabelColor: textSecondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GoalListView(goals: activeGoals, isCompleted: false),
          _GoalListView(goals: completedGoals, isCompleted: true),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGoalSheet(context),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Новая цель', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  void _showCreateGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateGoalSheet(),
    );
  }
}

// ─── Goal List ────────────────────────────────────────────────────────────────

class _GoalListView extends StatelessWidget {
  final List<Goal> goals;
  final bool isCompleted;

  const _GoalListView({required this.goals, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.emoji_events_outlined : Icons.flag_outlined,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              isCompleted
                  ? 'Выполненных целей пока нет'
                  : 'Нет активных целей.\nНажмите «+», чтобы создать.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: goals.length,
      itemBuilder: (context, i) => _GoalCard(goal: goals[i]),
    );
  }
}

// ─── Goal Card ────────────────────────────────────────────────────────────────

class _GoalCard extends ConsumerWidget {
  final Goal goal;

  const _GoalCard({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = goal.progress;
    final isOverdue = goal.isOverdue;
    final daysLeft = goal.daysLeft;

    Color progressColor;
    if (goal.isCompleted) {
      progressColor = successGreen;
    } else if (isOverdue) {
      progressColor = errorRed;
    } else if (daysLeft <= 7) {
      progressColor = const Color(0xFFF59E0B); // amber
    } else {
      progressColor = primaryLight;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GoalDetailsScreen(goalId: goal.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Goal icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: goal.isCompleted
                          ? successGreen.withValues(alpha: 0.1)
                          : primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      goal.isCompleted
                          ? Icons.check_circle_rounded
                          : Icons.flag_rounded,
                      color: goal.isCompleted ? successGreen : primaryBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'до ${DateFormat('dd MMM yyyy', 'ru_RU').format(goal.deadline)}',
                          style: const TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status chip
                  _buildStatusChip(daysLeft, isOverdue),
                ],
              ),
            ),

            // ── Progress ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        CurrencyFormatter.format(goal.currentAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: progressColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'из ${CurrencyFormatter.format(goal.targetAmount)}',
                    style: const TextStyle(color: textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: backgroundLight,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),

            // ── Stats Row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _buildStat(
                    Icons.savings_outlined,
                    'Осталось',
                    CurrencyFormatter.format(goal.remainingAmount),
                    textSecondary,
                  ),
                  const SizedBox(width: 20),
                  if (!goal.isCompleted)
                    _buildStat(
                      Icons.today_outlined,
                      'Дней',
                      isOverdue ? 'Просрочено' : '$daysLeft',
                      isOverdue ? errorRed : textSecondary,
                    ),
                ],
              ),
            ),

            // ── Action Row ──
            if (!goal.isCompleted)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAddMoneyDialog(context, ref),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Пополнить',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryBlue,
                          side: BorderSide(
                              color: primaryBlue.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: successGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, color: successGreen, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Цель достигнута! 🎉',
                        style: TextStyle(
                          color: successGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(int daysLeft, bool isOverdue) {
    if (goal.isCompleted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: successGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          '✓ Готово',
          style: TextStyle(
              color: successGreen, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    }
    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Просрочено',
          style: TextStyle(
              color: errorRed, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
    }
    if (daysLeft <= 7) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$daysLeft дн.',
          style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 11,
              fontWeight: FontWeight.w700),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$daysLeft дн.',
        style: const TextStyle(
            color: primaryBlue, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ],
    );
  }

  void _showAddMoneyDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final availableBalance = ref.read(balanceProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Пополнить «${goal.title}»',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      size: 16, color: primaryBlue),
                  const SizedBox(width: 8),
                  Text(
                    'Доступно: ${CurrencyFormatter.format(availableBalance > 0 ? availableBalance : 0)}',
                    style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Сумма (KGS)',
                prefixIcon: const Icon(Icons.add_circle_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final amount =
                  double.tryParse(controller.text.replaceAll(',', '.'));
              if (amount == null || amount <= 0) return;

              final currentBalance = ref.read(balanceProvider);
              if (amount > currentBalance || currentBalance <= 0) {
                Navigator.pop(ctx);
                final maxAvailable = currentBalance > 0 ? currentBalance : 0.0;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Недостаточно средств. Доступно: ${CurrencyFormatter.format(maxAvailable)}',
                    ),
                    backgroundColor: errorRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
                return;
              }

              ref
                  .read(goalsProvider.notifier)
                  .addMoneyToGoal(goal.id, amount);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${CurrencyFormatter.format(amount)} добавлено к цели!'),
                  backgroundColor: successGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child:
                const Text('Добавить', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Create Goal Sheet ────────────────────────────────────────────────────────

class _CreateGoalSheet extends ConsumerStatefulWidget {
  const _CreateGoalSheet();

  @override
  ConsumerState<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends ConsumerState<_CreateGoalSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_rounded, color: primaryBlue),
              ),
              const SizedBox(width: 12),
              const Text(
                'Новая финансовая цель',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Title field
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Название цели',
              hintText: 'Например: Купить ноутбук',
              prefixIcon: const Icon(Icons.label_outline),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: backgroundLight,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Amount field
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Целевая сумма (KGS)',
              prefixIcon: const Icon(Icons.savings_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: backgroundLight,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Deadline picker
          GestureDetector(
            onTap: _pickDeadline,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundLight,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      color: textSecondary),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Дедлайн',
                          style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMMM yyyy', 'ru_RU').format(_deadline),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: textPrimary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Save button
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text(
                    'Создать цель',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.'));

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название цели')),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите корректную целевую сумму')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await ref.read(goalsProvider.notifier).addGoal(
          title: title,
          targetAmount: amount,
          deadline: _deadline,
        );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Цель создана! 🎯'),
          backgroundColor: successGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }
}
