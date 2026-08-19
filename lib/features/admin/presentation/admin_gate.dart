import 'package:flutter/material.dart';

import '../../../core/config/admin_access.dart';
import '../../../core/localization/app_strings.dart';
import '../../../services/auth_service.dart';
import 'admin_dashboard_page.dart';
import 'admin_login_page.dart';

class AdminGate extends StatefulWidget {
  const AdminGate({super.key, this.authService});
  final AuthService? authService;

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  late final AuthService _service = widget.authService ?? AuthService();
  bool _denied = false;
  bool _signingOutUnauthorizedUser = false;

  Future<void> _denyAndSignOut() async {
    if (_signingOutUnauthorizedUser) return;
    _signingOutUnauthorizedUser = true;
    setState(() => _denied = true);
    await _service.signOut();
  }

  @override
  Widget build(BuildContext context) => StreamBuilder(
    stream: _service.authStateChanges,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      if (user != null && !isAuthorizedAdmin(user.uid)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _denyAndSignOut());
        return _UnauthorizedPage(
          onContinue: () => setState(() => _denied = false),
        );
      }
      if (_denied) {
        return _UnauthorizedPage(
          onContinue: () => setState(() => _denied = false),
        );
      }
      if (user == null) return AdminLoginPage(authService: _service);
      return AdminDashboardPage(authService: _service);
    },
  );
}

class _UnauthorizedPage extends StatelessWidget {
  const _UnauthorizedPage({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48),
              SizedBox(height: 18),
              Text(
                context.strings.adminAccessDenied,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text(
                context.strings.adminAccessDeniedBody,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: onContinue,
                child: Text(context.strings.signInWithAnotherAccount),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
