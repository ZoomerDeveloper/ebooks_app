import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/app_constants.dart';
import '../providers/app_data_provider.dart';
import '../services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await context.read<AppDataProvider>().loadAppConfig();
    await Future.delayed(AppConstants.splashDuration);

    if (!mounted) return;

    final storageService = context.read<StorageService>();
    final bool onboardingComplete = storageService.isOnboardingComplete();

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacementNamed(onboardingComplete ? '/home' : '/onboarding');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool useTwoLineAuthors = screenWidth < 390;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      Text(
                        useTwoLineAuthors
                            ? 'Ирина и Иван\nДемьяновские'
                            : 'Ирина и Иван Демьяновские',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          height: 1.3,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: [
                            // App Icon/Logo
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_stories,
                                size: 60,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // App Name
                            Text(
                              'Smart Poems',
                              style: AppTextStyles.h1.copyWith(
                                color: Colors.white,
                                fontSize: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          // Text(
                          //   'Миры английских слов в стихах',
                          //   textAlign: TextAlign.center,
                          //   style: AppTextStyles.bodyMedium.copyWith(
                          //     color: Colors.white.withOpacity(0.9),
                          //     height: 1.3,
                          //     fontSize: 18,
                          //   ),
                          // ),
                          // const SizedBox(height: 6),
                          Text(
                            'Более 7000 стихов',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withOpacity(0.95),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          // const SizedBox(height: 6),
                          // Text(
                          //   'Smart poems',
                          //   textAlign: TextAlign.center,
                          //   style: AppTextStyles.bodyMedium.copyWith(
                          //     color: Colors.white.withOpacity(0.9),
                          //     letterSpacing: 0.5,
                          //   ),
                          // ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
