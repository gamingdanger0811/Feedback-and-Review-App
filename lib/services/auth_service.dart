import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _createUser(name: name, email: email, password: password);
      return null;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        return 'An account already uses this email. Use Forgot Password? to recover it.';
      }
      if (error.code == 'weak-password') {
        return 'Choose a stronger password with at least 6 characters.';
      }
      return error.message ?? 'Signup failed';
    } on FirebaseException catch (error) {
      return error.message ?? 'Could not save your account profile';
    }
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) {
    return _createUser(name: name, email: email, password: password);
  }

  Future<UserCredential> _createUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;

    if (user == null) {
      throw StateError('Firebase Auth did not return a user after signup.');
    }

    final trimmedName = name.trim();
    if (trimmedName.isNotEmpty) {
      await user.updateProfile(displayName: trimmedName);
    }

    await _firestore.collection('users').doc(user.uid).set({
      'name': trimmedName,
      'email': email.trim(),
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential;
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (error) {
      return switch (error.code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' =>
          'Email or password is incorrect. Use Forgot Password? to reset it, '
              'or Sign Up if you have not created an account.',
        'invalid-email' => 'Enter a valid email address.',
        'user-disabled' =>
          'This account is disabled. Contact an administrator.',
        'too-many-requests' =>
          'Too many sign-in attempts. Wait a little and try again.',
        'network-request-failed' => 'Could not connect to Firebase. Check your internet connection and try again.',
        _ => error.message ?? 'Login failed',
      };
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Failed to send reset email';
    }
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<String?> getUserRole(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();
    final role = document.data()?['role'];
    return role is String ? role.trim().toLowerCase() : null;
  }

  Future<String?> getUserName(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();
    final name = document.data()?['name'];
    return name is String && name.trim().isNotEmpty ? name : null;
  }

  Future<void> logout() => signOut();

  Future<void> signOut() => _auth.signOut();
}
