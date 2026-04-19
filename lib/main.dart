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

  final role = await FirestoreService.getRole();

  if (role == 'admin') return const AdminScreen();

  if (role == 'doctor') {
    final status = await FirestoreService.getDoctorStatus();
    if (status == 'verified') return const DoctorScreen();
    return const PendingVerificationScreen();
  }

  // Patient (or role not set yet — treat as patient)
  final onboardingDone = await FirestoreService.isOnboardingComplete();
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
      home: FutureBuilder<Widget>(
        future: _getStartScreen(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}