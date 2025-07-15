import 'package:dartz/dartz.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/auth_user.dart';
import '../../repositories/auth_repository.dart';

class FacebookSignInUseCase implements UseCase<AuthUser, NoParams> {
  final AuthRepository repository;

  FacebookSignInUseCase(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(NoParams params) async {
    return await repository.signInWithFacebook();
  }
}
