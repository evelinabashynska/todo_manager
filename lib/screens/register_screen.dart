import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_text_field.dart';
import '../utils/responsive_helper.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _analytics = FirebaseAnalytics.instance;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Логування відкриття екрану реєстрації
    _analytics.logScreenView(
      screenName: 'RegisterScreen',
      screenClass: 'RegisterScreen',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Валідація форми
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    // Спроба реєстрації
    final result = await _authService.registerWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      // Успішна реєстрація - переходимо на головний екран
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // Показуємо помилку
      _showErrorDialog(result.errorMessage ?? 'Помилка реєстрації');
    }
  }

  // Функція для тестування Crashlytics - генерує помилку
  void _testCrashlytics() {
    _analytics.logEvent(name: 'test_crash_button_pressed');

    // Показуємо попередження перед крашем
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Тест Crashlytics'),
        content: const Text(
          'Зараз буде згенеровано тестову помилку для Firebase Crashlytics.\n\n'
          'Застосунок може закритись. Після перезапуску перевірте Firebase Console → Crashlytics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Генеруємо різні типи помилок для тестування

              // 1. Фатальна помилка (краш)
              FirebaseCrashlytics.instance.crash();

              // 2. Нефатальна помилка (для тестування)
              // FirebaseCrashlytics.instance.recordError(
              //   Exception('Тестова помилка з RegisterScreen'),
              //   StackTrace.current,
              //   reason: 'Тестування Firebase Crashlytics',
              //   fatal: false,
              // );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Згенерувати краш'),
          ),
        ],
      ),
    );
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
                _buildRegisterCard(isMobile),
                // Кнопка для тестування Crashlytics (видаліть в продакшені)
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _testCrashlytics,
                  child: const Text(
                    'Тест Crashlytics (для звіту)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
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

  Widget _buildRegisterCard(bool isMobile) {
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
              'Реєстрація',
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildLoginLink(),
            SizedBox(height: isMobile ? 24 : 32),
            CustomTextField(
              label: 'Повне ім\'я',
              hint: 'Іван Іваненко',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Будь ласка, введіть ваше ім\'я';
                }
                if (value.length < 2) {
                  return 'Ім\'я має містити мінімум 2 символи';
                }
                if (RegExp(r'\d').hasMatch(value)) {
                  return 'Ім\'я не повинно містити цифри';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
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
                if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
                  return 'Пароль має містити хоча б одну букву';
                }
                if (!RegExp(r'\d').hasMatch(value)) {
                  return 'Пароль має містити хоча б одну цифру';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'Підтвердіть пароль',
              hint: '••••••••',
              controller: _confirmPasswordController,
              isPassword: true,
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () {
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Будь ласка, підтвердіть пароль';
                }
                if (value != _passwordController.text) {
                  return 'Паролі не співпадають';
                }
                return null;
              },
            ),
            SizedBox(height: isMobile ? 24 : 32),
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      children: [
        Text(
          'Вже є акаунт? ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        GestureDetector(
          onTap: () {
            _analytics.logEvent(
              name: 'navigate_to_login',
              parameters: {'source': 'register_screen'},
            );
            Navigator.pop(context);
          },
          child: const Text(
            'Увійти',
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

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleRegister,
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
              'Зареєструватися',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }
}
