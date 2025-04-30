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

    // Calculate lecturer-wide metrics (similar to lecturer_dashboard.dart)
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

    // Assuming total enrolled students can be calculated (not directly passed)
    // For simplicity, we'll assume a placeholder; in a real app, this should be passed or fetched
    final totalEnrolled = unitEvaluations.keys.length * 50; // Placeholder: 50 students per unit
    final responseRate = totalEnrolled > 0 ? (totalResponses / totalEnrolled) * 100 : 0.0;

    final improvementAreas = averages.entries
        .where((entry) => entry.key != 'overall_satisfaction' && entry.value < 3.0)
        .map((entry) => '${entry.key.replaceAll('_', ' ').capitalize()} (${entry.value.toStringAsFixed(1)}/5)')
        .toList();

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
              'Lecturer: ${lecturerData?['title'] ?? ''} ${lecturerData?['firstName'] ?? ''} ${lecturerData?['secondName'] ?? ''}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              'Department: ${lecturerData?['department'] ?? 'N/A'}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              'Units Assigned: ${unitEvaluations.keys.length}',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.Text(
              'Total Evaluations: $totalResponses',
              style: const pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 20),

            // Lecturer Evaluation Analysis (from lecturer_dashboard.dart)
            pw.Text(
              'Lecturer Evaluation Analysis',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Key Performance Metrics',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Bullet(
              text: 'Overall Performance: ${overallPerformance.toStringAsFixed(1)}/5',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Bullet(
              text: 'Response Rate: ${responseRate.toStringAsFixed(1)}%',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Bullet(
              text: 'Total Responses: $totalResponses',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Bullet(
              text: 'Improvement Areas: ${improvementAreas.length}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            if (improvementAreas.isNotEmpty) ...[
              pw.SizedBox(height: 10),
              pw.Text(
                'Improvement Areas',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              ...improvementAreas.map((area) => pw.Bullet(
                    text: area,
                    style: const pw.TextStyle(fontSize: 14),
                  )),
            ],
            pw.SizedBox(height: 20),

            // Overall Summary (from lecturer_dashboard.dart)
            pw.Text(
              'Overall Summary',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Overall Performance (Across All Categories): ${overallPerformance.toStringAsFixed(1)}/5',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.Text(
              'Performance Level: ${overallPerformance >= 4 ? 'Excellent' : overallPerformance >= 3 ? 'Good' : 'Needs Improvement'}',
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 20),

            // Unit-specific Feedback (from unit_feedback_card.dart)
            ...unitEvaluations.entries.map((entry) {
              final unitCode = entry.key;
              final evals = entry.value;
              final unitName = evals.isNotEmpty ? evals.first['unit_name'] as String : 'Unknown Unit';

              // Calculate unit-specific metrics (similar to unit_feedback_card.dart)
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

              // Calculate Performance Distribution (Pie Chart Data)
              final overallPerformancePerEval = evals
                  .map((eval) {
                    final ratings = performanceCategories
                        .map((category) =>
                            (eval[category] as num?)?.toDouble() ?? 0.0)
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
                if (score >= 4.5) {
                  excellentCount++;
                } else if (score >= 3.5) {
                  goodCount++;
                } else if (score >= 2.5) {
                  averageCount++;
                } else {
                  poorCount++;
                }
              }
              final totalUnitResponses = overallPerformancePerEval.length;

              final poorAndAveragePercentage =
                  totalUnitResponses > 0
                      ? ((poorCount + averageCount) / totalUnitResponses * 100)
                      : 0.0;

              // Sort categories by average rating (like in unit_feedback_card.dart)
              final sortedCategories = categories
                  .map((category) => {
                        'category': category,
                        'avg': unitAverages[category] ?? 0.0,
                      })
                  .toList();

              sortedCategories.sort((a, b) {
                final avgA = a['avg'] as double;
                final avgB = b['avg'] as double;

                if (avgA.isNaN && avgB.isNaN) return 0;
                if (avgA.isNaN) return -1;
                if (avgB.isNaN) return 1;

                return avgA.compareTo(avgB);
              });

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
                    pw.Bullet(
                      text: 'Excellent (≥4.5): ${(excellentCount / totalUnitResponses * 100).toStringAsFixed(1)}% ($excellentCount)',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.Bullet(
                      text: 'Good (≥3.5): ${(goodCount / totalUnitResponses * 100).toStringAsFixed(1)}% ($goodCount)',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.Bullet(
                      text: 'Average (≥2.5): ${(averageCount / totalUnitResponses * 100).toStringAsFixed(1)}% ($averageCount)',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.Bullet(
                      text: 'Poor (<2.5): ${(poorCount / totalUnitResponses * 100).toStringAsFixed(1)}% ($poorCount)',
                      style: const pw.TextStyle(fontSize: 14),
                    ),
                    pw.Text(
                      'Note: This distribution shows the percentage of individual evaluation scores for this unit, categorized as Excellent (≥4.5), Good (≥3.5), Average (≥2.5), or Poor (<2.5). These scores collectively average to the Unit Overall Performance above.',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                    ),
                  ] else ...[
                    pw.Text(
                      'No evaluations available.',
                      style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey),
                    ),
                  ],
                  if (poorAndAveragePercentage > 30 && totalUnitResponses > 0) ...[
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Actionable Insight: ${(poorAndAveragePercentage).toStringAsFixed(1)}% of evaluations are Average or Poor. Check the "Average Ratings" below to identify specific areas for improvement.',
                      style: pw.TextStyle(fontSize: 14, color: PdfColors.red, fontStyle: pw.FontStyle.italic),
                    ),
                  ],
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Average Ratings (1-5)',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  ...sortedCategories.map((entry) {
                    final category = entry['category'] as String;
                    final avg = entry['avg'] as double;
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(category.replaceAll('_', ' ').capitalize()),
                        pw.Text(avg.toStringAsFixed(1)),
                      ],
                    );
                  }),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Course Objectives (% Yes)',
                    style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                  ),
                  ...unitBoolPercentages.entries.map((bp) {
                    return pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(bp.key.replaceAll('_', ' ').capitalize()),
                        pw.Text('${bp.value.toStringAsFixed(1)}%'),
                      ],
                    );
                  }),
                  if (unitComments.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Comments',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    ...unitComments.map((comment) => pw.Bullet(
                          text: comment!,
                          style: const pw.TextStyle(fontSize: 14),
                        )),
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
}