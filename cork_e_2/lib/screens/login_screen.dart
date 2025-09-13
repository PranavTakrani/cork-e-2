import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/corkboard_background.dart';
import '../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (_isSignUp) {
        await authService.signUpWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await authService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
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
              decoration: BoxDecoration(
                color: RetroTheme.yellowSticky,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(5, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Tape decoration
                  Positioned(
                    top: -10,
                    left: 100,
                    right: 100,
                    child: Container(
                      height: 30,
                      color: RetroTheme.tape.withOpacity(0.7),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Log In to CorkE',
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          
                          Text(
                            '(Your Digital Scrapbook - Reimagined)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: RetroTheme.blackMarker.withOpacity(0.7),
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'EMAIL ADDRESS',
                              hintText: 'johndoe@example.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'PASSWORD',
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.visibility_off),
                                onPressed: () {},
                              ),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() => _rememberMe = value ?? false);
                                },
                                fillColor: MaterialStateProperty.all(RetroTheme.blackMarker),
                              ),
                              Text(
                                'Remember Me',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: RetroTheme.blackMarker.withOpacity(0.7),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
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
                                  : Text(_isSignUp ? 'SIGN UP' : 'PROCEED'),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Expanded(child: Divider(color: RetroTheme.blackMarker.withOpacity(0.3))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR USE',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Expanded(child: Divider(color: RetroTheme.blackMarker.withOpacity(0.3))),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Colors.grey),
                              ),
                              icon: Image.network(
                                'https://www.google.com/favicon.ico',
                                height: 24,
                              ),
                              label: const Text(
                                'Sign in with Google',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          TextButton(
                            onPressed: () {
                              setState(() => _isSignUp = !_isSignUp);
                            },
                            child: Text(
                              _isSignUp
                                  ? 'Already have an account? Sign In'
                                  : "Don't have an account? Sign Up",
                              style: TextStyle(
                                color: RetroTheme.blackMarker.withOpacity(0.7),
                                decoration: TextDecoration.underline,
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: RetroTheme.blackMarker.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}