import 'package:evaluation_app/auth/login_screen.dart';
import 'package:evaluation_app/home/views/evaluation_view.dart';
import 'package:evaluation_app/home/views/student_view.dart';
import 'package:evaluation_app/lecturer/lecturer_dashboard.dart';
import 'package:evaluation_app/model/user_model.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String studentDashboard = '/student_dashboard';
  static const String evaluation = '/evaluation';
  static const String lecturerDashboard = '/lecturer_dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case root:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: const RouteSettings(name: login),
        );
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case studentDashboard:
        final loggedInUser = settings.arguments as UserModel?;
        if (loggedInUser == null) {
          return _errorRoute('No user data provided');
        }
        return MaterialPageRoute(
          builder: (_) => StudentView(user: loggedInUser),
        );
      case evaluation:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || args['unit'] == null || args['studentReg'] == null || args['lecturerId'] == null) {
          return _errorRoute('Missing required evaluation data');
        }
        return MaterialPageRoute(
          builder: (_) => EvaluationScreen(
            unit: args['unit'],
            studentReg: args['studentReg'],
          ),
        );
      case lecturerDashboard:
        return MaterialPageRoute(builder: (_) => const LecturerDashboard());
      default:
        return _errorRoute('No route defined for ${settings.name}');
    }
  }

  static MaterialPageRoute _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(child: Text(message)),
      ),
    );
  }
}