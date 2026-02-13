import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../../../core/services/auth_service.dart';
import '../../../models/user_model.dart';

/// Authentication state class
class AuthState extends Equatable {
  final bool isLoading;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  /// Create initial state
  factory AuthState.initial() => const AuthState();

  /// Create loading state
  AuthState copyWith({
    bool? isLoading,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }

  /// Clear error
  AuthState clearError() {
    return AuthState(
      isLoading: isLoading,
      user: user,
      error: null,
    );
  }

  @override
  List<Object?> get props => [isLoading, user, error];
}

/// Authentication StateNotifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FirebaseFirestore _firestore;

  AuthNotifier(this._authService, this._firestore) : super(AuthState.initial()) {
    _initAuthListener();
  }

  /// Initialize auth state listener
  void _initAuthListener() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await _loadUserData(firebaseUser.uid);
      } else {
        state = AuthState.initial();
      }
    });
  }

  /// Load user data from Firestore
  Future<void> _loadUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!, doc.id);
        state = state.copyWith(user: user, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load user data',
        isLoading: false,
      );
    }
  }

  /// Sign up a new user
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authService.signUp(
        name: name,
        email: email,
        password: password,
        role: role,
      );

      // User data will be loaded by auth state listener
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Sign up failed',
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      rethrow;
    }
  }

  /// Login user
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _authService.login(
        email: email,
        password: password,
      );

      // User data will be loaded by auth state listener
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Login failed',
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _authService.logout();
      state = AuthState.initial();
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Logout failed',
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.clearError();
  }
}

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for Firestore instance
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Main authentication provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final firestore = ref.watch(firestoreProvider);
  return AuthNotifier(authService, firestore);
});

/// Helper provider to check if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user != null;
});

/// Helper provider to get current user
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});
