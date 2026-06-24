import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:edu_app_flutter/constants/api_config.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:edu_app_flutter/services/auth_storage.dart';
import 'package:edu_app_flutter/views/screens/splash_screen.dart';
import 'package:edu_app_flutter/views/widgets/app_loading_overlay.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await Firebase.initializeApp();
  AuthSession.instance.configureStorage(SecureAuthStorage());
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
      builder: (context, child) {
        return AppLoadingOverlay(
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
