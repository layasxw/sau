import 'package:firebase_auth/firebase_auth.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AuthService
//
// A single place for all Firebase Auth operations.
// Screens never call FirebaseAuth directly — they call this instead.
// That way if you switch auth providers later, you only change this file.
// ─────────────────────────────────────────────────────────────────────────────
class AuthService {
  // The Firebase Auth instance — singleton provided by Firebase SDK
  static final _auth = FirebaseAuth.instance;

  // ── Current user ───────────────────────────────────────────────────────────
  // Returns the currently signed-in user, or null if nobody is signed in.
  // Used in main.dart to decide whether to show Login or HomeScreen on launch.
  static User? get currentUser => _auth.currentUser;

  // ── Sign in with email + password ──────────────────────────────────────────
  // Returns null on success.
  // Returns a human-readable error string if something goes wrong.
  static Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    }
  }

  // ── Create account ─────────────────────────────────────────────────────────
  // Returns null on success.
  // Returns a human-readable error string if something goes wrong.
  static Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e.code);
    }
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Translate Firebase error codes into readable messages ──────────────────
  // Firebase returns codes like "wrong-password" — we show something nicer.
  static String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Check your network.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
