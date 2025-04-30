import 'package:evaluation_app/home/controllers/student_controller.dart';
import 'package:flutter/material.dart';
import 'package:evaluation_app/model/user_model.dart';

class UserInfoCard extends StatelessWidget {
  final UserModel user;
  final StudentController controller;

  const UserInfoCard({
    super.key,
    required this.user,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF008000).withOpacity(0.15),
          child: const Icon(Icons.person, size: 32, color: Color(0xFF008000)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome, ${user.firstname}', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Reg No: ${user.regno}'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Dept: ${controller.department}'),
                  Text('Program: ${controller.program}'),
                ],
              ),
              Text('${user.year} | ${user.semester}'),
            ],
          ),
        ),
      ],
    );
  }
}