import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/app_data_provider.dart';
import 'tabs/premium_tab.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDataProvider>(
      builder: (context, appDataProvider, _) {
        final config = appDataProvider.appConfig;
        if (config == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            appDataProvider.loadAppConfig(forceRefresh: true);
          });
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!config.paymentsEnabled) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text('Подписка', style: AppTextStyles.h3),
              backgroundColor: AppColors.background,
              elevation: 0,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Функция временно недоступна.',
                  style: AppTextStyles.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              const PremiumTab(),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: Material(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
