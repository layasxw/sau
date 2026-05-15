import 'package:flutter/material.dart';
import 'package:rehab_assist/screens/admin_screen.dart';
import 'package:rehab_assist/screens/doctor_screen.dart';
import 'package:rehab_assist/services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/language_provider.dart';
import 'package:provider/provider.dart';
import '../l10n/translations.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn(AppLanguage lang) async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError(Translations.get(lang, 'login_err_empty'));
      return;
    }

    setState(() => _isLoading = true);
    final error = await AuthService.signIn(email, password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
    } else {
      final role = await FirestoreService.getRole();
      if (!mounted) return;
      if (role == 'doctor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DoctorScreen()),
        );
      } else if (role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).currentLanguage;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Logo + header ───────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8F7F6), AppColors.background],
                  ),
                ),
                child: Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.favorite_border, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text('SAU',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(Translations.get(lang, 'onboarding_subtitle'),
                      style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                ]),
              ),

              // ── Login card ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                      color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(Translations.get(lang, 'login_welcome_back'),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text(Translations.get(lang, 'login_subtitle'),
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 28),

                    // Email
                    Text(Translations.get(lang, 'login_email'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'you@example.com',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                        filled: true, fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    Text(Translations.get(lang, 'login_password'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppColors.textSecondary),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true, fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Sign in button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _signIn(lang),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(Translations.get(lang, 'login_sign_in'),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18),
                              ]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sign up link
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(Translations.get(lang, 'login_no_account'),
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: Text(Translations.get(lang, 'login_sign_up_link'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ),
                    ]),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
