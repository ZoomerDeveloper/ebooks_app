import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../read_history_screen.dart';
import 'dart:math' as math;

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (!authProvider.isAuthenticated) return;
      context.read<AppDataProvider>().loadStats();
    });
  }

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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.textLight.withOpacity(0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
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
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_graph,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Прогресс',
                            style: AppTextStyles.h4.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${stats.progressPercent.toStringAsFixed(1)}%',
                        style: AppTextStyles.h1.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'От коллекции стихов',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: stats.progressPercent / 100,
                          minHeight: 8,
                          backgroundColor: AppColors.textLight.withOpacity(
                            0.12,
                          ),
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${stats.poemsRead} прочитано • ${stats.poemsLearned} выучено • ${stats.favoritesCount} в избранном',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _buildModernStatCard(
                      icon: Icons.auto_stories,
                      label: 'Прочитано',
                      value: stats.poemsRead.toString(),
                      color: const Color(0xFF6366F1),
                    ),
                    _buildModernStatCard(
                      icon: Icons.school,
                      label: 'Выучено',
                      value: stats.poemsLearned.toString(),
                      color: const Color(0xFF22C55E),
                    ),
                    _buildModernStatCard(
                      icon: Icons.favorite,
                      label: 'Избранное',
                      value: stats.favoritesCount.toString(),
                      color: const Color(0xFFEC4899),
                    ),
                    _buildModernStatCard(
                      icon: Icons.library_books,
                      label: 'Всего',
                      value: stats.totalPoems.toString(),
                      color: const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildRankingWidget(stats.poemsLearned),
                if (context.watch<AppDataProvider>().appConfig?.paymentsEnabled == true) ...[
                  const SizedBox(height: 16),
                  _buildActionCard(
                    context,
                    icon: Icons.history,
                    title: 'История чтения',
                    subtitle: 'Открыть список стихов в порядке прочтения',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ReadHistoryScreen(),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _getMotivationalMessage(stats.progressPercent),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
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

  Widget _buildModernStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(
              fontSize: 26,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getMotivationalMessage(double progress) {
    if (progress < 10)
      return 'Хороший старт. Держите темп и расширяйте коллекцию постепенно.';
    if (progress < 30)
      return 'Прогресс уже заметен. Регулярность здесь важнее скорости.';
    if (progress < 50)
      return 'Середина близко. Вы читаете стабильно и это уже даёт эффект.';
    if (progress < 80)
      return 'Сильный результат. Осталось совсем немного до следующего уровня.';
    if (progress < 100)
      return 'Финиш рядом. Еще чуть-чуть — и коллекция будет почти закрыта.';
    return 'Коллекция закрыта. Дальше — только закрепление и скорость.';
  }

  ({String rank, String medal, Color color, int? nextThreshold}) _getRankInfo(
    int learned,
  ) {
    if (learned >= 5000) {
      return (
        rank: 'Профи',
        medal: 'Золото',
        color: const Color(0xFFFFD700),
        nextThreshold: null,
      );
    } else if (learned >= 2000) {
      return (
        rank: 'Мастер',
        medal: 'Серебро',
        color: const Color(0xFFC0C0C0),
        nextThreshold: 5000,
      );
    } else {
      return (
        rank: 'Новичок',
        medal: 'Бронза',
        color: const Color(0xFFCD7F32),
        nextThreshold: 2000,
      );
    }
  }

  Widget _buildRankingWidget(int learned) {
    final info = _getRankInfo(learned);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textLight.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ранг',
                style: AppTextStyles.h4.copyWith(color: AppColors.textPrimary),
              ),
              const Spacer(),
              _buildTierChip(
                label: info.rank,
                range: info.medal,
                color: info.color,
                active: true,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: info.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: info.color.withOpacity(0.22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.rank,
                  style: AppTextStyles.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                  ),
                ),
                Text(
                  info.medal,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: info.nextThreshold == null
                        ? 1.0
                        : (learned / info.nextThreshold!).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: AppColors.textLight.withOpacity(0.10),
                    color: info.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  info.nextThreshold == null
                      ? 'Все уровни достигнуты'
                      : 'До следующего ранга осталось ${info.nextThreshold! - learned}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTierChip(
            label: 'Новичок',
            range: '0 - 1999',
            color: const Color(0xFFCD7F32),
            active: learned < 2000,
          ),
          const SizedBox(height: 8),
          _buildTierChip(
            label: 'Мастер',
            range: '2000 - 4999',
            color: const Color(0xFFC0C0C0),
            active: learned >= 2000 && learned < 5000,
          ),
          const SizedBox(height: 8),
          _buildTierChip(
            label: 'Профи',
            range: 'от 5000',
            color: const Color(0xFFFFD700),
            active: learned >= 5000,
          ),
        ],
      ),
    );
  }

  Widget _buildTierChip({
    required String label,
    required String range,
    required Color color,
    required bool active,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? color.withOpacity(0.55)
              : AppColors.textLight.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 8 : 10,
            height: compact ? 8 : 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: active ? AppColors.textPrimary : AppColors.textLight,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            range,
            style: AppTextStyles.bodySmall.copyWith(
              color: active ? AppColors.textPrimary : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.textLight.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textLight, size: 22),
            ],
          ),
        ),
      ),
    );
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
