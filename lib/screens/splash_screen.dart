import 'package:flutter/material.dart';
import 'homepage.dart';
import 'first_time_login.dart'; // Import FirstTimeLoginPage

class SplashScreen extends StatefulWidget {
  final bool isFirstTime;

  const SplashScreen({super.key, required this.isFirstTime});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
          widget.isFirstTime ? FirstTimeLoginPage() : HomePage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A3D62), // Deep Navy Blue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/connectx_logo.png',
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'ConnectX',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Text in White
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Fast. Secure. Offline',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFFE0E6ED), // Light Steel Blue - Soft and elegant
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
