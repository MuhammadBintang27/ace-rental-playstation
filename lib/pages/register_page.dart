import 'package:ace_rental/components/my_button.dart';
import 'package:ace_rental/components/my_textfield.dart';
import 'package:ace_rental/service/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  final void Function()? onTap;
  const RegisterPage({Key? key, this.onTap}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String userRole = "kasir"; // Default user role

  String? emailError;
  String? passwordError;
  String? confirmPasswordError;
  bool isLoading = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool validateEmail(String email) {
    if (email.isEmpty) {
      setState(() => emailError = "Email tidak boleh kosong");
      return false;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => emailError = "Format email tidak valid");
      return false;
    }
    setState(() => emailError = null);
    return true;
  }

  bool validatePassword(String password) {
    if (password.isEmpty) {
      setState(() => passwordError = "Kata sandi tidak boleh kosong");
      return false;
    } else if (password.length < 6) {
      setState(() => passwordError = "Kata sandi harus minimal 6 karakter");
      return false;
    }
    setState(() => passwordError = null);
    return true;
  }

  bool validateConfirmPassword(String confirmPassword) {
    if (confirmPassword != passwordController.text) {
      setState(() => confirmPasswordError = "Kata sandi tidak cocok");
      return false;
    }
    setState(() => confirmPasswordError = null);
    return true;
  }

  Future<void> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (!validateEmail(email) ||
        !validatePassword(password) ||
        !validateConfirmPassword(confirmPassword)) {
      return;
    }

    setState(() => isLoading = true);

    try {
      await _authService.signUpWithEmailAndPassword(email, password, userRole);
      // Navigasi ke halaman utama atau tampilkan pesan sukses
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          setState(() => emailError = "Email sudah digunakan");
          break;
        case 'invalid-email':
          setState(() => emailError = "Format email tidak valid");
          break;
        case 'weak-password':
          setState(() => passwordError = "Kata sandi terlalu lemah");
          break;
        default:
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Error"),
              content: Text(e.message ?? "Terjadi kesalahan"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
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
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.casino, size: 100),
              const SizedBox(height: 25),

              // Email textfield
              MyTextfield(
                controller: emailController,
                hintText: "Email",
                obscureText: false,
              ),
              if (emailError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                  child: Text(emailError!,
                      style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 10),

              // Password textfield
              MyTextfield(
                controller: passwordController,
                hintText: "Password",
                obscureText: true,
              ),
              if (passwordError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                  child: Text(passwordError!,
                      style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 10),

              // Confirm password textfield
              MyTextfield(
                controller: confirmPasswordController,
                hintText: "Confirm Password",
                obscureText: true,
              ),
              if (confirmPasswordError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
                  child: Text(confirmPasswordError!,
                      style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 25),

              // Sign up button
              MyButton(
                text: isLoading ? "Loading..." : "Sign Up",
                onTap: isLoading ? null : register,
              ),

              const SizedBox(height: 25),

              // Already have an account? Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: const Text(
                      "Login now",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}