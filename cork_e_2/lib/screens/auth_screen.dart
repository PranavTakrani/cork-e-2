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
              width: 400,
              margin: const EdgeInsets.all(32),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Background sticky note
                  Image.asset(
                    'assets/images/sticky_note.png',
                    fit: BoxFit.fill,
                    centerSlice: const Rect.fromLTRB(90, 3, 682, 591),
                  ),

                  // Tape decoration
                  Positioned(
                    top: -15,
                    left: 100,
                    right: 100,
                    child: Container(
                      height: 30,
                      color: RetroTheme.tape.withOpacity(0.7),
                    ),
                  ),

                  // Form content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 60),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isSignUpMode ? 'Join CorkE' : 'Welcome to CorkE',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: RetroTheme.blackMarker,
                            ),
                          ),
                          Text(
                            '(Your Digital Scrapbook - Reimagined)',
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              color: RetroTheme.blackMarker.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Username field (only for sign up)
                          if (_isSignUpMode) ...[
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'USERNAME',
                                hintText: 'johndoe',
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
                            const SizedBox(height: 16),
                          ],
                          
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'EMAIL ADDRESS',
                              hintText: 'johndoe@example.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your email';
                              if (!value.contains('@')) return 'Please enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'PASSWORD',
                              hintText: '••••••••',
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your password';
                              if (value.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          
                          // Confirm password field (only for sign up)
                          if (_isSignUpMode) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: const InputDecoration(
                                labelText: 'CONFIRM PASSWORD',
                                hintText: '••••••••',
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (_isSignUpMode && (value == null || value.isEmpty)) {
                                  return 'Please confirm your password';
                                }
                                return null;
                              },
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Main action button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleEmailAuth,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RetroTheme.blackMarker,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(_isSignUpMode ? 'CREATE ACCOUNT' : 'SIGN IN'),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Toggle between login and signup
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
                            child: Text(
                              _isSignUpMode
                                  ? 'Already have an account? Sign In'
                                  : "Don't have an account? Sign Up",
                              style: TextStyle(
                                color: RetroTheme.blackMarker.withOpacity(0.7),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Google sign in button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                side: const BorderSide(color: Colors.grey),
                                minimumSize: const Size(200, 0),
                              ),
                              icon: SizedBox(
                                width: 24,
                                height: 24,
                                child: Image.asset(
                                  'assets/images/google_logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              label: Text(
                                _isSignUpMode ? 'Sign up with Google' : 'Sign in with Google',
                                style: const TextStyle(color: Colors.black87),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
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