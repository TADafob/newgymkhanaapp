import 'package:flutter/material.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/users.dart';
import '../../domain/repositories/auth_repo.dart';
import '../data_sources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource firebaseAuthDataSource;

  AuthRepositoryImpl(this.firebaseAuthDataSource);

  @override
  Future<User?> signIn(String email, String password) async {
    try {
      final firebaseUser = await firebaseAuthDataSource.signInWithEmailAndPassword(email, password);
      return firebaseUser != null ? User(uid: firebaseUser.uid, email: firebaseUser.email!) : null;
    } on AuthFailure catch (e) {
      debugPrint(e.toString());
      rethrow;
      
    }
  }

  @override
  Future<void> signOut() {
    return firebaseAuthDataSource.signOut();
  }

  @override
  Stream<User?> get authStateChanges {
    return firebaseAuthDataSource.authStateChanges.map(
      (firebaseUser) => firebaseUser != null
          ? User(uid: firebaseUser.uid, email: firebaseUser.email!)
          : null,
    );
  }
}


