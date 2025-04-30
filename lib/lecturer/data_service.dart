import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataService {
  Future<void> fetchLecturerData(
      void Function(Map<String, dynamic>?) callback) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('No user is logged in');
      return;
    }
    final staffNo = user.email!.split('@')[0].toUpperCase();
    print('Fetching lecturer data for staffNo: $staffNo');
    final doc = await FirebaseFirestore.instance
        .collection('lecturers')
        .doc(staffNo)
        .get();
    if (doc.exists) {
      callback(doc.data());
    } else {
      print('Lecturer document not found for $staffNo');
      callback(null);
    }
  }

  Future<void> fetchAssignedUnitsAndSemesters(
      void Function(Map<String, Map<String, dynamic>>) callback) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user is logged in');
        return;
      }
      final staffNo = user.email!.split('@')[0].toUpperCase();
      print('Fetching units for lecturer: $staffNo');

      final List<Map<String, dynamic>> unitDocs = [];

      final unitsSnapshot = await FirebaseFirestore.instance
          .collection('units')
          .where('lecturers', arrayContains: staffNo)
          .get();

      print('Units found: ${unitsSnapshot.docs.length}');
      for (var doc in unitsSnapshot.docs) {
        print('Unit ${doc.id}: ${doc.data()}');
        unitDocs.add({
          'id': doc.id,
          'data': doc.data(),
        });
      }

      if (unitDocs.isEmpty) {
        print('No units found with uppercase staffNo, trying lowercase...');
        final lowercaseStaffNo = user.email!.split('@')[0].toLowerCase();
        final lowercaseUnitsSnapshot = await FirebaseFirestore.instance
            .collection('units')
            .where('lecturers', arrayContains: lowercaseStaffNo)
            .get();
        print('Units found with lowercase: ${lowercaseUnitsSnapshot.docs.length}');
        for (var doc in lowercaseUnitsSnapshot.docs) {
          print('Unit ${doc.id}: ${doc.data()}');
          unitDocs.add({
            'id': doc.id,
            'data': doc.data(),
          });
        }
      }

      if (unitDocs.isEmpty) {
        print(
            'No units found in units collection, falling back to lecturers collection');
        final lecturerDoc = await FirebaseFirestore.instance
            .collection('lecturers')
            .doc(staffNo)
            .get();
        if (lecturerDoc.exists) {
          final assignedUnitCodes =
              List<String>.from(lecturerDoc.get('units') ?? []);
          print('Units from lecturers collection: $assignedUnitCodes');
          if (assignedUnitCodes.isNotEmpty) {
            for (var unitCode in assignedUnitCodes) {
              final unitDoc = await FirebaseFirestore.instance
                  .collection('units')
                  .doc(unitCode)
                  .get();
              if (unitDoc.exists) {
                unitDocs.add({
                  'id': unitDoc.id,
                  'data': unitDoc.data(),
                });
              }
            }
          }
        }
      }

      final unitToDetailsMap = <String, Map<String, dynamic>>{};
      for (var unit in unitDocs) {
        final data = unit['data'] as Map<String, dynamic>;
        final unitCode = data['unitCode'] as String?;
        final semester = data['semester'] as String?;
        final year = data['year'] as String?;
        final unitName = data['unitName'] as String?;
        final courseCode = data['courseCode'] as String?;
        if (unitCode != null &&
            semester != null &&
            year != null &&
            unitName != null &&
            courseCode != null) {
          final semesterYear = '$semester, $year';
          unitToDetailsMap[unitCode] = {
            'unitName': unitName,
            'semesterYear': semesterYear,
            'courseCode': courseCode,
          };
        } else {
          print(
              'Skipping unit ${unit['id']} due to missing fields: unitCode=$unitCode, semester=$semester, year=$year, unitName=$unitName, courseCode=$courseCode');
        }
      }

      callback(unitToDetailsMap);

      if (unitToDetailsMap.isEmpty) {
        print('No units assigned after processing');
      } else {
        print('Assigned units: $unitToDetailsMap');
      }
    } catch (e) {
      print('Error fetching assigned units: $e');
      callback({});
    }
  }
}