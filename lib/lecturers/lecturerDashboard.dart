import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class LecturerDashboard extends StatefulWidget {
  const LecturerDashboard({super.key});

  @override
  State<LecturerDashboard> createState() => _LecturerDashboardState();
}

class _LecturerDashboardState extends State<LecturerDashboard> {
  Map<String, dynamic>? _lecturerData;
  Map<String, Map<String, dynamic>> _assignedUnits = {};

  @override
  void initState() {
    super.initState();
    _fetchLecturerData();
    _fetchAssignedUnitsAndSemesters();
  }

  Future<void> _fetchLecturerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user is logged in');
      return;
    }
    final staffNo = user.email!.split('@')[0].toUpperCase();
    print('Fetching lecturer data for staffNo: $staffNo');
    final doc = await FirebaseFirestore.instance
        .collection('lecturers')
        .doc(staffNo)
        .get();
    if (doc.exists) {
      setState(() {
        _lecturerData = doc.data();
      });
    } else {
      print('Lecturer document not found for $staffNo');
    }
  }

  Future<void> _fetchAssignedUnitsAndSemesters() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user is logged in');
        return;
      }
      final staffNo = user.email!.split('@')[0].toUpperCase();
      print('Fetching units for lecturer: $staffNo');

      // List to store all unit documents (from both query and fallback)
      final List<Map<String, dynamic>> unitDocs = [];

      // Step 1: Query units where this lecturer is assigned
      final unitsSnapshot = await FirebaseFirestore.instance
          .collection('units')
          .where('lecturers', arrayContains: staffNo)
          .get();

      print('Units found: ${unitsSnapshot.docs.length}');
      for (var doc in unitsSnapshot.docs) {
        print('Unit ${doc.id}: ${doc.data()}');
        unitDocs.add({
          'id': doc.id,
          'data': doc.data(),
        });
      }

      // Step 2: If no units found, try lowercase staffNo
      if (unitDocs.isEmpty) {
        print('No units found with uppercase staffNo, trying lowercase...');
        final lowercaseStaffNo = user.email!.split('@')[0].toLowerCase();
        final lowercaseUnitsSnapshot = await FirebaseFirestore.instance
            .collection('units')
            .where('lecturers', arrayContains: lowercaseStaffNo)
            .get();
        print('Units found with lowercase: ${lowercaseUnitsSnapshot.docs.length}');
        for (var doc in lowercaseUnitsSnapshot.docs) {
          print('Unit ${doc.id}: ${doc.data()}');
          unitDocs.add({
            'id': doc.id,
            'data': doc.data(),
          });
        }
      }

      // Step 3: Fallback to lecturers collection if still no units
      if (unitDocs.isEmpty) {
        print('No units found in units collection, falling back to lecturers collection');
        final lecturerDoc = await FirebaseFirestore.instance
            .collection('lecturers')
            .doc(staffNo)
            .get();
        if (lecturerDoc.exists) {
          final assignedUnitCodes = List<String>.from(lecturerDoc.get('units') ?? []);
          print('Units from lecturers collection: $assignedUnitCodes');
          if (assignedUnitCodes.isNotEmpty) {
            for (var unitCode in assignedUnitCodes) {
              final unitDoc = await FirebaseFirestore.instance
                  .collection('units')
                  .doc(unitCode)
                  .get();
              if (unitDoc.exists) {
                unitDocs.add({
                  'id': unitDoc.id,
                  'data': unitDoc.data(),
                });
              }
            }
          }
        }
      }

      // Step 4: Build a map of assigned units with their details
      final unitToDetailsMap = <String, Map<String, dynamic>>{};
      for (var unit in unitDocs) {
        final data = unit['data'] as Map<String, dynamic>;
        final unitCode = data['unitCode'] as String?;
        final semester = data['semester'] as String?;
        final year = data['year'] as String?;
        final unitName = data['unitName'] as String?;
        final courseCode = data['courseCode'] as String?;
        if (unitCode != null && semester != null && year != null && unitName != null && courseCode != null) {
          final semesterYear = '$semester, $year';
          unitToDetailsMap[unitCode] = {
            'unitName': unitName,
            'semesterYear': semesterYear,
            'courseCode': courseCode,
          };
        } else {
          print('Skipping unit ${unit['id']} due to missing fields: unitCode=$unitCode, semester=$semester, year=$year, unitName=$unitName, courseCode=$courseCode');
        }
      }

      setState(() {
        _assignedUnits = unitToDetailsMap;
      });

      if (_assignedUnits.isEmpty) {
        print('No units assigned after processing');
      } else {
        print('Assigned units: $_assignedUnits');
      }
    } catch (e) {
      print('Error fetching assigned units: $e');
    }
  }

  Future<void> _downloadAsPDF(
    Map<String, List<Map<String, dynamic>>> unitEvaluations,
    Map<String, double> averages,
    Map<String, double> boolPercentages,
    List<String?> comments,
  ) async {
    final pdf = pw.Document();
    final user = FirebaseAuth.instance.currentUser!;
    final staffNo = user.email!.split('@')[0].toUpperCase();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Lecturer Feedback Report - $staffNo',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Lecturer: ${_lecturerData?['title'] ?? ''} ${_lecturerData?['firstName'] ?? ''} ${_lecturerData?['secondName'] ?? ''}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 20),
            ...unitEvaluations.entries.map((entry) {
              final unitCode = entry.key;
              final evals = entry.value;
              final unitName = evals.first['unit_name'] as String;

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '$unitName ($unitCode)',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('Evaluations: ${evals.length}'),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Average Ratings (1-5)',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  ...averages.entries.map((avg) {
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(avg.key.replaceAll('_', ' ').capitalize()),
                        pw.Text(avg.value.toStringAsFixed(1)),
                      ],
                    );
                  }),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Course Objectives (% Yes)',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  ...boolPercentages.entries.map((bp) {
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(bp.key.replaceAll('_', ' ').capitalize()),
                        pw.Text('${bp.value.toStringAsFixed(1)}%'),
                      ],
                    );
                  }),
                  if (comments.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Comments',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    ...comments.map((comment) => pw.Text('• $comment')),
                  ],
                  pw.SizedBox(height: 20),
                ],
              );
            }),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'lecturer_feedback_report_$staffNo.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'User not logged in.',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }
    final staffNo = user.email!.split('@')[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Lecturer Dashboard'),
        backgroundColor: const Color(0xFF008000),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {}); // Trigger rebuild to refresh data
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
      body: Column(
        children: [
          // Lecturer Information
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
                // Calculate total evaluations
                final totalEvaluations = snapshot.hasData
                    ? snapshot.data!.docs.length
                    : 0;

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
                      semanticsLabel: 'Department: ${_lecturerData?['department'] ?? 'Loading...'}',
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
          // Unit-wise Feedback Reports
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('evaluations')
                  .where('lecturer_number', isEqualTo: staffNo)
                  .snapshots(),
              builder: (context, snapshot) {
                // Map evaluations by unit_code
                final Map<String, List<Map<String, dynamic>>> unitEvaluations = {};
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final evaluations = snapshot.data!.docs;
                  print('Retrieved ${evaluations.length} evaluations for staffNo: $staffNo');
                  for (var doc in evaluations) {
                    final data = doc.data() as Map<String, dynamic>;
                    var unitCode = data['unit_code'] as String;
                    print('Evaluation for unit: $unitCode');
                    // Normalize unit_code if it contains concatenated fields
                    if (unitCode.contains('_')) {
                      final parts = unitCode.split('_');
                      unitCode = parts.firstWhere((part) => part.startsWith('CCS'), orElse: () => unitCode);
                    }
                    unitEvaluations.putIfAbsent(unitCode, () => []).add(data);
                  }
                } else {
                  print('No evaluations found for staffNo: $staffNo');
                }

                // Log the unitEvaluations keys
                print('unitEvaluations keys: ${unitEvaluations.keys}');

                // Calculate total evaluations
                final totalEvaluations = unitEvaluations.values.fold<int>(
                    0, (sum, evals) => sum + evals.length);

                // Calculate overall satisfaction across all units
                final allOverallSatisfaction = unitEvaluations.values
                    .expand((evals) => evals)
                    .map((e) => (e['overall_satisfaction'] as num?)?.toDouble())
                    .where((e) => e != null)
                    .toList();
                final overallAvg = allOverallSatisfaction.isNotEmpty
                    ? allOverallSatisfaction.reduce((a, b) => a! + b!)! /
                        allOverallSatisfaction.length
                    : 0.0;

                // Calculate averages and percentages for PDF (across all units)
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

                // If no units are assigned, show a message
                if (_assignedUnits.isEmpty) {
                  return const Center(
                    child: Text(
                      'No units assigned.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                      semanticsLabel: 'No units assigned',
                    ),
                  );
                }

                return Column(
                  children: [
                    // Overall Summary
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                              const Text(
                                'Average Overall Satisfaction:',
                                style: TextStyle(fontSize: 16),
                              ),
                              Text(
                                overallAvg.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF008000),
                                ),
                                semanticsLabel:
                                    'Average Overall Satisfaction: ${overallAvg.toStringAsFixed(1)} out of 5',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            label: 'Overall satisfaction progress: ${overallAvg.toStringAsFixed(1)} out of 5',
                            child: LinearProgressIndicator(
                              value: overallAvg / 5.0,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                overallAvg >= 4
                                    ? Colors.green
                                    : overallAvg >= 3
                                        ? Colors.yellow
                                        : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Unit List
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _assignedUnits.entries.map((entry) {
                          final unitCode = entry.key;
                          final unitDetails = entry.value;
                          final unitName = unitDetails['unitName'] as String;
                          final courseCode = unitDetails['courseCode'] as String;
                          final semesterYear = unitDetails['semesterYear'] as String;
                          final evals = unitEvaluations[unitCode] ?? [];

                          print('Unit $unitCode has ${evals.length} evaluations');

                          // If no evaluations, show a placeholder card
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
                                subtitle: Text(
                                  'Year ${semesterYear.split(', ')[1].replaceAll('Year ', '')} ${semesterYear.split(', ')[0]}, Course: $courseCode\nEvaluations: ${evals.length}',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  semanticsLabel: 'Year ${semesterYear.split(', ')[1].replaceAll('Year ', '')} ${semesterYear.split(', ')[0]}, Course: $courseCode, Evaluations: ${evals.length}',
                                ),
                                trailing: const Icon(
                                  Icons.expand_more,
                                  color: Color(0xFF008000),
                                  semanticLabel: 'Expand',
                                ),
                              ),
                            );
                          }

                          // Calculate averages for numerical ratings
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
                            final values = evals
                                .map((e) => (e[category] as num?)?.toDouble())
                                .where((e) => e != null)
                                .toList();
                            averages[category] = values.isNotEmpty
                                ? values.reduce((a, b) => a! + b!)! / values.length
                                : 0.0;
                          }

                          // Calculate percentages for boolean fields
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

                          // Collect anonymized comments
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
                            averages: averages,
                            boolPercentages: boolPercentages,
                            comments: comments,
                          );
                        }).toList(),
                      ),
                    ),
                    // Floating Action Button for PDF Download (only if evaluations exist)
                    if (unitEvaluations.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: FloatingActionButton(
                          onPressed: () => _downloadAsPDF(
                            unitEvaluations,
                            averages,
                            boolPercentages,
                            comments,
                          ),
                          backgroundColor: const Color(0xFF008000),
                          child: const Icon(Icons.download, color: Colors.white),
                          tooltip: 'Download Feedback Report as PDF',
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for each unit's feedback report (collapsible)
class UnitFeedbackCard extends StatefulWidget {
  final String unitName;
  final String unitCode;
  final String courseCode;
  final String semesterYear;
  final int evaluationsCount;
  final Map<String, double> averages;
  final Map<String, double> boolPercentages;
  final List<String?> comments;

  const UnitFeedbackCard({
    super.key,
    required this.unitName,
    required this.unitCode,
    required this.courseCode,
    required this.semesterYear,
    required this.evaluationsCount,
    required this.averages,
    required this.boolPercentages,
    required this.comments,
  });

  @override
  State<UnitFeedbackCard> createState() => _UnitFeedbackCardState();
}

class _UnitFeedbackCardState extends State<UnitFeedbackCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
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
    final boolFields = ['outline_given', 'objectives_clear', 'objectives_met'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            title: Text(
              '${widget.unitName} (${widget.unitCode})',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF008000),
              ),
              semanticsLabel: 'Unit: ${widget.unitName} (${widget.unitCode})',
            ),
            subtitle: Text(
              'Year ${widget.semesterYear.split(', ')[1].replaceAll('Year ', '')} ${widget.semesterYear.split(', ')[0]}, Course: ${widget.courseCode}\nEvaluations: ${widget.evaluationsCount}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              semanticsLabel: 'Year ${widget.semesterYear.split(', ')[1].replaceAll('Year ', '')} ${widget.semesterYear.split(', ')[0]}, Course: ${widget.courseCode}, Evaluations: ${widget.evaluationsCount}',
            ),
            trailing: Icon(
              _isExpanded ? Icons.expand_less : Icons.expand_more,
              color: const Color(0xFF008000),
              semanticLabel: _isExpanded ? 'Collapse' : 'Expand',
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Average Ratings (1-5)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF008000),
                    ),
                    semanticsLabel: 'Average Ratings (1 to 5)',
                  ),
                  const SizedBox(height: 8),
                  ...categories.map((category) {
                    final avg = widget.averages[category]!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              category.replaceAll('_', ' ').capitalize(),
                              style: const TextStyle(fontSize: 14),
                              semanticsLabel:
                                  '${category.replaceAll('_', ' ').capitalize()}',
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Semantics(
                                    label:
                                        '${category.replaceAll('_', ' ').capitalize()} rating: ${avg.toStringAsFixed(1)} out of 5',
                                    child: LinearProgressIndicator(
                                      value: avg / 5.0,
                                      backgroundColor: Colors.grey[300],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        avg >= 4
                                            ? Colors.green
                                            : avg >= 3
                                                ? Colors.yellow
                                                : Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  avg.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF008000),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  const Text(
                    'Course Objectives (% Yes)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF008000),
                    ),
                    semanticsLabel: 'Course Objectives (Percentage Yes)',
                  ),
                  const SizedBox(height: 8),
                  ...boolFields.map((field) {
                    final percentage = widget.boolPercentages[field]!;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            field.replaceAll('_', ' ').capitalize(),
                            style: const TextStyle(fontSize: 14),
                            semanticsLabel:
                                '${field.replaceAll('_', ' ').capitalize()}',
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF008000),
                            ),
                            semanticsLabel:
                                '${field.replaceAll('_', ' ').capitalize()}: ${percentage.toStringAsFixed(1)} percent',
                          ),
                        ],
                      ),
                    );
                  }),
                  if (widget.comments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF008000),
                      ),
                      semanticsLabel: 'Comments',
                    ),
                    const SizedBox(height: 8),
                    ...widget.comments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final comment = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '• $comment',
                          style: const TextStyle(fontSize: 14),
                          semanticsLabel: 'Comment ${index + 1}: $comment',
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Extension to capitalize strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).replaceAll('_', ' ')}";
  }
}