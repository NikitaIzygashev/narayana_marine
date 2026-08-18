import 'package:flutter/material.dart';

import '../../../core/config/admin_access.dart';
import '../../../services/auth_service.dart';
import 'admin_dashboard_page.dart';
import 'admin_login_page.dart';

class AdminGate extends StatelessWidget {
  const AdminGate({super.key, this.authService});

  final AuthService? authService;

  @override
  Widget build(BuildContext context) {
    final service = authService ?? AuthService();
    return StreamBuilder(
      stream: service.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) return AdminLoginPage(authService: service);
        if (!isAuthorizedAdmin(user.uid)) {
          return _UnauthorizedPage(authService: service);
        }
        return AdminDashboardPage(authService: service);
      },
    );
  }
}

class _UnauthorizedPage extends StatelessWidget {
  const _UnauthorizedPage({required this.authService});
  final AuthService authService;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 18),
                Text('Administrator access required', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text('This account is not authorized to edit Narayana Marine content.', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                OutlinedButton(onPressed: authService.signOut, child: const Text('Sign out')),
              ]),
            ),
          ),
        ),
      );
}
