import 'package:evaluation_app/auth/login_screen.dart';
import 'package:evaluation_app/lecturers/lecturerDashboard.dart';
import 'package:evaluation_app/model/user_model.dart';
import 'package:evaluation_app/students/evaluation_screen.dart';
import 'package:evaluation_app/students/home_screen.dart';
import 'package:flutter/material.dart';


class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String evaluation = '/evaluation';
  static const String lecturerDashboard = '/lecturer_dashboard'; // New route for lecturer dashboard

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case home:
        final loggedInUser = settings.arguments as UserModel?;
        if (loggedInUser == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('No user data provided')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => HomeScreen(loggedInUser: loggedInUser),
        );
      case evaluation:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args == null || args['unit'] == null || args['studentReg'] == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(child: Text('No unit or student data provided')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => EvaluationScreen(
            unit: args['unit'],
            studentReg: args['studentReg'],
          ),
        );
      case lecturerDashboard: // New route handler for lecturer dashboard
        return MaterialPageRoute(builder: (_) => const LecturerDashboard());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}