import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/gradient_button.dart';
import '../services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.auto_stories,
      title: 'Учитесь через поэзию',
      description:
          'Открывайте новые слова в контексте красивых стихов. Сделайте обучение запоминающимся и приятным.',
      gradient: AppColors.primaryGradient,
    ),
    OnboardingPage(
      icon: Icons.psychology,
      title: 'Запоминайте лучше',
      description:
          'Рифма, ритм и эмоции создают мощные якоря памяти, которые помогают удерживать слова дольше.',
      gradient: AppColors.accentGradient,
    ),
    OnboardingPage(
      icon: Icons.star,
      title: 'Отслеживайте прогресс',
      description:
          'Систематически пополняйте словарный запас. Следите за изученными словами, сохраняйте избранное.',
      gradient: AppColors.primaryGradient,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final storageService = context.read<StorageService>();
    await storageService.setOnboardingComplete();

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  'Пропустить',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            // Page Indicator
            SmoothPageIndicator(
              controller: _pageController,
              count: _pages.length,
              effect: ExpandingDotsEffect(
                activeDotColor: AppColors.primary,
                dotColor: AppColors.textLight.withOpacity(0.3),
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 4,
              ),
            ),
            const SizedBox(height: 32),
            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GradientButton(
                text: _currentPage == _pages.length - 1 ? 'Начать' : 'Далее',
                onPressed: () {
                  if (_currentPage == _pages.length - 1) {
                    _completeOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: page.gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Icon(page.icon, size: 70, color: Colors.white),
          ),
          const SizedBox(height: 48),
          // Title
          Text(
            page.title,
            style: AppTextStyles.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            page.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Gradient gradient;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
