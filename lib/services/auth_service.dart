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
    required String role,
  }) async {
    try {
      await _createUser(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      return null;
    } on FirebaseAuthException catch (error) {
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
    return _createUser(
      name: name,
      email: email,
      password: password,
      role: 'user',
    );
  }

  Future<UserCredential> _createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;

    if (user == null) {
      throw StateError('Firebase Auth did not return a user after signup.');
    }

    await _firestore.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role,
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
      return error.message ?? 'Login failed';
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
    return document.data()?['role'] as String?;
  }

  Future<String?> getUserName(String uid) async {
    final document = await _firestore.collection('users').doc(uid).get();
    final name = document.data()?['name'];
    return name is String && name.trim().isNotEmpty ? name : null;
  }

  Future<void> logout() => signOut();

  Future<void> signOut() => _auth.signOut();
}
