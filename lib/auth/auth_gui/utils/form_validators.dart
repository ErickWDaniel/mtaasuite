import 'package:mtaasuite/services/translation_service.dart';

class FormValidators {
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return tr('validation.required');
    }
    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return tr('validation.required');
    }
    // Basic phone validation - can be enhanced
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 9) {
      return tr('validation.invalid_phone');
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('validation.required');
    }
    if (value.trim().length < 2) {
      return tr('validation.name_too_short');
    }
    // Check for valid characters (letters, spaces, hyphens)
    final nameRegex = RegExp(r'^[a-zA-Z\s\-]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return tr('validation.invalid_name');
    }
    return null;
  }

  static String? validateDateOfBirth(String? value) {
    if (value == null || value.isEmpty) {
      return tr('validation.required');
    }
    try {
      final date = DateTime.parse(value);
      final now = DateTime.now();
      final age = now.year - date.year - ((now.month > date.month || (now.month == date.month && now.day >= date.day)) ? 0 : 1);
      
      if (age < 13) {
        return tr('validation.too_young');
      }
      if (age > 120) {
        return tr('validation.invalid_dob');
      }
      return null;
    } catch (e) {
      return tr('validation.invalid_date');
    }
  }

  static String? validateRegion(String? value) {
    if (value == null || value.isEmpty) {
      return tr('auth.register.select_region');
    }
    return null;
  }

  static String? validateDistrict(String? value) {
    if (value == null || value.isEmpty) {
      return tr('auth.register.select_district');
    }
    return null;
  }

  static String? validateWard(String? value) {
    if (value == null || value.isEmpty) {
      return tr('auth.register.select_ward');
    }
    return null;
  }

  static String? validateCheckNumber(String? value, bool isWardOfficer) {
    if (isWardOfficer) {
      if (value == null || value.trim().isEmpty) {
        return tr('auth.register.required_field');
      }
      // Basic check number validation - can be enhanced
      if (value.trim().length < 3) {
        return tr('validation.invalid_check_number');
      }
    }
    return null;
  }

  static String? validateOTP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('validation.required');
    }
    if (value.trim().length != 6) {
      return tr('validation.invalid_otp_length');
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) {
      return tr('validation.invalid_otp_format');
    }
    return null;
  }
}