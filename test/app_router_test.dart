import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:narayana_marine/routing/app_router.dart';

void main() {
  test('path-based admin URL matches the dedicated admin route', () {
    final match = appRouter.configuration.findMatch(Uri.parse('/admin'));

    expect(match.isError, isFalse);
    expect(match.routes.last, isA<GoRoute>());
    expect((match.routes.last as GoRoute).path, '/admin');
  });

  test('root URL matches the public route', () {
    final match = appRouter.configuration.findMatch(Uri.parse('/'));

    expect(match.isError, isFalse);
    expect((match.routes.last as GoRoute).path, '/');
  });
}
