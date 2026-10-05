import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'constants/app_colors.dart';
import 'constants/app_text_styles.dart';
import 'services/api_service.dart';
import 'services/app_navigation_service.dart';
import 'services/storage_service.dart';
import 'providers/auth_provider.dart';
import 'providers/poem_provider.dart';
import 'providers/app_data_provider.dart';
import 'providers/reader_settings_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/login_code_screen.dart';
import 'screens/home_screen.dart';
import 'screens/poem_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/favorites_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting for Russian locale
  await initializeDateFormatting('ru', null);

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final apiService = ApiService(storageService: storageService);

  runApp(MyApp(storageService: storageService, apiService: apiService));
}

class MyApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;

  const MyApp({
    super.key,
    required this.storageService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(apiService, storageService)..init(),
        ),
        ChangeNotifierProvider(create: (context) => PoemProvider(apiService)),
        ChangeNotifierProvider(
          create: (context) => AppDataProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (context) => ReaderSettingsProvider(apiService)..init(),
        ),
      ],
      child: Consumer<ReaderSettingsProvider>(
        builder: (context, readerSettings, _) => MaterialApp(
          title: 'Smart Poems',
          debugShowCheckedModeBanner: false,
          navigatorKey: AppNavigationService.navigatorKey,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: readerSettings.appPrimaryColor,
              primary: readerSettings.appPrimaryColor,
              secondary: AppColors.secondary,
              brightness:
                  readerSettings.backgroundMode == ReaderBackgroundMode.dark
                  ? Brightness.dark
                  : Brightness.light,
            ),
            scaffoldBackgroundColor: Colors.transparent,
            appBarTheme: AppBarTheme(
              centerTitle: true,
              foregroundColor: Colors.white,
              backgroundColor: readerSettings.appPrimaryColor,
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            textTheme: TextTheme(
              displayLarge: AppTextStyles.h1,
              displayMedium: AppTextStyles.h2,
              displaySmall: AppTextStyles.h3,
              headlineMedium: AppTextStyles.h4,
              bodyLarge: AppTextStyles.bodyLarge,
              bodyMedium: AppTextStyles.bodyMedium,
              bodySmall: AppTextStyles.bodySmall,
            ),
          ),
          builder: (context, child) {
            return DecoratedBox(
              decoration: BoxDecoration(
                gradient: readerSettings.appPrimaryGradient,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          initialRoute: '/',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(
                  builder: (context) => const SplashScreen(),
                );
              case '/onboarding':
                return MaterialPageRoute(
                  builder: (context) => const OnboardingScreen(),
                );
              case '/login':
                return MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                );
              case '/register':
                return MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                );
              case '/login-code':
                return MaterialPageRoute(
                  builder: (context) => const LoginCodeScreen(),
                );
              case '/home':
                return MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                );
              case '/poem':
                final arguments = settings.arguments;
                final args = arguments is PoemScreenArgs
                    ? arguments
                    : PoemScreenArgs(poemId: arguments as int? ?? 0);
                return MaterialPageRoute(
                  builder: (context) => PoemScreen(
                    poemId: args.poemId,
                    openedFromLetter: args.openedFromLetter,
                  ),
                );
              case '/profile':
                return MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                );
              case '/stats':
                return MaterialPageRoute(
                  builder: (context) => const StatsScreen(),
                );
              case '/subscription':
                return MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                );
              case '/favorites':
                return MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                );
              default:
                return MaterialPageRoute(
                  builder: (context) => const SplashScreen(),
                );
            }
          },
        ),
      ),
    );
  }
}
