import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evaluation_app/model/lecturerEvaluation_model.dart';
import 'package:flutter/material.dart';

class EvaluationScreen extends StatefulWidget {
  final Map<String, dynamic> unit;
  final String studentReg;

  const EvaluationScreen({super.key, required this.unit, required this.studentReg});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
 int currentSection = 0;
  final _formKey = GlobalKey<FormState>();
  late LecturerEvaluation _evaluation;
  bool _isSubmitting = false;
  late Future<void> _fetchDataFuture;
  bool _hasEvaluated = false; // New flag to track if evaluation exists

  final List<Map<String, dynamic>> _sections = [
    {
      'title': 'Background Information',
      'description': 'Details about the course and lecturer',
    },
    {
      'title': 'Course Requirements',
      'description': 'Evaluate the course structure and requirements',
    },
    {
      'title': 'Teaching Effectiveness',
      'description': 'Rate the lecturer\'s teaching quality',
    },
    {
      'title': 'Course Conduct',
      'description': 'Evaluate classroom interaction and support',
    },
    {
      'title': 'Evaluation of Learning',
      'description': 'Assess assignments and feedback',
    },
    {
      'title': 'Overall Evaluation',
      'description': 'Provide your final assessment',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize evaluation with default values
    _evaluation = LecturerEvaluation(
      lecturerName: '',
      lecturerNumber: '',
      unitCode: widget.unit['unitCode'] ?? '',
      unitName: widget.unit['unitName'] ?? '',
      studentReg: widget.studentReg,
    );
    // Cache the future in initState
    _fetchDataFuture = _fetchEvaluationData();
  }

  Future<void> _fetchEvaluationData() async {
  try {
    // Check if evaluation already exists
    String safeReg = widget.studentReg.replaceAll('/', '_slash_').toLowerCase();
    String evaluationId = '${safeReg}_${_evaluation.unitCode}';
    final existingEvaluation = await FirebaseFirestore.instance
        .collection('evaluations')
        .doc(evaluationId)
        .get();

    if (existingEvaluation.exists) {
      setState(() {
        _hasEvaluated = true;
      });
      return;
    }

    // Fetch lecturer data
    final lecturerIds = (widget.unit['lecturers'] as List<dynamic>?) ?? [];
    String lecturerName = 'Unknown';
    String lecturerNumber = 'Unknown';

    if (lecturerIds.isNotEmpty) {
      final lecturerDoc = await FirebaseFirestore.instance
          .collection('lecturers')
          .doc(lecturerIds.first.toString())
          .get();
      final lecturerData = lecturerDoc.data() ?? {};
      lecturerName = '${lecturerData['title'] ?? ''} ${lecturerData['firstName'] ?? ''} ${lecturerData['secondName'] ?? ''}'.trim();
      lecturerNumber = lecturerData['staffNo']?.toString() ?? 'Unknown';
    }

    // Fetch courseCode based on studentReg, using the same safeReg format
    String courseCode = 'Unknown';
    final studentDoc = await FirebaseFirestore.instance
        .collection('students')
        .doc(safeReg) // Use safeReg to match Firestore document ID
        .get();
    if (studentDoc.exists) {
      courseCode = studentDoc.data()?['courseCode'] ?? 'Unknown';
    } else {
      print('Student document not found for reg: $safeReg'); // Debug log
    }

    // Update evaluation object
    setState(() {
      _evaluation = LecturerEvaluation(
        lecturerName: lecturerName,
        lecturerNumber: lecturerNumber,
        unitCode: widget.unit['unitCode'] ?? '',
        unitName: widget.unit['unitName'] ?? '',
        studentReg: widget.studentReg,
        courseCode: courseCode, // Set courseCode
      );
    });
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching evaluation data: $e')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Evaluation'),
        backgroundColor: Color(0xFF008000),
      ),
      body: FutureBuilder(
        future: _fetchDataFuture, // Use cached future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // If evaluation already exists, show message
          if (_hasEvaluated) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info, size: 48, color: Color(0xFF008000)),
                    const SizedBox(height: 16),
                    const Text(
                      'You have already submitted an evaluation for this unit.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF008000),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              LinearProgressIndicator(
                value: (currentSection + 1) / _sections.length,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008000)),
                minHeight: 5,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey[300],
                          child: const Text(
                            'PURPOSE AND CONFIDENTIALITY\n'
                            'The purpose of this evaluation is to assist your lecturer perform better by evaluating his/her teaching in this unit. '
                            'It is important that you answer these questions as honestly as possible. Your response to the items in this form is strictly confidential. '
                            'The information you provide will help the university to improve the quality of the curriculum and teaching process.',
                            style: TextStyle(fontSize: 16),
                            textAlign: TextAlign.justify,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSection(currentSection),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitForm() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();
    setState(() => _isSubmitting = true);

    try {
      // Create a safe document ID
      String safeReg = widget.studentReg.replaceAll('/', '_slash_').toLowerCase();
      String evaluationId = '${safeReg}_${_evaluation.unitCode}';

      // Save evaluation with custom docId
      await FirebaseFirestore.instance
          .collection('evaluations')
          .doc(evaluationId) // Use custom ID
          .set(_evaluation.toJson()); // Use set() instead of add()

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Evaluation Submitted', style: TextStyle(color: Color(0xFF008000))),
            content: const Text('Thank you for your feedback!'),
            actions: [
              TextButton(
                onPressed: (){
Navigator.pop(context);//close dialog
Navigator.pop(context);//pop the evaluation scree
                } ,
                child: const Text('OK', style: TextStyle(color: Color(0xFF008000))),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit evaluation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

  bool _validateSection(int sectionIndex) {
    if (sectionIndex == 0) {
      return true;
    } else if (sectionIndex == 1) {
      return _evaluation.outlineGiven != null &&
          _evaluation.objectivesClear != null &&
          _evaluation.objectivesMet != null;
    } else if (sectionIndex == 2) {
      return _evaluation.attendance != null &&
          _evaluation.explanation != null &&
          _evaluation.resources != null &&
          _evaluation.communication != null;
    } else if (sectionIndex == 3) {
      return _evaluation.participation != null &&
          _evaluation.attitude != null &&
          _evaluation.availability != null;
    } else if (sectionIndex == 4) {
      return _evaluation.timeliness != null &&
          _evaluation.relevance != null &&
          _evaluation.markingTimeliness != null;
    } else if (sectionIndex == 5) {
      return _evaluation.overallSatisfaction != null;
    }
    return false;
  }

  Widget _buildSection(int index) {
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
              _sections[index]['title'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF008000)),
            ),
            const SizedBox(height: 4),
            Text(
              _sections[index]['description'],
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            if (index == 0) ...[
              _buildInfoRow('Lecturer Name', _evaluation.lecturerName),
              const SizedBox(height: 12),
              // _buildInfoRow('Lecturer Number', _evaluation.lecturerNumber),
              const SizedBox(height: 12),
              _buildInfoRow('Unit Code', _evaluation.unitCode),
              const SizedBox(height: 12),
              _buildInfoRow('Unit Name', _evaluation.unitName),
            ] else if (index == 1) ...[
              _buildYesNoQuestion(
                'Was the course outline given within the first two weeks of the semester?',
                _evaluation.outlineGiven,
                (value) => setState(() => _evaluation.outlineGiven = value),
              ),
              const SizedBox(height: 24),
              _buildYesNoQuestion(
                'Did the course outline include clear objectives?',
                _evaluation.objectivesClear,
                (value) => setState(() => _evaluation.objectivesClear = value),
              ),
              const SizedBox(height: 24),
              _buildYesNoQuestion(
                'Were the course objectives met during the semester?',
                _evaluation.objectivesMet,
                (value) => setState(() => _evaluation.objectivesMet = value),
              ),
            ] else if (index == 2) ...[
              _buildRatingQuestion(
                'How would you rate the lecturer\'s attendance and punctuality?',
                _evaluation.attendance,
                (value) => setState(() => _evaluation.attendance = value),
                [
                  'Always on time and attended all classes',
                  'Rarely late, missed only one or two classes',
                  'Sometimes late, missed a few classes',
                  'Frequently late or missed several classes',
                  'Often late or missed many classes',
                ],
              ),
              const SizedBox(height: 24),
              _buildRatingQuestion(
                'How well did the lecturer explain concepts?',
                _evaluation.explanation,
                (value) => setState(() => _evaluation.explanation = value),
                [
                  'Clear and easy to understand, explained in-depth',
                  'Generally clear, with a few moments of confusion',
                  'Sometimes hard to understand or lacked depth',
                  'Often unclear, hard to follow',
                  'Struggled to explain, leaving students confused',
                ],
              ),
              const SizedBox(height: 24),
              _buildRatingQuestion(
                'How would you rate the lecturer\'s use of teaching resources (slides, videos, etc.)?',
                _evaluation.resources,
                (value) => setState(() => _evaluation.resources = value),
                [
                  'Effective use of a variety of teaching materials',
                  'Used good materials, but could have included more variety',
                  'Limited resources used, some helpful',
                  'Rarely used teaching aids or materials',
                  'Did not use any helpful resources',
                ],
              ),
              const SizedBox(height: 24),
              _buildRatingQuestion(
                'How would you rate the lecturer\'s communication skills (clarity, fluency, audibility)?',
                _evaluation.communication,
                (value) => setState(() => _evaluation.communication = value),
                [
                  'Clear, understandable, and engaging',
                  'Mostly clear, with minor issues in understanding',
                  'Sometimes unclear or hard to follow',
                  'Often hard to understand',
                  'Difficult to understand, unclear communication',
                ],
              ),
            ] else if (index == 3) ...[
              _buildRatingQuestion(
                'Did the lecturer encourage student participation (questions, comments, etc.)?',
                _evaluation.participation,
                (value) => setState(() => _evaluation.participation = value),
                [
                  'Actively encouraged participation',
                  'Allowed participation, though not always encouraged',
                  'Gave some opportunities for participation',
                  'Rarely encouraged participation',
                  'Did not encourage participation at all',
                ],
              ),
              const SizedBox(height: 24),
              _buildRatingQuestion(
                'How would you rate the lecturer\'s attitude towards students (support, motivation)?',
                _evaluation.attitude,
                (value) => setState(() => _evaluation.attitude = value),
                [
                  'Always supportive and motivating',
                  'Generally supportive, motivated most of the time',
                  'Neutral attitude, sometimes supportive',
                  'Occasionally unmotivated or discouraging',
                  'Did not motivate or engage students',
                ],
              ),
              const SizedBox(height: 24),
              _buildRatingQuestion(
                'How would you rate the lecturer\'s availability for consultations outside class?',
                _evaluation.availability,
                (value) => setState(() => _evaluation.availability = value),
                [
                  'Always available for consultations',
                  'Available most of the time',
                  'Sometimes available, but not always',
                  'Rarely available for consultations',
                  'Never available for consultations',
                ],
              ),
            ] else if (index == 4) ...[
              _buildRatingQuestion(
                'How timely were the CATS (Continuous Assessment Tests) and assignments?',
                _evaluation.timeliness,
                (value) => setState(() => _evaluation.timeliness = value),
                [
                  'Always given and returned on time',
                  'Mostly on time, with minor delays',
                  'Some delays in submission or return',
                  'Often late with assignments',
                  'Frequently late or unclear deadlines',
                ],
              ),
              const SizedBox(height: 24),
              _buildRatingQuestion(
                'How relevant were the CATS and assignments to the course content?',
                _evaluation.relevance,
                (value) => setState(() => _evaluation.relevance = value),
                [
                  'All assessments were highly relevant to the course',
                  'Most assessments were relevant, some were less aligned',
                  'Some assignments seemed irrelevant to the course content',
                  'Many assignments were not relevant to the course',
                  'Assessments were unrelated to the course material',
                ],
              ),
              const SizedBox(height: 24),
              _buildRatingQuestion(
                'How timely were the marking and return of assignments?',
                _evaluation.markingTimeliness,
                (value) => setState(() => _evaluation.markingTimeliness = value),
                [
                  'Returned marked assignments promptly',
                  'Returned most assignments on time with minor delays',
                  'Some assignments returned late',
                  'Frequently delayed in returning work',
                  'Did not return assignments on time, long delays',
                ],
              ),
            ] else if (index == 5) ...[
              _buildRatingQuestion(
                'How satisfied are you with the lecturer\'s overall performance?',
                _evaluation.overallSatisfaction,
                (value) => setState(() => _evaluation.overallSatisfaction = value),
                [
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
                  onSaved: (value) => _evaluation.comments = value,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (currentSection > 0)
                    ElevatedButton(
                      onPressed: () => setState(() => currentSection--),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[400],
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Previous'),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _formKey.currentState!.save();
                              if (_validateSection(currentSection)) {
                                if (currentSection < _sections.length - 1) {
                                  setState(() => currentSection++);
                                } else {
                                  _submitForm();
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please complete all required fields')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF008000),
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(currentSection == _sections.length - 1 ? 'Submit Evaluation' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildYesNoQuestion(String question, bool? value, ValueChanged<bool?> onChanged) {
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

  Widget _buildRatingQuestion(String question, int? value, ValueChanged<int?> onChanged, List<String> descriptions) {
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
                activeColor: Color(0xFF008000),
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