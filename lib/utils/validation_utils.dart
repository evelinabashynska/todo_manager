/// Утиліти для валідації полів форм
class ValidationUtils {
  // Валідація email
  static String? validateEmail(String? value) {
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
  }

  // Валідація паролю
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Будь ласка, введіть пароль';
    }

    if (value.length < minLength) {
      return 'Пароль має містити мінімум $minLength символів';
    }

    // Перевірка на наявність букв
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'Пароль має містити хоча б одну букву';
    }

    // Перевірка на наявність цифр
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Пароль має містити хоча б одну цифру';
    }

    return null;
  }

  // Валідація підтвердження паролю
  static String? validateConfirmPassword(
    String? value,
    String? originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Будь ласка, підтвердіть пароль';
    }

    if (value != originalPassword) {
      return 'Паролі не співпадають';
    }

    return null;
  }

  // Валідація імені
  static String? validateName(String? value, {int minLength = 2}) {
    if (value == null || value.isEmpty) {
      return 'Будь ласка, введіть ім\'я';
    }

    if (value.length < minLength) {
      return 'Ім\'я має містити мінімум $minLength символи';
    }

    // Перевірка на цифри в імені
    if (RegExp(r'\d').hasMatch(value)) {
      return 'Ім\'я не повинно містити цифри';
    }

    return null;
  }

  // Валідація обов'язкового поля
  static String? validateRequired(
    String? value, {
    String fieldName = 'Це поле',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName є обов\'язковим';
    }
    return null;
  }
}
