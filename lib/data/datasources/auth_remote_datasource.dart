import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/firebase_constants.dart';
import '../../core/errors/exceptions.dart';
import '../models/auth_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> login({required String email, required String password});
  Future<AuthModel> register(
      {required String email, required String password, required String name});
  Future<void> logout();
  Future<AuthModel?> getCurrentUser();
  Future<void> resetPassword({required String email});
  Future<void> verifyEmail();
  Stream<AuthModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<AuthModel> login(
      {required String email, required String password}) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const AuthException(message: 'Login failed');
      }

      return AuthModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Login failed', code: e.code);
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<AuthModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw const AuthException(message: 'Registration failed');
      }

      // Update display name
      await userCredential.user!.updateDisplayName(name);

      // Create user document in Firestore
      await firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userCredential.user!.uid)
          .set({
        FirebaseConstants.emailField: email,
        FirebaseConstants.nameField: name,
        FirebaseConstants.createdAtField: FieldValue.serverTimestamp(),
        FirebaseConstants.updatedAtField: FieldValue.serverTimestamp(),
        FirebaseConstants.isActiveField: true,
      });

      return AuthModel.fromFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
          message: e.message ?? 'Registration failed', code: e.code);
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> logout() async {
    try {
      await firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Logout failed', code: e.code);
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<AuthModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) return null;

      return AuthModel.fromFirebaseUser(user);
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> resetPassword({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
          message: e.message ?? 'Password reset failed', code: e.code);
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Future<void> verifyEmail() async {
    try {
      final user = firebaseAuth.currentUser;
      if (user == null) {
        throw const AuthException(message: 'No user logged in');
      }

      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
          message: e.message ?? 'Email verification failed', code: e.code);
    } catch (e) {
      throw AuthException(message: e.toString());
    }
  }

  @override
  Stream<AuthModel?> get authStateChanges {
    return firebaseAuth.authStateChanges().map(
          (user) => user != null ? AuthModel.fromFirebaseUser(user) : null,
        );
  }
}
