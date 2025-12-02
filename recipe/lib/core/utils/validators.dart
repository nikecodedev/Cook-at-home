/// Input validation utilities
class Validators {
  /// Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Password validation regex (at least 8 chars, 1 uppercase, 1 lowercase, 1 number)
  static final RegExp _strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
  );

  /// Validate email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es requerido';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Por favor ingresa un correo electrónico válido';
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Validate strong password
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!_strongPasswordRegex.hasMatch(value)) {
      return 'La contraseña debe contener mayúsculas, minúsculas y números';
    }
    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirm(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'El número de teléfono es requerido';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s-()]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Por favor ingresa un número de teléfono válido';
    }
    if (value.replaceAll(RegExp(r'[\s-()]'), '').length < 10) {
      return 'El número de teléfono debe tener al menos 10 dígitos';
    }
    return null;
  }

  /// Validate number
  static String? validateNumber(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    if (double.tryParse(value) == null) {
      return 'Por favor ingresa un número válido';
    }
    return null;
  }

  /// Validate positive number
  static String? validatePositiveNumber(String? value, [String fieldName = 'Este campo']) {
    final numberError = validateNumber(value, fieldName);
    if (numberError != null) return numberError;
    
    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName debe ser mayor que 0';
    }
    return null;
  }

  /// Validate integer
  static String? validateInteger(String? value, [String fieldName = 'Este campo']) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    if (int.tryParse(value) == null) {
      return 'Por favor ingresa un número entero válido';
    }
    return null;
  }

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'La URL es requerida';
    }
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Por favor ingresa una URL válida';
    }
    return null;
  }

  /// Validate date (not in past)
  static String? validateFutureDate(DateTime? value, [String fieldName = 'Fecha']) {
    if (value == null) {
      return '$fieldName es requerida';
    }
    if (value.isBefore(DateTime.now())) {
      return '$fieldName no puede estar en el pasado';
    }
    return null;
  }

  /// Validate min length
  static String? validateMinLength(String? value, int minLength, [String fieldName = 'Este campo']) {
    if (value == null || value.isEmpty) {
      return '$fieldName es requerido';
    }
    if (value.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }
    return null;
  }

  /// Validate max length
  static String? validateMaxLength(String? value, int maxLength, [String fieldName = 'Este campo']) {
    if (value != null && value.length > maxLength) {
      return '$fieldName debe tener como máximo $maxLength caracteres';
    }
    return null;
  }

  /// Validate range
  static String? validateRange(double? value, double min, double max, [String fieldName = 'Valor']) {
    if (value == null) {
      return '$fieldName es requerido';
    }
    if (value < min || value > max) {
      return '$fieldName debe estar entre $min y $max';
    }
    return null;
  }

  /// Validate quantity
  static String? validateQuantity(String? value) {
    return validatePositiveNumber(value, 'Cantidad');
  }

  /// Validate recipe title
  static String? validateRecipeTitle(String? value) {
    return validateMinLength(value, 3, 'Título de la receta');
  }

  /// Validate recipe description
  static String? validateRecipeDescription(String? value) {
    return validateMinLength(value, 10, 'Descripción de la receta');
  }

  /// Validate item name
  static String? validateItemName(String? value) {
    return validateMinLength(value, 2, 'Nombre del artículo');
  }
}

