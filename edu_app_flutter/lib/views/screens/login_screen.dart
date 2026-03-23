import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: _LoginCard(),
              ),
              const SizedBox(height: 2),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _FooterLinks(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopIllustration extends StatelessWidget {
  const _TopIllustration();

  static const String _illustrationAsset = 'lib/assets/logo1.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
      ),
      child: Stack(
        children: [
          Align(
            child: Container(
              width: 118,
              height: 118,
              child: Image.asset(
                _illustrationAsset,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x00000000)),
                  child: Center(
                    child: Icon(
                      Icons.school_outlined,
                      size: 56,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A20387A),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TopIllustration(),
          const Center(
            child: Text(
              'Đăng nhập',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F1D44),
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Chào mừng bạn trở lại với EduTeacher',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF687A98),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Email',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2E52),
            ),
          ),
          const SizedBox(height: 5),
          _InputField(
            controller: _emailController,
            icon: Icons.mail_rounded,
            hintText: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
            fontSize: 14,
          ),
          const SizedBox(height: 16),
          const Text(
            'Mật khẩu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B2E52),
            ),
          ),
          const SizedBox(height: 5),
          _InputField(
            controller: _passwordController,
            icon: Icons.lock,
            hintText: '••••••••',
            obscureText: _obscurePassword,
            suffix: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF9AA8BE),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Transform.scale(
                scale: 1,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: const BorderSide(color: Color(0xFFCAD6E7), width: 1.6),
                  activeColor: const Color(0xFF1337EC),
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                'Ghi nhớ đăng nhập',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF2D4266),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1132E4),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Quên mật khẩu?'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _PrimaryButton(
            label: 'Đăng nhập',
            icon: Icons.login,
            onPressed: () {},
          ),
          const SizedBox(height: 16),
          const _DividerLabel(label: 'HOẶC'),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              side: const BorderSide(color: Color(0xFFD2DCE8), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              foregroundColor: const Color(0xFF21324F),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {},
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('G', style: TextStyle(fontSize: 30, color: Color(0xFFDB4437))),
                SizedBox(width: 12),
                Text('Tiếp tục với Google'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF677B9C),
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(text: 'Chưa có tài khoản?  '),
                  TextSpan(
                    text: 'Đăng ký ngay',
                    style: TextStyle(
                      color: Color(0xFF1132E4),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.icon,
    required this.hintText,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.fontSize = 14,
  });

  final TextEditingController controller;
  final IconData icon;
  final String hintText;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F8FC),
        prefixIcon: Icon(icon, color: const Color(0xFF94A4BC)),
        suffixIcon: suffix,
        hintText: hintText,
        hintStyle: TextStyle(
          color: Color(0xFF93A2B8),
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFFD5DFEB), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Color(0xFF1337EC), width: 1.6),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1537EC), Color(0xFF4A69F3)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D2449E9),
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 62,
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          icon: Text(label, style: const TextStyle(letterSpacing: 0.1)),
          label: Icon(icon, size: 24),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: Color(0xFFD5DEEA), thickness: 1.2),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9AA7BC),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: Color(0xFFD5DEEA), thickness: 1.2),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  const _FooterLinks();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          'Điều khoản',
          style: TextStyle(
            color: Color(0xFF98A6BC),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'Chính sách bảo mật',
          style: TextStyle(
            color: Color(0xFF98A6BC),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          'Trợ giúp',
          style: TextStyle(
            color: Color(0xFF98A6BC),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
