import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../constants/app_text_styles.dart';
import '../widgets/common_widgets.dart';
import '../providers/poem_provider.dart';
import '../providers/app_data_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/reader_settings_provider.dart';
import '../services/storage_service.dart';
import '../models/poem.dart';

class PoemScreenArgs {
  final int poemId;
  final bool openedFromLetter;

  const PoemScreenArgs({required this.poemId, this.openedFromLetter = false});
}

class PoemScreen extends StatefulWidget {
  final int poemId;
  // From the alphabet the meaning filter may swap the opened poem for the
  // nearest matching one; from favorites/search the tapped poem is kept.
  final bool openedFromLetter;

  const PoemScreen({
    super.key,
    required this.poemId,
    this.openedFromLetter = false,
  });

  @override
  State<PoemScreen> createState() => _PoemScreenState();
}

class _PoemScreenState extends State<PoemScreen> {
  bool _hideContextWords = false;
  bool _focusHighlightsOnly = false;
  bool _showMeaningLines = false;
  bool _isInitialPageSyncing = false;
  bool _isProgrammaticPageSync = false;
  bool _isLetterPoemsLoading = false;
  final Set<int> _learnedPoemIds = <int>{};
  Poem? _stablePoem; // locked snapshot shown while letter list is loading
  Key _pageViewKey = const ValueKey('initial');
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
    await poemProvider.loadPoemById(widget.poemId);

    if (!mounted) return;

    if (poemProvider.error != null) {
      if (poemProvider.error!.contains('403') ||
          poemProvider.error!.contains('Subscription required')) {
        _showSubscriptionDialog();
      } else {
        ErrorSnackbar.show(context, poemProvider.error!);
      }
      return;
    }

    _pageController.dispose();
    _pageController = PageController(initialPage: 0);

    // Lock the displayed poem so provider rebuilds can't swap it out
    _stablePoem = poemProvider.currentPoem;

    setState(() {
      _isInitialPageSyncing = false;
      _isProgrammaticPageSync = false;
      _isLetterPoemsLoading = true;
    });

    final letter = poemProvider.currentPoem?.letter ?? '';
    final settings = context.read<ReaderSettingsProvider>();
    final filter = settings.meaningFilterFor(letter);
    final openedPoemStub = poemProvider.currentPoem;

    var loadedAllLetters = false;
    if (settings.meaningFilterAllLetters &&
        filter.isNotEmpty &&
        openedPoemStub != null) {
      loadedAllLetters = await poemProvider.loadAllLettersPoems(
        anchor: openedPoemStub,
        meaningFilter: filter,
        keepAnchor: !widget.openedFromLetter,
      );
      if (!mounted) return;
      if (!loadedAllLetters) _showNoMeaningFilterMatches(null);
    }
    if (!loadedAllLetters) {
      await poemProvider.loadPoemWithLetterPoems(
        widget.poemId,
        showLoading: false,
        meaningFilter: settings.meaningFilterAllLetters ? const {} : filter,
        keepOpenedPoem: !widget.openedFromLetter,
      );
    }

    if (!mounted) return;

    if (poemProvider.meaningFilterHasNoMatches) {
      _showNoMeaningFilterMatches(letter);
    }
    final openedPoem = poemProvider.currentPoem;
    if (openedPoem != null && openedPoem.id != widget.poemId) {
      _saveLetterProgress(openedPoem);
    }

    final initialIndex = poemProvider.currentLetterPoemIndex.clamp(
      0,
      poemProvider.poemsForLetter.isEmpty
          ? 0
          : poemProvider.poemsForLetter.length - 1,
    );

    // Create controller at correct page BEFORE setState so PageView
    // never renders the full list at page 0.
    _pageController.dispose();
    _pageController = PageController(initialPage: initialIndex);
    // Force PageView to be fully recreated so the new controller's
    // initialPage is used — swapping controllers on an existing PageView
    // causes Flutter to absorb the old scroll offset (page 0) instead.
    _pageViewKey = UniqueKey();

    setState(() {
      _isInitialPageSyncing = false;
      _isProgrammaticPageSync = false;
      _isLetterPoemsLoading = false;
      _stablePoem = null;
    });
  }

  void _saveLetterProgress(Poem poem) {
    final letter = poem.letter.isNotEmpty
        ? poem.letter
        : context.read<PoemProvider>().currentLetter ?? '';
    if (letter.isEmpty) return;
    context.read<StorageService>().saveLastPoemIdForLetter(letter, poem.id);
  }

  /// [letter] is null when nothing matches in the whole catalogue.
  void _showNoMeaningFilterMatches(String? letter) {
    ErrorSnackbar.show(
      context,
      letter == null
          ? 'Нет стихов с выбранным количеством значений. Показаны все стихи.'
          : 'На букву $letter нет стихов с выбранным количеством значений. '
                'Показаны все стихи.',
    );
  }

  Future<void> _applyMeaningFilterFromSettings() async {
    if (!mounted || _isLetterPoemsLoading) return;
    final poemProvider = context.read<PoemProvider>();
    final settings = context.read<ReaderSettingsProvider>();
    final current = poemProvider.currentPoem;
    if (current == null) return;
    final letter = poemProvider.currentLetter ?? '';
    final filter = settings.meaningFilterFor(letter);

    if (settings.meaningFilterAllLetters && filter.isNotEmpty) {
      if (poemProvider.isAllLettersMode &&
          setEquals(filter, poemProvider.meaningFilter)) {
        return;
      }
      await _reloadPoemList(() async {
        final loaded = await poemProvider.loadAllLettersPoems(
          anchor: current,
          meaningFilter: filter,
        );
        if (!loaded && mounted) _showNoMeaningFilterMatches(null);
      });
      return;
    }

    if (poemProvider.isAllLettersMode) {
      await _reloadPoemList(
        () => poemProvider.loadPoemWithLetterPoems(
          current.id,
          showLoading: false,
          meaningFilter: filter,
          keepOpenedPoem: false,
        ),
      );
      if (mounted && poemProvider.meaningFilterHasNoMatches) {
        _showNoMeaningFilterMatches(letter);
      }
      return;
    }

    if (setEquals(filter, poemProvider.meaningFilter)) return;
    final listChanged = poemProvider.setMeaningFilter(filter);
    if (poemProvider.meaningFilterHasNoMatches) {
      _showNoMeaningFilterMatches(letter);
    }
    if (!listChanged) return;

    _replacePageController(poemProvider.currentLetterPoemIndex);
    final poem = poemProvider.currentPoem;
    if (poem != null) _saveLetterProgress(poem);
    setState(() {});
  }

  /// Shows the current poem alone while [load] replaces the list to page through.
  Future<void> _reloadPoemList(Future<void> Function() load) async {
    final poemProvider = context.read<PoemProvider>();
    setState(() {
      _stablePoem = poemProvider.currentPoem;
      _isLetterPoemsLoading = true;
    });
    await load();
    if (!mounted) return;

    _replacePageController(poemProvider.currentLetterPoemIndex);
    final poem = poemProvider.currentPoem;
    if (poem != null) _saveLetterProgress(poem);
    setState(() {
      _isLetterPoemsLoading = false;
      _stablePoem = null;
    });
  }

  void _replacePageController(int initialPage) {
    final oldController = _pageController;
    _pageController = PageController(initialPage: initialPage);
    _pageViewKey = UniqueKey();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
    });
  }

  void _showSubscriptionDialog() {
    final appDataProvider = context.read<AppDataProvider>();
    final authProvider = context.read<AuthProvider>();
    final paymentsEnabled = appDataProvider.appConfig?.paymentsEnabled == true;

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
            Text(paymentsEnabled ? 'Premium контент' : 'Стих недоступен'),
          ],
        ),
        content: Text(
          !paymentsEnabled
              ? 'Этот стих сейчас недоступен.'
              : (!authProvider.isAuthenticated
                    ? 'Войдите, чтобы получить доступ к стихам по подписке.'
                    : 'Этот стих доступен только с Premium подпиской. '
                          'Подпишитесь, чтобы разблокировать все стихи!'),
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
          if (paymentsEnabled)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (authProvider.isAuthenticated) {
                  Navigator.of(context).pushNamed('/subscription');
                } else {
                  Navigator.of(context).pushNamed('/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                authProvider.isAuthenticated ? 'Подписаться' : 'Войти',
              ),
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

  Future<void> _markAsLearned(Poem poem) async {
    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      ErrorSnackbar.show(context, 'Войдите, чтобы отметить стих как выученный');
      return;
    }

    final appDataProvider = context.read<AppDataProvider>();
    final success = await appDataProvider.markAsLearned(poem.id);

    if (!mounted) return;

    if (success) {
      setState(() {
        _learnedPoemIds.add(poem.id);
      });
      SuccessSnackbar.show(context, 'Отмечено как выученное');
    } else if (appDataProvider.error != null) {
      ErrorSnackbar.show(context, appDataProvider.error!);
    }
  }

  bool _isPoemLearned(Poem poem) {
    return poem.isLearned || _learnedPoemIds.contains(poem.id);
  }

  void _showAccentColorPicker() {
    final readerSettings = context.read<ReaderSettingsProvider>();
    final poemProvider = context.read<PoemProvider>();
    final meaningFilterLetter = poemProvider.currentLetter ?? '';
    poemProvider.loadCatalogMeaningCounts();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                const SizedBox(height: 22),
                Text(
                  'Размер шрифта',
                  style: AppTextStyles.h4.copyWith(
                    color: readerSettings.primaryTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<ReaderSettingsProvider>(
                  builder: (context, settings, _) {
                    return Row(
                      children: [
                        Text(
                          'A',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: readerSettings.primaryTextColor,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: settings.fontSizeScale,
                            min: 0.8,
                            max: 1.4,
                            divisions: 6,
                            activeColor: readerSettings.accentTextColor,
                            inactiveColor: Colors.black12,
                            onChanged: (value) {
                              settings.setFontSizeScale(value);
                            },
                          ),
                        ),
                        Text(
                          'A',
                          style: AppTextStyles.h3.copyWith(
                            color: readerSettings.primaryTextColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                _buildMeaningFilterSection(meaningFilterLetter),
              ],
            ),
          ),
        );
      },
    ).whenComplete(_applyMeaningFilterFromSettings);
  }

  Widget _buildMeaningFilterSection(String letter) {
    return Consumer2<ReaderSettingsProvider, PoemProvider>(
      builder: (context, settings, poemProvider, _) {
        final selection = settings.meaningFilterFor(letter);
        final allLetters = settings.meaningFilterAllLetters;
        const maxBucket = AppConstants.meaningFilterMaxBucket;

        final Set<int>? availableBuckets;
        if (allLetters) {
          availableBuckets = poemProvider.hasCatalogMeaningCounts
              ? poemProvider.catalogMeaningBuckets
              : null;
        } else {
          availableBuckets = poemProvider.hasLetterPoems
              ? poemProvider.availableMeaningBuckets
              : null;
        }
        // Selected buckets stay visible so a global selection can be undone.
        final visibleBuckets = availableBuckets != null
            ? ({...availableBuckets, ...selection}.toList()..sort())
            : [for (var bucket = 1; bucket <= maxBucket; bucket++) bucket];

        final String summary;
        if (selection.isEmpty) {
          summary = allLetters
              ? 'Выберите количество — покажем стихи из всех букв'
              : 'Показаны все стихи на букву $letter';
        } else if (allLetters && poemProvider.hasCatalogMeaningCounts) {
          summary =
              'Подходит стихов во всех буквах: '
              '${poemProvider.countCatalogPoemsMatchingMeaningFilter(selection)}';
        } else if (!allLetters && poemProvider.hasLetterPoems) {
          summary =
              'Подходит стихов на букву $letter: '
              '${poemProvider.countPoemsMatchingMeaningFilter(selection)}';
        } else {
          summary = '';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Количество значений',
                    style: AppTextStyles.h4.copyWith(
                      color: settings.primaryTextColor,
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: selection.isEmpty ? 0 : 1,
                  duration: const Duration(milliseconds: 180),
                  child: IgnorePointer(
                    ignoring: selection.isEmpty,
                    child: InkWell(
                      onTap: () => settings.clearMeaningFilter(letter),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Сбросить',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Сколько слов выделено в стихе. Можно выбрать несколько.',
              style: AppTextStyles.bodySmall.copyWith(
                color: settings.primaryTextColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            _buildMeaningFilterScopeSwitch(settings, letter),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final bucket in visibleBuckets)
                  _buildMeaningBucketChip(
                    settings: settings,
                    letter: letter,
                    bucket: bucket,
                    label: bucket == maxBucket ? '$maxBucket+' : '$bucket',
                    selected: selection.contains(bucket),
                  ),
              ],
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    selection.isEmpty
                        ? Icons.menu_book_rounded
                        : Icons.filter_alt_rounded,
                    size: 16,
                    color: selection.isEmpty
                        ? settings.primaryTextColor.withOpacity(0.5)
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      summary,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: settings.primaryTextColor.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMeaningFilterScopeSwitch(
    ReaderSettingsProvider settings,
    String letter,
  ) {
    Widget segment({
      required String label,
      required IconData icon,
      required bool allLetters,
    }) {
      final selected = settings.meaningFilterAllLetters == allLetters;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => settings.setMeaningFilterAllLetters(letter, allLetters),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.primaryGradient : null,
              borderRadius: BorderRadius.circular(10),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected
                      ? Colors.white
                      : settings.primaryTextColor.withOpacity(0.6),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: selected
                          ? Colors.white
                          : settings.primaryTextColor.withOpacity(0.7),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          segment(
            label: 'Буква $letter',
            icon: Icons.text_fields_rounded,
            allLetters: false,
          ),
          segment(
            label: 'Все буквы',
            icon: Icons.sort_by_alpha_rounded,
            allLetters: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMeaningBucketChip({
    required ReaderSettingsProvider settings,
    required String letter,
    required int bucket,
    required String label,
    required bool selected,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => settings.toggleMeaningFilterBucket(letter, bucket),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppColors.primaryGradient : null,
          color: selected ? null : AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: selected ? Colors.white : settings.primaryTextColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPoemGuide() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final readerSettings = context.watch<ReaderSettingsProvider>();
        return DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: readerSettings.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textLight.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  // Header
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Как читать стихи',
                          style: AppTextStyles.h4.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Scrollable content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _guideSection(
                          readerSettings: readerSettings,
                          icon: Icons.auto_stories,
                          title: 'Уважаемый читатель!',
                          body:
                              'Хотим представить вашему вниманию нашу работу и немного пояснительной информации, как устроены наши стихи.',
                        ),
                        _guideSection(
                          readerSettings: readerSettings,
                          icon: Icons.text_fields,
                          title: 'Первая строчка — произношение',
                          body:
                              'Когда вы видите первую строчку стиха, вы видите разбросанные жирные буквы синего цвета (цвет можно менять). Они всегда идут в начале каждого стиха в первой строчке.\n\nЕсли вы сложите и прочитаете эти синие буквы — вы получите, как звучит английское слово. Звучание будет на 100% совпадать с английским оригиналом.',
                        ),
                        _guideSection(
                          readerSettings: readerSettings,
                          icon: Icons.format_bold,
                          title: 'Жирные слова — значения',
                          body:
                              'В стихе вы видите слова, выделенные жирным курсивным чёрным шрифтом. Это значения данного английского слова.\n\nЧеловек, который выучивает один наш стих, тем самым заучивает и как английское слово звучит, произноситься русскими буквами, + он выучивает не одно, а много значений данного слова. Столько значений, сколько нам удалось поместить в каждый стих.',
                        ),
                        _guideSectionWithButtons(
                          readerSettings: readerSettings,
                        ),
                        _guideSection(
                          readerSettings: readerSettings,
                          icon: Icons.library_books,
                          title: 'О нашей коллекции',
                          body:
                              'Стихов более 7000. Каждый стих — это маленький рассказ со своим сюжетом, героями, сказочными и настоящими, реальными и вымышленными ситуациями из жизни.\n\nПомимо основного предназначения стихов — это помощь в запоминание английских слов и их значений, эти стихи можно читать и как просто стихи и получать удовольствие от прочитанного.\n\nНадеемся, что наша работа придется вам по душе и займет своё заслуженное место в вашей жизни.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _guideSection({
    required ReaderSettingsProvider readerSettings,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: readerSettings.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: readerSettings.primaryTextColor.withOpacity(0.08),
        ),
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
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h4.copyWith(
                    color: readerSettings.primaryTextColor,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            body,
            style: AppTextStyles.bodyMedium.copyWith(
              color: readerSettings.primaryTextColor.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideSectionWithButtons({
    required ReaderSettingsProvider readerSettings,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: readerSettings.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: readerSettings.primaryTextColor.withOpacity(0.08),
        ),
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
                  Icons.touch_app,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Две кнопки внизу экрана',
                  style: AppTextStyles.h4.copyWith(
                    color: readerSettings.primaryTextColor,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'В приложении есть две важные кнопки, которые для наглядности разбивают стих на два действия:',
            style: AppTextStyles.bodyMedium.copyWith(
              color: readerSettings.primaryTextColor.withOpacity(0.8),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          // Eye button explanation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.visibility,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Кнопка убирает выделенные жирным шрифтом значения английского слова.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: readerSettings.primaryTextColor.withOpacity(0.8),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Focus button explanation
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.filter_center_focus_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Кнопка убирает лишние строчки (связующие элементы стиха) и оставляет только как произноситься английское слово русскими буквами и значения английского слова. Остальные строчки отсутствуют.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: readerSettings.primaryTextColor.withOpacity(0.8),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Чередование этих кнопок призвано визуально помочь и облегчить работу человеку по запоминанию наших стихов.\n\nТак же эти две кнопки наглядно демонстрируют вам, как устроены стихи, по какому принципу они собраны и как они работают. У всех стихов одна и таже конструкция сборки, они все собраны по одному и то муже алгоритму. Поэтому поняв, как работает один стих, вы без труда разберетесь и со всеми остальными нашими стихами.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: readerSettings.primaryTextColor.withOpacity(0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
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

  void _showPoemsForCurrentLetter(PoemProvider poemProvider) {
    final poems = poemProvider.poemsForLetter;
    if (poems.isEmpty) return;

    final selectedPoemId = poemProvider.currentPoem?.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          bottom: false,
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.backgroundGradient,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.26),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              poemProvider.isAllLettersMode
                                  ? 'Подборка из всех букв'
                                  : 'Слова на эту букву',
                              style: AppTextStyles.h4.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${poems.length}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: poems.length,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemBuilder: (context, index) {
                        final poem = poems[index];
                        final isCurrent = poem.id == selectedPoemId;
                        final isLocked =
                            !poem.isFree &&
                            poem.tokens.isEmpty &&
                            !poemProvider.isPoemTextPending(poem);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                // Animating across many pages would load
                                // every poem in between.
                                final distance =
                                    (index -
                                            poemProvider.currentLetterPoemIndex)
                                        .abs();
                                if (distance > 3) {
                                  _pageController.jumpToPage(index);
                                } else {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeInOut,
                                  );
                                }
                              },
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isCurrent
                                      ? AppColors.primaryGradient
                                      : null,
                                  color: isCurrent ? null : AppColors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isCurrent
                                        ? Colors.transparent
                                        : AppColors.textLight.withOpacity(0.24),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isCurrent
                                          ? AppColors.primary.withOpacity(0.24)
                                          : Colors.black.withOpacity(0.04),
                                      blurRadius: isCurrent ? 12 : 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: isCurrent
                                            ? Colors.white.withOpacity(0.2)
                                            : AppColors.primary.withOpacity(
                                                0.1,
                                              ),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${index + 1}',
                                        style: AppTextStyles.caption.copyWith(
                                          color: isCurrent
                                              ? Colors.white
                                              : AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        poem.word,
                                        style: AppTextStyles.bodyMedium
                                            .copyWith(
                                              color: isCurrent
                                                  ? Colors.white
                                                  : AppColors.textPrimary,
                                              fontWeight: isCurrent
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                    Icon(
                                      isCurrent
                                          ? Icons.check_circle
                                          : (isLocked
                                                ? Icons.lock_rounded
                                                : Icons.chevron_right),
                                      size: 20,
                                      color: isCurrent
                                          ? Colors.white
                                          : (isLocked
                                                ? AppColors.primary.withOpacity(
                                                    0.6,
                                                  )
                                                : AppColors.textLight),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
            key: _pageViewKey,
            controller: _pageController,
            onPageChanged: (index) {
              if (_isProgrammaticPageSync) return;

              if (index >= 0 && index < poemProvider.poemsForLetter.length) {
                poemProvider.moveToPoem(index);
                // Save progress: remember which poem the user last read for this letter
                _saveLetterProgress(poemProvider.poemsForLetter[index]);
              }
            },
            // While the full letter list is loading, show only the stable poem
            // so notifyListeners() rebuilds can't swap in the wrong page.
            itemCount: _isLetterPoemsLoading
                ? 1
                : poemProvider.poemsForLetter.length,
            itemBuilder: (context, index) {
              if (_isLetterPoemsLoading && _stablePoem != null) {
                return _buildPoemPage(
                  poemProvider,
                  0,
                  readerSettings,
                  overridePoem: _stablePoem,
                );
              }
              return _buildPoemPage(poemProvider, index, readerSettings);
            },
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
                      if (poem.meaningLines.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: _showMeaningLines
                                ? AppColors.accentGradient
                                : AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (_showMeaningLines
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
                                _showMeaningLines = !_showMeaningLines;
                              });
                            },
                            icon: Icon(
                              _showMeaningLines
                                  ? Icons.playlist_remove_rounded
                                  : Icons.format_list_bulleted_rounded,
                              color: Colors.white,
                            ),
                            tooltip: _showMeaningLines
                                ? 'Скрыть список значений'
                                : 'Список значений',
                          ),
                        ),
                      ],
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
    ReaderSettingsProvider readerSettings, {
    Poem? overridePoem,
  }) {
    final poem = overridePoem ?? poemProvider.poemsForLetter[index];
    final isMeaningFilterActive = poemProvider.isMeaningFilterActive;
    final totalPoemsInLetter = isMeaningFilterActive
        ? poemProvider.poemsForLetter.length
        : poemProvider.poemCountForLetter(poem.letter) ??
              poemProvider.poemsForLetter.length;
    final currentPoemNumber = index + 1;

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
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLetterPoemsLoading
                    ? null
                    : () => _showPoemsForCurrentLetter(poemProvider),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isLetterPoemsLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isMeaningFilterActive) ...[
                                const Icon(
                                  Icons.filter_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                '$currentPoemNumber/$totalPoemsInLetter',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            // if (_isLetterPoemsLoading)
            //   Container(
            //     margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
            //     padding: const EdgeInsets.symmetric(horizontal: 8),
            //     decoration: BoxDecoration(
            //       color: Colors.white.withOpacity(0.2),
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     child: Center(
            //       child: Text(
            //         'Загрузка...',
            //         style: AppTextStyles.caption.copyWith(
            //           color: Colors.white,
            //           fontWeight: FontWeight.w600,
            //         ),
            //       ),
            //     ),
            //   ),
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
              margin: const EdgeInsets.fromLTRB(8, 8, 0, 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white),
                onPressed: _showPoemGuide,
                tooltip: 'Как читать стихи',
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
                  final isLearned = _isPoemLearned(poem);
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isLearned ? Icons.school : Icons.school_outlined,
                          color: isLearned
                              ? readerSettings.accentTextColor
                              : Colors.white,
                        ),
                        tooltip: isLearned
                            ? 'Отмечено как выученное'
                            : 'Отметить как выученное',
                        onPressed: () => _markAsLearned(poem),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? readerSettings.accentTextColor
                              : Colors.white,
                        ),
                        onPressed: () => _toggleFavorite(poem),
                      ),
                    ],
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
                if (poemProvider.isPoemTextPending(poem))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: readerSettings.accentTextColor,
                      ),
                    ),
                  )
                else if (!poem.isFree && poem.tokens.isEmpty)
                  _buildPremiumPaywall()
                else
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
                    child: _showMeaningLines && poem.meaningLines.isNotEmpty
                        ? _buildMeaningLinesText(
                            poem.meaningLines,
                            readerSettings,
                          )
                        : _buildPoemText(poem.tokens, readerSettings),
                  ),
                const SizedBox(height: 100), // Space for bottom nav
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Lines are shown verbatim; a number is prepended only when the line
  /// doesn't already start with one (e.g. "1. зоопарк n").
  Widget _buildMeaningLinesText(
    List<String> lines,
    ReaderSettingsProvider readerSettings,
  ) {
    final alreadyNumbered = RegExp(r'^\s*\d+[.)]');
    final text = [
      for (var i = 0; i < lines.length; i++)
        alreadyNumbered.hasMatch(lines[i]) ? lines[i] : '${i + 1}. ${lines[i]}',
    ].join('\n');

    return Text(
      text,
      textAlign: TextAlign.left,
      style: AppTextStyles.poemText.copyWith(
        color: readerSettings.primaryTextColor,
        fontSize:
            AppTextStyles.poemText.fontSize! * readerSettings.fontSizeScale,
      ),
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

  Widget _buildPremiumPaywall() {
    final appDataProvider = context.watch<AppDataProvider>();
    final authProvider = context.watch<AuthProvider>();
    final paymentsEnabled = appDataProvider.appConfig?.paymentsEnabled == true;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            paymentsEnabled ? 'Premium контент' : 'Стих недоступен',
            style: AppTextStyles.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            !paymentsEnabled
                ? 'Этот стих сейчас недоступен.'
                : (!authProvider.isAuthenticated
                      ? 'Войдите, чтобы получить доступ к этому стиху.'
                      : 'Этот стих доступен только с Premium подпиской. '
                            'Подпишитесь, чтобы разблокировать все стихи!'),
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.85),
            ),
            textAlign: TextAlign.center,
          ),
          if (paymentsEnabled) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  authProvider.isAuthenticated ? '/subscription' : '/login',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
              ),
              child: Text(
                authProvider.isAuthenticated ? 'Подписаться' : 'Войти',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
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
          fontSize:
              AppTextStyles.poemUppercase.fontSize! *
              readerSettings.fontSizeScale,
        );
      } else if (token.isContext) {
        final shouldHideContextWord =
            _hideContextWords && !_focusHighlightsOnly;
        style = AppTextStyles.poemContextWord.copyWith(
          color: shouldHideContextWord
              ? Colors.transparent
              : readerSettings.primaryTextColor,
          fontSize:
              AppTextStyles.poemContextWord.fontSize! *
              readerSettings.fontSizeScale,
        );
      } else {
        final shouldHideRegularText = _focusHighlightsOnly;
        style = AppTextStyles.poemText.copyWith(
          color: shouldHideRegularText
              ? Colors.transparent
              : readerSettings.primaryTextColor,
          fontSize:
              AppTextStyles.poemText.fontSize! * readerSettings.fontSizeScale,
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
