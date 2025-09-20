import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/main/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'services/database_service.dart';
import 'services/api_service.dart';
import 'services/persona_verification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: .env file not found. Please create one with your API keys.');
  }

  // Initialize database
  await DatabaseService().database;

  // Initialize API service
  await ApiService.init();

  // Initialize PersonaVerificationService for deep link handling
  await PersonaVerificationService().initialize();

  runApp(const HealthMapApp());
}

class HealthMapApp extends StatelessWidget {
  const HealthMapApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthMap AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2196F3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const AppInitializer(),
      routes: {
        '/onboarding': (context) => const OnboardingFlow(),
        '/main': (context) => const HomeScreen(),
      },
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _hasCompletedOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      // Check if user has a valid authentication token
      if (ApiService.isAuthenticated) {
        // Verify token is still valid by making a request to the backend
        try {
          final userProfile = await ApiService.getUserProfile();
          final user = userProfile['user'];
          final onboardingCompleted = (user?['onboarding_completed'] == 1) || (user?['onboarding_completed'] == true);

          setState(() {
            _isAuthenticated = true;
            _hasCompletedOnboarding = onboardingCompleted;
            _isLoading = false;
          });
        } catch (e) {
          // Token is invalid, clear it and show login
          debugPrint('Token invalid, clearing authentication: $e');
          await ApiService.clearToken();
          setState(() {
            _isAuthenticated = false;
            _hasCompletedOnboarding = false;
            _isLoading = false;
          });
        }
      } else {
        // No token found, show login
        setState(() {
          _isAuthenticated = false;
          _hasCompletedOnboarding = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking authentication status: $e');
      setState(() {
        _isAuthenticated = false;
        _hasCompletedOnboarding = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    if (!_isAuthenticated) {
      return const LoginScreen();
    }

    if (!_hasCompletedOnboarding) {
      return const OnboardingFlow();
    }

    return const HomeScreen();
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.air,
                size: 64,
                color: Color(0xFF2196F3),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'HealthMap AI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Air Quality Companion',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}