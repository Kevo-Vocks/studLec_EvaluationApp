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

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController regNoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false; // For password visibility toggle
  bool isStudent = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    regNoController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String generateEmail(String input) {
    input = input.trim().toLowerCase();
    if (isStudent) {
      final encodedRegNo = input.replaceAll('/', '_SLASH_');
      return '$encodedRegNo@students.must.ac.ke';
    }
    return '$input@must.ac.ke';
  }

  Future<UserModel?> _fetchUserData(String docId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection(isStudent ? 'students' : 'lecturers')
        .doc(docId)
        .get();

    if (!userDoc.exists) {
      throw Exception('${isStudent ? "Student" : "Lecturer"} data not found in Firestore.');
    }

    return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final input = regNoController.text.trim();
      final email = generateEmail(input);
      final password = passwordController.text;

      final docId = isStudent ? input.replaceAll('/', '_SLASH_').toLowerCase() : input.toUpperCase();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = await _fetchUserData(docId);

      setState(() => _isLoading = false);

      // Show a snackbar instead of a dialog for success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful! Redirecting...'),
          backgroundColor: Color(0xFF008000),
          duration: Duration(seconds: 2),
        ),
      );

      // Delay slightly to show the snackbar before redirecting
      await Future.delayed(const Duration(seconds: 2));

      if (isStudent) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.studentDashboard,
          arguments: userModel,
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.lecturerDashboard,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'user-disabled':
          errorMessage = 'This user account has been disabled.';
          break;
        default:
          errorMessage = 'Login failed. Please try again.';
      }
      _showErrorDialog(errorMessage);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _resetPassword() async {
    final input = regNoController.text.trim();
    if (input.isEmpty) {
      _showErrorDialog('Please enter your ${isStudent ? "Registration Number" : "Lecturer ID"} to reset your password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = generateEmail(input);
      await _auth.sendPasswordResetEmail(email: email);

      setState(() => _isLoading = false);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Password Reset"),
          content: Text('A password reset link has been sent to $email.'),
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
      _showErrorDialog('Failed to send password reset email: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                        value == null || value.isEmpty ? "Enter ${isStudent ? 'RegNo' : 'Lecturer ID'}" : null,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF008000)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF008000),
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
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
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Login", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _isLoading ? null : _resetPassword,
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
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => isStudent = true),
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
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => isStudent = false),
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
      ),
    );
  }
}