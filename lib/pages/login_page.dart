import 'package:ace_rental/components/my_button.dart';
import 'package:ace_rental/components/my_textField.dart';
import 'package:ace_rental/service/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final void Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  final AuthService _authService = AuthService();

  void _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog("Please fill in all fields.");
      return;
    }

    if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")
        .hasMatch(email)) {
      _showErrorDialog("Invalid email format. Please check your email.");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      UserCredential? userCredential =
          await _authService.signInWithEmailAndPassword(email, password);

      if (userCredential != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        _showErrorDialog("Login failed. Please try again.");
      }
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      _showErrorDialog('An unexpected error occurred: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'invalid-email':
        message = 'Invalid email format. Please check your email address.';
        break;
      case 'user-not-found':
        message = 'No user found with this email. Please register first.';
        break;
      case 'wrong-password':
        message = 'Incorrect password. Please try again.';
        break;
      case 'network-request-failed':
        message = 'Network connection failed. Please check your internet.';
        break;
      default:
        message = 'An error occurred: ${e.message ?? "Please try again later."}';
    }
    _showErrorDialog(message);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
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
              Icon(
                Icons.casino,
                size: 100,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              const SizedBox(height: 25),
              Text(
                'Ace Rental',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 25),
              MyTextfield(
                controller: emailController,
                hintText: "Email",
                obscureText: false,
              ),
              const SizedBox(height: 10),
              MyTextfield(
                controller: passwordController,
                hintText: "Password",
                obscureText: true,
              ),
              const SizedBox(height: 10),
              isLoading
                  ? const CircularProgressIndicator()
                  : MyButton(
                      text: "Sign In",
                      onTap: _login,
                    ),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Not a member?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: widget.onTap,
                    child: Text(
                      "Register now",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
