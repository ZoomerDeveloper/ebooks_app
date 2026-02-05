import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../payment_webview_screen.dart';

class PremiumTab extends StatelessWidget {
  const PremiumTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, appDataProvider, _) {
        final config = appDataProvider.appConfig;
        final subscription = appDataProvider.subscription;
        final paymentsEnabled = config?.paymentsEnabled ?? false;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 32,
                  right: 32,
                  bottom: 32,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.workspace_premium,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Откройте Premium',
                      style: AppTextStyles.h2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Доступ ко всем стихам и возможностям',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              // Features
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Premium функции', style: AppTextStyles.h3),
                    const SizedBox(height: 16),
                    _buildFeature(
                      icon: Icons.all_inclusive,
                      title: 'Неограниченный доступ',
                      description: 'Читайте все стихи без ограничений',
                    ),
                    _buildFeature(
                      icon: Icons.download,
                      title: 'Оффлайн доступ',
                      description: 'Скачивайте стихи для чтения оффлайн',
                    ),
                    _buildFeature(
                      icon: Icons.favorite,
                      title: 'Безлимитное избранное',
                      description: 'Сохраняйте сколько угодно стихов',
                    ),
                    _buildFeature(
                      icon: Icons.bar_chart,
                      title: 'Расширенная статистика',
                      description: 'Отслеживайте прогресс обучения детально',
                    ),
                    _buildFeature(
                      icon: Icons.notifications,
                      title: 'Ежедневные напоминания',
                      description:
                          'Получайте уведомления для ежедневной практики',
                    ),
                    _buildFeature(
                      icon: Icons.stars,
                      title: 'Ранний доступ',
                      description: 'Получайте новые стихи раньше всех',
                    ),
                    const SizedBox(height: 32),
                    // Pricing
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryLight.withOpacity(0.2),
                            AppColors.accentLight.withOpacity(0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                config?.subscriptionAmountRub ?? '299',
                                style: AppTextStyles.h1.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₽',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                '/мес',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Отменить можно в любое время',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Subscribe Button
                    if (subscription?.hasSubscription == true) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.success.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Premium активна',
                                    style: AppTextStyles.h4.copyWith(
                                      color: AppColors.success,
                                    ),
                                  ),
                                  if (subscription?.expiresAt != null)
                                    Text(
                                      'Продлевается автоматически',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (paymentsEnabled) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ElevatedButton(
                            onPressed: () => _handlePayment(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Оформить подписку',
                              style: AppTextStyles.button,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Подписки скоро будут доступны!',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Оформляя подписку, вы соглашаетесь с Условиями использования и Политикой конфиденциальности.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handlePayment(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      Navigator.of(context).pushNamed('/login');
      return;
    }

    final appDataProvider = context.read<AppDataProvider>();

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('Подготовка оплаты...'),
              ],
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      final checkoutUrl = await appDataProvider.createPayment();

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (checkoutUrl != null && context.mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PaymentWebViewScreen(checkoutUrl: checkoutUrl),
          ),
        );

        if (result == true && context.mounted) {
          SuccessSnackbar.show(
            context,
            'Оплата завершена! Подписка будет активирована в ближайшее время.',
          );
          appDataProvider.loadSubscription();
        }
      } else if (context.mounted) {
        ErrorSnackbar.show(
          context,
          appDataProvider.error ?? 'Не удалось создать платёж',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ErrorSnackbar.show(context, 'Ошибка при создании платежа: $e');
      }
    }
  }

  Widget _buildFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
