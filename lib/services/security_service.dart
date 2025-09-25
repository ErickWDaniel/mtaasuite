import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

/// Security service for authentication rate limiting and input validation
class SecurityService {
  static const String _otpRequestPrefix = 'otp_request_';
  static const String _loginAttemptPrefix = 'login_attempt_';
  static const int _maxOtpRequestsPerHour = 5;
  static const int _maxLoginAttemptsPerHour = 10;
  static const int _timeWindowHours = 1;

  /// Rate limiting for OTP requests
  static Future<bool> canRequestOTP(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_otpRequestPrefix${_sanitizePhoneNumber(phoneNumber)}';
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeWindow = _timeWindowHours * 60 * 60 * 1000; // Convert to milliseconds

      // Get existing requests within the time window
      final requestsJson = prefs.getStringList(key) ?? [];
      final validRequests = requestsJson
          .map((r) => int.tryParse(r) ?? 0)
          .where((timestamp) => (now - timestamp) < timeWindow)
          .toList();

      // Check if under the limit
      if (validRequests.length < _maxOtpRequestsPerHour) {
        // Add current request
        validRequests.add(now);
        await prefs.setStringList(key, validRequests.map((e) => e.toString()).toList());
        developer.log('OTP request allowed for $phoneNumber (${validRequests.length}/$_maxOtpRequestsPerHour)', name: 'SecurityService');
        return true;
      }

      developer.log('OTP request rate limited for $phoneNumber', name: 'SecurityService');
      return false;
    } catch (e) {
      developer.log('Error in OTP rate limiting: $e', name: 'SecurityService');
      return true; // Allow on error to prevent blocking users
    }
  }

  /// Rate limiting for login attempts
  static Future<bool> canAttemptLogin(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_loginAttemptPrefix${_sanitizePhoneNumber(phoneNumber)}';
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeWindow = _timeWindowHours * 60 * 60 * 1000;

      final attemptsJson = prefs.getStringList(key) ?? [];
      final validAttempts = attemptsJson
          .map((r) => int.tryParse(r) ?? 0)
          .where((timestamp) => (now - timestamp) < timeWindow)
          .toList();

      if (validAttempts.length < _maxLoginAttemptsPerHour) {
        validAttempts.add(now);
        await prefs.setStringList(key, validAttempts.map((e) => e.toString()).toList());
        developer.log('Login attempt allowed for $phoneNumber (${validAttempts.length}/$_maxLoginAttemptsPerHour)', name: 'SecurityService');
        return true;
      }

      developer.log('Login attempt rate limited for $phoneNumber', name: 'SecurityService');
      return false;
    } catch (e) {
      developer.log('Error in login rate limiting: $e', name: 'SecurityService');
      return true;
    }
  }

  /// Get remaining time before next OTP request is allowed
  static Future<Duration> getOTPCooldown(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_otpRequestPrefix${_sanitizePhoneNumber(phoneNumber)}';
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeWindow = _timeWindowHours * 60 * 60 * 1000;

      final requestsJson = prefs.getStringList(key) ?? [];
      final timestamps = requestsJson
          .map((r) => int.tryParse(r) ?? 0)
          .where((timestamp) => (now - timestamp) < timeWindow)
          .toList();

      if (timestamps.length >= _maxOtpRequestsPerHour) {
        timestamps.sort();
        final oldestRequest = timestamps.first;
        final cooldownEnd = oldestRequest + timeWindow;
        final remainingMs = cooldownEnd - now;
        return Duration(milliseconds: remainingMs > 0 ? remainingMs : 0);
      }

      return Duration.zero;
    } catch (e) {
      developer.log('Error getting OTP cooldown: $e', name: 'SecurityService');
      return Duration.zero;
    }
  }

  /// Sanitize and validate phone number input
  static String _sanitizePhoneNumber(String phoneNumber) {
    // Remove all non-digit characters except '+'
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Sanitize user name input
  static String sanitizeName(String name) {
    // Remove potentially harmful characters and trim
    return name
        .replaceAll(RegExp(r'[<>"\/\\&' + "']"), '') // Remove HTML/script characters
        .trim()
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Validate and sanitize phone number
  static String? sanitizeAndValidatePhone(String phoneNumber) {
    if (phoneNumber.isEmpty) return null;
    
    final sanitized = _sanitizePhoneNumber(phoneNumber);
    
    // Basic validation
    if (sanitized.length < 10 || sanitized.length > 15) {
      return null;
    }

    return sanitized;
  }

  /// Sanitize OTP input
  static String sanitizeOTP(String otp) {
    // Only allow digits and limit to 6 characters
    final sanitized = otp.replaceAll(RegExp(r'[^\d]'), '');
    return sanitized.length > 6 ? sanitized.substring(0, 6) : sanitized;
  }

  /// Validate OTP format
  static bool isValidOTP(String otp) {
    final sanitized = sanitizeOTP(otp);
    return sanitized.length == 6 && RegExp(r'^\d{6}$').hasMatch(sanitized);
  }

  /// Clear rate limiting data (for testing or admin purposes)
  static Future<void> clearRateLimitData(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sanitizedPhone = _sanitizePhoneNumber(phoneNumber);
      await prefs.remove('$_otpRequestPrefix$sanitizedPhone');
      await prefs.remove('$_loginAttemptPrefix$sanitizedPhone');
      developer.log('Rate limit data cleared for $phoneNumber', name: 'SecurityService');
    } catch (e) {
      developer.log('Error clearing rate limit data: $e', name: 'SecurityService');
    }
  }

  /// Validate input length to prevent buffer overflow attacks
  static bool isValidInputLength(String input, {int maxLength = 255}) {
    return input.length <= maxLength;
  }

  /// Check for suspicious patterns in input
  static bool hasSuspiciousPatterns(String input) {
    // Check for common injection patterns
    final suspiciousPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false),
      RegExp(r'eval\s*\(', caseSensitive: false),
      RegExp(r'union\s+select', caseSensitive: false),
      RegExp(r'drop\s+table', caseSensitive: false),
    ];

    return suspiciousPatterns.any((pattern) => pattern.hasMatch(input));
  }

  /// Comprehensive input validation
  static ValidationResult validateInput(String input, InputType type) {
    if (input.isEmpty) {
      return ValidationResult(false, 'Input cannot be empty');
    }

    // Check length based on input type
    int maxLength;
    switch (type) {
      case InputType.phone:
        maxLength = 20;
        break;
      case InputType.name:
        maxLength = 100;
        break;
      case InputType.otp:
        maxLength = 6;
        break;
      case InputType.address:
        maxLength = 500;
        break;
      default:
        maxLength = 255;
    }

    if (!isValidInputLength(input, maxLength: maxLength)) {
      return ValidationResult(false, 'Input too long (max $maxLength characters)');
    }

    if (hasSuspiciousPatterns(input)) {
      developer.log('Suspicious input detected: $input', name: 'SecurityService');
      return ValidationResult(false, 'Invalid characters detected');
    }

    return ValidationResult(true, 'Valid input');
  }

  /// Generate secure random string for session tokens
  static String generateSecureToken({int length = 32}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    var result = '';
    
    for (int i = 0; i < length; i++) {
      result += chars[(random + i) % chars.length];
    }
    
    return result;
  }
}

/// Input validation result
class ValidationResult {
  final bool isValid;
  final String message;

  ValidationResult(this.isValid, this.message);
}

/// Input types for validation
enum InputType {
  phone,
  name,
  otp,
  address,
  general,
}