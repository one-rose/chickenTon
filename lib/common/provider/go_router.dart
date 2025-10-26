import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:template/common/view/root_tab.dart';
import 'package:template/features/login/login_page.dart';
import 'package:template/features/splash/splash_page.dart';
import 'package:template/features/user/provider/auth_provider.dart';
import 'package:template/main.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isSplash = state.uri.toString() == '/splash';

      if (isSplash) return null;
      if (!isLoggedIn) return '/login';
      if (isLoggedIn && state.uri.toString() == '/login') return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const RootTab(),
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('404 Not Found')),
    ),
  );
});
