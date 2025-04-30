// lib/controllers/evaluation_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evaluation_app/model/lecturer_Evaluation_model.dart';

class EvaluationController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  

  
  // Method to fetch lecturer data
  Future<Map<String, String>> fetchLecturerData(List<dynamic>? lecturerIds) async {
    String lecturerName = 'Unknown';
    String lecturerNumber = 'Unknown';
    
    if (lecturerIds != null && lecturerIds.isNotEmpty) {
      final lecturerDoc = await _firestore
          .collection('lecturers')
          .doc(lecturerIds.first.toString())
          .get();
          
      final lecturerData = lecturerDoc.data() ?? {};
      lecturerName = '${lecturerData['title'] ?? ''} ${lecturerData['firstName'] ?? ''} ${lecturerData['secondName'] ?? ''}'.trim();
      lecturerNumber = lecturerData['staffNo']?.toString() ?? 'Unknown';
    }
    
    return {
      'name': lecturerName,
      'number': lecturerNumber,
    };
  }
  
  // Method to fetch student course code
  Future<String> fetchStudentCourseCode(String studentReg) async {
    String safeReg = studentReg.replaceAll('/', '_slash_').toLowerCase();
    String courseCode = 'Unknown';
    
    final studentDoc = await _firestore
        .collection('students')
        .doc(safeReg)
        .get();
        
    if (studentDoc.exists) {
      courseCode = studentDoc.data()?['courseCode'] ?? 'Unknown';
    }
    
    return courseCode;
  }
  
  // Method to submit evaluation
  Future<bool> submitEvaluation(LecturerEvaluation evaluation) async {
    try {
      String safeReg = evaluation.studentReg.replaceAll('/', '_slash_').toLowerCase();
      String evaluationId = '${safeReg}_${evaluation.unitCode}';
      
      await _firestore
          .collection('evaluations')
          .doc(evaluationId)
          .set(evaluation.toJson());
          
      return true;
    } catch (e) {
      print('Error submitting evaluation: $e');
      return false;
    }
  }
  
  // Method to validate specific section
  bool validateSection(int sectionIndex, LecturerEvaluation evaluation) {
    if (sectionIndex == 0) {
      return true;
    } else if (sectionIndex == 1) {
      return evaluation.outlineGiven != null &&
          evaluation.objectivesClear != null &&
          evaluation.objectivesMet != null;
    } else if (sectionIndex == 2) {
      return evaluation.attendance != null &&
          evaluation.explanation != null &&
          evaluation.resources != null &&
          evaluation.communication != null;
    } else if (sectionIndex == 3) {
      return evaluation.participation != null &&
          evaluation.attitude != null &&
          evaluation.availability != null;
    } else if (sectionIndex == 4) {
      return evaluation.timeliness != null &&
          evaluation.relevance != null &&
          evaluation.markingTimeliness != null;
    } else if (sectionIndex == 5) {
      return evaluation.overallSatisfaction != null;
    }
    return false;
  }
}