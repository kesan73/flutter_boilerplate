// lib/injection_container.dart - 수정된 버전
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Core
import 'core/network/network_info.dart';
import 'core/cache/cache_manager.dart';

// Data
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/user_remote_datasource.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/user_repository_impl.dart';

// Domain
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'domain/usecases/auth/get_current_user_usecase.dart';
import 'domain/usecases/auth/login_usecase.dart';
import 'domain/usecases/auth/logout_usecase.dart';
import 'domain/usecases/auth/register_usecase.dart';
import 'domain/usecases/auth/reset_password_usecase.dart';
import 'domain/usecases/auth/verify_email_usecase.dart';
import 'domain/usecases/user/get_user_profile_usecase.dart';
import 'domain/usecases/user/update_user_profile_usecase.dart';

// Presentation
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/user/user_bloc.dart';

// Services
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/storage_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! External Dependencies (가장 먼저 등록)
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // Google Sign In 설정
  sl.registerLazySingleton(() => GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
      ));

  //! Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(connectivity: sl()),
  );

  sl.registerLazySingleton<CacheManager>(
    () => CacheManager(sl()),
  );

  //! Services
  sl.registerLazySingleton<FirebaseService>(
    () => FirebaseServiceImpl(sl()),
  );

  sl.registerLazySingleton<AuthService>(
    () => AuthServiceImpl(sl()),
  );

  sl.registerLazySingleton<StorageService>(
    () => StorageServiceImpl(sl()),
  );

  //! Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      googleSignIn: sl(), // 추가된 매개변수
    ),
  );

  sl.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(
      firestore: sl(),
    ),
  );

  //! Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      cacheManager: sl(), // 추가된 매개변수
    ),
  );

  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  //! Use Cases - Auth
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => VerifyEmailUseCase(sl()));

  //! Use Cases - User
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserProfileUseCase(sl()));

  //! BLoCs
  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl(),
        registerUseCase: sl(),
        logoutUseCase: sl(),
        getCurrentUserUseCase: sl(),
        resetPasswordUseCase: sl(),
        verifyEmailUseCase: sl(),
      ));

  sl.registerFactory(() => UserBloc(
        getUserProfileUseCase: sl(),
        updateUserProfileUseCase: sl(),
      ));
}

// 필요한 UseCase들 추가 정의
// lib/domain/usecases/auth/reset_password_usecase.dart
/*
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/auth_repository.dart';

class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(ResetPasswordParams params) async {
    return await repository.resetPassword(email: params.email);
  }
}

class ResetPasswordParams extends Equatable {
  final String email;

  const ResetPasswordParams({required this.email});

  @override
  List<Object> get props => [email];
}
*/

// lib/domain/usecases/auth/verify_email_usecase.dart
/*
import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../core/usecases/usecase.dart';
import '../../repositories/auth_repository.dart';

class VerifyEmailUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  VerifyEmailUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.sendEmailVerification();
  }
}
*/