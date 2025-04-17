import 'package:cloud_firestore/cloud_firestore.dart';

class Unit {
  final String id;
  final String unitCode;
  final String unitName;
  final String courseCode;
  final List<DocumentReference> lecturers;
  final String semester;
  final String year;
  final String status;
  final List<String> evaluations;

  Unit({
    required this.id,
    required this.unitCode,
    required this.unitName,
    required this.courseCode,
    required this.lecturers,
    required this.semester,
    required this.year,
    required this.status,
    required this.evaluations,
  });

  factory Unit.fromMap(String id, Map<String, dynamic> map) {
    return Unit(
      id: id,
      unitCode: map['unitCode'] ?? '',
      unitName: map['unitName'] ?? '',
      courseCode: map['courseCode'] ?? '',
      lecturers: List<DocumentReference>.from(map['lecturers'] ?? []),
      semester: map['semester']?.toString() ?? '',
      year: map['year']?.toString() ?? '',
      status: map['status'] ?? 'active',
      evaluations: List<String>.from(map['evaluations'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'unitCode': unitCode,
      'unitName': unitName,
      'courseCode': courseCode,
      'lecturers': lecturers,
      'semester': semester,
      'year': year,
      'status': status,
      'evaluations': evaluations,
    };
  }
}
