import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/app_data_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Статистика', style: AppTextStyles.h3),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AppDataProvider>(
        builder: (context, appDataProvider, _) {
          if (appDataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = appDataProvider.stats;
          if (stats == null) {
            return Center(
              child: Text(
                'Статистика недоступна',
                style: AppTextStyles.bodyLarge,
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Progress Circle
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Ваш прогресс',
                        style: AppTextStyles.h4.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: ProgressCirclePainter(
                            progress: stats.progressPercent / 100,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${stats.progressPercent.toStringAsFixed(1)}%',
                                  style: AppTextStyles.h1.copyWith(
                                    color: Colors.white,
                                    fontSize: 36,
                                  ),
                                ),
                                Text(
                                  'Выполнено',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Stats Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.auto_stories,
                        label: 'Прочитано',
                        value: stats.poemsRead.toString(),
                        gradient: AppColors.primaryGradient,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.favorite,
                        label: 'Избранное',
                        value: stats.favoritesCount.toString(),
                        gradient: AppColors.accentGradient,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Total Poems
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.textLight.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.library_books,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Всего стихов', style: AppTextStyles.bodySmall),
                          Text(
                            '${stats.totalPoems}',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Motivational Message
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryLight.withOpacity(0.2),
                        AppColors.secondaryLight.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: AppColors.accent,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _getMotivationalMessage(stats.progressPercent),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textLight.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.h2.copyWith(fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(double progress) {
    if (progress < 10) {
      return 'Отличное начало! Продолжайте читать, чтобы расширить словарный запас.';
    } else if (progress < 30) {
      return 'Вы движетесь вперёд! Продолжайте в том же духе.';
    } else if (progress < 50) {
      return 'Полпути! Ваша целеустремлённость вдохновляет.';
    } else if (progress < 80) {
      return 'Фантастическая работа! Вы становитесь мастером слов.';
    } else if (progress < 100) {
      return 'Почти у цели! Ещё немного, чтобы завершить коллекцию.';
    } else {
      return 'Потрясающе! Вы прошли всю коллекцию!';
    }
  }
}

class ProgressCirclePainter extends CustomPainter {
  final double progress;

  ProgressCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius - 6, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 6),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
