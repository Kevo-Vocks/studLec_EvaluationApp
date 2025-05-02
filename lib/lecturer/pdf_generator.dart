import 'package:evaluation_app/extensions/string_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  static Future<void> downloadAsPDF({
    required Map<String, dynamic>? lecturerData,
    required Map<String, List<Map<String, dynamic>>> unitEvaluations,
    required Map<String, double> averages,
    required Map<String, double> boolPercentages,
    required List<String?> comments,
    required int totalEnrolled,
    Map<String, Map<String, dynamic>>? assignedUnits,
    Map<String, int>? enrolledStudentsMap,
  }) async {
    final pdf = pw.Document();
    final user = FirebaseAuth.instance.currentUser!;
    final staffNo = user.email!.split('@')[0].toUpperCase();

    // Categories for evaluation
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

    // Calculate lecturer-wide metrics
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

    final responseRate = totalEnrolled > 0 ? (totalResponses / totalEnrolled) * 100 : 0.0;

    final improvementAreas = averages.entries
        .where((entry) => entry.key != 'overall_satisfaction' && entry.value < 3.0)
        .map((entry) => '${entry.key.replaceAll('_', ' ').capitalize()} (${entry.value.toStringAsFixed(1)}/5)')
        .toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        footer: (pw.Context context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
        build: (pw.Context context) {
          return [
            // Header with Decoration
            pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#008000'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Lecturer Feedback Report - $staffNo',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Lecturer Information
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Lecturer: ${lecturerData?['title'] ?? ''} ${lecturerData?['firstName'] ?? ''} ${lecturerData?['secondName'] ?? ''}',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Department: ${lecturerData?['department'] ?? 'N/A'}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Staff Number: $staffNo',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Units Assigned: ${assignedUnits?.length ?? 0}',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Total Evaluations: $totalResponses',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  'Total Enrolled: $totalEnrolled',
                  style: pw.TextStyle(fontSize: 14),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Lecturer Evaluation Analysis
            pw.Text(
              'Lecturer Evaluation Analysis',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#008000')),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Key Performance Metrics',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Bullet(
              text: 'Overall Performance: ${overallPerformance.toStringAsFixed(1)}/5',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.Bullet(
              text: 'Response Rate: ${responseRate.toStringAsFixed(1)}%',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.Bullet(
              text: 'Total Responses: $totalResponses',
              style: pw.TextStyle(fontSize: 14),
            ),
            pw.Bullet(
              text: 'Improvement Areas: ${improvementAreas.length}',
              style: pw.TextStyle(fontSize: 14),
            ),
            if (improvementAreas.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                'Improvement Areas',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: improvementAreas.map((area) => pw.Bullet(
                      text: area,
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.red),
                    )).toList(),
              ),
            ],
            pw.SizedBox(height: 20),

            // Overall Summary
            pw.Text(
              'Overall Summary',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#008000')),
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Overall Performance (Across All Categories):',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  '${overallPerformance.toStringAsFixed(1)}/5',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.Text(
              'Performance Level: ${overallPerformance >= 4 ? 'Excellent' : overallPerformance >= 3 ? 'Good' : 'Needs Improvement'}',
              style: pw.TextStyle(fontSize: 14, color: overallPerformance >= 4 ? PdfColors.green : overallPerformance >= 3 ? PdfColors.amber : PdfColors.red),
            ),
            pw.SizedBox(height: 20),

            // Unit-specific Feedback
            ...unitEvaluations.entries.map((entry) {
              final unitCode = entry.key;
              final evals = entry.value;
              final unitName = evals.isNotEmpty && evals.first['unit_name'] != null
                  ? evals.first['unit_name'] as String
                  : 'Unknown Unit';
              final unitDetails = assignedUnits?[unitCode] ?? {};
              final semesterYear = unitDetails['semesterYear'] ?? 'N/A';
              final courseCode = unitDetails['courseCode'] ?? 'N/A';
              final enrolledStudents = enrolledStudentsMap?[unitCode] ?? 0;
              final unitResponseRate = enrolledStudents > 0 ? (evals.length / enrolledStudents) * 100 : 0.0;

              // Calculate unit-specific metrics
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

              // Calculate Performance Distribution
              final overallPerformancePerEval = evals
                  .map((eval) {
                    final ratings = performanceCategories
                        .map((category) {
                          final value = eval[category];
                          return value != null
                              ? (value is num
                                  ? value.toDouble()
                                  : double.tryParse(value.toString()) ?? 0.0)
                              : 0.0;
                        })
                        .where((rating) => rating > 0)
                        .toList();
                    return ratings.isNotEmpty
                        ? ratings.reduce((a, b) => a + b) / ratings.length
                        : 0.0;
                  })
                  .where((score) => score > 0)
                  .toList();

              int excellentCount = 0, goodCount = 0, averageCount = 0, poorCount = 0;
              for (var score in overallPerformancePerEval) {
                if (score >= 4.5) excellentCount++;
                else if (score >= 3.5) goodCount++;
                else if (score >= 2.5) averageCount++;
                else poorCount++;
              }
              final totalUnitResponses = overallPerformancePerEval.length;

              final poorAndAveragePercentage =
                  totalUnitResponses > 0
                      ? ((poorCount + averageCount) / totalUnitResponses * 100)
                      : 0.0;

              // Sort categories by average rating
              final sortedCategories = categories
                  .map((category) => {
                        'category': category,
                        'avg': unitAverages[category] ?? 0.0,
                      })
                  .toList()
                ..sort((a, b) => (b['avg'] as double).compareTo(a['avg'] as double));

              // Unit-specific boolean percentages
              final boolFields = ['outline_given', 'objectives_clear', 'objectives_met'];
              final unitBoolPercentages = <String, double>{};
              for (var field in boolFields) {
                final trueCount = evals.where((e) => e[field] == true).length;
                unitBoolPercentages[field] = evals.isNotEmpty
                    ? (trueCount / evals.length) * 100
                    : 0.0;
              }

              // Unit-specific comments
              final unitComments = evals
                  .map((e) => e['comments'] as String?)
                  .where((c) => c != null && c.isNotEmpty)
                  .toList();

              return pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                padding: const pw.EdgeInsets.all(10),
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          '$unitName ($unitCode)',
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#008000')),
                        ),
                       
                      ],
                    ),
                     pw.Text(
                          'Evaluations: ${evals.length}',
                          style: pw.TextStyle(fontSize: 14),
                        ),
                    pw.Text(
                      'Course: $courseCode | Semester/Year: $semesterYear | Enrolled: $enrolledStudents',
                      style: pw.TextStyle(fontSize: 12, ),
                    ),
                    pw.Text(
                      'Response Rate: ${unitResponseRate.toStringAsFixed(1)}%',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.green),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Unit Overall Performance: ${unitPerformance.toStringAsFixed(1)}/5',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Performance Distribution',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 5),
                    if (totalUnitResponses > 0) ...[
                      pw.Table(
                        border: pw.TableBorder.all(color: PdfColors.grey),
                        children: [
                          pw.TableRow(
                            children: [
                              pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text('Percentage', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text('Count', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              pw.Text('Excellent (=> 4.5)'),
                              pw.Text('${(excellentCount / totalUnitResponses * 100).toStringAsFixed(1)}%'),
                              pw.Text('$excellentCount'),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              pw.Text('Good (=> 3.5)'),
                              pw.Text('${(goodCount / totalUnitResponses * 100).toStringAsFixed(1)}%'),
                              pw.Text('$goodCount'),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              pw.Text('Average (=> 2.5)'),
                              pw.Text('${(averageCount / totalUnitResponses * 100).toStringAsFixed(1)}%'),
                              pw.Text('$averageCount'),
                            ],
                          ),
                          pw.TableRow(
                            children: [
                              pw.Text('Poor (< 2.5)'),
                              pw.Text('${(poorCount / totalUnitResponses * 100).toStringAsFixed(1)}%'),
                              pw.Text('$poorCount'),
                            ],
                          ),
                        ],
                      ),
                      pw.Text(
                        'Note: This distribution shows the percentage of individual evaluation scores for this unit, categorized as Excellent (=> 4.5), Good (=> 3.5), Average (=> 2.5), or Poor (<2.5). These scores collectively average to the Unit Overall Performance above.',
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                      ),
                    ] else ...[
                      pw.Text(
                        'No evaluations available.',
                        style: pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                      ),
                    ],
                    if (poorAndAveragePercentage > 30 && totalUnitResponses > 0) ...[
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Actionable Insight: ${(poorAndAveragePercentage).toStringAsFixed(1)}% of evaluations are Average or Poor. Check the "Average Ratings" below to identify specific areas for improvement.',
                        style: pw.TextStyle(fontSize: 12, color: PdfColors.red, fontStyle: pw.FontStyle.italic),
                      ),
                    ],
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Average Ratings (1-5)',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('Rating', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        ...sortedCategories.map((entry) {
                          final category = entry['category'] as String;
                          final avg = entry['avg'] as double;
                          return pw.TableRow(
                            children: [
                              pw.Text(category.replaceAll('_', ' ').capitalize()),
                              pw.Text(avg.toStringAsFixed(1)),
                            ],
                          );
                        }),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Course Objectives (% Yes)',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey),
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Text('Objective', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            pw.Text('Percentage', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        ...unitBoolPercentages.entries.map((bp) {
                          return pw.TableRow(
                            children: [
                              pw.Text(bp.key.replaceAll('_', ' ').capitalize()),
                              pw.Text('${bp.value.toStringAsFixed(1)}%'),
                            ],
                          );
                        }),
                      ],
                    ),
                    if (unitComments.isNotEmpty) ...[
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Comments',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: unitComments.map((comment) => pw.Bullet(
                              text: comment!,
                              style: pw.TextStyle(fontSize: 12),
                            )).toList(),
                      ),
                    ],
                  ],
                ),
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
}