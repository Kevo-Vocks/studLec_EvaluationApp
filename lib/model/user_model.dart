class UserModel {
  final String firstname;
  final String secondname;
  final String regno;
  final String department;
  final String year;
  final String semester;
  final String program;
  final String courseCode; // Add this line

  UserModel({
    required this.firstname,
    required this.secondname,
    required this.regno,
    required this.department,
    required this.year,
    required this.semester,
    required this.program,
    required this.courseCode, // Add this
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      firstname: map['firstname'] ?? '',
      secondname: map['secondname'] ?? '',
      regno: map['regno'] ?? '',
      department: map['department'] ?? '',
      year: (map['year'] ?? ''),
      semester: (map['semester'] ?? ''),
      program: map['program'] ?? '',
      courseCode: map['courseCode'] ?? '', // Add this
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstname': firstname,
      'secondname': secondname,
      'regno': regno,
      'department': department,
      'year': year,
      'semester': semester,
      'program': program,
      'courseCode': courseCode, // Add this
    };
  }
}
