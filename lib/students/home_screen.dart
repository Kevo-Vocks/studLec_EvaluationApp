import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evaluation_app/model/user_model.dart';
import 'package:evaluation_app/routes/app_routes.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  final UserModel loggedInUser;
  const HomeScreen({super.key, required this.loggedInUser});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String department = '';
String program = '';
bool isLoadingCourseDetails = true;


  @override
void initState() {
  super.initState();
  _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();

  fetchCourseDetails(); // Fetch department and program
}

Future<void> fetchCourseDetails() async {
  try {
    final courseDoc = await FirebaseFirestore.instance
        .collection('courses')
        .doc(widget.loggedInUser.courseCode)
        .get();

    final courseData = courseDoc.data();
    if (courseData != null) {
      setState(() {
        department = courseData['department'] ?? '';
        program = courseData['name'] ?? '';
        isLoadingCourseDetails = false;
      });
    }
  } catch (e) {
    setState(() => isLoadingCourseDetails = false);
  }
}


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getUnitIcon(String? iconName) {
    switch (iconName) {
      case 'code':
        return Icons.code;
      case 'data_array':
        return Icons.data_array;
      case 'storage':
        return Icons.storage;
      case 'computer':
        return Icons.computer;
      case 'network':
        return Icons.network_check;
      case 'phone':
        return Icons.phone_android;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Student Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF008000),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF008000).withOpacity(0.15),
                  child: const Icon(Icons.person, size: 32, color: Color(0xFF008000)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome, ${widget.loggedInUser.firstname}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Reg No: ${widget.loggedInUser.regno}'),
                      isLoadingCourseDetails
  ? const CircularProgressIndicator()
  : Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dept: $department'),
        Text('Program: $program'),
      ],
    ),

                      Text('${widget.loggedInUser.year} | ${widget.loggedInUser.semester}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF008000)),
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('units')
                    .where('courseCode', isEqualTo: widget.loggedInUser.courseCode)
                    .where('year', isEqualTo: widget.loggedInUser.year)
                    .where('semester', isEqualTo: widget.loggedInUser.semester)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No units found for your course/year/semester"));
                  }

                  final units = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: units.length,
                    itemBuilder: (context, index) {
                      final data = units[index].data() as Map<String, dynamic>;
                      final iconColor = Color(int.parse(data['iconColor'] ?? '0xFF008000'));

                      return AnimatedOpacity(
                        opacity: _controller.value,
                        duration: const Duration(milliseconds: 500),
                        child: Card(
                          elevation: 8,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.evaluation,
                              arguments: {
                                'unit': data,
                                'studentReg': widget.loggedInUser.regno,
                              },
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: iconColor,
                                        radius: 24,
                                        child: Icon(_getUnitIcon(data['icon']), color: Colors.white),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(data['unitCode'] ?? '', style: TextStyle(color: iconColor, fontWeight: FontWeight.bold)),
                                            Text(data['unitName'] ?? '', style: const TextStyle(fontSize: 14)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  FutureBuilder(
                                    future: Future.wait(
                                      (data['lecturers'] as List<dynamic>).map(
                                        (lecturerId) => FirebaseFirestore.instance
                                            .collection('lecturers')
                                            .doc(lecturerId.toString())
                                            .get(),
                                      ),
                                    ),
                                    builder: (context, lecturerSnapshot) {
                                      if (lecturerSnapshot.connectionState == ConnectionState.waiting) {
                                        return const Text('Lecturers: Loading...');
                                      } else if (lecturerSnapshot.hasError || !lecturerSnapshot.hasData) {
                                        return const Text('Lecturers: Unknown');
                                      } else {
                                        final docs = lecturerSnapshot.data as List<DocumentSnapshot>;
                                        final names = docs.map((doc) {
                                          final lecturer = doc.data() as Map<String, dynamic>? ?? {};
                                          final title = lecturer['title'] ?? '';
                                          final firstName = lecturer['firstName'] ?? '';
                                          final secondName = lecturer['secondName'] ?? '';
                                          return '$title $firstName $secondName'.trim();
                                        }).join(', ');
                                        return Text('Lecturer: $names');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Chip(
                                        label: Text(data['status'] ?? 'Pending', style: const TextStyle(color: Colors.white)),
                                        backgroundColor: Colors.orange,
                                      ),
                                      if (data['deadline'] != 'N/A') Text('Deadline: ${data['deadline']}'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF008000)),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.evaluation,
                                        arguments: {
                                          'unit': data,
                                          'studentReg': widget.loggedInUser.regno,
                                        },
                                      );
                                    },
                                    child: const Text("Evaluate Lecturer", style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF008000),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}