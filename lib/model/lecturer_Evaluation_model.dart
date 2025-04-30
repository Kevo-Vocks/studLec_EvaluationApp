class LecturerEvaluation {
  final String lecturerName;
  final String lecturerNumber;
  final String unitCode;
  final String unitName;
  final String studentReg;
  String? courseCode;

  bool? outlineGiven;
  bool? objectivesClear;
  bool? objectivesMet;

  int? attendance;
  int? explanation;
  int? resources;
  int? communication;

  int? participation;
  int? attitude;
  int? availability;

  int? timeliness;
  int? relevance;
  int? markingTimeliness;

  int? overallSatisfaction;
  String? comments;

  LecturerEvaluation({
    required this.lecturerName,
    required this.lecturerNumber,
    required this.unitCode,
    required this.unitName,
    required this.studentReg,
    this.courseCode,
    this.outlineGiven,
    this.objectivesClear,
    this.objectivesMet,
    this.attendance,
    this.explanation,
    this.resources,
    this.communication,
    this.participation,
    this.attitude,
    this.availability,
    this.timeliness,
    this.relevance,
    this.markingTimeliness,
    this.overallSatisfaction,
    this.comments,
  });

  Map<String, dynamic> toJson() {
    return {
      'lecturer_name': lecturerName,
      'lecturer_number': lecturerNumber,
      'unit_code': unitCode,
      'unit_name': unitName,
      'student_reg': studentReg,
      'courseCode' : courseCode,
      'outline_given': outlineGiven,
      'objectives_clear': objectivesClear,
      'objectives_met': objectivesMet,
      'attendance': attendance,
      'explanation': explanation,
      'resources': resources,
      'communication': communication,
      'participation': participation,
      'attitude': attitude,
      'availability': availability,
      'timeliness': timeliness,
      'relevance': relevance,
      'marking_timeliness': markingTimeliness,
      'overall_satisfaction': overallSatisfaction,
      'comments': comments,
      'submitted_at': DateTime.now().toIso8601String(),
    };
  }
}


