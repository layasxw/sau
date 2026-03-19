import 'package:flutter/material.dart';
import 'package:rehab_assist/screens/onboarding/onboarding_screen.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSignUp() async {
    final name            = _nameController.text.trim();
    final email           = _emailController.text.trim();
    final password        = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Local validation first — no need to hit Firebase for obvious mistakes
    if (name.isEmpty) {
      _showError('Please enter your full name.');
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (password.isEmpty || password.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match.');
      return;
    }
    if (!_agreeToTerms) {
      _showError('Please agree to the terms and conditions.');
      return;
    }

    setState(() => _isLoading = true);

    // Create the account in Firebase Auth
    final error = await AuthService.signUp(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _showError(error);
    } else {
      // Account created — go to onboarding so user fills in their profile
      // Use pushReplacement so they can't go back to the signup screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
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
                const Text('Create Account',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                const Text('Join SAU to start your recovery journey',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
              ]),
            ),

            // ── Form card ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Sign up',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  const Text('Create your account to get started',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  const SizedBox(height: 28),

                  // Full Name
                  _label('Full Name'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _dec('Enter your full name'),
                  ),
                  const SizedBox(height: 20),

                  // Email
                  _label('Email'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _dec('Enter your email'),
                  ),
                  const SizedBox(height: 20),

                  // Password
                  _label('Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _dec('Enter a strong password').copyWith(
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password
                  _label('Confirm Password'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: _dec('Confirm your password').copyWith(
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        child: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Terms checkbox
                  Row(children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                      fillColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    const Expanded(
                      child: Text('I agree to the terms and conditions',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // Create Account button
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _validateAndSignUp,
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
                          : const Text('Create Account',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Already have account
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Already have an account? ',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen())),
                      child: const Text('Sign in',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
