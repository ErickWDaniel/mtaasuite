# MtaaSuite Firebase Functions - SMS OTP Service

This Firebase Functions service provides SMS/OTP functionality with multiple fallback providers for Tanzania.

## Features

- **Primary**: Firebase Auth built-in SMS
- **Fallback 1**: Beem SMS (Tanzania local provider)
- **Fallback 2**: Tigo SMS (Tanzania local provider)  
- **Fallback 3**: Twilio SMS (International provider)
- Custom OTP verification for non-Firebase Auth flows
- Comprehensive error handling and logging
- Health check endpoints

## Setup Instructions

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure Environment Variables

Copy the environment template and fill in your API keys:

```bash
cp .env.example .env
```

Edit `.env` with your actual API credentials:

```bash
# Beem SMS (Tanzania) - Get from https://beem.africa/
BEEM_API_KEY=your_beem_api_key_here
BEEM_SECRET_KEY=your_beem_secret_key_here
BEEM_SENDER_NAME=MtaaSuite

# Tigo SMS (Tanzania) - Contact Tigo Business API
TIGO_API_TOKEN=your_tigo_api_token_here
TIGO_SENDER_ID=MtaaSuite

# Twilio SMS (International) - Get from https://twilio.com/
TWILIO_ACCOUNT_SID=your_twilio_account_sid_here
TWILIO_AUTH_TOKEN=your_twilio_auth_token_here
TWILIO_PHONE_NUMBER=+1234567890
```

### 3. Set Firebase Environment Variables

```bash
# Set environment variables for Firebase Functions
firebase functions:config:set \
  beem.api_key="your_beem_api_key" \
  beem.secret_key="your_beem_secret_key" \
  beem.sender_name="MtaaSuite" \
  tigo.api_token="your_tigo_api_token" \
  tigo.sender_id="MtaaSuite" \
  twilio.account_sid="your_twilio_account_sid" \
  twilio.auth_token="your_twilio_auth_token" \
  twilio.phone_number="+1234567890"
```

### 4. Configure SMS Regions for Tanzania

```bash
# Configure Firebase Auth to allow SMS for Tanzania
node sms_region_config.js allowlist 255
```

### 5. Deploy Functions

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:sendOTP
```

## Available Functions

### `sendOTP(phoneNumber, customMessage?)`
- **Type**: Callable HTTPS function
- **Purpose**: Send OTP via multiple SMS providers with fallback
- **Parameters**: 
  - `phoneNumber`: Tanzania phone number in E.164 format (+255XXXXXXXXX)
  - `customMessage` (optional): Custom OTP message
- **Returns**: Success/failure status with provider information

### `verifyOTP(phoneNumber, otp)`
- **Type**: Callable HTTPS function  
- **Purpose**: Verify custom OTP (for non-Firebase Auth flows)
- **Parameters**:
  - `phoneNumber`: Phone number used to send OTP
  - `otp`: 6-digit OTP code
- **Returns**: Verification success/failure

### `healthCheck`
- **Type**: HTTP function
- **Purpose**: Service health check
- **URL**: `https://your-project.cloudfunctions.net/healthCheck`

### `checkSMSProviders` 
- **Type**: Callable HTTPS function
- **Purpose**: Check SMS provider configuration status
- **Returns**: Configuration status for each provider

## Client Integration

### Flutter/Dart Usage

```dart
// Call the sendOTP function
final callable = FirebaseFunctions.instance.httpsCallable('sendOTP');
try {
  final result = await callable.call({
    'phoneNumber': '+255712345678',
    'customMessage': 'Your MtaaSuite code is: {otp}'
  });
  
  print('SMS sent via: ${result.data['provider']}');
} catch (e) {
  print('SMS sending failed: $e');
}

// Verify OTP (if using custom flow)
final verifyCallable = FirebaseFunctions.instance.httpsCallable('verifyOTP');
try {
  final result = await verifyCallable.call({
    'phoneNumber': '+255712345678', 
    'otp': '123456'
  });
  
  if (result.data['success']) {
    print('OTP verified successfully');
  }
} catch (e) {
  print('OTP verification failed: $e');
}
```

## Phone Number Format

- **Required Format**: E.164 (+255XXXXXXXXX for Tanzania)
- **Examples**: 
  - ✅ `+255712345678`
  - ✅ `+255622345678` 
  - ❌ `0712345678`
  - ❌ `255712345678`

## SMS Provider Setup

### Beem SMS (Primary Tanzania Provider)
1. Register at [https://beem.africa/](https://beem.africa/)
2. Get API credentials from dashboard
3. Add credits to your account
4. Set sender name (e.g., "MtaaSuite")

### Tigo SMS (Secondary Tanzania Provider)  
1. Contact Tigo Business API team
2. Get API token and sender ID
3. Configure bulk SMS service

### Twilio (International Fallback)
1. Sign up at [https://twilio.com/](https://twilio.com/)
2. Get Account SID and Auth Token
3. Purchase phone number for SMS sending
4. Verify your account for international SMS

## Testing

### Test SMS Sending
```bash
# Test via Firebase CLI
firebase functions:shell

# In the shell, call:
sendOTP({phoneNumber: '+255712345678'})
```

### Test via HTTP
```bash
# Health check
curl https://your-project.cloudfunctions.net/healthCheck

# Check provider status (requires authentication)
curl -X POST https://your-project.cloudfunctions.net/checkSMSProviders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN"
```

## Troubleshooting

### Common Issues

1. **"SMS sending failed"**
   - Check environment variables are set
   - Verify SMS provider credentials
   - Check account balance/credits

2. **"Invalid Tanzania phone number"**
   - Ensure E.164 format: +255XXXXXXXXX
   - Phone must start with +255

3. **"Function not found"**
   - Ensure functions are deployed: `firebase deploy --only functions`
   - Check Firebase project is correct

4. **"Permission denied"**
   - Enable App Check for production
   - Verify Firebase Auth rules

### Logs and Monitoring

```bash
# View function logs
firebase functions:log

# View specific function logs
firebase functions:log --only sendOTP

# Real-time logs
firebase functions:log --follow
```

## Security Considerations

- Enable App Check for production deployment
- Set up proper security rules
- Monitor usage to prevent abuse
- Use Firebase Auth built-in SMS when possible
- Implement rate limiting for custom OTP flows

## Cost Optimization

- Firebase Auth SMS: ~$0.05 per SMS
- Beem SMS: Check current rates on Beem portal
- Tigo SMS: Contact Tigo for pricing
- Twilio SMS: ~$0.0075 per SMS (varies by region)

Use Firebase Auth built-in SMS as primary to minimize costs.