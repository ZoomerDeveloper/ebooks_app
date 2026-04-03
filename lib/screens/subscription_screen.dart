import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/gradient_button.dart';
import '../widgets/common_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/app_data_provider.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadAppConfig();
      context.read<AppDataProvider>().loadSubscription();
    });
  }

  Future<void> _handlePayment() async {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      _showLoginDialog();
      return;
    }

    final appDataProvider = context.read<AppDataProvider>();
    final checkoutUrl = await appDataProvider.createPayment();

    if (!mounted) return;

    if (checkoutUrl != null) {
      final uri = Uri.parse(checkoutUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Show message about returning
        if (mounted) {
          SuccessSnackbar.show(
            context,
            'Завершите оплату в браузере. Ваша подписка будет активирована автоматически.',
          );
        }
      } else {
        ErrorSnackbar.show(context, 'Не удалось открыть страницу оплаты');
      }
    } else if (appDataProvider.error != null) {
      ErrorSnackbar.show(context, appDataProvider.error!);
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.login, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Требуется вход'),
          ],
        ),
        content: Text(
          'Войдите или создайте аккаунт, чтобы оформить подписку.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Отмена',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Premium', style: AppTextStyles.h3),
        backgroundColor: AppColors.background,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: Consumer<AppDataProvider>(
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
                  padding: const EdgeInsets.all(32),
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
                                  '\$',
                                  style: AppTextStyles.h3.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  '9.99',
                                  style: AppTextStyles.h1.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 48,
                                  ),
                                ),
                                Text(
                                  '/mo',
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
                        GradientButton(
                          text: 'Оформить подписку',
                          onPressed: _handlePayment,
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
      ),
    );
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
