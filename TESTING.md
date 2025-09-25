# Testing Phone Authentication

This document explains how to test phone authentication in development mode without sending actual SMS messages.

## Test Phone Numbers

The following test phone numbers are configured for development and testing:

| Phone Number | Test OTP | Description |
|--------------|----------|-------------|
| +255123456789 | 123456 | Primary test number |
| +255987654321 | 654321 | Alternative test number |
| +255111111111 | 111111 | Simple test number |
| +255222222222 | 222222 | Another test number |
| +255700000001 | 123456 | Tanzania Vodacom test |
| +255650000001 | 654321 | Tanzania Tigo test |

## How to Use Test Numbers

### 1. Development Mode
Test numbers are automatically enabled when `TestPhoneNumbers.isDevelopmentMode` is set to `true` (default).

### 2. Registration Flow
1. Enter any of the test phone numbers above in the registration form
2. Complete the registration form with required information
3. When prompted for OTP, enter the corresponding test OTP from the table above
4. The system will bypass Firebase SMS and authenticate using the test OTP

### 3. Login Flow
1. Enter any of the test phone numbers above in the login form
2. When prompted for OTP, enter the corresponding test OTP
3. The system will authenticate without sending actual SMS

### 4. Features Supported with Test Numbers
- ✅ Registration with test phone numbers
- ✅ Login with test phone numbers
- ✅ OTP validation without SMS
- ✅ User profile creation and storage
- ✅ All UI flows and validation

### 5. Production Mode
In production, set `TestPhoneNumbers.isDevelopmentMode = false` to disable test numbers and use real SMS.

## Configuration

Test phone numbers are configured in `lib/services/test_phone_numbers.dart`:

```dart
static const Map<String, String> testNumbers = {
  '+255123456789': '123456',  // Test number with OTP
  // ... more test numbers
};
```

## Security Note

⚠️ **Important**: Test phone numbers should only be enabled in development/testing environments. Make sure to disable them in production builds by setting `TestPhoneNumbers.isDevelopmentMode = false`.

## Adding New Test Numbers

To add new test numbers:

1. Open `lib/services/test_phone_numbers.dart`
2. Add the new phone number and OTP to the `testNumbers` map
3. Follow the Tanzania phone number format: `+255XXXXXXXXX`

## Troubleshooting

### Test OTP Not Working
- Ensure you're using the exact OTP from the test numbers table
- Check that development mode is enabled
- Verify the phone number format is correct

### Test Numbers Not Recognized
- Make sure the phone number exactly matches one in the `testNumbers` map
- Check that `TestPhoneNumbers.testNumbersEnabled` returns `true`

## Firebase Test Configuration

For Firebase Authentication testing, you can also configure test phone numbers in the Firebase Console:
1. Go to Firebase Console → Authentication → Settings
2. Scroll to "Phone numbers for testing"
3. Add test phone numbers with their verification codes

This provides an additional layer of testing with Firebase's built-in test number support.