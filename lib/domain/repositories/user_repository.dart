import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class UserRepository {
  Future<Either<Failure, User>> getUserProfile(String userId);

  Future<Either<Failure, User>> updateUserProfile({
    required String userId,
    required Map<String, dynamic> data,
  });

  Future<Either<Failure, void>> deleteUserProfile(String userId);

  Future<Either<Failure, List<User>>> getAllUsers({
    int? limit,
    String? lastUserId,
  });

  Future<Either<Failure, List<User>>> searchUsers({
    required String query,
    int? limit,
  });
}
