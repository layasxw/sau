import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rehab_assist/screens/admin_screen.dart';
import 'package:rehab_assist/screens/doctor_screen.dart';
import 'package:rehab_assist/screens/pending_verification_screen.dart';
import 'package:rehab_assist/screens/onboarding/onboarding_screen.dart';
import 'package:rehab_assist/services/firestore_service.dart';
import './firebase_options.dart';
import './theme/app_theme.dart';
import './screens/login_screen.dart';
import './screens/home_screen.dart';
import './services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RehabAssistApp());
}

Future<Widget> _getStartScreen() async {
  if (AuthService.currentUser == null) return const LoginScreen();

  // Run role + onboarding check in parallel instead of sequential
  final results = await Future.wait([
    FirestoreService.getRole(),
    FirestoreService.isOnboardingComplete(),
  ]).timeout(
    const Duration(seconds: 8),
    onTimeout: () => [null, false], // on timeout → go to HomeScreen
  );

  final role = results[0] as String?;
  final onboardingDone = results[1] as bool;

  if (role == 'admin') return const AdminScreen();

  if (role == 'doctor') {
    // getDoctorStatus reuses same doc — already fast after parallel fetch
    final status = await FirestoreService.getDoctorStatus()
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    if (status == 'verified') return const DoctorScreen();
    return const PendingVerificationScreen();
  }

  return onboardingDone ? const HomeScreen() : const OnboardingScreen();
}

class RehabAssistApp extends StatelessWidget {
  const RehabAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _StartupGate(),
    );
  }
}

// ── StatefulWidget caches the future so it's never called twice ───────────────
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  // Created once in initState — never recreated on rebuild
  late final Future<Widget> _startFuture;

  @override
  void initState() {
    super.initState();
    _startFuture = _getStartScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Any uncaught error → go to login
          return const LoginScreen();
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FFFE),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2EC4B6),
                strokeWidth: 2.5,
              ),
            ),
          );
        }
        return snapshot.data!;
      },
    );
  }
}