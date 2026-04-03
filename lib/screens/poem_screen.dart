import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/common_widgets.dart';
import '../providers/poem_provider.dart';
import '../providers/app_data_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reader_settings_provider.dart';
import '../models/poem.dart';

class PoemScreen extends StatefulWidget {
  final int poemId;

  const PoemScreen({super.key, required this.poemId});

  @override
  State<PoemScreen> createState() => _PoemScreenState();
}

class _PoemScreenState extends State<PoemScreen> {
  bool _hideContextWords = false;
  bool _focusHighlightsOnly = false;
  bool _isInitialPageSyncing = false;
  bool _isProgrammaticPageSync = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPoem();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPoem() async {
    final poemProvider = context.read<PoemProvider>();
    await poemProvider.loadPoemWithLetterPoems(widget.poemId);

    if (!mounted) return;

    final initialIndex = poemProvider.currentLetterPoemIndex.clamp(
      0,
      poemProvider.poemsForLetter.isEmpty
          ? 0
          : poemProvider.poemsForLetter.length - 1,
    );

    _pageController.dispose();
    _pageController = PageController(initialPage: initialIndex);

    setState(() {
      _isInitialPageSyncing = false;
      _isProgrammaticPageSync = false;
    });

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

  void _showAccentColorPicker() {
    final readerSettings = context.read<ReaderSettingsProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Цвет акцента',
                  style: AppTextStyles.h4.copyWith(
                    color: readerSettings.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: readerSettings.availableAccentColors.map((accent) {
                    final selected = readerSettings.accentColor == accent;
                    final color = readerSettings.colorForAccent(accent);
                    return InkWell(
                      onTap: () {
                        readerSettings.setAccentColor(accent);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? color : Colors.black12,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_accentColorLabel(accent)),
                            if (selected) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.check, size: 16, color: color),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                Text(
                  'Тема фона',
                  style: AppTextStyles.h4.copyWith(
                    color: readerSettings.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: readerSettings.availableBackgroundModes.map((mode) {
                    final selected = readerSettings.backgroundMode == mode;
                    final color = readerSettings.colorForBackgroundMode(mode);
                    final isDark = mode == ReaderBackgroundMode.dark;
                    return InkWell(
                      onTap: () {
                        readerSettings.setBackgroundMode(mode);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? color.withOpacity(0.15) : null,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.black12,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _backgroundModeLabel(mode),
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: readerSettings.primaryTextColor,
                              ),
                            ),
                            if (selected) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.check,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _accentColorLabel(ReaderAccentColor color) {
    switch (color) {
      case ReaderAccentColor.green:
        return 'Зелёный';
      case ReaderAccentColor.red:
        return 'Красный';
      case ReaderAccentColor.gold:
        return 'Золотой';
      case ReaderAccentColor.blue:
        return 'Синий';
      case ReaderAccentColor.purple:
        return 'Фиолетовый';
    }
  }

  String _backgroundModeLabel(ReaderBackgroundMode mode) {
    switch (mode) {
      case ReaderBackgroundMode.white:
        return 'Белый';
      case ReaderBackgroundMode.dark:
        return 'Чёрный';
      case ReaderBackgroundMode.papyrus:
        return 'Папирус';
    }
  }

  @override
  Widget build(BuildContext context) {
    final readerSettings = context.watch<ReaderSettingsProvider>();

    return Scaffold(
      backgroundColor: readerSettings.backgroundColor,
      body: Consumer<PoemProvider>(
        builder: (context, poemProvider, _) {
          if (poemProvider.isLoading) {
            return _buildPoemSkeleton(readerSettings);
          }

          final poem = poemProvider.currentPoem;
          if (poem == null || poemProvider.poemsForLetter.isEmpty) {
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

          final poemPageView = PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (_isProgrammaticPageSync) return;

              if (index >= 0 && index < poemProvider.poemsForLetter.length) {
                poemProvider.moveToPoem(index);
              }
            },
            itemCount: poemProvider.poemsForLetter.length,
            itemBuilder: (context, index) =>
                _buildPoemPage(poemProvider, index, readerSettings),
          );

          if (!_isInitialPageSyncing) {
            return poemPageView;
          }

          return Stack(
            children: [
              poemPageView,
              Positioned.fill(
                child: IgnorePointer(child: _buildPoemSkeleton(readerSettings)),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<PoemProvider>(
        builder: (context, poemProvider, _) {
          if (poemProvider.isLoading || _isInitialPageSyncing) {
            return const SizedBox.shrink();
          }

          final readerSettings = context.watch<ReaderSettingsProvider>();
          const themePrimaryColor = AppColors.primary;
          final poem = poemProvider.currentPoem;
          if (poem == null) return const SizedBox.shrink();

          final previousPoem = poemProvider.previousPoem;
          final nextPoem = poemProvider.nextPoem;

          return Container(
            decoration: BoxDecoration(
              color: readerSettings.cardColor,
              border: Border(
                top: BorderSide(
                  color: readerSettings.primaryTextColor.withOpacity(0.12),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(
                    readerSettings.backgroundMode == ReaderBackgroundMode.dark
                        ? 0.25
                        : 0.07,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: SafeArea(
              child: Row(
                children: [
                  // Previous Button
                  Expanded(
                    child: _buildNavButton(
                      readerSettings: readerSettings,
                      enabled: poemProvider.hasPreviousPoem,
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      icon: Icons.arrow_back_ios_new,
                      label: previousPoem?.word ?? 'Предыдущий',
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Center Toggle Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: themePrimaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _hideContextWords = !_hideContextWords;
                            });
                          },
                          icon: Icon(
                            _hideContextWords
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                          tooltip: _hideContextWords ? 'Показать' : 'Скрыть',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          gradient: _focusHighlightsOnly
                              ? AppColors.accentGradient
                              : AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_focusHighlightsOnly
                                          ? AppColors.accent
                                          : themePrimaryColor)
                                      .withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _focusHighlightsOnly = !_focusHighlightsOnly;
                            });
                          },
                          icon: Icon(
                            _focusHighlightsOnly
                                ? Icons.filter_center_focus
                                : Icons.filter_center_focus_outlined,
                            color: Colors.white,
                          ),
                          tooltip: _focusHighlightsOnly
                              ? 'Показать весь текст'
                              : 'Режим фокуса',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Next Button
                  Expanded(
                    child: _buildNavButton(
                      readerSettings: readerSettings,
                      enabled: poemProvider.hasNextPoem,
                      onPressed: () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      icon: Icons.arrow_forward_ios,
                      label: nextPoem?.word ?? 'Следующий',
                      isNext: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPoemPage(
    PoemProvider poemProvider,
    int index,
    ReaderSettingsProvider readerSettings,
  ) {
    final poem = poemProvider.poemsForLetter[index];
    final totalPoemsInLetter = poemProvider.poemsForLetter.length;
    final currentPoemNumber = index + 1;
    final poemsRemaining = totalPoemsInLetter > currentPoemNumber
        ? totalPoemsInLetter - currentPoemNumber
        : 0;

    return CustomScrollView(
      slivers: [
        // Modern App Bar
        SliverAppBar(
          expandedHeight: 132,
          pinned: true,
          elevation: 0,
          backgroundColor: readerSettings.appPrimaryColor,
          leading: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 0, 8),
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
              margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$currentPoemNumber/$totalPoemsInLetter',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.palette_outlined, color: Colors.white),
                onPressed: _showAccentColorPicker,
                tooltip: 'Цвет акцента',
              ),
            ),
            Container(
              margin: const EdgeInsets.fromLTRB(8, 8, 16, 8),
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
                      color: isFavorite
                          ? readerSettings.accentTextColor
                          : Colors.white,
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
              decoration: BoxDecoration(
                gradient: readerSettings.appPrimaryGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        poem.word,
                        style: AppTextStyles.poemUppercase.copyWith(
                          color: Colors.white,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        poem.phonetic,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontFamily: 'PhoneticTM',
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      // const SizedBox(height: 8),
                      // Text(
                      //   'Прочитано: $currentPoemNumber из $totalPoemsInLetter · Осталось: $poemsRemaining',
                      //   maxLines: 1,
                      //   overflow: TextOverflow.ellipsis,
                      //   style: AppTextStyles.bodySmall.copyWith(
                      //     color: Colors.white.withOpacity(0.88),
                      //     fontWeight: FontWeight.w600,
                      //     letterSpacing: 0.15,
                      //   ),
                      // ),
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
                // Container(
                //   padding: const EdgeInsets.all(20),
                //   decoration: BoxDecoration(
                //     color: readerSettings.cardColor,
                //     borderRadius: BorderRadius.circular(20),
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withOpacity(0.06),
                //         blurRadius: 16,
                //         offset: const Offset(0, 4),
                //       ),
                //     ],
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Row(
                //         children: [
                //           Container(
                //             padding: const EdgeInsets.all(8),
                //             decoration: BoxDecoration(
                //               gradient: AppColors.primaryGradient,
                //               borderRadius: BorderRadius.circular(10),
                //             ),
                //             child: const Icon(
                //               Icons.translate,
                //               color: Colors.white,
                //               size: 20,
                //             ),
                //           ),
                //           const SizedBox(width: 12),
                //           Text(
                //             'Значения',
                //             style: AppTextStyles.h4.copyWith(
                //               color: readerSettings.primaryTextColor,
                //               fontWeight: FontWeight.w600,
                //             ),
                //           ),
                //         ],
                //       ),
                //       const SizedBox(height: 16),
                //       Text(
                //         poem.meanings,
                //         style: AppTextStyles.bodyMedium.copyWith(
                //           height: 1.6,
                //           fontSize: 15,
                //           color: readerSettings.primaryTextColor,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                // const SizedBox(height: 24),
                // // Poem Header
                // Row(
                //   children: [
                //     Container(
                //       padding: const EdgeInsets.symmetric(
                //         horizontal: 16,
                //         vertical: 8,
                //       ),
                //       decoration: BoxDecoration(
                //         gradient: AppColors.accentGradient,
                //         borderRadius: BorderRadius.circular(12),
                //         boxShadow: [
                //           BoxShadow(
                //             color: AppColors.accent.withOpacity(0.3),
                //             blurRadius: 8,
                //             offset: const Offset(0, 2),
                //           ),
                //         ],
                //       ),
                //       child: Row(
                //         children: [
                //           const Icon(
                //             Icons.auto_stories,
                //             size: 18,
                //             color: Colors.white,
                //           ),
                //           const SizedBox(width: 8),
                //           Text(
                //             'СТИХ',
                //             style: AppTextStyles.bodyMedium.copyWith(
                //               color: Colors.white,
                //               fontWeight: FontWeight.bold,
                //               letterSpacing: 1.2,
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //     const Spacer(),
                //     if (!poem.isFree)
                //       Container(
                //         padding: const EdgeInsets.symmetric(
                //           horizontal: 14,
                //           vertical: 8,
                //         ),
                //         decoration: BoxDecoration(
                //           gradient: AppColors.primaryGradient,
                //           borderRadius: BorderRadius.circular(12),
                //           boxShadow: [
                //             BoxShadow(
                //               color: AppColors.primary.withOpacity(0.3),
                //               blurRadius: 8,
                //               offset: const Offset(0, 2),
                //             ),
                //           ],
                //         ),
                //         child: Row(
                //           children: [
                //             const Icon(
                //               Icons.workspace_premium,
                //               size: 16,
                //               color: Colors.white,
                //             ),
                //             const SizedBox(width: 6),
                //             Text(
                //               'PRO',
                //               style: AppTextStyles.bodyMedium.copyWith(
                //                 color: Colors.white,
                //                 fontWeight: FontWeight.bold,
                //                 fontSize: 12,
                //                 letterSpacing: 1.0,
                //               ),
                //             ),
                //           ],
                //         ),
                //       ),
                //   ],
                // ),
                const SizedBox(height: 16),
                // Poem Text Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  // padding: const EdgeInsets.all(24),
                  // decoration: BoxDecoration(
                  //   color: readerSettings.cardColor,
                  //   borderRadius: BorderRadius.circular(20),
                  //   boxShadow: [
                  //     BoxShadow(
                  //       color: Colors.black.withOpacity(0.06),
                  //       blurRadius: 16,
                  //       offset: const Offset(0, 4),
                  //     ),
                  //   ],
                  // ),
                  child: _buildPoemText(poem.tokens, readerSettings),
                ),
                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required ReaderSettingsProvider readerSettings,
    required bool enabled,
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    bool isNext = false,
  }) {
    const primary = AppColors.primary;
    final disabled = AppColors.textLight.withOpacity(0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.textLight.withOpacity(0.06),
            border: Border.all(
              color: enabled
                  ? AppColors.primary.withOpacity(0.32)
                  : AppColors.textLight.withOpacity(0.16),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: isNext
                ? [
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: enabled ? primary : disabled,
                          fontWeight: FontWeight.w600,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(icon, size: 14, color: enabled ? primary : disabled),
                  ]
                : [
                    Icon(icon, size: 14, color: enabled ? primary : disabled),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: enabled ? primary : disabled,
                          fontWeight: FontWeight.w600,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }

  Widget _buildPoemSkeleton(ReaderSettingsProvider readerSettings) {
    final skeletonBase =
        readerSettings.backgroundMode == ReaderBackgroundMode.dark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final skeletonStrong =
        readerSettings.backgroundMode == ReaderBackgroundMode.dark
        ? Colors.white.withOpacity(0.14)
        : Colors.black.withOpacity(0.1);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 132,
          pinned: true,
          elevation: 0,
          backgroundColor: readerSettings.appPrimaryColor,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              width: 40,
              height: 40,
            ),
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              width: 40,
              height: 40,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Container(
              decoration: BoxDecoration(
                gradient: readerSettings.appPrimaryGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildSkeletonLine(
                        190,
                        28,
                        Colors.white.withOpacity(0.32),
                      ),
                      const SizedBox(height: 8),
                      _buildSkeletonLine(
                        120,
                        16,
                        Colors.white.withOpacity(0.22),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildSkeletonLine(double.infinity, 26, skeletonStrong),
                const SizedBox(height: 14),
                _buildSkeletonLine(double.infinity, 22, skeletonBase),
                const SizedBox(height: 10),
                _buildSkeletonLine(double.infinity, 22, skeletonBase),
                const SizedBox(height: 10),
                _buildSkeletonLine(280, 22, skeletonBase),
                const SizedBox(height: 24),
                _buildSkeletonLine(double.infinity, 22, skeletonBase),
                const SizedBox(height: 10),
                _buildSkeletonLine(double.infinity, 22, skeletonBase),
                const SizedBox(height: 10),
                _buildSkeletonLine(240, 22, skeletonBase),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLine(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildPoemText(
    List<PoemToken> tokens,
    ReaderSettingsProvider readerSettings,
  ) {
    final children = <TextSpan>[];
    var isLineStart = true;

    for (final token in tokens) {
      TextStyle style;
      var displayText = token.text.replaceAll('\r', '');

      if (isLineStart) {
        displayText = displayText.replaceFirst(RegExp(r'^\s+'), '');
      }

      if (token.isUppercase) {
        style = AppTextStyles.poemUppercase.copyWith(
          color: readerSettings.accentTextColor,
        );
      } else if (token.isContext) {
        final shouldHideContextWord =
            _hideContextWords && !_focusHighlightsOnly;
        style = AppTextStyles.poemContextWord.copyWith(
          color: shouldHideContextWord
              ? Colors.transparent
              : readerSettings.primaryTextColor,
        );
      } else {
        final shouldHideRegularText = _focusHighlightsOnly;
        style = AppTextStyles.poemText.copyWith(
          color: shouldHideRegularText
              ? Colors.transparent
              : readerSettings.primaryTextColor,
        );
      }

      children.add(TextSpan(text: displayText, style: style));

      if (displayText.contains('\n')) {
        isLineStart =
            displayText.endsWith('\n') ||
            RegExp(r'\n\s*$').hasMatch(displayText);
      } else if (displayText.isNotEmpty && displayText.trim().isNotEmpty) {
        isLineStart = false;
      }
    }

    return RichText(
      text: TextSpan(children: children),
      textAlign: TextAlign.left,
    );
  }
}
