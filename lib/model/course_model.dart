class Course {
  final String courseCode;
  final String name;
  final String department;
  final String duration;
  final List<String> students; // List of student regnos or references

  Course({
    required this.courseCode,
    required this.name,
    required this.department,
    required this.duration,
    required this.students,
  });

  factory Course.fromMap(String id, Map<String, dynamic> map) {
    return Course(
      courseCode: id,
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      duration: map['duration'] ?? '',
      students: List<String>.from(map['students'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'department': department,
      'duration': duration,
      'students': students,
    };
  }
}