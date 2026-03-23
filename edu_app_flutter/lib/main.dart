import 'package:flutter/material.dart';
import 'package:edu_app_flutter/views/screens/splash_screen.dart';

void main() {
  runApp(const EduApp());
}

class EduApp extends StatelessWidget {
  const EduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduTeacher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1337EC)),
      ),
      home: const SplashScreen(),
    );
  }
}
