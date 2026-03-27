import 'package:flutter/material.dart';
import 'package:edu_app_flutter/constants/api_config.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:edu_app_flutter/views/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthSession.instance.bootstrap();

  assert(() {
    debugPrint('API Base URL: ${ApiConfig.apiBaseUrl}');
    return true;
  }());

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
