import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_provider.dart';
import '../domain/customer_model.dart';
import '../presentation/accessible_home.dart';
import '../presentation/standard_home.dart';
import '../presentation/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final user = ref.read(authProvider);
      
      // Check if user is at root or splash screen
      final isAtStart = state.matchedLocation == '/splash' || state.matchedLocation == '/';

      // Agar user logged in nahi hai, toh splash par hi rakho
      if (user == null && !isAtStart) {
        return '/splash';
      }

      // Agar user logged in hai aur app start ho raha hai, toh directly sahi dashboard par bhejo
      if (user != null && isAtStart) {
        if (user.segment == CustomerSegment.senior || user.segment == CustomerSegment.rural) {
          return '/home/accessible';
        } else {
          return '/home/standard';
        }
      }
      return null;
    },
    routes: [
      // Web browser ke default '/' path ko handle karne ke liye
      GoRoute(
        path: '/',
        redirect: (_, __) => '/splash',
      ),
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/home/accessible',
        builder: (context, state) => const AccessibleHomeShell(),
      ),
      GoRoute(
        path: '/home/standard',
        builder: (context, state) => const StandardHomeShell(),
      ),
    ],
  );
});