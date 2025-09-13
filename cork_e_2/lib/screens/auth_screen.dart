import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/corkboard_background.dart';
import '../utils/theme.dart';
import 'profile_home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isSignUpMode = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isSignUpMode && _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      User? user;

      if (_isSignUpMode) {
        user = await authService.signUpWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _usernameController.text.trim(),
        );
      } else {
        user = await authService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfileHomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CorkboardBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 500,
              height: _isSignUpMode ? 820 : 650, // Increased height for sign-up
              margin: const EdgeInsets.all(32),
              child: Stack(
                children: [
                  // Sticky note background
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/sticky_note.png',
                      fit: BoxFit.fill,
                    ),
                  ),

                  // Form content positioned and centered within sticky note
                  Positioned(
                    left: 22,
                    top: 25,
                    right: 60,
                    bottom: 60,
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Title
                            Text(
                              _isSignUpMode ? 'Join CorkE' : 'Log In to CorkE',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: RetroTheme.blackMarker,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '(Your Digital Scrapbook - Reimagined)',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: RetroTheme.blackMarker.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20), // Reduced from 25

                            // Username field (sign up only)
                            if (_isSignUpMode) ...[
                              SizedBox(
                                width: 280,
                                child: TextFormField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    labelText: 'USERNAME',
                                    hintText: 'johndoe',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Reduced padding
                                  ),
                                  validator: (value) {
                                    if (_isSignUpMode && (value == null || value.isEmpty)) {
                                      return 'Please enter a username';
                                    }
                                    if (_isSignUpMode && value!.length < 3) {
                                      return 'Username must be at least 3 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 8), // Reduced from 12
                            ],

                            // Email field
                            SizedBox(
                              width: 280,
                              child: TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'EMAIL ADDRESS',
                                  hintText: 'johndoe@example.com',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Reduced padding
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your email';
                                  if (!value.contains('@')) return 'Please enter a valid email';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 8), // Reduced from 12

                            // Password field
                            SizedBox(
                              width: 280,
                              child: TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'PASSWORD',
                                  hintText: '••••••••',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Reduced padding
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter your password';
                                  if (value.length < 6) return 'Password must be at least 6 characters';
                                  return null;
                                },
                              ),
                            ),

                            // Confirm password field (sign up only)
                            if (_isSignUpMode) ...[
                              const SizedBox(height: 8), // Reduced from 12
                              SizedBox(
                                width: 280,
                                child: TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: const InputDecoration(
                                    labelText: 'CONFIRM PASSWORD',
                                    hintText: '••••••••',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Reduced padding
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (_isSignUpMode && (value == null || value.isEmpty)) {
                                      return 'Please confirm your password';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],

                            const SizedBox(height: 14), // Reduced from 18

                            // Primary button
                            SizedBox(
                              width: 280,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleEmailAuth,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: RetroTheme.blackMarker,
                                  padding: const EdgeInsets.symmetric(vertical: 12), // Reduced padding
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: _isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(_isSignUpMode ? 'CREATE ACCOUNT' : 'PROCEED'),
                              ),
                            ),

                            const SizedBox(height: 8), // Reduced from 12

                            // Toggle between sign in / sign up
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isSignUpMode = !_isSignUpMode;
                                  _formKey.currentState?.reset();
                                  _emailController.clear();
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                  _usernameController.clear();
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 4), // Reduced padding
                              ),
                              child: Text(
                                _isSignUpMode
                                    ? 'Already have an account? Log In'
                                    : "Don't have an account? Sign Up",
                                style: TextStyle(
                                  color: RetroTheme.blackMarker.withOpacity(0.7),
                                  decoration: TextDecoration.underline,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            const SizedBox(height: 8), // Reduced from 12

                            // OR USE divider
                            Text(
                              'OR USE',
                              style: TextStyle(
                                color: RetroTheme.blackMarker.withOpacity(0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8), // Reduced from 12

                            // Google sign in button
                            SizedBox(
                              width: 280,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _handleGoogleSignIn,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Reduced padding
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                icon: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Image.asset(
                                    'assets/images/google_logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                label: Text(
                                  _isSignUpMode ? 'Sign up with Google' : 'Sign in with Google',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          '© 2025 All Rights Reserved. CorkE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: RetroTheme.blackMarker.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}