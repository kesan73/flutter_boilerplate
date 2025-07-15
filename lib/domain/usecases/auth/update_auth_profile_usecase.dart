import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/auth_repository.dart';

class UpdateAuthProfileUseCase
    implements UseCase<void, UpdateAuthProfileParams> {
  final AuthRepository repository;

  UpdateAuthProfileUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateAuthProfileParams params) async {
    return await repository.updateProfile(
      displayName: params.displayName,
      photoURL: params.photoURL,
    );
  }
}

class UpdateAuthProfileParams extends Equatable {
  final String? displayName;
  final String? photoURL;

  const UpdateAuthProfileParams({
    this.displayName,
    this.photoURL,
  });

  @override
  List<Object?> get props => [displayName, photoURL];
}
