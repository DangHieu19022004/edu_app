import 'dart:async';
import 'dart:math' as math;

import 'package:edu_app_flutter/services/auth_service.dart';
import 'package:edu_app_flutter/services/auth_session.dart';
import 'package:edu_app_flutter/views/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:edu_app_flutter/views/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bootstrapAndNavigate();
  }

  Future<void> _bootstrapAndNavigate() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final hasLocalSession = AuthSession.instance.isAuthenticated;
    var canKeepLogin = false;

    if (hasLocalSession) {
      canKeepLogin = await _authService.verifyToken();
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => canKeepLogin ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF1337EC);
    const Color deepIndigo = Color(0xFF0F172A);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.15,
                colors: [Color(0xFF1E40AF), deepIndigo],
              ),
            ),
          ),
          const _BackgroundGlow(
            alignment: Alignment(-1.1, -1.2),
            size: 320,
            color: Color(0x4D1337EC),
          ),
          const _BackgroundGlow(
            alignment: Alignment(1.1, 1.2),
            size: 420,
            color: Color(0x331A4DFF),
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: _NetworkNodePainter(),
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                children: [
                  const Spacer(),
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: _LogoSection(primary: primary),
                  ),
                  const SizedBox(height: 56),
                  const _TitleSection(),
                  const Spacer(),
                  const _LoadingSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.45),
                  blurRadius: 60,
                  spreadRadius: 14,
                ),
              ],
            ),
          ),
          Transform.rotate(
            angle: math.pi / 13,
            child: _glassCard(opacity: 0.34),
          ),
          Transform.rotate(
            angle: -math.pi / 16,
            child: _glassCard(opacity: 0.5),
          ),
          Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Transform.scale(
              scale: 1.3,
              child: Image.asset(
                'lib/assets/logo.png',
                fit: BoxFit.cover,
                width: 136,
                height: 136,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required double opacity}) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(28),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text(
          'EduTeacher',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Color(0x52000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
        ),
        SizedBox(height: 14),
        SizedBox(
          width: 48,
          child: Divider(color: Color(0x4DFFFFFF), thickness: 1),
        ),
        SizedBox(height: 12),
        Text(
          'Số hóa học bạ &\nKhai phá tiềm năng giáo dục',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xE6FFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.w300,
            height: 1.45,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 0.85),
          duration: const Duration(seconds: 3),
          curve: Curves.easeInOut,
          builder: (context, value, _) {
            final percent = (value * 100).round();
            return Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SYSTEM STATUS',
                            style: TextStyle(
                              color: Color(0x80FFFFFF),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Đang khởi động hệ thống...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 10,
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.11),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 44),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user_rounded, size: 16, color: Color(0xFF60A5FA)),
              SizedBox(width: 8),
              Text(
                'Chuyển đổi số công nghệ',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xB3FFFFFF),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'v2.4.0 • SECURE END-TO-END',
          style: TextStyle(
            color: Color(0x52FFFFFF),
            fontSize: 10,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _NetworkNodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    final pulsePaint = Paint()..style = PaintingStyle.fill;

    final points = <Offset>[
      Offset(size.width * 0.14, size.height * 0.15),
      Offset(size.width * 0.86, size.height * 0.21),
      Offset(size.width * 0.25, size.height * 0.50),
      Offset(size.width * 0.75, size.height * 0.75),
      Offset(size.width * 0.10, size.height * 0.90),
    ];

    final connections = [
      [0, 1],
      [1, 3],
      [3, 2],
      [2, 0],
      [2, 4],
    ];

    for (final pair in connections) {
      canvas.drawLine(points[pair[0]], points[pair[1]], linePaint);
    }

    for (int i = 0; i < points.length; i++) {
      final radius = i == 2 ? 2.8 : (i.isEven ? 2.2 : 1.8);
      pulsePaint.color = Colors.white.withValues(alpha: i.isEven ? 0.55 : 0.35);
      canvas.drawCircle(points[i], radius, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// class _PlaceholderHomeScreen extends StatelessWidget {
//   const _PlaceholderHomeScreen();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Edu App')),
//       body: const Center(
//         child: Text('Home screen placeholder'),
//       ),
//     );
//   }
// }
