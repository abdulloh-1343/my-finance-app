import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/goal.dart';
import '../providers/finance_provider.dart';
import '../providers/goals_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/theme.dart';

class GoalDetailsScreen extends ConsumerWidget {
  final String goalId;

  const GoalDetailsScreen({super.key, required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch so the screen updates when money is added
    final goal = ref.watch(goalsProvider).firstWhere(
          (g) => g.id == goalId,
          orElse: () => Goal(
            id: '',
            title: '',
            targetAmount: 0,
            deadline: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        );

    if (goal.id.isEmpty) {
      return const Scaffold(body: Center(child: Text('Цель не найдена')));
    }

    final progress = goal.progress;
    final daysLeft = goal.daysLeft;
    final isOverdue = goal.isOverdue;

    Color accentColor;
    if (goal.isCompleted) {
      accentColor = successGreen;
    } else if (isOverdue) {
      accentColor = errorRed;
    } else if (daysLeft <= 7) {
      accentColor = const Color(0xFFF59E0B);
    } else {
      accentColor = primaryLight;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero App Bar ──
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Goal title
                        Text(
                          goal.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Создана ${DateFormat('dd MMM yyyy', 'ru_RU').format(goal.createdAt)}',
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        // Big progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  CurrencyFormatter.format(goal.currentAmount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'из ${CurrencyFormatter.format(goal.targetAmount)}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Status Banner ──
                  if (goal.isCompleted)
                    _buildSuccessBanner()
                  else if (isOverdue)
                    _buildOverdueBanner()
                  else
                    _buildActiveBanner(goal, accentColor),

                  const SizedBox(height: 20),

                  // ── Stats Grid ──
                  _buildStatsGrid(goal, daysLeft, isOverdue, accentColor),

                  const SizedBox(height: 20),

                  // ── Goal Info Card ──
                  _buildInfoCard(goal),

                  const SizedBox(height: 20),

                  // ── Daily Plan Bar ──
                  if (!goal.isCompleted && !isOverdue)
                    _buildDailyPlanCard(goal, accentColor),

                  if (!goal.isCompleted && !isOverdue)
                    const SizedBox(height: 20),

                  // ── Action Buttons ──
                  if (!goal.isCompleted)
                    _AddMoneyButton(goal: goal),

                  if (goal.currentAmount > 0) ...[
                    const SizedBox(height: 12),
                    _WithdrawMoneyButton(goal: goal),
                  ],

                  // ── Delete ──
                  const SizedBox(height: 12),
                  _DeleteGoalButton(goalId: goal.id),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            successGreen.withValues(alpha: 0.15),
            successGreen.withValues(alpha: 0.05)
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: successGreen.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Text('🏆', style: TextStyle(fontSize: 32)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Цель достигнута!',
                    style: TextStyle(
                        color: successGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 18)),
                SizedBox(height: 4),
                Text('Поздравляем! Вы достигли своей финансовой цели.',
                    style: TextStyle(color: successGreen, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: errorRed.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Text('⚠️', style: TextStyle(fontSize: 28)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Срок истёк',
                    style: TextStyle(
                        color: errorRed,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                SizedBox(height: 4),
                Text('Дедлайн прошёл. Вы всё ещё можете пополнить цель.',
                    style: TextStyle(color: errorRed, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBanner(Goal goal, Color accentColor) {
    final daysLeft = goal.daysLeft;
    String emoji = daysLeft <= 7 ? '🔥' : '🎯';
    String message = daysLeft <= 7
        ? 'Осталось совсем немного — не останавливайтесь!'
        : 'Продолжайте откладывать — вы на верном пути!';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(message,
                style:
                    TextStyle(color: accentColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
      Goal goal, int daysLeft, bool isOverdue, Color accentColor) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _StatCard(
          icon: Icons.savings_outlined,
          label: 'Осталось собрать',
          value: CurrencyFormatter.format(goal.remainingAmount),
          iconColor: primaryBlue,
        ),
        _StatCard(
          icon: Icons.today_outlined,
          label: 'Дней осталось',
          value: isOverdue ? 'Просрочено' : '$daysLeft',
          iconColor: isOverdue ? errorRed : accentColor,
          valueColor: isOverdue ? errorRed : null,
        ),
        _StatCard(
          icon: Icons.show_chart,
          label: 'Прогресс',
          value: '${(goal.progress * 100).toStringAsFixed(1)}%',
          iconColor: accentColor,
        ),
        _StatCard(
          icon: Icons.calendar_today_outlined,
          label: 'Дедлайн',
          value: DateFormat('dd MMM yy', 'ru_RU').format(goal.deadline),
          iconColor: textSecondary,
        ),
      ],
    );
  }

  Widget _buildInfoCard(Goal goal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Детали',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          _InfoRow(label: 'Название', value: goal.title),
          _InfoRow(
              label: 'Цель',
              value: CurrencyFormatter.format(goal.targetAmount)),
          _InfoRow(
              label: 'Накоплено',
              value: CurrencyFormatter.format(goal.currentAmount)),
          _InfoRow(
              label: 'Создана',
              value: DateFormat('dd MMMM yyyy', 'ru_RU').format(goal.createdAt)),
          _InfoRow(
              label: 'Дедлайн',
              value: DateFormat('dd MMMM yyyy', 'ru_RU').format(goal.deadline),
              isLast: true),
        ],
      ),
    );
  }

  Widget _buildDailyPlanCard(Goal goal, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.trending_up, color: accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Нужно в день',
                    style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  CurrencyFormatter.format(goal.requiredPerDay),
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('для достижения цели в срок',
                    style: TextStyle(color: textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color? valueColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow(
      {required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
        if (!isLast) Divider(color: Colors.grey.withValues(alpha: 0.08), height: 1),
      ],
    );
  }
}

class _AddMoneyButton extends ConsumerWidget {
  final Goal goal;

  const _AddMoneyButton({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _showDialog(context, ref),
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Пополнить цель',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final availableBalance = ref.read(balanceProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Пополнить «${goal.title}»',
            style:
                const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Сумма (KGS)',
                prefixIcon: const Icon(Icons.add_circle_outline),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
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
                      '${CurrencyFormatter.format(amount)} добавлено!'),
                  backgroundColor: successGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Добавить',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _WithdrawMoneyButton extends ConsumerWidget {
  final Goal goal;

  const _WithdrawMoneyButton({required this.goal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _showDialog(context, ref),
      icon: const Icon(Icons.output_rounded, size: 18),
      label: const Text('Вывести средства',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFF59E0B),
        side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  void _showDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final availableInGoal = goal.currentAmount;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Вывести из «${goal.title}»',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings_outlined,
                      size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Text(
                    'В цели: ${CurrencyFormatter.format(availableInGoal)}',
                    style: const TextStyle(
                        color: Color(0xFFF59E0B),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Сумма (KGS)',
                prefixIcon: const Icon(Icons.output_rounded),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final amount =
                  double.tryParse(controller.text.replaceAll(',', '.'));
              if (amount == null || amount <= 0) return;

              if (amount > goal.currentAmount) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Недостаточно средств в цели. Доступно: ${CurrencyFormatter.format(goal.currentAmount)}',
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
                  .withdrawMoneyFromGoal(goal.id, amount);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '${CurrencyFormatter.format(amount)} возвращено на баланс'),
                  backgroundColor: primaryBlue,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Вывести',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _DeleteGoalButton extends ConsumerWidget {
  final String goalId;

  const _DeleteGoalButton({required this.goalId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _confirmDelete(context, ref),
      icon: const Icon(Icons.delete_outline, size: 18),
      label: const Text('Удалить цель',
          style: TextStyle(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: errorRed,
        side: BorderSide(color: errorRed.withValues(alpha: 0.4)),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить цель?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
            'Это действие нельзя отменить. Все данные о прогрессе будут удалены.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: errorRed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              ref.read(goalsProvider.notifier).deleteGoal(goalId);
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // go back to goals list
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
