import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/finance_provider.dart';
import '../providers/goals_provider.dart';
import '../models/transaction.dart';
import '../utils/currency_formatter.dart';
import '../utils/theme.dart';
import 'goal_details_screen.dart';
import '../services/auth_service.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider);
    final expenses = ref.watch(totalExpensesCurrentMonthProvider);
    final income = ref.watch(totalIncomeCurrentMonthProvider);
    final transactions = ref.watch(transactionsProvider);
    final featuredGoal = ref.watch(featuredGoalProvider);

    double budgetUsage = 0.0;
    if (income > 0) {
      budgetUsage = (expenses / income).clamp(0.0, 1.0);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showIncomeSettingsDialog(context, ref);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
               await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildBalanceCard(context, balance, expenses, income, budgetUsage),

              // ── Featured Goal ──
              if (featuredGoal != null) ...
              [
                const SizedBox(height: 24),
                Text('Активная цель', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildFeaturedGoalCard(context, ref, featuredGoal),
              ],
              
              const SizedBox(height: 24),
              Text('Анализ по категориям', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildCategoryBreakdown(context, transactions, expenses),
              
              const SizedBox(height: 24),
              Text('Последние транзакции', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildRecentTransactions(context, ref, transactions),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, double balance, double expenses, double income, double budgetUsage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [primaryBlue, Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Общий баланс',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Colors.white),
                    SizedBox(width: 6),
                    Text('KGS', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyFormatter.format(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(child: _buildSummaryItem('Доход (мес)', CurrencyFormatter.format(income))),
                Container(width: 1, height: 30, color: Colors.white12),
                const SizedBox(width: 16),
                Expanded(child: _buildSummaryItem('Расход (мес)', CurrencyFormatter.format(expenses))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Лимит бюджета', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
              Text(
                '${(budgetUsage * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: budgetUsage,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                budgetUsage > 0.85 ? errorRed : Colors.white,
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedGoalCard(BuildContext context, WidgetRef ref, goal) {
    final progress = goal.progress as double;
    final daysLeft = goal.daysLeft as int;
    final isOverdue = goal.isOverdue as bool;

    Color progressColor = isOverdue
        ? errorRed
        : daysLeft <= 7
            ? const Color(0xFFF59E0B)
            : primaryLight;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => GoalDetailsScreen(goalId: goal.id as String)),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.flag_rounded,
                      color: primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title as String,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isOverdue
                            ? 'Срок истёк'
                            : '$daysLeft дн. осталось',
                        style: TextStyle(
                            color: isOverdue ? errorRed : textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: textSecondary),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  CurrencyFormatter.format(goal.currentAmount as double),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: textPrimary),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: progressColor),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'из ${CurrencyFormatter.format(goal.targetAmount as double)}',
              style: const TextStyle(color: textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: backgroundLight,
                valueColor:
                    AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddMoneyDialog(context, ref, goal),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Пополнить',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: BorderSide(
                      color: primaryBlue.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, WidgetRef ref, goal) {
    final controller = TextEditingController();
    final availableBalance = ref.read(balanceProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Пополнить «${goal.title}»',
          style:
              const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
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
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Сумма (KGS)',
                prefixIcon: const Icon(Icons.add_circle_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
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
              final amount = double.tryParse(
                  controller.text.replaceAll(',', '.'));
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
                  .addMoneyToGoal(goal.id as String, amount);
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

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, List<Transaction> transactions, double totalExpenses) {
    if (totalExpenses == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              const Text('Нет данных о расходах для анализа.', style: TextStyle(color: textSecondary)),
            ],
          ),
        ),
      );
    }

    final Map<String, double> categorySums = {};
    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        categorySums[t.category] = (categorySums[t.category] ?? 0) + t.amount;
      }
    }

    final sortedCategories = categorySums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedCategories.map((entry) {
        final percentage = entry.value / totalExpenses;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(
                    CurrencyFormatter.format(entry.value),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: backgroundLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: percentage,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [primaryBlue, primaryLight]),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}% от общих расходов',
                style: const TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, WidgetRef ref, List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('Список транзакций пуст', style: TextStyle(color: textSecondary)),
        ),
      );
    }

    return Column(
      children: transactions.take(10).map((t) {
        final isIncome = t.type == TransactionType.income;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => _showTransactionDetails(context, t),
            leading: CircleAvatar(
              backgroundColor: isIncome ? successGreen.withValues(alpha: 0.1) : errorRed.withValues(alpha: 0.1),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? successGreen : errorRed,
              ),
            ),
            title: Text(t.category, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(DateFormat('dd MMM yyyy', 'ru_RU').format(t.date)),
            trailing: Text(
              '${isIncome ? '+' : '-'}${CurrencyFormatter.format(t.amount)}',
              style: TextStyle(
                color: isIncome ? successGreen : textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showTransactionDetails(BuildContext context, Transaction t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Детали транзакции', style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow('Тип', t.type == TransactionType.income ? 'Доход' : 'Расход'),
              _buildDetailRow('Категория', t.category),
              _buildDetailRow('Сумма', CurrencyFormatter.format(t.amount)),
              _buildDetailRow('Дата', DateFormat('dd MMMM yyyy', 'ru_RU').format(t.date)),
              if (t.note.isNotEmpty) _buildDetailRow('Заметка', t.note),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  void _showIncomeSettingsDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: ref.read(monthlyIncomeProvider).toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фиксированный доход (мес)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Сумма (KGS)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text);
              if (val != null) {
                ref.read(monthlyIncomeProvider.notifier).updateIncome(val);
              }
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
