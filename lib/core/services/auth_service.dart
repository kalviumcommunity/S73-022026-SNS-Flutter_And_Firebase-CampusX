import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service class for handling authentication operations using Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up a new user with email and password
  /// 
  /// Creates a user in Firebase Auth and stores additional user data in Firestore
  /// 
  /// Parameters:
  /// - [name]: User's full name
  /// - [email]: User's email address
  /// - [password]: User's password
  /// - [role]: User's role (e.g., 'student', 'admin', 'club_lead')
  /// 
  /// Returns: [UserCredential] on successful signup
  /// Throws: [FirebaseAuthException] or [FirebaseException] on failure
  Future<UserCredential> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user data in Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Rethrow with Firebase Auth specific errors
      throw FirebaseAuthException(
        code: e.code,
        message: _getAuthErrorMessage(e.code),
      );
    } on FirebaseException catch (e) {
      // Rethrow Firestore errors
      throw FirebaseException(
        plugin: e.plugin,
        code: e.code,
        message: 'Failed to store user data: ${e.message}',
      );
    } catch (e) {
      // Handle any other errors
      throw Exception('An unexpected error occurred during sign up: $e');
    }
  }

  /// Login user with email and password
  /// 
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: User's password
  /// 
  /// Returns: [UserCredential] on successful login
  /// Throws: [FirebaseAuthException] on failure
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      throw Exception('An unexpected error occurred during login: $e');
    }
  }

  /// Logout the current user
  /// 
  /// Throws: [FirebaseAuthException] on failure
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: 'Failed to logout: ${e.message}',
      );
    } catch (e) {
      throw Exception('An unexpected error occurred during logout: $e');
    }
  }

  /// Get user-friendly error messages for Firebase Auth errors
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}