import 'package:boilerplate/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/app_config.dart';
import 'config/theme_config.dart';
import 'injection_container.dart' as di;

import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/auth/auth_event.dart';
import 'presentation/blocs/user/user_bloc.dart';
import 'presentation/routes/app_router.dart';

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp();
//   await di.init();

//   runApp(const MaterialApp(
//     home: HomeScreen(),
//   ));
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화를 DefaultFirebaseOptions 사용하도록 개선
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>()..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<UserBloc>(
          create: (context) => di.sl<UserBloc>(),
        ),
      ],
      child: MaterialApp.router(
        title: AppConfig.appName,
        theme: ThemeConfig.lightTheme,
        darkTheme: ThemeConfig.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
