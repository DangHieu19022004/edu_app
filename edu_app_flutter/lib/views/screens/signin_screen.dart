import 'package:flutter/material.dart';
import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_spacing.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.cardHorizontal,
                  14,
                  AppSpacing.cardHorizontal,
                  0,
                ),
                child: Row(
                  children: [
                    Material(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: AppFontSizes.icon38,
                          height: AppFontSizes.icon38,
                          child: Icon(
                            AppIcons.arrowBack,
                            color: AppColors.primary,
                            size: AppFontSizes.icon20,
                          ),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          AppTexts.appName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.title,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 38),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _SigninHero(),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(
                  AppSpacing.cardHorizontal,
                  12,
                  AppSpacing.cardHorizontal,
                  12,
                ),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 28,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SignInputField(
                      label: AppTexts.fullNameLabel,
                      hintText: AppTexts.fullNameHint,
                      icon: AppIcons.personOutline,
                      controller: _nameController,
                    ),
                    const SizedBox(height: 14),
                    _SignInputField(
                      label: AppTexts.workEmailLabel,
                      hintText: AppTexts.workEmailHint,
                      icon: AppIcons.mailOutline,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 14),
                    _SignInputField(
                      label: AppTexts.passwordLabel,
                      hintText: AppTexts.signInPasswordHint,
                      icon: AppIcons.lockOutline,
                      obscureText: _obscurePassword,
                      controller: _passwordController,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? AppIcons.visibilityOffOutlined
                              : AppIcons.visibilityOutlined,
                          color: AppColors.inputIcon,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SignInputField(
                      label: AppTexts.schoolLabel,
                      hintText: AppTexts.schoolHint,
                      icon: AppIcons.apartmentOutline,
                      controller: _schoolController,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1337EC), Color(0xFF2458F3)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x332348EF),
                              blurRadius: 16,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: AppFontSizes.signInButton,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text(AppTexts.createAccount),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _DividerLabel(label: AppTexts.orLower),
                    const SizedBox(height: 18),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(color: Color(0xFFD4DDE8), width: 1.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        foregroundColor: const Color(0xFF21324F),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'G',
                            style: TextStyle(
                              fontSize: 26,
                              color: AppColors.googleRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(AppTexts.continueWithGoogle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.body,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        const TextSpan(text: AppTexts.haveAccount),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Text(
                              AppTexts.loginTitle,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SigninHero extends StatelessWidget {
  const _SigninHero();
  static const String _illustrationAsset = 'lib/assets/logo1.png';
  @override
  Widget build(BuildContext context) {
    return Column(
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
                      AppIcons.schoolOutlined,
                      size: 56,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
              ),
            ),
          ),
        SizedBox(height: 10),
        Text(
          AppTexts.signInTitle,
          style: TextStyle(
            fontSize: AppFontSizes.signInTitle,
            fontWeight: FontWeight.w700,
            color: AppColors.title,
          ),
        ),
        SizedBox(height: 6),
        Text(
          AppTexts.signInWelcome,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppFontSizes.signInDescription,
            color: AppColors.subtitle,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SignInputField extends StatelessWidget {
  const _SignInputField({
    required this.label,
    required this.hintText,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  final String label;
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: AppFontSizes.signInLabel,
              fontWeight: FontWeight.w600,
              color: AppColors.label,
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.inputFill,
            prefixIcon: Icon(icon, color: AppColors.inputIcon, size: 20),
            suffixIcon: suffix,
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppColors.inputHint,
              fontSize: AppFontSizes.inputHint,
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.inputBorderFocus, width: 1.5),
            ),
          ),
        ),
      ],
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
          child: Divider(color: AppColors.divider, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.footer,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.divider, thickness: 1),
        ),
      ],
    );
  }
}
