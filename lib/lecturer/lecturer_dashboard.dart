import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evaluation_app/extensions/string_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'data_service.dart';
import 'pdf_generator.dart';
import 'unit_feedback_card.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  Map<String, dynamic>? _lecturerData;
  Map<String, Map<String, dynamic>> _assignedUnits = {};
  final DataService _dataService = DataService();
  Map<String, int> _enrolledStudentsMap = {};
  Map<String, List<Map<String, dynamic>>> unitEvaluations = {};
  Map<String, double> averages = {};
  Map<String, double> boolPercentages = {};
  List<String?> comments = [];
  int totalEnrolled = 0;
  bool _canPop =false; //State to control pop behaviour
  

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _dataService.fetchLecturerData((data) {
      setState(() {
        _lecturerData = data;
      });
    });
    await _dataService.fetchAssignedUnitsAndSemesters((units) async {
      setState(() {
        _assignedUnits = units;
      });
      final enrolledMap = <String, int>{};
      for (var unitCode in _assignedUnits.keys) {
        final unitDetails = _assignedUnits[unitCode]!;
        final courseCode = unitDetails['courseCode'] as String;
        final semester = unitDetails['semesterYear'].split(', ')[0]; // e.g., "Semester 2"
        final year = unitDetails['semesterYear'].split(', ')[1]; // e.g., "Year 3"

        // Query the units collection to confirm the unit exists
        final unitSnapshot = await FirebaseFirestore.instance
            .collection('units')
            .where('unitCode', isEqualTo: unitCode)
            .where('courseCode', isEqualTo: courseCode)
            .where('semester', isEqualTo: semester)
            .where('year', isEqualTo: year)
            .get();

        if (unitSnapshot.docs.isEmpty) {
          print('Unit $unitCode (Course: $courseCode, $semester, $year) not found in Firestore');
          enrolledMap[unitCode] = 0;
          continue;
        }

        // Query the students collection to count enrolled students
        final studentsSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('courseCode', isEqualTo: courseCode)
            .where('semester', isEqualTo: semester)
            .where('year', isEqualTo: year)
            .get();

        final enrolledCount = studentsSnapshot.docs.length;
        enrolledMap[unitCode] = enrolledCount;
        print('Unit $unitCode (Course: $courseCode, $semester, $year): $enrolledCount students enrolled');
      }
      setState(() {
        _enrolledStudentsMap = enrolledMap;
        print('Enrolled Students Map: $_enrolledStudentsMap');
      });
    });
  }

  void _handlePop(bool didPop, dynamic result) {
  if (didPop) return; // If the pop already happened, do nothing

  showDialog<bool>(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (context) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Do you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop(true); // Close dialog
            // Perform logout
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login'); // Navigate to login
            }
          },
          child: const Text('Yes'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return PopScope(
        canPop: false, // Control whether popping is allowed
  onPopInvokedWithResult: _handlePop,
        child: const Scaffold(
          body: Center(
            child: Text(
              'User not logged in.',
              style: TextStyle(fontSize: 18, color: Colors.red),
            ),
          ),
        ),
      );
    }
    final staffNo = user.email!.split('@')[0].toUpperCase();

    return PopScope(
      canPop: false, // Control whether popping is allowed
  onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Lecturer Dashboard'),
          backgroundColor: const Color(0xFF008000),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _fetchData();
                });
              },
              tooltip: 'Refresh Data',
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              tooltip: 'Logout',
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('evaluations')
                        .where('lecturer_number', isEqualTo: staffNo)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final totalEvaluations =
                          snapshot.hasData ? snapshot.data!.docs.length : 0;
          
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _lecturerData != null
                                ? '${_lecturerData!['title'] ?? ''} ${_lecturerData!['firstName'] ?? ''} ${_lecturerData!['secondName'] ?? ''}'
                                : 'Loading...',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF008000),
                            ),
                            semanticsLabel:
                                'Lecturer Name: ${_lecturerData != null ? '${_lecturerData!['title'] ?? ''} ${_lecturerData!['firstName'] ?? ''} ${_lecturerData!['secondName'] ?? ''}' : 'Loading'}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Staff Number: $staffNo',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                            semanticsLabel: 'Staff Number: $staffNo',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Department: ${_lecturerData?['department'] ?? 'Loading...'}',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                            semanticsLabel:
                                'Department: ${_lecturerData?['department'] ?? 'Loading...'}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Units Count: ${_assignedUnits.length}',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                            semanticsLabel: 'Units Count: ${_assignedUnits.length}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Evaluations: $totalEvaluations',
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                            semanticsLabel: 'Total Evaluations: $totalEvaluations',
                          ),
                        ],
                      );
                    },
                  ),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('evaluations')
                      .where('lecturer_number', isEqualTo: staffNo)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final Map<String, List<Map<String, dynamic>>> unitEvaluations = {};
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        var unitCode = data['unit_code'] as String;
                        unitEvaluations.putIfAbsent(unitCode, () => []).add(data);
                      }
                    }
          
                    final categories = [
                      'attendance',
                      'explanation',
                      'resources',
                      'communication',
                      'participation',
                      'attitude',
                      'availability',
                      'timeliness',
                      'relevance',
                      'marking_timeliness',
                      'overall_satisfaction'
                    ];
          
                    final Map<String, double> averages = {};
                    for (var category in categories) {
                      final values = unitEvaluations.values
                          .expand((evals) => evals)
                          .map((e) => (e[category] as num?)?.toDouble())
                          .where((e) => e != null)
                          .toList();
                      averages[category] = values.isNotEmpty
                          ? values.reduce((a, b) => a! + b!)! / values.length
                          : 0.0;
                    }
          
                    final performanceCategories = categories
                        .where((category) => category != 'overall_satisfaction')
                        .toList();
                    final overallPerformanceValues = performanceCategories
                        .map((category) => averages[category]!)
                        .where((avg) => avg > 0)
                        .toList();
                    final overallPerformance = overallPerformanceValues.isNotEmpty
                        ? overallPerformanceValues.reduce((a, b) => a + b) /
                            overallPerformanceValues.length
                        : 0.0;
          
                    final totalResponses = unitEvaluations.values
                        .expand((evals) => evals)
                        .length;
          
                    final boolFields = [
                      'outline_given',
                      'objectives_clear',
                      'objectives_met'
                    ];
                    final Map<String, double> boolPercentages = {};
                    for (var field in boolFields) {
                      final trueCount = unitEvaluations.values
                          .expand((evals) => evals)
                          .where((e) => e[field] == true)
                          .length;
                      final totalEvals = unitEvaluations.values
                          .expand((evals) => evals)
                          .length;
                      boolPercentages[field] = totalEvals > 0
                          ? (trueCount / totalEvals) * 100
                          : 0.0;
                    }
          
                    final comments = unitEvaluations.values
                        .expand((evals) => evals)
                        .map((e) => e['comments'] as String?)
                        .where((c) => c != null && c.isNotEmpty)
                        .toList();
          
                    final totalEnrolled = _enrolledStudentsMap.values.fold<int>(0, (sum, count) => sum + count);
                    final responseRate = totalEnrolled > 0 ? (totalResponses / totalEnrolled) * 100 : 0.0;
                    print('Total Enrolled: $totalEnrolled, Total Responses: $totalResponses, Response Rate: $responseRate%');
          
                    final improvementAreas = averages.entries
                        .where((entry) => entry.key != 'overall_satisfaction' && entry.value < 3.0)
                        .map((entry) => '${entry.key.replaceAll('_', ' ').capitalize()} (${entry.value.toStringAsFixed(1)}/5)')
                        .toList();
          
                    if (_assignedUnits.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No units assigned.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                            semanticsLabel: 'No units assigned',
                          ),
                        ),
                      );
                    }
          
                    final List<Map<String, dynamic>> unitData = [];
                    for (var entry in _assignedUnits.entries) {
                      final unitCode = entry.key;
                      final unitDetails = entry.value;
                      final evals = unitEvaluations[unitCode] ?? [];
                      final enrolledStudents = _enrolledStudentsMap[unitCode] ?? 0;
          
                      final unitAverages = <String, double>{};
                      for (var category in categories) {
                        final values = evals
                            .map((e) => (e[category] as num?)?.toDouble())
                            .where((e) => e != null)
                            .toList();
                        unitAverages[category] = values.isNotEmpty
                            ? values.reduce((a, b) => a! + b!)! / values.length
                            : 0.0;
                      }
                      final unitPerformanceValues = performanceCategories
                          .map((category) => unitAverages[category]!)
                          .where((avg) => avg > 0)
                          .toList();
                      final unitPerformance = unitPerformanceValues.isNotEmpty
                          ? unitPerformanceValues.reduce((a, b) => a + b) /
                              unitPerformanceValues.length
                          : 0.0;
          
                      final hasLowCategory = unitAverages.entries
                          .any((entry) => entry.key != 'overall_satisfaction' && entry.value < 3.0 && entry.value > 0);
          
                      unitData.add({
                        'unitCode': unitCode,
                        'unitDetails': unitDetails,
                        'evals': evals,
                        'enrolledStudents': enrolledStudents,
                        'averages': unitAverages,
                        'performance': unitPerformance,
                        'hasLowCategory': hasLowCategory,
                      });
                    }
          
                    unitData.sort((a, b) {
                      final perfA = a['performance'] as double;
                      final perfB = b['performance'] as double;
          
                      if (perfA.isNaN && perfB.isNaN) return 0;
                      if (perfA.isNaN) return -1;
                      if (perfB.isNaN) return 1;
          
                      return perfA.compareTo(perfB);
                    });
          
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lecturer Evaluation Analysis',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008000),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Key Performance Metrics',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008000),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 2,
                                children: [
                                  _buildMetricCard(
                                    'Overall Performance',
                                    '${overallPerformance.toStringAsFixed(1)}/5',
                                    Colors.purple.withOpacity(0.1),
                                  ),
                                  _buildMetricCard(
                                    'Response Rate',
                                    '${responseRate.toStringAsFixed(1)}%',
                                    Colors.green.withOpacity(0.1),
                                  ),
                                  _buildMetricCard(
                                    'Total Responses',
                                    '$totalResponses',
                                    Colors.yellow.withOpacity(0.1),
                                  ),
                                  _buildMetricCard(
                                    'Improvement Areas',
                                    '${improvementAreas.length}',
                                    Colors.red.withOpacity(0.1),
                                  ),
                                ],
                              ),
                              if (improvementAreas.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'Improvement Areas',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF008000),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...improvementAreas.map((area) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Text(
                                        '• $area',
                                        style: const TextStyle(fontSize: 14, color: Colors.red),
                                      ),
                                    )),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Overall Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008000),
                                ),
                                semanticsLabel: 'Overall Summary',
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Overall Performance (Across All Categories):',
                                      style: const TextStyle(fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    overallPerformance.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF008000),
                                    ),
                                    semanticsLabel:
                                        'Overall Performance: ${overallPerformance.toStringAsFixed(1)} out of 5',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Semantics(
                                label:
                                    'Overall performance progress: ${overallPerformance.toStringAsFixed(1)} out of 5',
                                child: LinearProgressIndicator(
                                  value: overallPerformance / 5.0,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    overallPerformance >= 4
                                        ? Colors.green
                                        : overallPerformance >= 3
                                            ? Colors.amber[700]!
                                            : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: unitData.length,
                          itemBuilder: (context, index) {
                            final unit = unitData[index];
                            final unitCode = unit['unitCode'] as String;
                            final unitDetails = unit['unitDetails'] as Map<String, dynamic>;
                            final unitName = unitDetails['unitName'] as String;
                            final courseCode = unitDetails['courseCode'] as String;
                            final semesterYear = unitDetails['semesterYear'] as String;
                            final evals = unit['evals'] as List<Map<String, dynamic>>;
                            final enrolledStudents = unit['enrolledStudents'] as int;
                            final averages = unit['averages'] as Map<String, double>;
                            final performance = unit['performance'] as double;
                            final hasLowCategory = unit['hasLowCategory'] as bool;
          
                            final unitResponseRate = enrolledStudents > 0
                                ? (evals.length / enrolledStudents) * 100
                                : 0.0;
          
                            if (evals.isEmpty) {
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  title: Text(
                                    '$unitName (${unitCode})',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF008000),
                                    ),
                                    semanticsLabel: 'Unit: $unitName ($unitCode)',
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Year ${semesterYear.split(', ')[1].replaceAll('Year ', '')} ${semesterYear.split(', ')[0]}, Course: $courseCode',
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        semanticsLabel:
                                            'Year ${semesterYear.split(', ')[1].replaceAll('Year ', '')} ${semesterYear.split(', ')[0]}, Course: $courseCode',
                                      ),
                                      Text(
                                        'Enrolled: $enrolledStudents, Evaluated: ${evals.length}',
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        semanticsLabel: 'Enrolled: $enrolledStudents, Evaluated: ${evals.length}',
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Performance: ${performance.toStringAsFixed(1)}/5',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: performance >= 4.0
                                                  ? Colors.green
                                                  : performance >= 3.0
                                                      ? Colors.yellow
                                                      : Colors.red,
                                            ),
                                            semanticsLabel:
                                                'Performance: ${performance.toStringAsFixed(1)} out of 5',
                                          ),
                                          const SizedBox(width: 8),
                                          if (hasLowCategory)
                                            const Icon(
                                              Icons.warning,
                                              color: Colors.red,
                                              size: 16,
                                              semanticLabel: 'Warning: Low category scores',
                                            ),
                                          const Spacer(),
                                          Text(
                                            'Response: ${unitResponseRate.toStringAsFixed(1)}%',
                                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                                            semanticsLabel: 'Response Rate: ${unitResponseRate.toStringAsFixed(1)} percent',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.expand_more,
                                    color: Color(0xFF008000),
                                    semanticLabel: 'Expand',
                                  ),
                                ),
                              );
                            }
          
                            final boolFields = [
                              'outline_given',
                              'objectives_clear',
                              'objectives_met'
                            ];
                            final Map<String, double> boolPercentages = {};
                            for (var field in boolFields) {
                              final trueCount =
                                  evals.where((e) => e[field] == true).length;
                              boolPercentages[field] = evals.isNotEmpty
                                  ? (trueCount / evals.length) * 100
                                  : 0.0;
                            }
          
                            final comments = evals
                                .map((e) => e['comments'] as String?)
                                .where((c) => c != null && c.isNotEmpty)
                                .toList();
          
                            return UnitFeedbackCard(
                              unitName: unitName,
                              unitCode: unitCode,
                              courseCode: courseCode,
                              semesterYear: semesterYear,
                              evaluationsCount: evals.length,
                              enrolledStudents: enrolledStudents,
                              averages: averages,
                              boolPercentages: boolPercentages,
                              comments: comments,
                              overallPerformance: performance,
                              hasLowCategory: hasLowCategory,
                              responseRate: unitResponseRate,
                              evaluations: evals,
                            );
                          },
                        ),
                        if (unitEvaluations.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: FloatingActionButton(
                              onPressed: () => PdfGenerator.downloadAsPDF(
                                lecturerData: _lecturerData,
                                unitEvaluations: unitEvaluations,
                                averages: averages,
                                boolPercentages: boolPercentages,
                                comments: comments,
                                totalEnrolled: totalEnrolled, // Pass totalEnrolled to PDF generator
                                      assignedUnits: _assignedUnits,
                                      enrolledStudentsMap: _enrolledStudentsMap,
                              ),
                              backgroundColor: const Color(0xFF008000),
                              child: const Icon(Icons.download, color: Colors.white),
                              tooltip: 'Download Feedback Report as PDF',
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF008000),
            ),
          ),
        ],
      ),
    );
  }
}