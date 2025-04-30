import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:evaluation_app/home/controllers/student_controller.dart';
import 'package:evaluation_app/routes/app_routes.dart';

class EvaluationButton extends StatefulWidget {
  final Map<String, dynamic> unitData;

  const EvaluationButton({super.key, required this.unitData});

  @override
  State<EvaluationButton> createState() => _EvaluationButtonState();
}

class _EvaluationButtonState extends State<EvaluationButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StudentController>(context);
    final isEvaluationActive = controller.isEvaluationActive;

    // Removed redundant isEvaluated check since UnitCard already handles this
    return Tooltip(
      message: isEvaluationActive
          ? 'Evaluate the lecturer for this unit'
          : 'Evaluation period is not active',
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF008000),
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        onPressed: isEvaluationActive && !_isLoading
            ? () async {
                HapticFeedback.lightImpact();
                setState(() {
                  _isLoading = true;
                });
                try {
                  await Navigator.pushNamed(
                    context,
                    AppRoutes.evaluation,
                    arguments: {
                      'unit': widget.unitData,
                      'studentReg': controller.loggedInUser.regno,
                      'lecturerId': (widget.unitData['lecturers'] as List<dynamic>)[0],
                    },
                  );
                  await controller.refreshEvaluations();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error refreshing evaluations: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } finally {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            : () {
                if (!isEvaluationActive) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Evaluation period is not active. Please wait until the period opens.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.rate_review, size: 20),
        label: const Text(
          'Evaluate Lecturer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}