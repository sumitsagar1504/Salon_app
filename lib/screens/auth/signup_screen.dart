import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/salon_theme.dart';
import '../../widgets/salon_ui.dart';

enum _SignupRole { customer, owner }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.owner = false});

  final bool owner;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late _SignupRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.owner ? _SignupRole.owner : _SignupRole.customer;
  }

  void _signup() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userModel = await AuthService().signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        requestAdminAccess: _selectedRole == _SignupRole.owner,
      );

      if (mounted) {
        if (userModel != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _selectedRole == _SignupRole.owner
                    ? 'Owner account requested. An existing admin must approve it before owner sign-in.'
                    : 'Account created successfully! Please login.',
              ),
            ),
          );
          Navigator.of(context).pop(_selectedRole == _SignupRole.owner);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AuthService.errorMessage(e))));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: 'Join the experience',
      headline: 'Make time for the way you want to feel.',
      description:
          'Create your account, explore salon services, and book a moment that belongs entirely to you.',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SalonBrand(compact: true),
          const SizedBox(height: 34),
          const SectionLabel('New account'),
          const SizedBox(height: 10),
          Text(
            'Create your account',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us how you will use The Salon.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: SalonTheme.taupe),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<_SignupRole>(
                  segments: const [
                    ButtonSegment(
                      value: _SignupRole.customer,
                      label: Text('Customer'),
                    ),
                    ButtonSegment(
                      value: _SignupRole.owner,
                      label: Text('Salon owner'),
                    ),
                  ],
                  selected: {_selectedRole},
                  onSelectionChanged: _isLoading
                      ? null
                      : (selection) {
                          setState(() => _selectedRole = selection.first);
                        },
                ),
                const SizedBox(height: 12),
                Text(
                  _selectedRole == _SignupRole.customer
                      ? 'Create an account to book and manage appointments.'
                      : 'Create an owner request. An existing admin must approve it.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Your name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 2
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty) return 'Please enter your email';
                    if (!RegExp(
                      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                    ).hasMatch(email)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) {
                    if (!_isLoading) _signup();
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) => (value == null || value.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signup,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _selectedRole == _SignupRole.owner
                              ? Icons.storefront_outlined
                              : Icons.arrow_forward_rounded,
                        ),
                  label: Text(
                    _isLoading
                        ? 'CREATING ACCOUNT…'
                        : _selectedRole == _SignupRole.owner
                        ? 'REQUEST OWNER ACCOUNT'
                        : 'SIGN UP',
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Already have an account? Sign in',
                    style: TextStyle(color: SalonTheme.taupe),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
