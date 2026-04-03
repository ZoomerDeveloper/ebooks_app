import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../widgets/poem_card.dart';
import '../providers/poem_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_data_provider.dart';
import 'tabs/favorites_tab.dart';
import 'tabs/stats_tab.dart';
import 'tabs/premium_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _pageController = PageController();
  String? _selectedLetter;
  bool _isSearching = false;
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load first letter by default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PoemProvider>().preloadLetterPoemCounts(
        AppConstants.alphabet,
      );
      _selectLetter('A');
      // Load app config for subscription page (no auth required)
      final appDataProvider = context.read<AppDataProvider>();
      appDataProvider.loadAppConfig();
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        appDataProvider.loadSubscription();
      }
    });

    // Listen to page changes to load data when needed
    _pageController.addListener(() {
      if (_pageController.page?.round() == _pageController.page) {
        _onPageChanged(_pageController.page!.toInt());
      }
    });
  }

  void _onPageChanged(int index) {
    final authProvider = context.read<AuthProvider>();
    final appDataProvider = context.read<AppDataProvider>();

    if (!authProvider.isAuthenticated) return;

    switch (index) {
      case 1: // Favorites
        if (appDataProvider.favorites.isEmpty && !appDataProvider.isLoading) {
          appDataProvider.loadFavorites();
        }
        break;
      case 2: // Stats
        if (appDataProvider.stats == null && !appDataProvider.isLoading) {
          appDataProvider.loadStats();
        }
        break;
      case 3: // Subscription
        if (appDataProvider.subscription == null &&
            !appDataProvider.isLoading) {
          appDataProvider.loadSubscription();
        }
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _selectLetter(String letter) {
    // Toggle: if same letter clicked, deselect it
    if (_selectedLetter == letter) {
      setState(() {
        _selectedLetter = null;
        _isSearching = false;
        _searchController.clear();
      });
      // Clear poems for smooth collapse animation
      context.read<PoemProvider>().clearPoems();
      return;
    }

    setState(() {
      _selectedLetter = letter;
      _isSearching = false;
      _searchController.clear();
    });
    context.read<PoemProvider>().loadPoemsByLetter(letter);

    // Auto-scroll to selected letter
    final index = AppConstants.alphabet.indexOf(letter);
    if (index != -1 && _scrollController.hasClients) {
      _scrollController.animateTo(
        index * 44.0, // width (36) + padding (8)
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _search(String query) {
    if (query.isEmpty) {
      if (_selectedLetter != null) {
        context.read<PoemProvider>().loadPoemsByLetter(_selectedLetter!);
      }
      setState(() {
        _isSearching = false;
      });
    } else {
      setState(() {
        _isSearching = true;
        _selectedLetter = null;
      });
      context.read<PoemProvider>().searchPoems(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isGuest = !authProvider.isAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
        children: [
          // Home Page
          _buildHomePage(isGuest),
          // Favorites Page
          isGuest
              ? _buildAuthPlaceholder('Избранное')
              : FavoritesTab(
                  onNavigateToHome: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
          // Stats Page
          isGuest ? _buildAuthPlaceholder('Статистика') : const StatsTab(),
          // Subscription Page
          const PremiumTab(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: AppColors.textLight.withOpacity(0.1)),
          BottomNavigationBar(
            currentIndex: _currentNavIndex,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textLight,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.white,
            selectedLabelStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            unselectedLabelStyle: AppTextStyles.caption.copyWith(fontSize: 11),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: _AnimatedNavIcon(
                  iconPath: 'assets/icons/home.svg',
                  isSelected: _currentNavIndex == 0,
                ),
                label: 'Главная',
              ),
              BottomNavigationBarItem(
                icon: _AnimatedNavIcon(
                  iconPath: 'assets/icons/favorite.svg',
                  isSelected: _currentNavIndex == 1,
                ),
                label: 'Избранное',
              ),
              BottomNavigationBarItem(
                icon: _AnimatedNavIcon(
                  iconPath: 'assets/icons/stat.svg',
                  isSelected: _currentNavIndex == 2,
                ),
                label: 'Статистика',
              ),
              BottomNavigationBarItem(
                icon: _AnimatedNavIcon(
                  iconPath: 'assets/icons/user.svg',
                  isSelected: _currentNavIndex == 3,
                ),
                label: 'Premium',
              ),
            ],
            onTap: (index) {
              setState(() {
                _currentNavIndex = index;
              });
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHomePage(bool isGuest) {
    return Consumer<PoemProvider>(
      builder: (context, poemProvider, _) {
        return CustomScrollView(
          slivers: [
            // Large Header with gradient
            SliverAppBar(
              expandedHeight: 168,
              floating: false,
              pinned: true,
              toolbarHeight: 168,
              elevation: 0,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Epoems',
                                style: AppTextStyles.h1.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isGuest)
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/login');
                                  },
                                  icon: const Icon(
                                    Icons.login,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                  label: const Text('Войти'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                )
                              else
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/profile');
                                  },
                                  icon: SvgPicture.asset(
                                    'assets/icons/profile.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  label: const Text('Профиль'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.white.withOpacity(
                                      0.2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Учите английский через поэзию',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _searchController,
                            onChanged: _search,
                            decoration: InputDecoration(
                              hintText: 'Поиск по названию или автору...',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textLight,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.primary,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: AppColors.textLight,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        _search('');
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.textLight.withOpacity(0.2),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // title: Text(
                //   'Epoems',
                //   style: AppTextStyles.h4.copyWith(
                //     color: Colors.white,
                //     fontWeight: FontWeight.bold,
                //   ),
                // ),
              ),
            ),
            // Search Bar - pinned
            // SliverAppBar(
            //   pinned: true,
            //   floating: false,
            //   elevation: 0,
            //   toolbarHeight: 22,
            //   automaticallyImplyLeading: false,
            //   backgroundColor: AppColors.background,
            //   flexibleSpace: Container(
            //     color: AppColors.background,
            //     padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            //     child: Align(
            //       alignment: Alignment.bottomCenter,
            //       child: TextField(
            //         controller: _searchController,
            //         onChanged: _search,
            //         decoration: InputDecoration(
            //           hintText: 'Поиск по названию или автору...',
            //           hintStyle: AppTextStyles.bodyMedium.copyWith(
            //             color: AppColors.textLight,
            //           ),
            //           prefixIcon: const Icon(
            //             Icons.search,
            //             color: AppColors.primary,
            //           ),
            //           suffixIcon: _searchController.text.isNotEmpty
            //               ? IconButton(
            //                   icon: const Icon(
            //                     Icons.clear,
            //                     color: AppColors.textLight,
            //                   ),
            //                   onPressed: () {
            //                     _searchController.clear();
            //                     _search('');
            //                   },
            //                 )
            //               : null,
            //           filled: true,
            //           fillColor: Colors.white,
            //           contentPadding: const EdgeInsets.symmetric(
            //             horizontal: 20,
            //             vertical: 16,
            //           ),
            //           border: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(16),
            //             borderSide: BorderSide.none,
            //           ),
            //           enabledBorder: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(16),
            //             borderSide: BorderSide(
            //               color: AppColors.textLight.withOpacity(0.2),
            //             ),
            //           ),
            //           focusedBorder: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(16),
            //             borderSide: const BorderSide(
            //               color: AppColors.primary,
            //               width: 2,
            //             ),
            //           ),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            // Alphabet Grid with expandable poems
            if (!_isSearching)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    // Calculate row and position
                    final lettersPairIndex = index ~/ 2;
                    final isExpansion = index % 2 == 1;

                    if (!isExpansion) {
                      // Show pair of letter cards
                      final letterIndex1 = lettersPairIndex * 2;
                      final letterIndex2 = lettersPairIndex * 2 + 1;

                      return Row(
                        children: [
                          if (letterIndex1 < AppConstants.alphabet.length)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: 6,
                                  bottom: 12,
                                ),
                                child: _buildLetterCard(
                                  AppConstants.alphabet[letterIndex1],
                                  AppConstants.alphabet[letterIndex1] ==
                                      _selectedLetter,
                                  poemProvider,
                                ),
                              ),
                            ),
                          if (letterIndex2 < AppConstants.alphabet.length)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 6,
                                  bottom: 12,
                                ),
                                child: _buildLetterCard(
                                  AppConstants.alphabet[letterIndex2],
                                  AppConstants.alphabet[letterIndex2] ==
                                      _selectedLetter,
                                  poemProvider,
                                ),
                              ),
                            ),
                        ],
                      );
                    } else {
                      // Check if selected letter is in this pair
                      final letterIndex1 = lettersPairIndex * 2;
                      final letterIndex2 = lettersPairIndex * 2 + 1;

                      final letter1 =
                          letterIndex1 < AppConstants.alphabet.length
                          ? AppConstants.alphabet[letterIndex1]
                          : null;
                      final letter2 =
                          letterIndex2 < AppConstants.alphabet.length
                          ? AppConstants.alphabet[letterIndex2]
                          : null;

                      if (letter1 != _selectedLetter &&
                          letter2 != _selectedLetter) {
                        return const SizedBox.shrink();
                      }

                      return _buildExpandedPoems(poemProvider);
                    }
                  }, childCount: ((AppConstants.alphabet.length + 1) ~/ 2) * 2),
                ),
              ),
            // Content for search mode
            if (_isSearching && poemProvider.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_isSearching && poemProvider.error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          poemProvider.error!,
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            // else if (poemProvider.poems.isEmpty)
            // SliverFillRemaining(
            //   child: Center(
            //     child: Column(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: [
            //         const Icon(
            //           Icons.search_off,
            //           size: 64,
            //           color: AppColors.textLight,
            //         ),
            //         const SizedBox(height: 16),
            //         Text(
            //           'Стихи не найдены',
            //           style: AppTextStyles.bodyLarge.copyWith(
            //             color: AppColors.textSecondary,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // )
            else if (_isSearching)
              // Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final poem = poemProvider.poems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PoemCard(
                        poem: poem,
                        onTap: () {
                          Navigator.of(
                            context,
                          ).pushNamed('/poem', arguments: poem.id);
                        },
                      ),
                    );
                  }, childCount: poemProvider.poems.length),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildLetterCard(
    String letter,
    bool isSelected,
    PoemProvider poemProvider,
  ) {
    final poemCount = poemProvider.poemCountForLetter(letter);
    final isCountLoading =
        poemCount == null && poemProvider.isLoadingLetterCounts;
    final countLabel = isCountLoading
        ? '...'
        : poemCount == null
        ? '—'
        : _formatPoemCount(poemCount);

    return GestureDetector(
      onTap: () => _selectLetter(letter),
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 6 : 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  letter,
                  style: AppTextStyles.h1.copyWith(
                    fontFamily: 'Rampart One',
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 72,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.18)
                      : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  countLabel,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    color: isSelected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPoemCount(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;

    if (mod100 >= 11 && mod100 <= 14) {
      return '$count стихов';
    }
    if (mod10 == 1) {
      return '$count стих';
    }
    if (mod10 >= 2 && mod10 <= 4) {
      return '$count стиха';
    }
    return '$count стихов';
  }

  Widget _buildExpandedPoems(PoemProvider poemProvider) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: poemProvider.poems.isEmpty
          ? const SizedBox.shrink()
          : Column(
              children: [
                const SizedBox(height: 8),
                ...poemProvider.poems.map(
                  (poem) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: PoemCard(
                      poem: poem,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).pushNamed('/poem', arguments: poem.id);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
    );
  }

  Widget _buildAuthPlaceholder(String pageName) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              pageName,
              style: AppTextStyles.h2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Войдите в аккаунт, чтобы получить доступ к этой функции',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Войти',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedNavIcon extends StatelessWidget {
  final String iconPath;
  final bool isSelected;

  const _AnimatedNavIcon({required this.iconPath, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      iconPath,
      width: 28,
      height: 28,
      colorFilter: ColorFilter.mode(
        isSelected ? AppColors.primary : AppColors.textLight,
        BlendMode.srcIn,
      ),
    );
  }
}
