import 'dart:async';
import 'package:flutter/material.dart';
import 'package:peresenceapp/screens/auth/login_screen.dart';

// SplashScreen: Menampilkan logo dan animasi teks "FaceApp" satu per satu
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Untuk mengontrol animasi teks satu per satu
  int _visibleChars = 0;
  final String _appName = 'FaceApp';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Mulai animasi teks satu per satu
    _startAnimation();
  }

  void _startAnimation() {
    // Mulai animasi teks satu per satu
    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (_visibleChars < _appName.length) {
        setState(() {
          _visibleChars++;
        });
      } else {
        _timer?.cancel();
        // Setelah animasi selesai, navigasi ke LoginScreen
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo aplikasi (gunakan asset logo.png di assets/images/)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Animasi teks FaceApp satu per satu
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_visibleChars, (i) {
                return Text(
                  _appName[i],
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                    letterSpacing: 2,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
