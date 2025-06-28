import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Get current user
  User? get currentUser => _auth.currentUser;

  // ✅ Stream for authentication state changes
  Stream<User?> get userChanges => _auth.authStateChanges();

  // ✅ Sign in with email & password with error handling
  Future<String?> signIn(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Check if email is verified before allowing login
      if (!userCredential.user!.emailVerified) {
        return "Please verify your email before logging in.";
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return "An unexpected error occurred. Please try again.";
    }
  }

  // ✅ Register with email & password + Send verification email
  Future<String?> register(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      return "Account created successfully. Please verify your email before logging in.";
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return "An unexpected error occurred. Please try again.";
    }
  }

  // ✅ Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ✅ Send password reset email and redirect to login
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "Password reset email sent. Check your inbox.";
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return "An unexpected error occurred. Please try again.";
    }
  }

  // ✅ Reauthenticate user before performing sensitive actions
  Future<String?> reauthenticate(String password) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return "User not logged in.";

      AuthCredential credential =
          EmailAuthProvider.credential(email: user.email!, password: password);
      await user.reauthenticateWithCredential(credential);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return "An unexpected error occurred. Please try again.";
    }
  }

  // ✅ Delete user account securely
  Future<String?> deleteAccount(String password) async {
    try {
      String? reauthResult = await reauthenticate(password);
      if (reauthResult != null) return reauthResult; // Reauth failed

      await _auth.currentUser!.delete();
      return "Account deleted successfully.";
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return "An unexpected error occurred. Please try again.";
    }
  }

  // ✅ Helper function to get user-friendly error messages
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
        return "Invalid email or password.";
      case 'email-already-in-use':
        return "This email is already registered. Try logging in.";
      case 'weak-password':
        return "Password should be at least 6 characters long.";
      case 'too-many-requests':
        return "Too many attempts. Try again later.";
      case 'network-request-failed':
        return "No internet connection. Please check your network.";
      default:
        return "Authentication failed. Please try again.";
    }
  }
}
