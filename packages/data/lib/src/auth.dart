import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;

class AuthUser {
  final String uid;
  final String? email;

  const AuthUser({required this.uid, this.email});
}

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  AuthUser? currentUser();
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> signUpWithEmail(String email, String password);
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({fb.FirebaseAuth? auth})
      : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  @override
  Stream<AuthUser?> authStateChanges() {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  AuthUser? currentUser() => _mapUser(_auth.currentUser);

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapUser(result.user)!;
  }

  @override
  Future<AuthUser> signUpWithEmail(String email, String password) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapUser(result.user)!;
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthUser? _mapUser(fb.User? user) {
    if (user == null) return null;
    return AuthUser(uid: user.uid, email: user.email);
  }
}

class MockAuthRepository implements AuthRepository {
  MockAuthRepository();

  AuthUser? _user;
  final _controller = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> authStateChanges() => _controller.stream;

  @override
  AuthUser? currentUser() => _user;

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    _user = AuthUser(uid: 'mock-user', email: email);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<AuthUser> signUpWithEmail(String email, String password) async {
    _user = AuthUser(uid: 'mock-user', email: email);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }
}
