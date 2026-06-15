import '../entities/users.dart';

abstract class AuthRepository {
  Future<User?> signIn(String email, String password);
  Future<void> signOut();
  Stream<User?> get authStateChanges;
}
