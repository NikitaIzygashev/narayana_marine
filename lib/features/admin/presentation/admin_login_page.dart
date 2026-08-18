import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/auth_service.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key, required this.authService});
  final AuthService authService;

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      await widget.authService.signIn(email: _email.text, password: _password.text);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to sign in. Check your credentials and try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.navy,
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('NARAYANA MARINE', style: TextStyle(color: AppTheme.sea, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                const SizedBox(height: 10),
                Text('Administrator sign in', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 24),
                TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.username], decoration: const InputDecoration(labelText: 'Email'), validator: (value) => value == null || value.trim().isEmpty ? 'Enter your email.' : null),
                const SizedBox(height: 14),
                TextFormField(controller: _password, obscureText: true, autofillHints: const [AutofillHints.password], decoration: const InputDecoration(labelText: 'Password'), validator: (value) => value == null || value.isEmpty ? 'Enter your password.' : null, onFieldSubmitted: (_) => _signIn()),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(_error!, style: const TextStyle(color: Colors.red))),
                const SizedBox(height: 22),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: _loading ? null : _signIn, child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in'))),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}
