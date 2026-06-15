import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/data_sources/firebase_auth_datasource.dart';
import '../../data/repositories/auth_repo_implement.dart';
import '../../domain/entities/users.dart';
import '../../domain/use_cases/sign_in_usecase.dart';
import '../../domain/use_cases/sign_out_usecase.dart';

final firebaseAuthProvider = Provider((ref) => firebase_auth.FirebaseAuth.instance);

final firebaseAuthDataSourceProvider = Provider((ref) {
  return FirebaseAuthDataSource(ref.watch(firebaseAuthProvider));
});

final authRepositoryProvider = Provider((ref) {
  return AuthRepositoryImpl(ref.watch(firebaseAuthDataSourceProvider));
});

final signInUseCaseProvider = Provider((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
  
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

