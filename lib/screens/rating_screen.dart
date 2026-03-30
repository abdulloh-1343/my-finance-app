import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/finance_provider.dart';
import '../utils/theme.dart';

class RatingScreen extends ConsumerWidget {
  const RatingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(financialScoreProvider);

    String statusText;
    Color statusColor;

    if (score >= 80) {
      statusText = 'Отлично';
      statusColor = successGreen;
    } else if (score >= 50) {
      statusText = 'Хорошо';
      statusColor = Colors.orange; // Custom state indication
    } else {
      statusText = 'Есть проблемы';
      statusColor = errorRed;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансовый рейтинг'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: surfaceWhite,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Показатель здоровья',
                      style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: score / 100,
                            backgroundColor: backgroundLight,
                            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                            strokeWidth: 20,
                            strokeCap: StrokeCap.round,
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$score',
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                    letterSpacing: -2,
                                  ),
                                ),
                                Text(
                                  'из 100',
                                  style: TextStyle(color: textSecondary, fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Рейтинг рассчитывается на основе соотношения ваших текущих расходов и доходов. Высокий балл означает финансовую стабильность.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textSecondary, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      ),
    );
  }
}
