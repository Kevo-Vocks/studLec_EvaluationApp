import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evaluation_app/model/user_model.dart';
import 'package:evaluation_app/routes/app_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController regNoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool isStudent = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  String generateEmail(String input) {
    if (isStudent) {
      final encodedRegNo = input.replaceAll('/', '_SLASH_').toLowerCase();
      return '$encodedRegNo@students.must.ac.ke';
    } else {
      final lecturerId = input.toLowerCase(); // Example: L001 → l001@must.ac.ke
      return '$lecturerId@must.ac.ke';
    }
  }

  void _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        String input = regNoController.text.trim();
        String email = generateEmail(input);
        String password = passwordController.text;

        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        final docId = isStudent
            ? input.replaceAll('/', '_SLASH_').toLowerCase()
            : input.toUpperCase(); // Preserve casing for lecturer IDs like L001

        final userDoc = await FirebaseFirestore.instance
            .collection(isStudent ? 'students' : 'lecturers')
            .doc(docId)
            .get();

        if (!userDoc.exists) {
          throw Exception('${isStudent ? "Student" : "Lecturer"} data not found in Firestore.');
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final userModel = UserModel.fromMap(userData);

        setState(() => _isLoading = false);

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Login Successful"),
            content: const Text("Welcome! Redirecting to your dashboard."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  if (isStudent) {
                    // Redirect students to HomeScreen with userModel
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.home,
                      arguments: userModel,
                    );
                  } else {
                    // Redirect lecturers to LecturerDashboard
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.lecturerDashboard,
                    );
                  }
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        String errorMessage = 'Login failed. Please try again.';

        if (e.code == 'user-not-found') {
          errorMessage = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          errorMessage = 'Wrong password provided.';
        }

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Login Failed"),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } catch (e) {
        setState(() => _isLoading = false);
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Error"),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Image.asset('assets/images/meru-logo.png', height: 120),
                const SizedBox(height: 40),
                Text(
                  isStudent ? "Student Login" : "Lecturer Login",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF008000),
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: regNoController,
                  decoration: InputDecoration(
                    labelText: isStudent ? "Registration Number" : "Lecturer ID",
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF008000)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF008000)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter RegNo" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF008000)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF008000)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Enter password" : null,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008000),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isLoading ? null : () => _login(context),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Login", style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: Color(0xFF008000), fontSize: 16),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Don't have an account? Contact admin.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => isStudent = true),
                      child: Text(
                        "Student",
                        style: TextStyle(
                          color: isStudent ? const Color(0xFF008000) : Colors.grey,
                          fontWeight:
                              isStudent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const Text("|", style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () => setState(() => isStudent = false),
                      child: Text(
                        "Lecturer",
                        style: TextStyle(
                          color: !isStudent ? const Color(0xFF008000) : Colors.grey,
                          fontWeight:
                              !isStudent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}