/// Test phone numbers configuration for development
/// These numbers can be used for testing without sending actual SMS
class TestPhoneNumbers {
  // Test phone numbers for development
  static const Map<String, String> testNumbers = {
    '+255123456789': '123456',  // Test number with OTP
    '+255987654321': '654321',  // Alternative test number
    '+255111111111': '111111',  // Simple test number
    '+255222222222': '222222',  // Another test number
    '+255700000001': '123456',  // Tanzania Vodacom test
    '+255650000001': '654321',  // Tanzania Tigo test
  };

  // Check if a phone number is a test number
  static bool isTestNumber(String phoneNumber) {
    return testNumbers.containsKey(phoneNumber);
  }

  // Get OTP for test number
  static String? getTestOTP(String phoneNumber) {
    return testNumbers[phoneNumber];
  }

  // Get all test numbers (for debugging/documentation)
  static List<String> getAllTestNumbers() {
    return testNumbers.keys.toList();
  }

  // Validate test OTP
  static bool validateTestOTP(String phoneNumber, String otp) {
    final expectedOTP = getTestOTP(phoneNumber);
    return expectedOTP != null && expectedOTP == otp;
  }

  // Development mode flag (can be set based on build config)
  static bool isDevelopmentMode = true; // Set to false in production

  // Check if test numbers should be enabled
  static bool get testNumbersEnabled => isDevelopmentMode;
}