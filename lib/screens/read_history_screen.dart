import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../providers/app_data_provider.dart';
import '../widgets/poem_card.dart';

class ReadHistoryScreen extends StatefulWidget {
  const ReadHistoryScreen({super.key});

  @override
  State<ReadHistoryScreen> createState() => _ReadHistoryScreenState();
}

class _ReadHistoryScreenState extends State<ReadHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadReadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('История чтения', style: AppTextStyles.h3),
        backgroundColor: AppColors.background,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: Consumer<AppDataProvider>(
        builder: (context, appDataProvider, _) {
          if (appDataProvider.isLoadingReadHistory) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = appDataProvider.readHistory;
          final error = appDataProvider.error;

          if (history.isEmpty && error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                      'История чтения недоступна',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          if (history.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                        Icons.history,
                        size: 80,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Пока нет истории чтения',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Откройте стих, и он появится здесь после того, как бэк начнёт отдавать историю прочитанного.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final poem = history[index];
              return PoemCard(
                poem: poem,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/poem',
                    arguments: poem.id,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}