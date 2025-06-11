import 'dart:async';
import 'package:flutter/material.dart';

import 'package:traveltest_app/login.dart'; // Import the next screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Set a timer to navigate to the next screen after a few seconds
    Timer(const Duration(seconds: 6), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LogIn(), // Navigate to the login screen
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.lightBlueAccent, // Light green color on one side
              const Color.fromARGB(
                  255, 166, 217, 169), // Darker green on the other side
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Display your logo or any other branding here
              Center(
                child: Image.asset(
                  'images/logo.png',
                  width: 300, // Set width to 250 pixels
                  height: 300, // Set height to 250 pixels
                ),
              ),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                color: Colors.red[
                    300], // Set the progress indicator color to a matching brown
              ), // Loading indicator
            ],
          ),
        ),
      ),
    );
  }
}
