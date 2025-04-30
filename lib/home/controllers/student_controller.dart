import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evaluation_app/model/user_model.dart';
import 'package:flutter/material.dart';

class StudentController extends ChangeNotifier {
  final UserModel loggedInUser;
  
  String department = '';
  String program = '';
  bool isLoading = true;
  bool isEvaluationActive = false;
  List<String> evaluatedUnits = [];
  AnimationController? animationController;
  DateTime? evaluationEndDate;

  //Public method
 

  StudentController(this.loggedInUser, TickerProvider vsync) {
    animationController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 500),
    )..forward();
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      _fetchCourseDetails(),
      _fetchEvaluationStatus(),
      _fetchEvaluatedUnits(),
    ]);
    isLoading = false;
    notifyListeners();
  }

  // Check if all units have been evaluated
  bool hasCompletedAllEvaluations(List<QueryDocumentSnapshot> units) {
    if (units.isEmpty) return false;
    return units.every((doc) => evaluatedUnits.contains(doc['unitCode'] as String));
  }

   Future<void> refreshEvaluations() async{
    await _fetchEvaluatedUnits();
  }

  Future<void> _fetchCourseDetails() async {
    try {
      final courseDoc = await FirebaseFirestore.instance
          .collection('courses')
          .doc(loggedInUser.courseCode)
          .get();

      if (courseDoc.exists) {
        final courseData = courseDoc.data();
        if (courseData != null) {
          department = courseData['department'] ?? 'Unknown Dept';
          program = courseData['name'] ?? 'Unknown Program';
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching course details: $e');
    }
  }

  Future<void> _fetchEvaluationStatus() async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('evaluation_periods')
        .doc('global')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final startTimestamp = data['startDate'] as Timestamp?;
      final endTimestamp = data['endDate'] as Timestamp?;
      final isActive = data['isActive'] as bool? ?? false;

      if (startTimestamp != null && endTimestamp != null && isActive) {
        final currentDate = DateTime.now();
        evaluationEndDate = endTimestamp.toDate(); // Store the end date
        isEvaluationActive = currentDate.isAfter(startTimestamp.toDate()) &&
            currentDate.isBefore(endTimestamp.toDate());
        notifyListeners();
      }
    }
  } catch (e) {
    debugPrint('Error fetching evaluation status: $e');
  }
}

  Future<void> _fetchEvaluatedUnits() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('evaluations')
          .where('student_reg', isEqualTo: loggedInUser.regno)
          .get();

      evaluatedUnits = snapshot.docs.map((doc) => doc['unit_code'] as String).toList();
      notifyListeners();
    } catch (e) {
      evaluatedUnits = [];
      debugPrint('Error fetching evaluated units: $e');
    }
  }

  bool hasEvaluated(String unitCode) => evaluatedUnits.contains(unitCode);

  bool canDownloadExamCard(List<QueryDocumentSnapshot> units) {
    return units.isNotEmpty && 
           units.every((doc) => hasEvaluated(doc['unitCode'] as String));
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }
}