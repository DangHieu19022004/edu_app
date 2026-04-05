import 'package:flutter/material.dart';
import 'package:edu_app_flutter/constants/app_colors.dart';
import 'package:edu_app_flutter/constants/app_spacing.dart';
import 'package:edu_app_flutter/constants/app_texts.dart';
import 'package:edu_app_flutter/constants/app_ui.dart';
import 'package:edu_app_flutter/controllers/login_controller.dart';
import 'package:edu_app_flutter/services/api_exception.dart';
import 'package:edu_app_flutter/services/facebook_auth_service.dart';
import 'package:edu_app_flutter/services/google_auth_service.dart';
import 'package:edu_app_flutter/views/screens/dashboard_screen.dart';
import 'package:edu_app_flutter/views/screens/signin_screen.dart';
import 'package:edu_app_flutter/views/widgets/app_notice_modal.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.cardTop),
                child: _LoginCard(),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  0,
                  AppSpacing.xl,
                  AppSpacing.footerBottom,
                ),
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

  static const String _illustrationAsset = 'lib/assets/logo.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(color: AppColors.white),
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
                      AppIcons.schoolOutlined,
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
  final LoginController _loginController = LoginController();
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  final FacebookAuthService _facebookAuthService = FacebookAuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loginController.addListener(_onLoginStateChanged);
  }

  Future<void> _onLoginStateChanged() async {
    if (!mounted || _loginController.isLoading) {
      return;
    }

    if (_loginController.status == LoginStatus.error &&
        _loginController.errorMessage != null) {
      await AppNoticeModal.showError(
        context,
        message: _loginController.errorMessage!,
      );
      _loginController.resetState();
      return;
    }

    if (_loginController.status == LoginStatus.success) {
      final successMessage =
          _loginController.response?.message.isNotEmpty == true
          ? _loginController.response!.message
          : (_loginController.googleResponse?.message.isNotEmpty == true
                ? _loginController.googleResponse!.message
                : (_loginController.facebookResponse?.message.isNotEmpty == true
                      ? _loginController.facebookResponse!.message
                      : 'Chao mung ban quay tro lai voi EduTeacher.'));

      await AppNoticeModal.showSuccess(
        context,
        title: 'Dang nhap thanh cong',
        message: successMessage,
        showAction: false,
        autoDismissDuration: const Duration(milliseconds: 1500),
        barrierDismissible: false,
      );

      if (!mounted) {
        return;
      }

      _loginController.resetState();

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _submitLogin() async {
    final emailOrPhone = _emailController.text.trim();
    final password = _passwordController.text;

    if (emailOrPhone.isEmpty || password.isEmpty) {
      await AppNoticeModal.showError(
        context,
        title: 'Thieu thong tin',
        message: 'Vui long nhap day du email/so dien thoai va mat khau.',
      );
      return;
    }

    await _loginController.login(
      emailOrPhone: emailOrPhone,
      password: password,
    );
  }

  Future<void> _submitGoogleLogin() async {
    try {
      final token = await _googleAuthService.getFirebaseIdToken();
      if (!mounted || token == null || token.trim().isEmpty) {
        return;
      }

      await _loginController.loginWithGoogleToken(token: token);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      await AppNoticeModal.showError(
        context,
        title: 'Google Sign-In that bai',
        message: e.message,
      );
    }
  }

  Future<void> _submitFacebookLogin() async {
    try {
      final profile = await _facebookAuthService.loginAndGetProfile();
      if (!mounted || profile == null) {
        return;
      }

      await _loginController.loginWithFacebookProfile(
        uid: profile.uid,
        displayName: profile.displayName,
        photoUrl: profile.photoUrl,
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      await AppNoticeModal.showError(
        context,
        title: 'Facebook login that bai',
        message: e.message,
      );
    }
  }

  @override
  void dispose() {
    _loginController.removeListener(_onLoginStateChanged);
    _loginController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardHorizontal,
        vertical: AppSpacing.cardVertical,
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
        26,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
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
              AppTexts.loginTitle,
              style: TextStyle(
                fontSize: AppFontSizes.titleLarge,
                fontWeight: FontWeight.w800,
                color: AppColors.title,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            AppTexts.loginWelcome,
            style: TextStyle(
              fontSize: AppFontSizes.subtitle,
              color: AppColors.subtitle,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            AppTexts.emailLabel,
            style: TextStyle(
              fontSize: AppFontSizes.inputLabel,
              fontWeight: FontWeight.w700,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InputField(
            controller: _emailController,
            icon: AppIcons.mail,
            hintText: AppTexts.emailHint,
            keyboardType: TextInputType.emailAddress,
            fontSize: AppFontSizes.inputHint,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            AppTexts.passwordLabel,
            style: TextStyle(
              fontSize: AppFontSizes.inputLabel,
              fontWeight: FontWeight.w700,
              color: AppColors.label,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InputField(
            controller: _passwordController,
            icon: AppIcons.lock,
            hintText: AppTexts.passwordHint,
            obscureText: _obscurePassword,
            suffix: IconButton(
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword ? AppIcons.visibility : AppIcons.visibilityOff,
                color: AppColors.inputIcon,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: -4,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: const BorderSide(color: Color(0xFFCAD6E7), width: 1.6),
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Text(
                AppTexts.rememberMe,
                style: TextStyle(
                  fontSize: AppFontSizes.footer,
                  color: AppColors.label,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.link,
                  textStyle: const TextStyle(
                    fontSize: AppFontSizes.footer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text(AppTexts.forgotPassword),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedBuilder(
            animation: _loginController,
            builder: (context, _) {
              return _PrimaryButton(
                label: AppTexts.loginButton,
                icon: AppIcons.login,
                onPressed: _loginController.isLoading ? null : _submitLogin,
                isLoading: _loginController.isLoading,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const _DividerLabel(label: AppTexts.orUpper),
          const SizedBox(height: AppSpacing.lg),
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
            onPressed: _loginController.isLoading ? null : _submitGoogleLogin,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'G',
                  style: TextStyle(fontSize: 30, color: Color(0xFFDB4437)),
                ),
                SizedBox(width: 12),
                Text(AppTexts.continueWithGoogle),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
            onPressed: _loginController.isLoading ? null : _submitFacebookLogin,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFF1877F2),
                  child: Text(
                    'f',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      height: 0.9,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Text(AppTexts.continueWithFacebook),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  AppTexts.noAccount,
                  style: TextStyle(
                    fontSize: AppFontSizes.body,
                    color: AppColors.body,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SigninScreen()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.link,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: AppFontSizes.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text(AppTexts.signUpNow),
                ),
              ],
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
    this.fontSize = AppFontSizes.inputHint,
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
        fillColor: AppColors.inputFill,
        prefixIcon: Icon(icon, color: AppColors.inputIcon),
        suffixIcon: suffix,
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.inputHint,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AppColors.inputBorder,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AppColors.inputBorderFocus,
            width: 1.6,
          ),
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
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

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
            color: AppColors.buttonShadow,
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
          icon: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(label, style: const TextStyle(letterSpacing: 0.1)),
          label: isLoading ? const SizedBox.shrink() : Icon(icon, size: 24),
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
          child: Divider(color: AppColors.divider, thickness: 1.2),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.footer,
              fontSize: AppFontSizes.divider,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.divider, thickness: 1.2),
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
          AppTexts.terms,
          style: TextStyle(
            color: AppColors.footer,
            fontSize: AppFontSizes.footer,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          AppTexts.privacy,
          style: TextStyle(
            color: AppColors.footer,
            fontSize: AppFontSizes.footer,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          AppTexts.support,
          style: TextStyle(
            color: AppColors.footer,
            fontSize: AppFontSizes.footer,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
