import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_text_styles.dart';
import '../../models/app_config.dart';
import '../../providers/app_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common_widgets.dart';
import '../payment_webview_screen.dart';
import '../webview_screen.dart';

class PremiumTab extends StatefulWidget {
  const PremiumTab({super.key});

  @override
  State<PremiumTab> createState() => _PremiumTabState();
}

class _PremiumTabState extends State<PremiumTab> {
  String _selectedPlanId = 'sub_1m';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appDataProvider = context.read<AppDataProvider>();
      appDataProvider.loadAppConfig(forceRefresh: true);

      if (context.read<AuthProvider>().isAuthenticated) {
        appDataProvider.loadSubscription(forceRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, appDataProvider, _) {
        final config = appDataProvider.appConfig;
        final subscription = appDataProvider.subscription;
        final paymentsEnabled = config?.paymentsEnabled ?? false;
        final plans = config?.subscriptionPlans ?? const <SubscriptionPlan>[];
        final authProvider = context.watch<AuthProvider>();
        final isGuest = !authProvider.isAuthenticated;

        // Keep selected plan valid if plans change
        if (plans.isNotEmpty && !plans.any((p) => p.planId == _selectedPlanId)) {
          _selectedPlanId = plans.first.planId;
        }

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
                      icon: Icons.favorite,
                      title: 'Безлимитное избранное',
                      description: 'Сохраняйте сколько угодно стихов',
                    ),
                    _buildFeature(
                      icon: Icons.bar_chart,
                      title: 'Расширенная статистика',
                      description: 'Отслеживайте прогресс обучения детально',
                    ),
                    const SizedBox(height: 32),
                    if (!paymentsEnabled) ...[
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
                                'Оплата временно недоступна.',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else if (isGuest) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.textLight.withOpacity(0.25),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Войдите, чтобы оформить подписку',
                              style: AppTextStyles.h4,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/login');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Войти',
                                  style: AppTextStyles.button,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else ...[
                      Text('Выберите тариф', style: AppTextStyles.h3),
                      const SizedBox(height: 16),
                      ...plans.asMap().entries.map((entry) {
                        final plan = entry.value;
                        final isBest = plan.planId == 'sub_12m';
                        return _buildPlanCard(plan, isBest: isBest);
                      }),
                      const SizedBox(height: 32),
                    ],
                    // Subscribe / active status
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
                                      'Подписка активна до ${DateFormat('dd MMM yyyy', 'ru').format(subscription!.expiresAt!)}',
                                      style: AppTextStyles.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (paymentsEnabled && !isGuest && plans.isNotEmpty) ...[
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
                      const SizedBox.shrink(),
                    ],
                    const SizedBox(height: 16),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textLight,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Оформляя подписку, вы соглашаетесь с ',
                          ),
                          TextSpan(
                            text: 'Политикой конфиденциальности',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const WebViewScreen(
                                        url: AppConstants.privacyPolicyUrl,
                                        title: 'Политика конфиденциальности',
                                      ),
                                    ),
                                  ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
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

  Widget _buildPlanCard(SubscriptionPlan plan, {bool isBest = false}) {
    final selected = _selectedPlanId == plan.planId;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlanId = plan.planId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppColors.primaryLight.withOpacity(0.25),
                    AppColors.accentLight.withOpacity(0.15),
                  ],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.textLight.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.textLight,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.title,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isBest) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Выгодно',
                            style: AppTextStyles.overline.copyWith(
                              color: Colors.white,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _perMonthLabel(plan),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Price
            Text(
              '${_formatRub(plan.amountRub)} ₽',
              style: AppTextStyles.h4.copyWith(
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _perMonthLabel(SubscriptionPlan plan) {
    if (plan.months == 1) return 'в месяц';
    final perMonth = (plan.amountRub / plan.months).round();
    return '≈ $perMonth ₽/мес';
  }

  String _formatRub(double amount) {
    if (amount == amount.roundToDouble()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
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

      final paymentResponse = await appDataProvider.createPayment(
        planId: _selectedPlanId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      final checkoutUrl = paymentResponse?['checkout_url']?.toString();
      if (checkoutUrl != null && checkoutUrl.isNotEmpty && context.mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              checkoutUrl: checkoutUrl,
              returnUrlPrefix: AppConstants.paymentReturnUrl,
            ),
          ),
        );

        if (result == true && context.mounted) {
          await _refreshSubscriptionWithRetry(appDataProvider);

          if (!context.mounted) return;

          if (appDataProvider.subscription?.hasSubscription == true) {
            SuccessSnackbar.show(context, 'Оплата прошла успешно. Подписка активна.');
          } else {
            SuccessSnackbar.show(
              context,
              'Оплата принята. Обновление подписки может занять несколько секунд.',
            );
          }
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

  Future<void> _refreshSubscriptionWithRetry(AppDataProvider appDataProvider) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      await appDataProvider.loadSubscription(forceRefresh: true);
      if (appDataProvider.subscription?.hasSubscription == true) {
        return;
      }
      if (attempt < 2) {
        await Future.delayed(const Duration(seconds: 2));
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

