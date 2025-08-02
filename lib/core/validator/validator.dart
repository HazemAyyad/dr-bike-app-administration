// ignore_for_file: depend_on_referenced_packages

import 'package:email_validator/email_validator.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class Validators {
  /// Validates an email address
  static String? validateEmail(String? value, String language) {
    if (value == null || value.trim().isEmpty) {
      return _getMessage(language, 'emailRequired');
    }
    if (!EmailValidator.validate(value.trim())) {
      return _getMessage(language, 'emailInvalid');
    }
    return null; // No error
  }

  /// Validates a password
  static String? validatePassword(String? value, String language) {
    if (value == null || value.trim().isEmpty) {
      return _getMessage(language, 'passwordRequired');
    }
    if (value.length < 8) return _getMessage(language, 'passwordTooShort');
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return _getMessage(language, 'passwordUppercaseRequired');
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return _getMessage(language, 'passwordLowercaseRequired');
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return _getMessage(language, 'passwordDigitRequired');
    }
    // if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
    //   return _getMessage(language, 'passwordSpecialCharRequired');
    // }
    return null; // No error
  }

  /// Validates a phone number
  static String? validatePhoneNumber(String? value, String language) {
    if (value == null || value.trim().isEmpty) {
      return _getMessage(language, 'phoneRequired');
    }
    try {
      final parsedNumber = PhoneNumber.parse(value.trim());
      if (!parsedNumber.isValid()) {
        return _getMessage(language, 'phoneInvalid');
      }
    } catch (e) {
      return _getMessage(language, 'phoneInvalid');
    }
    return null; // No error
  }

  /// Validates a general text field
  static String? validateTextField(String? value, String language) {
    if (value == null || value.trim().isEmpty) {
      return _getMessage(language, 'defaultRequired');
    }
    return null; // No error
  }

  /// Message retrieval based on language and key
  static String _getMessage(String language, String messageKey) {
    final messages = {
      'en': {
        'emailRequired': 'Email is required',
        'emailInvalid': 'Enter a valid email address',
        'passwordRequired': 'Password is required',
        'passwordTooShort': 'Password must be at least 8 characters',
        'passwordUppercaseRequired':
            'Password must contain at least one uppercase letter',
        'passwordLowercaseRequired':
            'Password must contain at least one lowercase letter',
        'passwordDigitRequired': 'Password must contain at least one digit',
        'phoneRequired': 'Phone number is required',
        'phoneInvalid': 'Enter a valid phone number',
        'defaultRequired': 'This field is required',
      },
      'ar': {
        'emailRequired': 'البريد الإلكتروني مطلوب',
        'emailInvalid': 'الرجاء إدخال بريد إلكتروني صحيح',
        'passwordRequired': 'كلمة المرور مطلوبة',
        'passwordTooShort': 'يجب أن تكون كلمة المرور على الأقل 8 أحرف',
        'passwordUppercaseRequired':
            'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل',
        'passwordLowercaseRequired':
            'يجب أن تحتوي كلمة المرور على حرف صغير واحد على الأقل',
        'passwordDigitRequired':
            'يجب أن تحتوي كلمة المرور على رقم واحد على الأقل',
        'phoneRequired': 'رقم الهاتف مطلوب',
        'phoneInvalid': 'الرجاء إدخال رقم هاتف صحيح',
        'defaultRequired': 'هذا الحقل مطلوب',
      }
    };
    return messages[language]?[messageKey] ?? messages['en']![messageKey]!;
  }
}
