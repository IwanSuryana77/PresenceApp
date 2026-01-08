import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/pengajuan_page.dart';
import 'screens/home/inbox_page.dart';
import 'screens/home/profile_page.dart';
import 'widgets/bottom_nav.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDzYZzOvPh6SECJMJhXPfM_TpgPOewAELA",
        appId: "1:993683626108:android:7af88d2abb86f784bb11f9",
        messagingSenderId: "993683626108",
        projectId: "presenceapp-bb0f5",
        storageBucket: "presenceapp-bb0f5.firebasestorage.app",
      ),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modern HR UI',
      theme: AppTheme.light(), // Pastikan ada AppTheme
      home: const AuthGate(), // Gate ke login jika belum auth
    );
  }
}

// Gate untuk login vs home berdasarkan status autentikasi Firebase
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) {
          // Belum login -> tampilkan layar login modern
          return const ModernLoginScreen();
        }
        // Sudah login -> lanjut ke aplikasi utama
        return const BottomNavWrapper();
      },
    );
  }
}

class BottomNavWrapper extends StatefulWidget {
  const BottomNavWrapper({super.key});

  @override
  State<BottomNavWrapper> createState() => _BottomNavWrapperState();
}

class _BottomNavWrapperState extends State<BottomNavWrapper> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const PengajuanPage(),
    const InboxPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNav(
        index: _selectedIndex,
        onChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}
