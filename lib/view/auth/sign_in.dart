// -***************************************** TESTED ***********************************-;

import '../../view/auth/reset_password.dart';
import '../../view/screens/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'sign_up.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  SignInState createState() => SignInState();
}

class SignInState extends State<SignIn> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final GlobalKey<FormState> formKey =
      GlobalKey<FormState>(); // FormKey to manage form validation

  bool isLoading = false;
  String errorMessage = '';
  bool obscureText = true;

  // Email Validator function
  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }
    // Regular expression to check for valid email format
    final emailRegex = RegExp(r"^[a-zA-Z0-9+_.-]+@[a-zA-Z0-9.-]+$");
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  // Password Validator function
  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  // Handle specific FirebaseAuth exceptions and return corresponding error message
  String _handleAuthError(String errorCode, String? errorMessage) {
    switch (errorCode) {
      case "auth/user-not-found":
        return 'Account does not exist. Please sign up first.';
      case "auth/invalid-password":
        return 'Wrong password! Try again or reset it.';
      case "auth/wrong-password":
        return 'Wrong password! Try again or reset it.';
      default:
        return errorMessage ?? 'An unknown error occurred';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const Text(
                    "Let's start!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Sign in to your account and start transforming your finances",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: email,
                          decoration: InputDecoration(
                            labelText: 'Enter your Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: emailValidator, // Apply email validation
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: password,
                          obscureText: obscureText,
                          decoration: InputDecoration(
                            labelText: 'Enter your Password',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    obscureText = !obscureText;
                                  });
                                },
                                child: obscureText
                                    ? const Icon(Icons.visibility)
                                    : const Icon(Icons.visibility_off)),
                          ),
                          validator: passwordValidator,
                        ),
                        const SizedBox(height: 20),
                        isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: () async {
                                  if (formKey.currentState?.validate() ??
                                      false) {
                                    // Show loading indicator
                                    setState(() {
                                      isLoading = true;
                                      errorMessage = '';
                                    });

                                    final credentials = {
                                      "email": email.text,
                                      "password": password.text,
                                    };

                                    try {
                                      await FirebaseAuth.instance
                                          .signInWithEmailAndPassword(
                                        email: credentials["email"]!,
                                        password: credentials["password"]!,
                                      );

                                      // On success, navigate to Home screen
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const Home(),
                                        ),
                                      );
                                    } on FirebaseAuthException catch (e) {
                                      setState(() {
                                        errorMessage =
                                            _handleAuthError(e.code, e.message);
                                        isLoading = false;
                                      });
                                    } catch (e) {
                                      setState(() {
                                        errorMessage =
                                            'An unexpected error occurred: ${e.toString()}';
                                        isLoading = false;
                                      });
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Log In'),
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (errorMessage.isNotEmpty)
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        style: ButtonStyle(
                            foregroundColor:
                                WidgetStateProperty.all<Color>(Colors.blue)),
                        onPressed: () {
                          // Push to sign up page
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const SignUp()));
                        },
                        child: const Text('Sign Up'),
                      ),
                      TextButton(
                        style: ButtonStyle(
                            foregroundColor:
                                WidgetStateProperty.all<Color>(Colors.blue)),
                        onPressed: () {
                          // Push to reset password page
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ResetPassword()));
                        },
                        child: const Text('Forgot password?'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -***************************************** TESTED ***********************************-;
