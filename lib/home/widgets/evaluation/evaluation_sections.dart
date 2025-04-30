// lib/views/widgets/evaluation_sections.dart
import 'package:evaluation_app/model/lecturer_Evaluation_model.dart';
import 'package:flutter/material.dart';

class EvaluationSections extends StatelessWidget {
  final int sectionIndex;
  final LecturerEvaluation evaluation;
  final Function(LecturerEvaluation) onEvaluationChanged;
  final Map<String, dynamic> section;

  const EvaluationSections({
    super.key,
    required this.sectionIndex,
    required this.evaluation,
    required this.onEvaluationChanged,
    required this.section,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section['title'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF008000)),
            ),
            const SizedBox(height: 4),
            Text(
              section['description'],
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            _buildSectionContent(sectionIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContent(int index) {
    switch (index) {
      case 0:
        return BackgroundInfoSection(evaluation: evaluation);
      case 1:
        return CourseRequirementsSection(
          evaluation: evaluation,
          onEvaluationChanged: onEvaluationChanged,
        );
      case 2:
        return TeachingEffectivenessSection(
          evaluation: evaluation,
          onEvaluationChanged: onEvaluationChanged,
        );
      case 3:
        return CourseConductSection(
          evaluation: evaluation,
          onEvaluationChanged: onEvaluationChanged,
        );
      case 4:
        return EvaluationOfLearningSection(
          evaluation: evaluation,
          onEvaluationChanged: onEvaluationChanged,
        );
      case 5:
        return OverallEvaluationSection(
          evaluation: evaluation,
          onEvaluationChanged: onEvaluationChanged,
        );
      default:
        return const Text('Unknown section');
    }
  }
}

class BackgroundInfoSection extends StatelessWidget {
  final LecturerEvaluation evaluation;

  const BackgroundInfoSection({super.key, required this.evaluation});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildInfoRow('Lecturer Name', evaluation.lecturerName),
        const SizedBox(height: 12),
        _buildInfoRow('Unit Code', evaluation.unitCode),
        const SizedBox(height: 12),
        _buildInfoRow('Unit Name', evaluation.unitName),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class CourseRequirementsSection extends StatelessWidget {
  final LecturerEvaluation evaluation;
  final Function(LecturerEvaluation) onEvaluationChanged;

  const CourseRequirementsSection({
    super.key,
    required this.evaluation,
    required this.onEvaluationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        YesNoQuestion(
          question: 'Was the course outline given within the first two weeks of the semester?',
          value: evaluation.outlineGiven,
          onChanged: (value) {
            final updatedEvaluation = LecturerEvaluation(
              lecturerName: evaluation.lecturerName,
              lecturerNumber: evaluation.lecturerNumber,
              unitCode: evaluation.unitCode,
              unitName: evaluation.unitName,
              studentReg: evaluation.studentReg,
              courseCode: evaluation.courseCode,
              outlineGiven: value,
              objectivesClear: evaluation.objectivesClear,
              objectivesMet: evaluation.objectivesMet,
              attendance: evaluation.attendance,
              explanation: evaluation.explanation,
              resources: evaluation.resources,
              communication: evaluation.communication,
              participation: evaluation.participation,
              attitude: evaluation.attitude,
              availability: evaluation.availability,
              timeliness: evaluation.timeliness,
              relevance: evaluation.relevance,
              markingTimeliness: evaluation.markingTimeliness,
              overallSatisfaction: evaluation.overallSatisfaction,
              comments: evaluation.comments,
            );
            onEvaluationChanged(updatedEvaluation);
          },
        ),
        const SizedBox(height: 24),
        YesNoQuestion(
          question: 'Did the course outline include clear objectives?',
          value: evaluation.objectivesClear,
          onChanged: (value) {
            final updatedEvaluation = LecturerEvaluation(
              lecturerName: evaluation.lecturerName,
              lecturerNumber: evaluation.lecturerNumber,
              unitCode: evaluation.unitCode,
              unitName: evaluation.unitName,
              studentReg: evaluation.studentReg,
              courseCode: evaluation.courseCode,
              outlineGiven: evaluation.outlineGiven,
              objectivesClear: value,
              objectivesMet: evaluation.objectivesMet,
              attendance: evaluation.attendance,
              explanation: evaluation.explanation,
              resources: evaluation.resources,
              communication: evaluation.communication,
              participation: evaluation.participation,
              attitude: evaluation.attitude,
              availability: evaluation.availability,
              timeliness: evaluation.timeliness,
              relevance: evaluation.relevance,
              markingTimeliness: evaluation.markingTimeliness,
              overallSatisfaction: evaluation.overallSatisfaction,
              comments: evaluation.comments,
            );
            onEvaluationChanged(updatedEvaluation);
          },
        ),
        const SizedBox(height: 24),
        YesNoQuestion(
          question: 'Were the course objectives met during the semester?',
          value: evaluation.objectivesMet,
          onChanged: (value) {
            final updatedEvaluation = LecturerEvaluation(
              lecturerName: evaluation.lecturerName,
              lecturerNumber: evaluation.lecturerNumber,
              unitCode: evaluation.unitCode,
              unitName: evaluation.unitName,
              studentReg: evaluation.studentReg,
              courseCode: evaluation.courseCode,
              outlineGiven: evaluation.outlineGiven,
              objectivesClear: evaluation.objectivesClear,
              objectivesMet: value,
              attendance: evaluation.attendance,
              explanation: evaluation.explanation,
              resources: evaluation.resources,
              communication: evaluation.communication,
              participation: evaluation.participation,
              attitude: evaluation.attitude,
              availability: evaluation.availability,
              timeliness: evaluation.timeliness,
              relevance: evaluation.relevance,
              markingTimeliness: evaluation.markingTimeliness,
              overallSatisfaction: evaluation.overallSatisfaction,
              comments: evaluation.comments,
            );
            onEvaluationChanged(updatedEvaluation);
          },
        ),
      ],
    );
  }
}

class TeachingEffectivenessSection extends StatelessWidget {
  final LecturerEvaluation evaluation;
  final Function(LecturerEvaluation) onEvaluationChanged;

  const TeachingEffectivenessSection({
    super.key,
    required this.evaluation,
    required this.onEvaluationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RatingQuestion(
          question: 'How would you rate the lecturer\'s attendance and punctuality?',
          value: evaluation.attendance,
          onChanged: (value) {
            final updatedEvaluation = _updateEvaluation(attendance: value);
            onEvaluationChanged(updatedEvaluation);
          },
          descriptions: [
            'Always on time and attended all classes',
            'Rarely late, missed only one or two classes',
            'Sometimes late, missed a few classes',
            'Frequently late or missed several classes',
            'Often late or missed many classes',
          ],
        ),
        const SizedBox(height: 24),
        RatingQuestion(
          question: 'How well did the lecturer explain concepts?',
          value: evaluation.explanation,
          onChanged: (value) {
            final updatedEvaluation = _updateEvaluation(explanation: value);
            onEvaluationChanged(updatedEvaluation);
          },
          descriptions: [
            'Clear and easy to understand, explained in-depth',
            'Generally clear, with a few moments of confusion',
            'Sometimes hard to understand or lacked depth',
            'Often unclear, hard to follow',
            'Struggled to explain, leaving students confused',
          ],
        ),
        const SizedBox(height: 24),
        RatingQuestion(
          question: 'How would you rate the lecturer\'s use of teaching resources (slides, videos, etc.)?',
          value: evaluation.resources,
          onChanged: (value) {
            final updatedEvaluation = _updateEvaluation(resources: value);
            onEvaluationChanged(updatedEvaluation);
          },
          descriptions: [
            'Effective use of a variety of teaching materials',
            'Used good materials, but could have included more variety',
            'Limited resources used, some helpful',
            'Rarely used teaching aids or materials',
            'Did not use any helpful resources',
          ],
        ),
        const SizedBox(height: 24),
        RatingQuestion(
          question: 'How would you rate the lecturer\'s communication skills (clarity, fluency, audibility)?',
          value: evaluation.communication,
          onChanged: (value) {
            final updatedEvaluation = _updateEvaluation(communication: value);
            onEvaluationChanged(updatedEvaluation);
          },
          descriptions: [
            'Clear, understandable, and engaging',
            'Mostly clear, with minor issues in understanding',
            'Sometimes unclear or hard to follow',
            'Often hard to understand',
            'Difficult to understand, unclear communication',
          ],
        ),
      ],
    );
  }
  
  LecturerEvaluation _updateEvaluation({
    int? attendance,
    int? explanation,
    int? resources,
    int? communication,
  }) {
    return LecturerEvaluation(
      lecturerName: evaluation.lecturerName,
      lecturerNumber: evaluation.lecturerNumber,
      unitCode: evaluation.unitCode,
      unitName: evaluation.unitName,
      studentReg: evaluation.studentReg,
      courseCode: evaluation.courseCode,
      outlineGiven: evaluation.outlineGiven,
      objectivesClear: evaluation.objectivesClear,
      objectivesMet: evaluation.objectivesMet,
      attendance: attendance ?? evaluation.attendance,
      explanation: explanation ?? evaluation.explanation,
      resources: resources ?? evaluation.resources,
      communication: communication ?? evaluation.communication,
      participation: evaluation.participation,
      attitude: evaluation.attitude,
      availability: evaluation.availability,
      timeliness: evaluation.timeliness,
      relevance: evaluation.relevance,
      markingTimeliness: evaluation.markingTimeliness,
      overallSatisfaction: evaluation.overallSatisfaction,
      comments: evaluation.comments,
    );
  }
}

class CourseConductSection extends StatelessWidget {
  final LecturerEvaluation evaluation;
  final Function(LecturerEvaluation) onEvaluationChanged;

  const CourseConductSection({
    super.key,
    required this.evaluation,
    required this.onEvaluationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RatingQuestion(
          question: 'Did the lecturer encourage student participation (questions, comments, etc.)?',
          value: evaluation.participation,
          onChanged: (value) {
            final updatedEvaluation = _updateEvaluation(participation: value);
            onEvaluationChanged(updatedEvaluation);
          },
          descriptions: [
            'Actively encouraged participation',
            'Allowed participation, though not always encouraged',
            'Gave some opportunities for participation',
            'Rarely encouraged participation',
            'Did not encourage participation at all',
          ],
        ),
        const SizedBox(height: 24),
        RatingQuestion(
          question: 'How would you rate the lecturer\'s attitude towards students (support, motivation)?',
          value: evaluation.attitude,
          onChanged: (value) {
            final updatedEvaluation = _updateEvaluation(attitude: value);
            onEvaluationChanged(updatedEvaluation);
          },
          descriptions: [
            'Always supportive and motivating',
            'Generally supportive, motivated most of the time',
            'Neutral attitude, sometimes supportive',
            'Occasionally unmotivated or discouraging',
            'Did not motivate or engage students',
          ],
        ),
        const SizedBox(height: 24),
        RatingQuestion(
          question: 'How would you rate the lecturer\'s availability for consultations outside class?',
          value: evaluation.availability,
          onChanged: (value) {
            final updatedEvaluation = _updateEvaluation(availability: value);
            onEvaluationChanged(updatedEvaluation);
          },
          descriptions: [
            'Always available for consultations',
            'Available most of the time',
            'Sometimes available, but not always',
            'Rarely available for consultations',
            'Never available for consultations',
          ],
        ),
      ],
    );
  }
  
  // Continuing from previous code...

  LecturerEvaluation _updateEvaluation({
    int? participation,
    int? attitude,
    int? availability,
  }) {
    return LecturerEvaluation(
      lecturerName: evaluation.lecturerName,
      lecturerNumber: evaluation.lecturerNumber,
      unitCode: evaluation.unitCode,
      unitName: evaluation.unitName,
      studentReg: evaluation.studentReg,
      courseCode: evaluation.courseCode,
      outlineGiven: evaluation.outlineGiven,
      objectivesClear: evaluation.objectivesClear,
      objectivesMet: evaluation.objectivesMet,
      attendance: evaluation.attendance,
      explanation: evaluation.explanation,
      resources: evaluation.resources,
      communication: evaluation.communication,
      participation: participation ?? evaluation.participation,
      attitude: attitude ?? evaluation.attitude,
      availability: availability ?? evaluation.availability,
      timeliness: evaluation.timeliness,
      relevance: evaluation.relevance,
      markingTimeliness: evaluation.markingTimeliness,
      overallSatisfaction: evaluation.overallSatisfaction,
      comments: evaluation.comments,
    );
  }
}

class EvaluationOfLearningSection extends StatelessWidget {
  final LecturerEvaluation evaluation;
  final Function(LecturerEvaluation) onEvaluationChanged;

  const EvaluationOfLearningSection({
    super.key,
    required this.evaluation,
    required this.onEvaluationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RatingQuestion(
          question: 'How timely were the CATS (Continuous Assessment Tests) and assignments?',
          value: evaluation.timeliness,
          onChanged: (value) {
            final updatedEvaluation = _updateEvaluation(timeliness: value);
            onEvaluationChanged(updatedEvaluation);
          },
          descriptions: [
            'Always given and returned on time',
            'Mostly on time, with minor delays',
            'Some delays in submission or return',
            'Often late with assignments',
            'Frequently late or unclear deadlines',
          ],
        ),
        const SizedBox(height: 24),
        RatingQuestion(
          question: 'How relevant were the CATS and assignments to the course content?',
          value: evaluation.relevance,
          onChanged: (value) {
            final updatedEvaluation = _updateEvaluation(relevance: value);
            onEvaluationChanged(updatedEvaluation);
          },
          descriptions: [
            'All assessments were highly relevant to the course',
            'Most assessments were relevant, some were less aligned',
            'Some assignments seemed irrelevant to the course content',
            'Many assignments were not relevant to the course',
            'Assessments were unrelated to the course material',
          ],
        ),
        const SizedBox(height: 24),
        RatingQuestion(
          question: 'How timely were the marking and return of assignments?',
          value: evaluation.markingTimeliness,
          onChanged: (value) {
            final updatedEvaluation = _updateEvaluation(markingTimeliness: value);
            onEvaluationChanged(updatedEvaluation);
          },
          descriptions: [
            'Returned marked assignments promptly',
            'Returned most assignments on time with minor delays',
            'Some assignments returned late',
            'Frequently delayed in returning work',
            'Did not return assignments on time, long delays',
          ],
        ),
      ],
    );
  }
  
  LecturerEvaluation _updateEvaluation({
    int? timeliness,
    int? relevance,
    int? markingTimeliness,
  }) {
    return LecturerEvaluation(
      lecturerName: evaluation.lecturerName,
      lecturerNumber: evaluation.lecturerNumber,
      unitCode: evaluation.unitCode,
      unitName: evaluation.unitName,
      studentReg: evaluation.studentReg,
      courseCode: evaluation.courseCode,
      outlineGiven: evaluation.outlineGiven,
      objectivesClear: evaluation.objectivesClear,
      objectivesMet: evaluation.objectivesMet,
      attendance: evaluation.attendance,
      explanation: evaluation.explanation,
      resources: evaluation.resources,
      communication: evaluation.communication,
      participation: evaluation.participation,
      attitude: evaluation.attitude,
      availability: evaluation.availability,
      timeliness: timeliness ?? evaluation.timeliness,
      relevance: relevance ?? evaluation.relevance,
      markingTimeliness: markingTimeliness ?? evaluation.markingTimeliness,
      overallSatisfaction: evaluation.overallSatisfaction,
      comments: evaluation.comments,
    );
  }
}

class OverallEvaluationSection extends StatelessWidget {
  final LecturerEvaluation evaluation;
  final Function(LecturerEvaluation) onEvaluationChanged;

  const OverallEvaluationSection({
    super.key,
    required this.evaluation,
    required this.onEvaluationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RatingQuestion(
          question: 'How satisfied are you with the lecturer\'s overall performance?',
          value: evaluation.overallSatisfaction,
          onChanged: (value) {
            final updatedEvaluation = LecturerEvaluation(
              lecturerName: evaluation.lecturerName,
              lecturerNumber: evaluation.lecturerNumber,
              unitCode: evaluation.unitCode,
              unitName: evaluation.unitName,
              studentReg: evaluation.studentReg,
              courseCode: evaluation.courseCode,
              outlineGiven: evaluation.outlineGiven,
              objectivesClear: evaluation.objectivesClear,
              objectivesMet: evaluation.objectivesMet,
              attendance: evaluation.attendance,
              explanation: evaluation.explanation,
              resources: evaluation.resources,
              communication: evaluation.communication,
              participation: evaluation.participation,
              attitude: evaluation.attitude,
              availability: evaluation.availability,
              timeliness: evaluation.timeliness,
              relevance: evaluation.relevance,
              markingTimeliness: evaluation.markingTimeliness,
              overallSatisfaction: value,
              comments: evaluation.comments,
            );
            onEvaluationChanged(updatedEvaluation);
          },
          descriptions: [
            'Exceeded expectations in all areas',
            'Met expectations in most areas',
            'Met some expectations, but there were areas for improvement',
            'Did not meet several key expectations',
            'Did not meet expectations in key areas',
          ],
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Additional comments (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            initialValue: evaluation.comments,
            onChanged: (value) {
              final updatedEvaluation = LecturerEvaluation(
                lecturerName: evaluation.lecturerName,
                lecturerNumber: evaluation.lecturerNumber,
                unitCode: evaluation.unitCode,
                unitName: evaluation.unitName,
                studentReg: evaluation.studentReg,
                courseCode: evaluation.courseCode,
                outlineGiven: evaluation.outlineGiven,
                objectivesClear: evaluation.objectivesClear,
                objectivesMet: evaluation.objectivesMet,
                attendance: evaluation.attendance,
                explanation: evaluation.explanation,
                resources: evaluation.resources,
                communication: evaluation.communication,
                participation: evaluation.participation,
                attitude: evaluation.attitude,
                availability: evaluation.availability,
                timeliness: evaluation.timeliness,
                relevance: evaluation.relevance,
                markingTimeliness: evaluation.markingTimeliness,
                overallSatisfaction: evaluation.overallSatisfaction,
                comments: value,
              );
              onEvaluationChanged(updatedEvaluation);
            },
          ),
        ),
      ],
    );
  }
}

// Common widgets used across sections
class YesNoQuestion extends StatelessWidget {
  final String question;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  const YesNoQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onChanged(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: value == true ? Colors.green[100] : Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('✅'),
                      SizedBox(width: 8),
                      Text('Yes'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onChanged(false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: value == false ? Colors.red[100] : Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('❌'),
                      SizedBox(width: 8),
                      Text('No'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (value == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Please select an option', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class RatingQuestion extends StatelessWidget {
  final String question;
  final int? value;
  final ValueChanged<int?> onChanged;
  final List<String> descriptions;

  const RatingQuestion({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    required this.descriptions,
  });

  @override
  Widget build(BuildContext context) {
    final emojis = ['🌟', '🙂', '😐', '🙁', '😞'];
    final ratings = ['Very Good', 'Good', 'Okay', 'Needs Improvement', 'Poor'];
    final scores = [5, 4, 3, 2, 1];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Column(
            children: List.generate(5, (index) {
              return RadioListTile<int>(
                title: Row(
                  children: [
                    Text(emojis[index], style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ratings[index], style: const TextStyle(fontSize: 16)),
                          Text(
                            descriptions[index],
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                value: scores[index],
                groupValue: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF008000),
              );
            }),
          ),
          if (value == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Please select an option', style: TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}