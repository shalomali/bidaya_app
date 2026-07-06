import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bidaya_app/services/auth_service.dart';
import 'package:bidaya_app/core/ui_helper.dart';
import 'package:bidaya_app/core/theme.dart';
import 'package:bidaya_app/utils/url_launcher.dart';
import 'package:flutter/gestures.dart';
import '../widgets/form_layout.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _agreedToPrivacyPolicy = false;
  String _selectedRole = 'student'; // Default role

  // Password requirements state
  bool _hasLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasLength = password.length >= 8;
      _hasUpper = RegExp(r'[A-Z]').hasMatch(password);
      _hasLower = RegExp(r'[a-z]').hasMatch(password);
      _hasDigit = RegExp(r'[0-9]').hasMatch(password);
      _hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_agreedToPrivacyPolicy) {
        UIHelper.showError(context, 'You must agree to the Privacy Policy to continue');
        return;
      }
      setState(() => _isLoading = true);
      final authService = context.read<AuthService>();
      
      try {
        final result = await authService.registerWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _selectedRole, // Use the dynamically selected role
        );

        if (mounted && result != null) {
          // Explicitly refresh and navigate to ensure the user isn't stuck or double-asked
          await authService.refreshUserData();
          if (mounted) {
            context.go(_selectedRole == 'student' ? '/student/setup' : '/startup/setup');
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          UIHelper.showError(context, e);
        }
      } catch (e) {
        if (mounted) {
          UIHelper.showError(context, e);
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _registerWithGoogle() async {
    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    
    try {
      final result = await authService.signInWithGoogle();
      
      if (mounted && result != null) {
        // Redirection to Role Selection is handled by the auth state listener in main/router
        // since for Google users we don't know the role yet.
        context.goNamed('roleSelection');
      }
    } catch (e) {
      if (mounted) {
        UIHelper.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormLayout(
      title: 'Join Bidaya',
      subtitle: 'Create an account to discover talent & opportunities.',
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role Selection UI
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'student',
                  label: Text('Student'),
                  icon: Icon(Icons.school_outlined),
                ),
                ButtonSegment<String>(
                  value: 'startup',
                  label: Text('Startup'),
                  icon: Icon(Icons.business_outlined),
                ),
              ],
              selected: {_selectedRole},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedRole = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // Email Input
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) => 
                  value == null || value.isEmpty ? 'Please enter your email' : null,
            ),
            const SizedBox(height: 16),
            
            // Password Input
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a password';
                if (!_hasLength || !_hasUpper || !_hasLower || !_hasDigit || !_hasSpecial) {
                  return 'Password does not meet requirements';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildPasswordRequirements(),
            const SizedBox(height: 16),
            
            // Confirm Password Input
            TextFormField(
              controller: _confirmController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Confirm your password';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Privacy Policy Agreement
            Row(
              children: [
                SizedBox(
                  height: 24,
                  width: 24,
                  child: Checkbox(
                    value: _agreedToPrivacyPolicy,
                    activeColor: AppTheme.getAdaptivePrimary(context),
                    onChanged: (value) {
                      setState(() {
                        _agreedToPrivacyPolicy = value ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.getAdaptiveTextSecondary(context),
                      ),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: AppTheme.getAdaptivePrimary(context),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => ExternalLauncher.open('https://sites.google.com/view/bidayaprivacypolicy/home?authuser=0'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),
            
            // Submit Button
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _register,
                  child: const Text('Create Account'),
                ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _registerWithGoogle,
              icon: Image.network(
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                height: 20,
              ),
              label: const Text(
                'Sign up with Google',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
          ],
        ),
      ),
      secondaryActionText: 'Already have an account? Sign in',
      onSecondaryAction: () => context.goNamed('login'),
    );
  }

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirementItem('Minimum 8 characters', _hasLength),
        _buildRequirementItem('At least one uppercase letter', _hasUpper),
        _buildRequirementItem('At least one lowercase letter', _hasLower),
        _buildRequirementItem('At least one numeric digit', _hasDigit),
        _buildRequirementItem('At least one special character', _hasSpecial),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color: isMet ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green[700] : Colors.grey[600],
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
