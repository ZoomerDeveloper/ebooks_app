import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import 'dart:math' as math;

class StatsTab extends StatelessWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Статистика', style: AppTextStyles.h3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AppDataProvider>(
        builder: (context, appDataProvider, _) {
          if (appDataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final stats = appDataProvider.stats;

          if (stats == null) {
            if (appDataProvider.error?.contains('401') == true ||
                appDataProvider.error?.contains('Unauthorized') == true ||
                !authProvider.isAuthenticated) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.bar_chart,
                        size: 80,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Статистика доступна после входа',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Войдите, чтобы отслеживать свой прогресс',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Войти', style: AppTextStyles.button),
                    ),
                  ],
                ),
              );
            }

            if (appDataProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 80,
                      color: AppColors.textLight,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Статистика недоступна',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        appDataProvider.error!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: Text('Нет данных'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Ваш прогресс',
                        style: AppTextStyles.h4.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CustomPaint(
                          painter: ProgressCirclePainter(
                            progress: stats!.progressPercent / 100,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${stats.progressPercent.toStringAsFixed(1)}%',
                                  style: AppTextStyles.h1.copyWith(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Выполнено',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 15,
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
                Row(
                  children: [
                    Expanded(
                      child: _buildModernStatCard(
                        icon: Icons.auto_stories,
                        label: 'Прочитано',
                        value: stats.poemsRead.toString(),
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernStatCard(
                        icon: Icons.favorite,
                        label: 'Избранное',
                        value: stats.favoritesCount.toString(),
                        color: const Color(0xFFEC4899),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildModernStatCard(
                        icon: Icons.library_books,
                        label: 'Всего',
                        value: stats.totalPoems.toString(),
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.accent.withOpacity(0.1),
                        AppColors.secondary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getAchievementTitle(stats.progressPercent),
                              style: AppTextStyles.h4.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getMotivationalMessage(stats.progressPercent),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getAchievementTitle(double progress) {
    if (progress < 10) {
      return 'Новичок 🌱';
    } else if (progress < 30) {
      return 'Энтузиаст 🔥';
    } else if (progress < 50) {
      return 'Книголюб 📚';
    } else if (progress < 80) {
      return 'Эксперт 🎯';
    } else if (progress < 100) {
      return 'Мастер 🏆';
    } else {
      return 'Легенда 👑';
    }
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

    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius - 6, backgroundPaint);

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
