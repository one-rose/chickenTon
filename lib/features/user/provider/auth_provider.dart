import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:template/features/user/repository/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  const AuthState({required this.isLoggedIn, this.user});
  final bool isLoggedIn;
  final User? user;
  static const initial = AuthState(isLoggedIn: false);
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(AuthState.initial) {
    _repo.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthState(isLoggedIn: true, user: user);
      } else {
        state = AuthState.initial;
      }
    });
  }
  final AuthRepository _repo;

  Future<void> signInWithGoogle() async {
    final user = await _repo.signInWithGoogle();
    if (user != null) {
      state = AuthState(isLoggedIn: true, user: user);
    }
  }

  Future<void> signInWithApple() async {
    final user = await _repo.signInWithApple();
    if (user != null) {
      state = AuthState(isLoggedIn: true, user: user);
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = AuthState.initial;
  }

  Future<void> clearAllData() async {
    await _repo.clearAllData();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
