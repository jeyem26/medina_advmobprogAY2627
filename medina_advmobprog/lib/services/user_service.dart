import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;

import '../constants.dart';
import '../models/user.dart';

class UserService {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;

  // ============================================================
  // DUMMYJSON LOGIN
  // ============================================================

  Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 30,
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(
        jsonDecode(response.body),
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    throw Exception(
      body['message'] ?? 'Sign in failed',
    );
  }

  // ============================================================
  // DUMMYJSON GET USER BY ID
  // ============================================================

  Future<User> getUserById(int userId) async {
    final response = await http.get(
      Uri.parse('$host/users/$userId'),
    );

    if (response.statusCode == 200) {
      return User.fromJson(
        jsonDecode(response.body),
      );
    }

    throw Exception(
      'Failed to load user information',
    );
  }

  // ============================================================
  // FIREBASE CURRENT USER
  // ============================================================

  firebase_auth.User? get currentUser {
    return _firebaseAuth.currentUser;
  }

  // ============================================================
  // FIREBASE SIGN IN
  // ============================================================

  Future<firebase_auth.UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(
        _firebaseErrorMessage(e),
      );
    }
  }

  // ============================================================
  // FIREBASE CREATE ACCOUNT
  // ============================================================

  Future<firebase_auth.UserCredential> createAccount({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final credential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (username != null && username.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(
          username.trim(),
        );

        await credential.user?.reload();
      }

      return credential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(
        _firebaseErrorMessage(e),
      );
    }
  }

  // ============================================================
  // FIREBASE SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // ============================================================
  // GET FIREBASE USER DATA
  // ============================================================

  Future<firebase_auth.User?> getUserData() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      return null;
    }

    await user.reload();

    return _firebaseAuth.currentUser;
  }

  // ============================================================
  // UPDATE USERNAME
  // ============================================================

  Future<void> updateUsername({
    required String username,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception(
        'No user is currently signed in.',
      );
    }

    if (username.trim().isEmpty) {
      throw Exception(
        'Username cannot be empty.',
      );
    }

    try {
      await user.updateDisplayName(
        username.trim(),
      );

      await user.reload();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(
        _firebaseErrorMessage(e),
      );
    }
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception(
        'No user is currently signed in.',
      );
    }

    final email = user.email;

    if (email == null || email.isEmpty) {
      throw Exception(
        'No email is associated with this account.',
      );
    }

    if (currentPassword.isEmpty) {
      throw Exception(
        'Current password is required.',
      );
    }

    if (newPassword.isEmpty) {
      throw Exception(
        'New password is required.',
      );
    }

    if (newPassword.length < 6) {
      throw Exception(
        'New password must be at least 6 characters.',
      );
    }

    try {
      final credential =
          firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      // Re-authenticate before changing password.
      await user.reauthenticateWithCredential(
        credential,
      );

      // Change password.
      await user.updatePassword(
        newPassword,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(
        _firebaseErrorMessage(e),
      );
    }
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  Future<void> deleteAccount({
    required String password,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception(
        'No user is currently signed in.',
      );
    }

    final email = user.email;

    if (email == null || email.isEmpty) {
      throw Exception(
        'No email is associated with this account.',
      );
    }

    if (password.isEmpty) {
      throw Exception(
        'Password is required.',
      );
    }

    try {
      final credential =
          firebase_auth.EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Re-authenticate before deleting the account.
      await user.reauthenticateWithCredential(
        credential,
      );

      // Delete the Firebase account.
      await user.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(
        _firebaseErrorMessage(e),
      );
    }
  }

  // ============================================================
  // FIREBASE ERROR MESSAGES
  // ============================================================

  String _firebaseErrorMessage(
    firebase_auth.FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is invalid.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'user-not-found':
        return 'No account was found with this email.';

      case 'wrong-password':
        return 'The current password is incorrect.';

      case 'invalid-credential':
        return 'The email or password is incorrect.';

      case 'email-already-in-use':
        return 'An account with this email already exists.';

      case 'weak-password':
        return 'The password is too weak. Use at least 6 characters.';

      case 'requires-recent-login':
        return 'Please sign in again before performing this action.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'user-mismatch':
        return 'The account credentials do not match.';

      case 'operation-not-allowed':
        return 'Email/password authentication is not enabled in Firebase.';

      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}