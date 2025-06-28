import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jobmentor/screens/login_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  _RegisterViewState createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isVerifying = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _gradientController;
  late Animation<Color?> _startColorAnimation;
  late Animation<Color?> _endColorAnimation;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() => setState(() {}));
    _setupGradientAnimation();
  }

  void _setupGradientAnimation() {
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _startColorAnimation = ColorTween(
      begin: Colors.blue.withOpacity(0.3),
      end: Colors.red.withOpacity(0.3),
    ).animate(_gradientController);

    _endColorAnimation = ColorTween(
      begin: Colors.purple.withOpacity(0.3),
      end: Colors.orange.withOpacity(0.3),
    ).animate(_gradientController);
  }

  bool _strongPassword(String value) {
    final regex = RegExp(r'(?=.{8,})(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\\$&*~])');
    return regex.hasMatch(value);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isVerifying = true);
    try {
      // Create user with Firebase directly
      final userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name and send verification
      await userCred.user!.updateDisplayName(name);
      await userCred.user!.sendEmailVerification();

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Verification Email Sent'),
          content: const Text(
              'A verification email has been sent. Please check your inbox.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      // Wait for verification (optional)
      await _waitForVerification(userCred.user!);

      if (userCred.user!.emailVerified) {
        _goToLogin();
      } else {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Email Not Verified'),
            content: const Text(
                'Email not verified yet. Please verify and try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'email-already-in-use') {
        message = 'An account with this email already exists. Please log in.';
      } else {
        message = e.message ?? 'Registration failed. Please try again.';
      }

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registration Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (e.code == 'email-already-in-use') _goToLogin();
              },
              child: Text(e.code == 'email-already-in-use' ? 'Go to Login' : 'OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _waitForVerification(User user) async {
    for (int i = 0; i < 12; i++) {
      await Future.delayed(const Duration(seconds: 5));
      await user.reload();
      if (user.emailVerified) break;
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  @override
  void dispose() {
    _gradientController.stop();
    _gradientController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/register_background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _gradientController,
            builder: (context, child) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _startColorAnimation.value!,
                    _endColorAnimation.value!
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Create an Account',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              _nameController,
                              'Name',
                              Icons.person,
                              false,
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              _emailController,
                              'Email',
                              Icons.email,
                              false,
                              isEmail: true,
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              _passwordController,
                              'Password',
                              Icons.lock,
                              _obscurePassword,
                              isPassword: true,
                              toggleVisibility: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            const SizedBox(height: 10),
                            _buildTextField(
                              _confirmController,
                              'Confirm Password',
                              Icons.lock_outline,
                              _obscureConfirmPassword,
                              isPassword: true,
                              toggleVisibility: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            const SizedBox(height: 20),
                            _isVerifying
                                ? const CircularProgressIndicator(
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  )
                                : ElevatedButton(
                                    onPressed: _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15, horizontal: 40),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Register'),
                                  ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: _goToLogin,
                              child: const Text(
                                'Already have an account? Log in',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool obscure,
    {
    bool isEmail = false,
    bool isPassword = false,
    VoidCallback? toggleVisibility,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      keyboardType:
          isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white70),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: toggleVisibility,
              )
            : null,
      ),
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) return 'This field is required';
        if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Enter a valid email';
        }
        if (isPassword && !_strongPassword(value)) {
          return 'Password must be ≥8 chars, include upper, lower, number, special';
        }
        if (controller == _confirmController &&
            value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }
}
