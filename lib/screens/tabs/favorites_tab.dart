import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/poem_card.dart';
import '../../providers/app_data_provider.dart';

class FavoritesTab extends StatelessWidget {
  final VoidCallback onNavigateToHome;

  const FavoritesTab({super.key, required this.onNavigateToHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Избранное', style: AppTextStyles.h3),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<AppDataProvider>(
        builder: (context, appDataProvider, _) {
          if (appDataProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final favorites = appDataProvider.favorites;

          if (favorites.isEmpty) {
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
                      Icons.favorite_border,
                      size: 80,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Пока нет избранных',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Начните добавлять любимые стихи!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: onNavigateToHome,
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
                    child: Text('Открыть стихи', style: AppTextStyles.button),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final poem = favorites[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: Key(poem.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('Удалить из избранного?'),
                        content: Text(
                          'Вы уверены, что хотите удалить "${poem.word}" из избранного?',
                          style: AppTextStyles.bodyMedium,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'Отмена',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    appDataProvider.removeFromFavorites(poem.id);
                  },
                  child: PoemCard(
                    poem: poem,
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pushNamed('/poem', arguments: poem.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
