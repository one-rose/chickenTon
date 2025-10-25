import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:template/features/user/provider/auth_provider.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  await authNotifier.signInWithGoogle();
                  context.go('/home');
                },
                icon: const Icon(Icons.g_mobiledata),
                label: const Text('Google로 로그인'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await authNotifier.signInWithApple();
                  context.go('/home');
                },
                icon: const Icon(Icons.apple),
                label: const Text('Apple로 로그인'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
