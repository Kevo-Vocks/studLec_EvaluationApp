import 'package:evaluation_app/home/controllers/student_controller.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'unit_card.dart';

class UnitsList extends StatelessWidget {
  final StudentController controller;
  final List<QueryDocumentSnapshot> units; // Add units parameter

  const UnitsList({super.key, required this.controller, required this.units});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: units.length,
      itemBuilder: (context, index) {
        return UnitCard(
          unitData: units[index].data() as Map<String, dynamic>,
          animation: controller.animationController!,
        );
      },
    );
  }
}