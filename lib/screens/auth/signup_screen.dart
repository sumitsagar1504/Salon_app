import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(
                children: [
                  Icon(Icons.content_cut, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 10),
                  Text(
                    'JOIN THE EXPERIENCE',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Create account',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            SegmentedButton<_SignupRole>(
                              segments: const [
                                ButtonSegment(value: _SignupRole.customer, label: Text('Customer')),
                                ButtonSegment(value: _SignupRole.owner, label: Text('Salon owner')),
                              ],
                              selected: {_selectedRole},
                              onSelectionChanged: _isLoading ? null : (selection) {
                                setState(() => _selectedRole = selection.first);
                              },
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedRole == _SignupRole.customer
                                  ? 'Create an account to book and manage appointments.'
                                  : 'Create an owner request. An existing admin must approve it.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                              validator: (value) => (value == null || value.isEmpty) ? 'Please enter your name' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: const Icon(Icons.email_outlined),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                              validator: (value) => (value == null || value.isEmpty) ? 'Please enter your email' : null,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                            ),
                            const SizedBox(height: 16),
                            const SizedBox(height: 32),
                            if (_isLoading)
                              const CircularProgressIndicator()
                            else
                              ElevatedButton(
                                onPressed: _signup,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  elevation: 5,
                                ),
                                child: Text(
                                  _selectedRole == _SignupRole.owner
                                      ? 'REQUEST OWNER ACCOUNT'
                                      : 'SIGN UP',
                                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                ),
                              ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Already have an account? Login', style: TextStyle(color: Colors.black87)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }
}
