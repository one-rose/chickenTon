import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 구글 로그인
  Future<User?> signInWithGoogle() async {
    final googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize();
    final account = await googleSignIn.authenticate();

    final googleAuth = account.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null &&
        (user.displayName == null || user.displayName!.isEmpty)) {
      await user.updateDisplayName(account.displayName);
      await user.reload();
    }

    return _auth.currentUser;
  }

  // 애플 로그인
  Future<User?> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);
    final user = userCredential.user;

    final fullName = [
      appleCredential.givenName ?? '',
      appleCredential.familyName ?? '',
    ].where((e) => e.isNotEmpty).join(' ');

    if (user != null && fullName.isNotEmpty) {
      await user.updateDisplayName(fullName);
      await user.reload();
    }

    return _auth.currentUser;
  }

  // 로그아웃
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }

  // 현재 로그인된 유저
  User? get currentUser => _auth.currentUser;

  // 데이터 초기화
  Future<void> clearAllData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final firestore = FirebaseFirestore.instance;

      final snapshot = await firestore
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint('✅ Firestore 작업 ${snapshot.docs.length}건 삭제 완료');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_tasks');
    } catch (e) {
      debugPrint('⚠️ 데이터 초기화 실패: $e');
    }
  }

  // FirebaseAuth 로그인 유지 (자동 로그인)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
