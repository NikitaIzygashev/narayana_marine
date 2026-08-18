import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_gate.dart';
import '../features/public/presentation/home_page.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomePage()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminGate()),
  ],
);
