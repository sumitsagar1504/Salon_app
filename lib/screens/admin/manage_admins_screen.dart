import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  final _authService = AuthService();

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    try {
      await _authService.approveAdminRequest(request);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${request['name']} now has admin access.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The owner request could not be approved.'),
        ),
      );
    }
  }

  Widget _buildPendingRequests() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _authService.getAdminRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending owner requests',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...snapshot.data!.docs.map((document) {
              final request = document.data();
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.hourglass_top)),
                  title: Text(request['name'] as String? ?? 'Owner request'),
                  subtitle: Text(request['email'] as String? ?? ''),
                  trailing: FilledButton(
                    onPressed: () => _approveRequest(request),
                    child: const Text('Approve'),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Future<void> _showCreateAdminDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var submitting = false;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create admin account'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'The new admin will receive an email to create their own password.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameController,
                    enabled: !submitting,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'Enter the admin’s name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: emailController,
                    enabled: !submitting,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting
                  ? null
                  : () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      try {
                        final resetSent = await _authService.createAdminAccount(
                          name: nameController.text,
                          email: emailController.text,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop(resetSent);
                      } on FirebaseAuthException catch (error) {
                        if (!dialogContext.mounted) return;
                        final message = error.code == 'email-already-in-use'
                            ? 'That email already has an account.'
                            : 'The admin account could not be created.';
                        ScaffoldMessenger.of(
                          dialogContext,
                        ).showSnackBar(SnackBar(content: Text(message)));
                        setDialogState(() => submitting = false);
                      } catch (_) {
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'The admin account could not be created.',
                            ),
                          ),
                        );
                        setDialogState(() => submitting = false);
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create admin'),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    emailController.dispose();
    if (!mounted || created == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created
              ? 'Admin created. A password setup email was sent.'
              : 'Admin created. Ask them to use Forgot password to set a password.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage admins')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateAdminDialog,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add admin'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _authService.getAdmins(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Admins could not be loaded.'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final admins = snapshot.data!.docs;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  Text(
                    'Administrator access',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create separate accounts for trusted salon managers. Each person sets their own password.',
                  ),
                  const SizedBox(height: 20),
                  _buildPendingRequests(),
                  Card(
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.shield_outlined),
                      ),
                      title: const Text('Primary salon owner'),
                      subtitle: Text(
                        FirebaseAuth.instance.currentUser?.uid ==
                                AuthService.ownerUid
                            ? '${FirebaseAuth.instance.currentUser?.email ?? ''} · You'
                            : 'Primary owner account',
                      ),
                      trailing: const Chip(label: Text('Owner')),
                    ),
                  ),
                  ...admins.map((admin) {
                    final data = admin.data();
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (data['name'] as String? ?? 'A')
                                .trim()
                                .characters
                                .first
                                .toUpperCase(),
                          ),
                        ),
                        title: Text(data['name'] as String? ?? 'Administrator'),
                        subtitle: Text(data['email'] as String? ?? ''),
                        trailing: const Chip(label: Text('Admin')),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
