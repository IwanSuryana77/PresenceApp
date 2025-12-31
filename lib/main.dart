import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'shells/home_shell.dart';
import 'package:firebase_core/firebase_core.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyD...EwAELA", // <- diisi dari Firebase
        appId: "1:993...b1f9", // <- diisi dari Firebase
        messagingSenderId: "993683626108", // <- dari Firebase
        projectId: "presenceapp-bb0f5", // <- dari Firebase
      ),
    );
  }

  runApp(const MyApp());
}
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: FirebaseOptions(
//       apiKey: "AIzaSyD...EwAELA", // <- diisi dari Firebase
//       appId: "1:993...b1f9", // <- diisi dari Firebase
//       messagingSenderId: "993683626108", // <- dari Firebase
//       projectId: "presenceapp-bb0f5", // <- dari Firebase
//     ),
//   );
//   runApp(const MyApp());
// }

// void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Modern HR UI',
      theme: AppTheme.light(),
      home: const HomeShell(),
    );
  }
}
