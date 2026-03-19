import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import './firebase_options.dart';
import './theme/app_theme.dart';
import './screens/login_screen.dart';
import './screens/home_screen.dart';
import './screens/onboarding/onboarding_data.dart';
import './services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const RehabAssistApp());
}

class RehabAssistApp extends StatelessWidget {
  const RehabAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // Check if a user is already signed in when the app opens.
      // If yes  → skip login and go straight to HomeScreen.
      // If no   → show LoginScreen as usual.
      //
      // AuthService.currentUser is non-null when Firebase has a saved session
      // (the user signed in previously and never signed out).
      home: AuthService.currentUser != null
          ? HomeScreen()
          : const LoginScreen(),
    );
  }
}
