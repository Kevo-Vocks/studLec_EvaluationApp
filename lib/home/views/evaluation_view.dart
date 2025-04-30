// lib/views/evaluation_screen.dart
import 'package:evaluation_app/home/widgets/evaluation/evaluation_sections.dart';
import 'package:evaluation_app/model/lecturer_Evaluation_model.dart';
import 'package:flutter/material.dart';
import '../controllers/evaluation_controller.dart';

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
  final EvaluationController _controller = EvaluationController();
  
  // Define the sections statically
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
      // Fetch lecturer data
      final lecturerData = await _controller.fetchLecturerData(
        widget.unit['lecturers'] as List<dynamic>?
      );
      
      // Fetch course code
      final courseCode = await _controller.fetchStudentCourseCode(widget.studentReg);
      
      // Update evaluation object
      if (mounted) {
        setState(() {
          _evaluation = LecturerEvaluation(
            lecturerName: lecturerData['name'] ?? '',
            lecturerNumber: lecturerData['number'] ?? '',
            unitCode: widget.unit['unitCode'] ?? '',
            unitName: widget.unit['unitName'] ?? '',
            studentReg: widget.studentReg,
            courseCode: courseCode,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching evaluation data: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSubmitting = true);
      
      final success = await _controller.submitEvaluation(_evaluation);
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        
        if (success) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Evaluation Submitted', style: TextStyle(color: Color(0xFF008000))),
              content: const Text('Thank you for your feedback!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // pop the evaluation screen
                  },
                  child: const Text('OK', style: TextStyle(color: Color(0xFF008000))),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to submit evaluation. Please try again.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lecturer Evaluation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        backgroundColor: const Color(0xFF008000),
      ),
      body: SafeArea(
        child: FutureBuilder(
          future: _fetchDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
        
            return Column(
              children: [
                LinearProgressIndicator(
                  value: (currentSection + 1) / _sections.length,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF008000)),
                  minHeight: 5,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildIntroductionPanel(),
                          const SizedBox(height: 16),
                          EvaluationSections(
                            sectionIndex: currentSection,
                            evaluation: _evaluation,
                            onEvaluationChanged: (updatedEvaluation) {
                              setState(() {
                                _evaluation = updatedEvaluation;
                              });
                            },
                            section: _sections[currentSection],
                          ),
                          _buildNavigationButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildIntroductionPanel() {
    return Container(
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
    );
  }
  
  
  Widget _buildNavigationButtons() {
    return Padding(
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
                      if (_controller.validateSection(currentSection, _evaluation)) {
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
              backgroundColor: const Color(0xFF008000),
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(currentSection == _sections.length - 1 ? 'Submit Evaluation' : 'Next'),
          ),
        ],
      ),
    );
  }
}