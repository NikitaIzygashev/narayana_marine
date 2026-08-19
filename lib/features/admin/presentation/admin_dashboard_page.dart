import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../public/presentation/home_page.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key, required this.authService});
  final AuthService authService;

  @override
  Widget build(BuildContext context) =>
      HomePage(adminMode: true, authService: authService);
}
