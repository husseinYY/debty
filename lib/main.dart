import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'view/auth/email_verification.dart';
import 'view/auth/sign_in.dart';
import 'view/screens/home.dart';

import 'firebase_options.dart';
// -***************************************** TESTED ***********************************-;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
// -***************************************** TESTED ***********************************-;

// -***************************************** TESTED ***********************************-;
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debt Management System',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F1013), // Background color
      ),
      home: const MyHomePage(title: 'Debt Management System'),
    );
  }
}
// -***************************************** TESTED ***********************************-;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // Check if the user is signed in
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // If no user is signed in, go to the SignIn page
      return const SignIn();
    }

    // If the user is signed in, check if their email is verified
    if (user.emailVerified) {
      // If the email is verified, go to Home
      return const Home();
    } else {
      // If the email is not verified, go to the confirmation screen
      return const EmailVerification();
    }
  }
}
// -***************************************** TESTED ***********************************-;
