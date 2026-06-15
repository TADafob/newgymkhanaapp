import '../repositories/auth_repo.dart';
import '../entities/users.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<User?> call(String email, String password) {
    return repository.signIn(email, password);
  }
}
