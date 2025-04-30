import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:evaluation_app/home/controllers/student_controller.dart';
import 'evaluation_button.dart';

class UnitCard extends StatelessWidget {
  final Map<String, dynamic> unitData;
  final Animation<double> animation;

  const UnitCard({
    super.key,
    required this.unitData,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    final unitCode = unitData['unitCode'] as String? ?? 'Unknown Code';
    final iconColor = Color(int.parse(unitData['iconColor'] ?? '0xFF008000'));

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value, // Subtle scale animation on entry
          child: child,
        );
      },
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1), // Subtle border
        ),
        child: Semantics(
          label: 'Unit card for $unitCode',
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(unitCode, iconColor),
                const SizedBox(height: 12),
                _buildLecturerInfo(),
                const SizedBox(height: 12), // Increased spacing for better layout
                _buildEvaluationStatus(context),
                const SizedBox(height: 12),
                _buildEvaluationButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String unitCode, Color iconColor) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: iconColor,
          radius: 24,
          child: const Icon(Icons.school, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unitCode,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16, // Slightly larger for emphasis
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unitData['unitName'] ?? 'Unknown Unit',
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLecturerInfo() {
    return FutureBuilder(
      future: Future.wait(
        (unitData['lecturers'] as List<dynamic>).map(
          (lecturerId) => FirebaseFirestore.instance
              .collection('lecturers')
              .doc(lecturerId.toString())
              .get(),
        ),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              const Text('Lecturer: ', style: TextStyle(color: Colors.black54)),
              const SizedBox(width: 8),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF008000),
                ),
              ),
            ],
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Row(
            children: [
              const Text('Lecturer: Failed to load', style: TextStyle(color: Colors.red)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: Colors.red),
                onPressed: () {
                  // Force rebuild to retry fetching lecturer data
                  (context as Element).markNeedsBuild();
                },
              ),
            ],
          );
        }

        final docs = snapshot.data as List<DocumentSnapshot>;
        final names = docs.map((doc) {
          if (!doc.exists) return 'Unknown';
          final lecturer = doc.data() as Map<String, dynamic>? ?? {};
          final title = lecturer['title'] ?? '';
          final firstName = lecturer['firstName'] ?? '';
          final secondName = lecturer['secondName'] ?? '';
          return '$title $firstName $secondName'.trim();
        }).join(', ');

        return Text(
          'Lecturer: ${names.isEmpty ? "Unknown" : names}',
          style: const TextStyle(color: Colors.black54),
        );
      },
    );
  }

  Widget _buildEvaluationStatus(BuildContext context) {
    final controller = Provider.of<StudentController>(context, listen: false);
    final isEvaluated = controller.hasEvaluated(unitData['unitCode'] as String);

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (!isEvaluated)
          Tooltip(
            message: 'Evaluation pending for this unit',
            child: Chip(
              label: const Text(
                'Pending',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
          ),
        if (isEvaluated)
          Tooltip(
            message: 'Evaluation completed for this unit',
            child: Chip(
              label: const Text(
                'Evaluated',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              backgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
          ),
      ],
    );
  }

  Widget _buildEvaluationButton(BuildContext context) {
    final controller = Provider.of<StudentController>(context, listen: false);
    final isEvaluated = controller.hasEvaluated(unitData['unitCode'] as String);

    if (isEvaluated) {
      return const SizedBox.shrink();
    }

    return EvaluationButton(unitData: unitData);
  }
}