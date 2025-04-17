import 'package:cloud_firestore/cloud_firestore.dart';

class Evaluation {
  final String id;
  final String studentRegNo;
  final String unitId;
  final String lecturer;
  final double rating;
  final String feedback;
  final DateTime timestamp;
  final String status;

  Evaluation({
    required this.id,
    required this.studentRegNo,
    required this.unitId,
    required this.lecturer,
    required this.rating,
    required this.feedback,
    required this.timestamp,
    required this.status,
  });

  factory Evaluation.fromMap(String id, Map<String, dynamic> map) {
    return Evaluation(
      id: id,
      studentRegNo: map['student'] ?? '',
      unitId: map['unit'] ?? '',
      lecturer: map['lecturer'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      feedback: map['feedback'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'submitted',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student': studentRegNo,
      'unit': unitId,
      'lecturer': lecturer,
      'rating': rating,
      'feedback': feedback,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
    };
  }
}