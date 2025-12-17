import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../utils/responsive_helper.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _analytics = FirebaseAnalytics.instance;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Логування відкриття екрану входу
    _analytics.logScreenView(
      screenName: 'LoginScreen',
      screenClass: 'LoginScreen',
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // Валідація форми
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Спроба входу
    final result = await _authService.signInWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      // Успішний вхід - переходимо на головний екран
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Показуємо помилку
      _showErrorDialog(result.errorMessage ?? 'Помилка входу');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Помилка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildHeader(isMobile),
                SizedBox(height: isMobile ? 32 : 48),
                _buildLoginCard(isMobile),
                const SizedBox(height: 24),
                _buildLanguageButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      children: [
        Text(
          'To-Do App',
          style: TextStyle(
            fontSize: isMobile ? 32 : 40,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Text(
          'Організуйте свої завдання ефективно',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard(bool isMobile) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Увійти',
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildRegisterLink(),
            SizedBox(height: isMobile ? 24 : 32),
            CustomTextField(
              label: 'Електронна пошта',
              hint: 'your@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Будь ласка, введіть електронну пошту';
                }
                final emailRegex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                );
                if (!emailRegex.hasMatch(value)) {
                  return 'Введіть коректну електронну адресу';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Пароль',
              hint: '••••••••',
              controller: _passwordController,
              isPassword: true,
              obscureText: _obscurePassword,
              onToggleVisibility: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Будь ласка, введіть пароль';
                }
                if (value.length < 6) {
                  return 'Пароль має містити мінімум 6 символів';
                }
                return null;
              },
            ),
            SizedBox(height: isMobile ? 24 : 32),
            _buildLoginButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      children: [
        Text(
          'Немає акаунта? ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        GestureDetector(
          onTap: () {
            _analytics.logEvent(
              name: 'navigate_to_register',
              parameters: {'source': 'login_screen'},
            );
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterScreen()),
            );
          },
          child: const Text(
            'Зареєструватися',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
        disabledBackgroundColor: Colors.grey,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Увійти',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildLanguageButton() {
    return TextButton(
      onPressed: () {},
      child: const Text(
        'English',
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
      ),
    );
  }
}
