import 'package:evaluation_app/extensions/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class UnitFeedbackCard extends StatefulWidget {
  final String unitName;
  final String unitCode;
  final String courseCode;
  final String semesterYear;
  final int evaluationsCount;
  final int enrolledStudents;
  final Map<String, double> averages;
  final Map<String, double> boolPercentages;
  final List<String?> comments;
  final double overallPerformance;
  final bool hasLowCategory;
  final double responseRate;
  final List<Map<String, dynamic>> evaluations;

  const UnitFeedbackCard({
    super.key,
    required this.unitName,
    required this.unitCode,
    required this.courseCode,
    required this.semesterYear,
    required this.evaluationsCount,
    required this.enrolledStudents,
    required this.averages,
    required this.boolPercentages,
    required this.comments,
    required this.overallPerformance,
    required this.hasLowCategory,
    required this.responseRate,
    required this.evaluations,
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

    final performanceCategories = categories
        .where((category) => category != 'overall_satisfaction')
        .toList();

    // Calculate overall performance per evaluation for this unit
    final overallPerformancePerEval = widget.evaluations
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
    final totalResponses = overallPerformancePerEval.length;

    // Calculate the percentage of Poor and Average evaluations for actionable insights
    final poorAndAveragePercentage =
        totalResponses > 0
            ? ((poorCount + averageCount) / totalResponses * 100)
            : 0.0;

    final sortedCategories = categories
        .map((category) => {
              'category': category,
              'avg': widget.averages[category] ?? 0.0,
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Year ${widget.semesterYear.split(', ')[1].replaceAll('Year ', '')} ${widget.semesterYear.split(', ')[0]}, Course: ${widget.courseCode}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  semanticsLabel:
                      'Year ${widget.semesterYear.split(', ')[1].replaceAll('Year ', '')} ${widget.semesterYear.split(', ')[0]}, Course: ${widget.courseCode}',
                ),
                Text(
                  'Enrolled: ${widget.enrolledStudents}, Evaluated: ${widget.evaluationsCount}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  semanticsLabel: 'Enrolled: ${widget.enrolledStudents}, Evaluated: ${widget.evaluationsCount}',
                ),
                Row(
                  children: [
                    Text(
                      'Performance: ${widget.overallPerformance.toStringAsFixed(1)}/5',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.overallPerformance >= 4.0
                            ? Colors.green
                            : widget.overallPerformance >= 3.0
                                ? Colors.amber[700]!
                                : Colors.red,
                      ),
                      semanticsLabel:
                          'Performance: ${widget.overallPerformance.toStringAsFixed(1)} out of 5',
                    ),
                    const SizedBox(width: 8),
                    if (widget.hasLowCategory)
                      const Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 16,
                        semanticLabel: 'Warning: Low category scores',
                      ),
                    const Spacer(),
                    Text(
                      'Response: ${widget.responseRate.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      semanticsLabel: 'Response Rate: ${widget.responseRate.toStringAsFixed(1)} percent',
                    ),
                  ],
                ),
              ],
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
                    'Performance Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF008000),
                    ),
                    semanticsLabel: 'Performance Distribution',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Unit Overall Performance: ${widget.overallPerformance.toStringAsFixed(1)}/5',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: widget.overallPerformance >= 4.0
                              ? Colors.green
                              : widget.overallPerformance >= 3.0
                                  ? Colors.amber[700]!
                                  : Colors.red,
                        ),
                        semanticsLabel:
                            'Unit Overall Performance: ${widget.overallPerformance.toStringAsFixed(1)} out of 5',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: totalResponses > 0
                            ? PieChart(
                                PieChartData(
                                  sections: [
                                    if (excellentCount > 0)
                                      PieChartSectionData(
                                        color: Colors.blue,
                                        value: excellentCount.toDouble(),
                                        title: '${(excellentCount / totalResponses * 100).toStringAsFixed(1)}%',
                                        radius: 50,
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    if (goodCount > 0)
                                      PieChartSectionData(
                                        color: Colors.green,
                                        value: goodCount.toDouble(),
                                        title: '${(goodCount / totalResponses * 100).toStringAsFixed(1)}%',
                                        radius: 50,
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    if (averageCount > 0)
                                      PieChartSectionData(
                                        color: const Color(0xFFF57C00),
                                        value: averageCount.toDouble(),
                                        title: '${(averageCount / totalResponses * 100).toStringAsFixed(1)}%',
                                        radius: 50,
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          shadows: [
                                            Shadow(
                                              color: Colors.white,
                                              offset: Offset(0.5, 0.5),
                                              blurRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (poorCount > 0)
                                      PieChartSectionData(
                                        color: Colors.red,
                                        value: poorCount.toDouble(),
                                        title: '${(poorCount / totalResponses * 100).toStringAsFixed(1)}%',
                                        radius: 50,
                                        titleStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 30,
                                ),
                              )
                            : const Text(
                                'No evaluations available.',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This chart shows the distribution of individual evaluation scores for this unit. Each evaluation’s overall score (average of category ratings) is categorized as Excellent (≥4.5), Good (≥3.5), Average (≥2.5), or Poor (<2.5). These scores collectively average to the Unit Overall Performance above.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildLegendItem(Colors.blue, 'Excellent'),
                      _buildLegendItem(Colors.green, 'Good'),
                      _buildLegendItem(const Color(0xFFF57C00), 'Average'),
                      _buildLegendItem(Colors.red, 'Poor'),
                    ],
                  ),
                  if (poorAndAveragePercentage > 30 && totalResponses > 0) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Actionable Insight: ${(poorAndAveragePercentage).toStringAsFixed(1)}% of evaluations are Average or Poor. Check the "Average Ratings" below to identify specific areas for improvement.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                      semanticsLabel:
                          'Actionable Insight: ${(poorAndAveragePercentage).toStringAsFixed(1)} percent of evaluations are Average or Poor. Check the Average Ratings below to identify specific areas for improvement.',
                    ),
                  ],
                  const SizedBox(height: 16),
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
                  ...sortedCategories.map((entry) {
                    final category = entry['category'] as String;
                    final avg = entry['avg'] as double;
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
          ? (Colors.amber[700] ?? Colors.yellow) // Fallback to Colors.yellow if null
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

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}