import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Currently signed-in user profile (cached after login).
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  /// Call once at startup to disable reCAPTCHA verification (mobile dev only).
  /// setSettings is only supported on Android/iOS — skip on desktop/web.
  Future<void> init() async {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await _auth.setSettings(appVerificationDisabledForTesting: true);
    }
  }

  /// Sign in with email & password. Returns the [AppUser] on success.
  /// Throws [FirebaseAuthException] on invalid credentials.
  Future<AppUser> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      throw Exception('User profile not found in database.');
    }
    _currentUser = AppUser.fromFirestore(doc);
    return _currentUser!;
  }

  /// Register a new account with email, password, display name, and role.
  Future<AppUser> register(String name, String email, String password,
      {String role = 'buyer'}) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final user = AppUser(
      uid: uid,
      name: name.trim(),
      email: email.trim(),
      role: role,
      createdAt: DateTime.now(),
    );
    await _users.doc(uid).set(user.toFirestore());
    _currentUser = user;
    return user;
  }

  /// Sign out and clear cached user.
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
  }

  /// Switch the current user's role between 'buyer' and 'seller'.
  /// Updates Firestore and the local cache.
  Future<void> switchRole(String newRole) async {
    final uid = _currentUser?.uid;
    if (uid == null) return;
    await _users.doc(uid).update({'role': newRole});
    _currentUser = AppUser(
      uid: _currentUser!.uid,
      name: _currentUser!.name,
      email: _currentUser!.email,
      role: newRole,
      createdAt: _currentUser!.createdAt,
    );
  }
}
