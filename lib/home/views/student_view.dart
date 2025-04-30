import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evaluation_app/home/controllers/student_controller.dart';
import 'package:evaluation_app/home/widgets/exam_card_pdf.dart';
import 'package:evaluation_app/home/widgets/student_info_card.dart';
import 'package:evaluation_app/home/widgets/units_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evaluation_app/model/user_model.dart';
import 'package:evaluation_app/routes/app_routes.dart';

class StudentView extends StatefulWidget {
  final UserModel user;
  const StudentView({super.key, required this.user});

  @override
  State<StudentView> createState() => _StudentViewState();
}

class _StudentViewState extends State<StudentView> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StudentController(widget.user, this),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(child: _buildBody()),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Student Dashboard', style: TextStyle(color: Colors.white)),
      backgroundColor: const Color(0xFF008000),
      actions: [
        IconButton(
          icon: const Icon(Icons.exit_to_app, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
        )
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<StudentController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                UserInfoCard(user: widget.user, controller: controller),
                const SizedBox(height: 20),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('units')
                      .where('courseCode', isEqualTo: controller.loggedInUser.courseCode)
                      .where('year', isEqualTo: controller.loggedInUser.year)
                      .where('semester', isEqualTo: controller.loggedInUser.semester)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(child: Text("Error loading units"));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No units found for your course/year/semester"));
                    }

                    final units = snapshot.data!.docs;
                    return Column(
                      children: [
                        _buildEvaluationCountdown(controller, units),
                        const SizedBox(height: 20),
                        UnitsList(controller: controller, units: units), // Pass units directly
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          color: const Color(0xFF008000).withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: _buildDownloadButton(controller, units, context),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEvaluationCountdown(StudentController controller, List<QueryDocumentSnapshot> units) {
    if (controller.hasCompletedAllEvaluations(units)) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'You’ve completed all evaluations! You can now download your exam card.',
          style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (controller.evaluationEndDate != null) {
      return StreamBuilder(
        stream: Stream.periodic(const Duration(seconds: 1), (i) => i),
        builder: (context, snapshot) {
          final now = DateTime.now();
          final difference = controller.evaluationEndDate!.difference(now);

          if (difference.isNegative) {
            final formattedEndDate = "${controller.evaluationEndDate!.day} ${_getMonthName(controller.evaluationEndDate!.month)}, ${controller.evaluationEndDate!.year}";
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Evaluation period ended on $formattedEndDate!',
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          final days = difference.inDays;
          final hours = difference.inHours % 24;
          final minutes = difference.inMinutes % 60;
          final seconds = difference.inSeconds % 60;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Time Left to Complete Evaluations:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$days days, $hours hrs, $minutes mins, $seconds secs',
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Evaluation period is not active. Stay tuned!',
        style: TextStyle(fontSize: 16, color: Colors.black54),
        textAlign: TextAlign.center,
      ),
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }

  Widget _buildDownloadButton(StudentController controller, List<QueryDocumentSnapshot> units, BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: controller.canDownloadExamCard(units) 
            ? const Color(0xFF008000) 
            : Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        minimumSize: const Size(double.infinity, 50),
      ),
      onPressed: controller.canDownloadExamCard(units)
          ? () => ExamCardPDF.generate(
                user: controller.loggedInUser,
                department: controller.department,
                program: controller.program,
                units: units,
                context: context,
              )
          : null,
      child: const Text(
        'Download Exam Card',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

