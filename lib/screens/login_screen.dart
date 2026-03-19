import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import './onboarding/onboarding_data.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false; // true while Firebase request is in progress

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Called when the user taps "Sign in"
  Future<void> _signIn() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text;

    // Basic local validation before hitting Firebase
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }
    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    // Show loading spinner on the button
    setState(() => _isLoading = true);

    // Call Firebase via AuthService
    final error = await AuthService.signIn(email, password);

    // Hide spinner
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      // Firebase returned an error — show it to the user
      _showError(error);
    } else {
      // Success — go to HomeScreen, remove login from the stack
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen()),
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
                  const Text('Your personal rehabilitation companion',
                      style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
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
                    const Text('Welcome back',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    const Text('Enter your credentials to access your recovery plan',
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    const SizedBox(height: 28),

                    // Email
                    const Text('Email', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                    const Text('Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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

                    // Sign in button — shows spinner while loading
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        // Disable button while request is in flight
                        onPressed: _isLoading ? null : _signIn,
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
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text('Sign in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18),
                              ]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sign up link
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const SignupScreen())),
                        child: const Text('Sign up',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
