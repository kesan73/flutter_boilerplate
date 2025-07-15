import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';

class UpdateUserProfileUseCase
    implements UseCase<User, UpdateUserProfileParams> {
  final UserRepository repository;

  UpdateUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateUserProfileParams params) async {
    return await repository.updateUserProfile(
      userId: params.userId,
      data: params.data,
    );
  }
}

class UpdateUserProfileParams extends Equatable {
  final String userId;
  final Map<String, dynamic> data;

  const UpdateUserProfileParams({
    required this.userId,
    required this.data,
    required Map<String, dynamic> userData,
  });

  @override
  List<Object> get props => [userId, data];
}
