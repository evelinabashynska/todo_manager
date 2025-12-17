import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Отримати поточного користувача
  User? get currentUser => _auth.currentUser;

  // Stream для відстеження стану авторизації
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Реєстрація з email та паролем
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Оновлюємо ім'я користувача
      await userCredential.user?.updateDisplayName(name);

      // Логування події в Analytics
      await _analytics.logSignUp(signUpMethod: 'email');

      return AuthResult(success: true, user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, errorMessage: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Виникла непередбачена помилка: $e',
      );
    }
  }

  // Вхід з email та паролем
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      // Логування події в Analytics
      await _analytics.logLogin(loginMethod: 'email');

      return AuthResult(success: true, user: userCredential.user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, errorMessage: _getErrorMessage(e.code));
    } catch (e) {
      return AuthResult(
        success: false,
        errorMessage: 'Виникла непередбачена помилка: $e',
      );
    }
  }

  // Вихід з акаунту
  Future<void> signOut() async {
    await _analytics.logEvent(name: 'logout');
    await _auth.signOut();
  }

  // Скидання паролю
  Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult(
        success: true,
        errorMessage: 'Лист для скидання паролю надіслано на вашу пошту',
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, errorMessage: _getErrorMessage(e.code));
    }
  }

  // Переклад кодів помилок Firebase на українську
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ця електронна адреса вже використовується';
      case 'invalid-email':
        return 'Невірний формат електронної пошти';
      case 'operation-not-allowed':
        return 'Операція не дозволена';
      case 'weak-password':
        return 'Пароль занадто слабкий (мінімум 6 символів)';
      case 'user-disabled':
        return 'Цей обліковий запис було вимкнено';
      case 'user-not-found':
        return 'Користувача з такою поштою не знайдено';
      case 'wrong-password':
        return 'Невірний пароль';
      case 'too-many-requests':
        return 'Забагато спроб входу. Спробуйте пізніше';
      case 'network-request-failed':
        return 'Помилка мережі. Перевірте з\'єднання з інтернетом';
      default:
        return 'Виникла помилка: $code';
    }
  }
}

// Клас для результату авторизації
class AuthResult {
  final bool success;
  final String? errorMessage;
  final User? user;

  AuthResult({required this.success, this.errorMessage, this.user});
}
