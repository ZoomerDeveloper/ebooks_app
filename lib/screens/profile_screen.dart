import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/gradient_button.dart';
import '../providers/auth_provider.dart';
import '../providers/app_data_provider.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: Text('Профиль', style: AppTextStyles.h3),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Email
                    Text(
                      user?.email ?? 'Guest',
                      style: AppTextStyles.h4.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    if (user?.name != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user!.name!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Subscription Status
              Consumer<AppDataProvider>(
                builder: (context, appDataProvider, _) {
                  final subscription = appDataProvider.subscription;

                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.textLight.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              subscription?.hasSubscription == true
                                  ? Icons.workspace_premium
                                  : Icons.lock_outline,
                              color: subscription?.hasSubscription == true
                                  ? AppColors.accent
                                  : AppColors.textLight,
                            ),
                            const SizedBox(width: 12),
                            Text('Статус подписки', style: AppTextStyles.h4),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          subscription?.hasSubscription == true
                              ? 'Premium активна'
                              : 'Бесплатный план',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: subscription?.hasSubscription == true
                                ? AppColors.success
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subscription?.expiresAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Истекает: ${DateFormat('dd MMM yyyy', 'ru').format(subscription!.expiresAt!)}',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                        if (subscription?.hasSubscription != true) ...[
                          const SizedBox(height: 16),
                          GradientButton(
                            text: 'Обновить до Premium',
                            onPressed: () {
                              Navigator.of(context).pushNamed('/subscription');
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Quick Links
              _buildQuickLink(
                icon: Icons.bar_chart,
                title: 'Статистика',
                onTap: () {
                  Navigator.of(context).pushNamed('/stats');
                },
              ),
              const SizedBox(height: 12),
              _buildQuickLink(
                icon: Icons.favorite,
                title: 'Избранное',
                onTap: () {
                  Navigator.of(context).pushNamed('/favorites');
                },
              ),
              const SizedBox(height: 12),
              _buildQuickLink(
                icon: Icons.subscriptions,
                title: 'Premium',
                onTap: () {
                  Navigator.of(context).pushNamed('/subscription');
                },
              ),
              const SizedBox(height: 32),
              // Logout Button
              GradientButton(
                text: 'Выйти',
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/home', (route) => false);
                  }
                },
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickLink({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textLight.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 16),
            Text(title, style: AppTextStyles.bodyLarge),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
