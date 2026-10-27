import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'signup_screen.dart';
import '../admin/admin_home_screen.dart';
import '../customer/customer_home_screen.dart';
import '../../theme/salon_theme.dart';
import '../../widgets/salon_ui.dart';

enum _SignInPath { customer, owner }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  _SignInPath _path = _SignInPath.customer;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userModel = await AuthService().signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        if (userModel != null) {
          if (userModel.role == 'admin') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
            );
          } else if (_path == _SignInPath.owner) {
            final pending = await AuthService().hasPendingAdminRequest(
              userModel.uid,
            );
            await AuthService().signOut();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  pending
                      ? 'Your owner request is waiting for approval from an existing admin.'
                      : 'This account does not have salon owner access.',
                ),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login failed: User not found')),
          );
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: 'Welcome back',
      headline: 'Your next great hair day starts here.',
      description:
          'Discover thoughtful services, reserve your time, and keep every appointment in one beautifully simple place.',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SalonBrand(compact: true),
          const SizedBox(height: 42),
          const SectionLabel('Secure sign in'),
          const SizedBox(height: 10),
          Text(
            'Welcome back',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you use The Salon, then sign in below.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: SalonTheme.taupe),
          ),
          const SizedBox(height: 26),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<_SignInPath>(
                  segments: const [
                    ButtonSegment(
                      value: _SignInPath.customer,
                      label: Text('Customer'),
                    ),
                    ButtonSegment(
                      value: _SignInPath.owner,
                      label: Text('Salon owner'),
                    ),
                  ],
                  selected: {_path},
                  onSelectionChanged: (selection) {
                    setState(() => _path = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  _path == _SignInPath.owner
                      ? 'Sign in with your existing owner account. Owner access is verified automatically.'
                      : 'Sign in to book services and manage your appointments.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.mail_outline_rounded),
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
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) {
                    if (!_isLoading) _login();
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
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final sent = await showDialog<bool>(
                              context: context,
                              builder: (_) => _PasswordResetDialog(
                                initialEmail: _emailController.text.trim(),
                              ),
                            );
                            if (sent == true && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'If an account exists for that email, a password reset link is on its way.',
                                  ),
                                ),
                              );
                            }
                          },
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _login,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(_isLoading ? 'SIGNING IN…' : 'SIGN IN'),
                ),
                const SizedBox(height: 16),
                if (_path == _SignInPath.customer)
                  TextButton(
                    onPressed: () async {
                      final ownerSignIn = await Navigator.of(context)
                          .push<bool>(
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                      if (ownerSignIn == true && context.mounted) {
                        setState(() => _path = _SignInPath.owner);
                      }
                    },
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: SalonTheme.taupe),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SignupScreen(owner: true),
                        ),
                      );
                    },
                    icon: const Icon(Icons.storefront_outlined, size: 19),
                    label: const Text('Need an owner account? Request access'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordResetDialog extends StatefulWidget {
  const _PasswordResetDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_PasswordResetDialog> createState() => _PasswordResetDialogState();
}

class _PasswordResetDialogState extends State<_PasswordResetDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  bool _sending = false;
  String? _error;

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await AuthService().sendPasswordResetEmail(_emailController.text);
      if (mounted) Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      if (error.code == 'user-not-found') {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _error = error.code == 'too-many-requests'
            ? 'Too many attempts. Please try again later.'
            : 'We could not send the reset link. Please try again.';
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'We could not send the reset link. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset your password'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your account email and we’ll send you a reset link.',
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                autofocus: true,
                enabled: !_sending,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Email address'),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (!_sending) _send();
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _sending ? null : _send,
          child: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send reset link'),
        ),
      ],
    );
  }
}
