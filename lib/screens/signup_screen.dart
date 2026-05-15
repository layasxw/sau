import 'package:flutter/material.dart';
import 'package:rehab_assist/screens/pending_verification_screen.dart';
import 'package:rehab_assist/screens/onboarding/onboarding_screen.dart';
import 'package:rehab_assist/services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/language_provider.dart';
import 'package:provider/provider.dart';
import '../l10n/translations.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController            = TextEditingController();
  final _emailController           = TextEditingController();
  final _passwordController        = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword        = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isLoading    = false;
  String _role = 'patient';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSignUp(AppLanguage lang) async {
    final name            = _nameController.text.trim();
    final email           = _emailController.text.trim();
    final password        = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      _showError(Translations.get(lang, 'signup_err_name'));
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showError(Translations.get(lang, 'signup_err_email'));
      return;
    }
    if (password.isEmpty || password.length < 6) {
      _showError(Translations.get(lang, 'signup_err_pass'));
      return;
    }
    if (password != confirmPassword) {
      _showError(Translations.get(lang, 'signup_err_match'));
      return;
    }
    if (!_agreeToTerms) {
      _showError(Translations.get(lang, 'signup_err_terms'));
      return;
    }

    setState(() => _isLoading = true);
    final error = await AuthService.signUp(email, password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
    } else {
      await FirestoreService.saveRole(_role, fullName: name);
      if (!mounted) return;
      if (_role == 'doctor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PendingVerificationScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
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
          child: Column(children: [
            // ── Logo + header ─────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
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
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                Text(Translations.get(lang, 'signup_title'),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(Translations.get(lang, 'signup_subtitle'),
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ]),
            ),

            // ── Form card ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(Translations.get(lang, 'signup_heading'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  Text(Translations.get(lang, 'signup_sub_heading'),
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 28),

                  // Full Name
                  _label(Translations.get(lang, 'signup_full_name')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dec(Translations.get(lang, 'signup_name_hint')),
                  ),
                  const SizedBox(height: 20),

                  // Email
                  _label(Translations.get(lang, 'login_email')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec(Translations.get(lang, 'signup_email_hint')),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  _label(Translations.get(lang, 'login_password')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _dec(Translations.get(lang, 'signup_pass_hint')).copyWith(
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password
                  _label(Translations.get(lang, 'signup_confirm_pass')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: _dec(Translations.get(lang, 'signup_confirm_hint')).copyWith(
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        child: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Role selector
                  const SizedBox(height: 20),
                  _label(Translations.get(lang, 'signup_i_am')),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: GestureDetector(
                      onTap: () => setState(() => _role = 'patient'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _role == 'patient' ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _role == 'patient' ? AppColors.primary : AppColors.divider),
                        ),
                        child: Column(children: [
                          Icon(Icons.person_outline, color: _role == 'patient' ? Colors.white : AppColors.textSecondary),
                          const SizedBox(height: 4),
                          Text(Translations.get(lang, 'signup_patient'),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: _role == 'patient' ? Colors.white : AppColors.textPrimary)),
                        ]),
                      ),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: GestureDetector(
                      onTap: () => setState(() => _role = 'doctor'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _role == 'doctor' ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _role == 'doctor' ? AppColors.primary : AppColors.divider),
                        ),
                        child: Column(children: [
                          Icon(Icons.medical_services_outlined, color: _role == 'doctor' ? Colors.white : AppColors.textSecondary),
                          const SizedBox(height: 4),
                          Text(Translations.get(lang, 'signup_doctor'),
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: _role == 'doctor' ? Colors.white : AppColors.textPrimary)),
                        ]),
                      ),
                    )),
                  ]),

                  // Terms checkbox
                  const SizedBox(height: 8),
                  Row(children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                      fillColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    Expanded(
                      child: Text(Translations.get(lang, 'signup_agree'),
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // Create Account button
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () => _validateAndSignUp(lang),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(Translations.get(lang, 'signup_create_btn'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Already have account
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(Translations.get(lang, 'signup_have_account'),
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: Text(Translations.get(lang, 'signup_sign_in_link'),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ),
                  ]),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary));

  InputDecoration _dec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    filled: true, fillColor: AppColors.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
  );
}