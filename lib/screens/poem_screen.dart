import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/common_widgets.dart';
import '../providers/poem_provider.dart';
import '../providers/app_data_provider.dart';
import '../providers/auth_provider.dart';
import '../models/poem.dart';

class PoemScreen extends StatefulWidget {
  final int poemId;

  const PoemScreen({super.key, required this.poemId});

  @override
  State<PoemScreen> createState() => _PoemScreenState();
}

class _PoemScreenState extends State<PoemScreen> {
  bool _hideContextWords = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPoem();
    });
  }

  Future<void> _loadPoem() async {
    await context.read<PoemProvider>().loadPoemById(widget.poemId);

    if (!mounted) return;

    final poemProvider = context.read<PoemProvider>();
    if (poemProvider.error != null) {
      if (poemProvider.error!.contains('403') ||
          poemProvider.error!.contains('Subscription required')) {
        _showSubscriptionDialog();
      } else {
        ErrorSnackbar.show(context, poemProvider.error!);
      }
    }
  }

  void _showSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.lock, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Premium контент'),
          ],
        ),
        content: Text(
          'Этот стих доступен только с Premium подпиской. '
          'Подпишитесь, чтобы разблокировать все стихи!',
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
              Navigator.of(context).pushNamed('/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Подписаться'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(Poem poem) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ErrorSnackbar.show(context, 'Войдите, чтобы добавить в избранное');
      return;
    }

    final appDataProvider = context.read<AppDataProvider>();
    final isFavorite = appDataProvider.isFavorite(poem.id);

    final success = isFavorite
        ? await appDataProvider.removeFromFavorites(poem.id)
        : await appDataProvider.addToFavorites(poem.id);

    if (!mounted) return;

    if (success) {
      SuccessSnackbar.show(
        context,
        isFavorite ? 'Удалено из избранного' : 'Добавлено в избранное',
      );
    } else if (appDataProvider.error != null) {
      ErrorSnackbar.show(context, appDataProvider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PoemProvider>(
        builder: (context, poemProvider, _) {
          if (poemProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final poem = poemProvider.currentPoem;
          if (poem == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text('Стих недоступен', style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Назад'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Modern App Bar with gradient
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.primary,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Consumer<AppDataProvider>(
                      builder: (context, appDataProvider, _) {
                        final isFavorite = appDataProvider.isFavorite(poem.id);
                        return IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? AppColors.accent : Colors.white,
                          ),
                          onPressed: () => _toggleFavorite(poem),
                        );
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              poem.word,
                              style: AppTextStyles.h1.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              poem.phonetic,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Meanings Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.translate,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Значения',
                                  style: AppTextStyles.h4.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              poem.meanings,
                              style: AppTextStyles.bodyMedium.copyWith(
                                height: 1.6,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Poem Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.accentGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_stories,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'СТИХ',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (!poem.isFree)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.workspace_premium,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'PRO',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Poem Text Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildPoemText(poem.tokens),
                      ),
                      const SizedBox(height: 100), // Space for FAB
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<PoemProvider>(
        builder: (context, poemProvider, _) {
          if (poemProvider.currentPoem == null) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              setState(() {
                _hideContextWords = !_hideContextWords;
              });
            },
            backgroundColor: _hideContextWords
                ? AppColors.accent
                : AppColors.primary,
            icon: Icon(
              _hideContextWords ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            label: Text(
              _hideContextWords ? 'Показать' : 'Скрыть',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPoemText(List<PoemToken> tokens) {
    return RichText(
      text: TextSpan(
        children: tokens.map((token) {
          TextStyle style;
          String displayText = token.text;

          if (token.isUppercase) {
            // Convert to uppercase and apply accent color
            // displayText = token.text.toUpperCase();
            style = AppTextStyles.poemUppercase.copyWith(
              fontSize: 17,
              height: 1.8,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            );
          } else if (token.isContext) {
            // Apply transparency when hideContextWords is true
            style = AppTextStyles.poemContextWord.copyWith(
              fontSize: 17,
              height: 1.8,
              color: _hideContextWords
                  ? Colors.transparent
                  // : AppTextStyles.poemContextWord.color,
                  : AppColors.textPrimary,
            );
          } else {
            style = AppTextStyles.poemText.copyWith(fontSize: 17, height: 1.8);
          }

          return TextSpan(text: displayText, style: style);
        }).toList(),
      ),
      textAlign: TextAlign.left,
    );
  }
}
