import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/home.dart';
// -***************************************** TESTED ***********************************-;

class EmailVerification extends StatefulWidget {
  const EmailVerification({super.key});

  @override
  EmailVerificationState createState() => EmailVerificationState();
}

class EmailVerificationState extends State<EmailVerification> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isVerified = false;
  bool _emailSent = false; // Track if the email has been sent in the session

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    User? user = _auth.currentUser;
    await user?.reload(); // Reload user to get the latest verification status
    setState(() {
      _isVerified = user?.emailVerified ?? false;
    });

    if (!_isVerified && !_emailSent) {
      await _sendVerificationEmail(user);
      setState(() {
        _emailSent = true; // Set the flag to true once email is sent
      });
    }

    if (_isVerified) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Home()),
      );
    }
  }

  Future<void> _sendVerificationEmail(User? user) async {
    try {
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send verification email: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: RefreshIndicator(
        onRefresh: _checkVerificationStatus,
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.email,
                    size: 100,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Please verify your email address.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'We have sent a verification email to your registered email address. Please check your inbox and click on the verification link.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _checkVerificationStatus,
                    child: const Text('Check Verification Status'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final user = _auth.currentUser;
                      await _sendVerificationEmail(user);
                      setState(() {
                        _emailSent = true; // Update flag if resend is manual
                      });
                    },
                    child: const Text('Resend Verification Email'),
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
