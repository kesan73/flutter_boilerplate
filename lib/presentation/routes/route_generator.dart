import 'package:flutter/material.dart';
import '../pages/auth/reset_password_page.dart';
import '../pages/splash/splash_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/signup_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/profile/edit_profile_page.dart';
import '../../core/constants/route_constants.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case RouteConstants.login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case RouteConstants.register:
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case RouteConstants.forgotPassword:
        return MaterialPageRoute(builder: (_) => const ResetPasswordPage());
      // case RouteConstants.home:
      //   return MaterialPageRoute(builder: (_) => const HomePage());
      case RouteConstants.profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case RouteConstants.editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfilePage());
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Error'),
          ),
          body: const Center(
            child: Text('ERROR: Page not found'),
          ),
        );
      },
    );
  }
}
