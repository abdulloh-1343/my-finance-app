import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_provider.dart';
import '../models/transaction.dart';
import '../models/goal.dart';
import '../providers/goals_provider.dart';
import '../utils/theme.dart';

enum InsightType {
  alert,
  analytic,
  recommendation,
  diagnosis,
}

class InsightItem {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final InsightType type;

  InsightItem({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.type,
  });
}

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionsProvider);
    final totalExpenses = ref.watch(totalExpensesCurrentMonthProvider);
    final totalIncome = ref.watch(totalIncomeCurrentMonthProvider);
    final balance = ref.watch(balanceProvider);
    final goals = ref.watch(goalsProvider);

    final insights = _generateInsights(transactions, totalExpenses, totalIncome, balance, goals);

    final alerts = insights.where((i) => i.type == InsightType.alert).toList();
    final analytics = insights.where((i) => i.type == InsightType.analytic).toList();
    final recommendations = insights.where((i) => i.type == InsightType.recommendation).toList();
    final diagnosis = insights.where((i) => i.type == InsightType.diagnosis).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Умные советы'),
      ),
      body: insights.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Пока недостаточно данных для формирования финансового анализа.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, fontSize: 16),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (alerts.isNotEmpty) _buildSection('🚨 Оповещения', alerts),
                if (analytics.isNotEmpty) _buildSection('📊 Аналитика', analytics),
                if (recommendations.isNotEmpty) _buildSection('💡 Рекомендации', recommendations),
                if (diagnosis.isNotEmpty) _buildSection('🩺 Финансовый диагноз', diagnosis),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<InsightItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ),
        ...items.map(_buildInsightCard),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInsightCard(InsightItem item) {
    final bool isAlert = item.type == InsightType.alert;
    final Color bgColor = isAlert ? item.color.withValues(alpha: 0.05) : surfaceWhite;
    final BorderSide borderSide = isAlert 
        ? BorderSide(color: item.color.withValues(alpha: 0.3)) 
        : BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 1);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(
        side: borderSide,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: const TextStyle(color: textSecondary, height: 1.4, fontSize: 14),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  List<InsightItem> _generateInsights(List<Transaction> transactions, double expenses, double income, double balance, List<Goal> goals) {
    final List<InsightItem> insights = [];
    final now = DateTime.now();

    // Group expenses by category for the current month
    final Map<String, double> categoryExpenses = {};
    for (var t in transactions) {
      if (t.type == TransactionType.expense && t.date.month == now.month && t.date.year == now.year) {
        categoryExpenses[t.category] = (categoryExpenses[t.category] ?? 0) + t.amount;
      }
    }

    String topCategory = '';
    double maxCategoryExpense = 0;
    categoryExpenses.forEach((key, value) {
      if (value > maxCategoryExpense) {
        maxCategoryExpense = value;
        topCategory = key;
      }
    });

    // 1. ALERTS (High Priority)
    if (balance <= 0 && transactions.isNotEmpty) {
      insights.add(InsightItem(
        title: 'Отрицательный баланс',
        message: 'Ваш баланс ниже нуля. Срочно пересмотрите свои расходы.',
        icon: Icons.warning_amber_rounded,
        color: errorRed,
        type: InsightType.alert,
      ));
    } else if (income > 0 && balance < income * 0.1) {
      insights.add(InsightItem(
        title: 'Низкий баланс',
        message: 'У вас осталось менее 10% от доступного бюджета.',
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.orange,
        type: InsightType.alert,
      ));
    }

    categoryExpenses.forEach((category, amount) {
      final percentage = amount / (expenses > 0 ? expenses : 1);
      if (percentage > 0.7 && expenses > 0) {
        insights.add(InsightItem(
          title: 'Превышение бюджета: $category',
          message: 'Вы потратили ${(percentage * 100).toInt()}% бюджета на эту категорию. Рекомендуем сократить траты.',
          icon: Icons.pie_chart_outline,
          color: errorRed,
          type: InsightType.alert,
        ));
      }
    });

    final bool noIncome = income == 0 && transactions.where((t) => t.type == TransactionType.income).isEmpty;
    if (noIncome && expenses > 0) {
        insights.add(InsightItem(
          title: 'Нет поступлений',
          message: 'За последнее время не зафиксировано доходов, но расходы продолжаются.',
          icon: Icons.money_off,
          color: Colors.orange,
          type: InsightType.alert,
        ));
    }

    // 2. ANALYTICS (What is happening)
    double recent7Days = 0;
    double previous7Days = 0;
    for (var t in transactions) {
      if (t.type == TransactionType.expense) {
        final diff = now.difference(t.date).inDays;
        if (diff < 7) {
          recent7Days += t.amount;
        } else if (diff >= 7 && diff < 14) {
          previous7Days += t.amount;
        }
      }
    }

    if (recent7Days > previous7Days * 1.2 && previous7Days > 0) {
      final increase = ((recent7Days / previous7Days - 1) * 100).toInt();
      insights.add(InsightItem(
        title: 'Рост расходов на $increase%',
        message: 'За последние 7 дней вы потратили больше, чем за предыдущую неделю.',
        icon: Icons.trending_up,
        color: Colors.orange,
        type: InsightType.analytic,
      ));
    } else if (recent7Days < previous7Days * 0.8 && previous7Days > 0) {
      final decrease = ((1 - recent7Days / previous7Days) * 100).toInt();
      insights.add(InsightItem(
        title: 'Снижение расходов',
        message: 'Отлично! Вы потратили на $decrease% меньше, чем на прошлой неделе.',
        icon: Icons.trending_down,
        color: successGreen,
        type: InsightType.analytic,
      ));
    }

    if (topCategory.isNotEmpty && maxCategoryExpense > 0) {
      final percentage = (maxCategoryExpense / expenses * 100).toInt();
      insights.add(InsightItem(
        title: 'Основная статья расходов',
        message: 'Анализ показывает, что большая часть средств уходит на «$topCategory» ($percentage%).',
        icon: Icons.analytics_outlined,
        color: primaryBlue,
        type: InsightType.analytic,
      ));
    }

    // 3. RECOMMENDATIONS (What to do)
    if (topCategory == 'Еда' && maxCategoryExpense > 0) {
      insights.add(InsightItem(
        title: 'Оптимизация расходов на еду',
        message: 'Попробуйте планировать меню заранее или реже заказывать доставку, чтобы снизить траты на 15%.',
        icon: Icons.restaurant,
        color: primaryLight,
        type: InsightType.recommendation,
      ));
    } else if (topCategory == 'Транспорт' && maxCategoryExpense > 0) {
        insights.add(InsightItem(
        title: 'Экономия на транспорте',
        message: 'Возможно, стоит рассмотреть приобретение проездного билета на весь месяц.',
        icon: Icons.directions_bus_outlined,
        color: primaryLight,
        type: InsightType.recommendation,
      ));
    } else if (income > 0 && (expenses / income) < 0.6) {
       insights.add(InsightItem(
        title: 'Увеличьте сбережения',
        message: 'У вас остаются свободные средства. Рекомендуем отложить часть на накопительный счет прямо сейчас.',
        icon: Icons.savings_outlined,
        color: successGreen,
        type: InsightType.recommendation,
      ));
    } else if (expenses > income && income > 0) {
      insights.add(InsightItem(
        title: 'Скорректируйте бюджет',
        message: 'Откажитесь от спонтанных покупок в ближайшие дни, чтобы вернуть баланс в норму.',
        icon: Icons.cut,
        color: primaryBlue,
        type: InsightType.recommendation,
      ));
    }

    // 4. FINANCIAL DIAGNOSIS (Impact / Consequences)
    final daysPassed = now.day;
    final int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    
    if (daysPassed > 3 && expenses > 0) {
      final dailyRate = expenses / daysPassed;
      final expectedExpenses = dailyRate * daysInMonth;

      if (expectedExpenses > balance + income && balance >= 0) {
        insights.add(InsightItem(
          title: 'Риск кассового разрыва',
          message: 'Если вы продолжите тратить в таком темпе (около ${dailyRate.toInt()} в день), ваш баланс иссякнет до конца месяца.',
          icon: Icons.monitor_heart_outlined,
          color: errorRed,
          type: InsightType.diagnosis,
        ));
      } else if (income > 0 && expectedExpenses < income * 0.8) {
         insights.add(InsightItem(
          title: 'Стабильный финансовый рост',
          message: 'Динамика позитивная. К концу месяца вы сможете сохранить значительную часть средств.',
          icon: Icons.volunteer_activism,
          color: successGreen,
          type: InsightType.diagnosis,
        ));
      } else {
        insights.add(InsightItem(
          title: 'Нейтральный прогноз',
          message: 'Вы тратите средства в умеренном темпе. К концу месяца ожидается небольшой положительный остаток.',
          icon: Icons.balance,
          color: textPrimary,
          type: InsightType.diagnosis,
        ));
      }
    } else if (expenses == 0 && income > 0) {
       insights.add(InsightItem(
          title: 'Прекрасное начало',
          message: 'Месяц только начался. Распределите бюджет заранее, чтобы избежать неожиданных трат.',
          icon: Icons.lightbulb_outline,
          color: successGreen,
          type: InsightType.diagnosis,
        ));
    }

    // 5. GOALS INSIGHTS
    for (var goal in goals) {
      if (goal.isCompleted) {
        insights.add(InsightItem(
          title: 'Цель достигнута: ${goal.title}',
          message: 'Вы успешно накопили нужную сумму. Отличная работа! → +30 score',
          icon: Icons.emoji_events,
          color: successGreen,
          type: InsightType.recommendation,
        ));
        continue;
      }

      final totalDays = goal.deadline.difference(goal.createdAt).inDays;
      final elapsedDays = now.difference(goal.createdAt).inDays;
      final expectedProgress = totalDays > 0 ? (elapsedDays / totalDays).clamp(0.0, 1.0) : 1.0;
      final actualProgress = goal.progress;

      if (actualProgress == 0 && elapsedDays > 7) {
        insights.add(InsightItem(
          title: 'Нет прогресса: ${goal.title}',
          message: 'Вы давно не пополняли эту цель. → -3 score',
          icon: Icons.pause_circle_outline,
          color: Colors.orange,
          type: InsightType.alert,
        ));
      } else if (actualProgress < expectedProgress - 0.05) {
        insights.add(InsightItem(
          title: 'Отставание от плана: ${goal.title}',
          message: 'Вы отстаете от графика. Вам нужно откладывать ${goal.requiredPerDay.toInt()} в день. → +5 score',
          icon: Icons.schedule,
          color: errorRed,
          type: InsightType.alert,
        ));
      } else if (actualProgress >= expectedProgress + 0.05) {
        insights.add(InsightItem(
          title: 'Опережение графика: ${goal.title}',
          message: 'Вы опережаете план вашей цели. Отличная работа! → +15 score',
          icon: Icons.speed,
          color: successGreen,
          type: InsightType.analytic,
        ));
      } else {
        insights.add(InsightItem(
          title: 'По плану: ${goal.title}',
          message: 'Вы идете по графику к завершению цели. → +10 score',
          icon: Icons.check_circle_outline,
          color: primaryBlue,
          type: InsightType.analytic,
        ));
      }
    }

    return insights;
  }
}
