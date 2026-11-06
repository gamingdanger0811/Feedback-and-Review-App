import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../main_shell.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isAdminLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    String? error;
    String? role;
    String? uid;
    try {
      error = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (error == null) {
        uid = _authService.currentUser?.uid;
        if (uid == null) {
          await _authService.logout();
          error = 'Unable to load your account. Please try again.';
        } else {
          role = await _authService.getUserRole(uid);
          if (role == null) {
            await _authService.logout();
            error = _isAdminLogin
                ? 'This account has no Firebase role profile. In Firebase '
                      'Console, add users/$uid with a string field role: "admin".'
                : 'This account has no Firebase user profile. Try signing up '
                      'again or contact the project administrator.';
          } else if (_isAdminLogin && role != 'admin') {
            await _authService.logout();
            error =
                'Firebase profile users/$uid has role "$role". Change '
                'that document role to "admin" in Firebase Console.';
          } else if (!_isAdminLogin && role == 'admin') {
            await _authService.logout();
            error = 'Choose Admin Login to sign in with this account.';
          }
        }
      }
    } on FirebaseException catch (exception) {
      uid ??= _authService.currentUser?.uid;
      await _authService.logout();
      error = switch (exception.code) {
        'permission-denied' =>
          'Firebase denied access to users/${uid ?? 'your account'}. '
              'Allow signed-in users to read their own profile in Firestore rules.',
        'unavailable' =>
          'Firestore is unavailable. Check your connection and try again.',
        _ =>
          'Could not load your Firebase profile (${exception.code}). '
              'Check the users document and Firestore rules.',
      };
    } catch (_) {
      uid ??= _authService.currentUser?.uid;
      await _authService.logout();
      error =
          'Could not verify Firebase profile for '
          '${uid ?? 'this account'}. Check its users document and role field.';
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => MainShell(role: role ?? 'user')),
    );
  }

  InputDecoration _fieldDecoration(String hintText) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF6C7BFF), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6C7BFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isAdminLogin ? 'Administrator access' : 'User access',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      key: const Key('login-email'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: _fieldDecoration('Email address'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('login-password'),
                      controller: _passwordController,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      decoration: _fieldDecoration('Password'),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B5CFF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _handleLogin,
                              child: Text(
                                _isAdminLogin ? 'Admin Log In' : 'Log In',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('login-role-toggle'),
                      onPressed: _isLoading
                          ? null
                          : () =>
                                setState(() => _isAdminLogin = !_isAdminLogin),
                      child: Text(_isAdminLogin ? 'User Login' : 'Admin Login'),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: const Text("Don't have an account? Sign Up"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
