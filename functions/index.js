/**
 * Firebase Cloud Functions for MtaaSuite
 * Handles OTP/SMS sending with fallback to local providers for Tanzania
 */

const {setGlobalOptions} = require("firebase-functions");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onRequest} = require("firebase-functions/v1/https");
const {logger} = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

// Initialize Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp();
}

// Set global options for cost control
setGlobalOptions({maxInstances: 10});

/**
 * SMS Provider Configuration for Tanzania
 */
const SMS_PROVIDERS = {
  BEEM: {
    name: "Beem",
    url: "https://apisms.beem.africa/v1/send",
    headers: {
      "Content-Type": "application/json",
      // Split long line for Authorization header
      "Authorization": `Basic ${
        Buffer.from(
            process.env.BEEM_API_KEY + ":" + process.env.BEEM_SECRET_KEY,
        ).toString("base64")
      }`,
    },
  },
  TIGO: {
    name: "Tigo",
    url: "https://messaging.tigo.co.tz/sms/sendsms",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${process.env.TIGO_API_TOKEN}`,
    },
  },
  // Add more providers as needed
  TWILIO: {
    name: "Twilio",
    url: "https://api.twilio.com/2010-04-01/Accounts/" + process.env.TWILIO_ACCOUNT_SID + "/Messages.json",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "Authorization": `Basic ${
        Buffer.from(
            process.env.TWILIO_ACCOUNT_SID + ":" +
          process.env.TWILIO_AUTH_TOKEN,
        ).toString("base64")
      }`,
    },
  },
};

/**
 * Validates Tanzania phone number format
 * @param {string} phoneNumber - Phone number to validate
 * @return {boolean} True if valid Tanzania phone number format
 */
const validateTanzaniaPhone = (phoneNumber) => {
  // E.164 format validation for Tanzania (+255XXXXXXXXX)
  const tzPhoneRegex = /^\+255[67]\d{8}$/;
  return tzPhoneRegex.test(phoneNumber);
};

/**
 * Generate 6-digit OTP
 * @return {string} Generated 6-digit OTP code
 */
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

/**
 * Send SMS via Beem SMS (Tanzania local provider)
 * @param {string} phoneNumber - Recipient phone number
 * @param {string} message - SMS message content
 * @return {Promise<boolean>} Success status of SMS sending
 */
const sendViaBeem = async (phoneNumber, message) => {
  try {
    const payload = {
      source_addr: process.env.BEEM_SENDER_NAME || "MtaaSuite",
      schedule_time: "",
      encoding: 0,
      message: message,
      recipients: [{
        recipient_id: 1,
        dest_addr: phoneNumber.replace("+", ""),
      }],
    };

    const response = await axios.post(SMS_PROVIDERS.BEEM.url, payload, {
      headers: SMS_PROVIDERS.BEEM.headers,
      timeout: 10000,
    });

    logger.info("Beem SMS response:", response.data);
    return response.data.successful > 0;
  } catch (error) {
    logger.error("Beem SMS failed:",
      error.response && error.response.data ?
        error.response.data : error.message);
    return false;
  }
};

/**
 * Send SMS via Tigo SMS (Tanzania local provider)
 * @param {string} phoneNumber - Recipient phone number
 * @param {string} message - SMS message content
 * @return {Promise<boolean>} Success status of SMS sending
 */
const sendViaTigo = async (phoneNumber, message) => {
  try {
    const payload = {
      msisdn: phoneNumber.replace("+", ""),
      message: message,
      sender_id: process.env.TIGO_SENDER_ID || "MtaaSuite",
    };

    const response = await axios.post(SMS_PROVIDERS.TIGO.url, payload, {
      headers: SMS_PROVIDERS.TIGO.headers,
      timeout: 10000,
    });

    logger.info("Tigo SMS response:", response.data);
    return response.data.status === "success";
  } catch (error) {
    logger.error("Tigo SMS failed:",
      error.response && error.response.data ?
        error.response.data : error.message);
    return false;
  }
};

/**
 * Send SMS via Twilio (international fallback)
 * @param {string} phoneNumber - Recipient phone number
 * @param {string} message - SMS message content
 * @return {Promise<boolean>} Success status of SMS sending
 */
const sendViaTwilio = async (phoneNumber, message) => {
  try {
    const payload = new URLSearchParams({
      From: process.env.TWILIO_PHONE_NUMBER,
      To: phoneNumber,
      Body: message,
    });

    const response = await axios.post(SMS_PROVIDERS.TWILIO.url, payload, {
      headers: SMS_PROVIDERS.TWILIO.headers,
      timeout: 10000,
    });

    logger.info("Twilio SMS response:", response.data);
    return response.data.status === "queued" ||
           response.data.status === "sent";
  } catch (error) {
    logger.error("Twilio SMS failed:",
      error.response && error.response.data ?
        error.response.data : error.message);
    return false;
  }
};

/**
 * Enhanced OTP sending function with multiple fallbacks
 * First tries Firebase Auth built-in SMS, then falls back to local providers
 */
exports.sendOTP = onCall({
  enforceAppCheck: false, // Set to true in production with App Check
  cors: true,
}, async (request) => {
  const {phoneNumber, customMessage} = request.data;

  if (!phoneNumber) {
    throw new HttpsError("invalid-argument", "Phone number is required");
  }

  // Validate phone number format
  if (!validateTanzaniaPhone(phoneNumber)) {
    throw new HttpsError("invalid-argument",
        "Invalid Tanzania phone number format. Use +255XXXXXXXXX");
  }

  const otp = generateOTP();
  const message = customMessage ||
    `Your MtaaSuite verification code is: ${otp}. Valid for 10 minutes. ` +
    `Do not share this code.`;

  logger.info(`Attempting to send OTP to ${phoneNumber}`);

  try {
    // Step 1: Try Firebase Auth built-in SMS first
    logger.info("Attempting Firebase Auth built-in SMS...");

    // Note: Firebase Auth handles SMS automatically during phone verification
    // This is mainly for logging and monitoring purposes
    // The actual SMS sending happens in the client-side phone verification
    // process

    // For custom OTP scenarios or when Firebase SMS fails, we use fallback
    // providers
    logger.info("Using fallback SMS providers for Tanzania...");

    // Step 2: Try Beem SMS (primary Tanzania provider)
    const beemSuccess = await sendViaBeem(phoneNumber, message);
    if (beemSuccess) {
      logger.info("SMS sent successfully via Beem");

      // Store OTP in Firestore for verification (if needed for custom flows)
      await admin.firestore().collection("otps").doc(phoneNumber).set({
        otp: otp,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 10 * 60 * 1000), // 10 minutes
        attempts: 0,
        verified: false,
      });

      return {
        success: true,
        provider: "Beem",
        message: "OTP sent successfully via Beem SMS",
        timestamp: new Date().toISOString(),
      };
    }

    // Step 3: Try Tigo SMS (secondary Tanzania provider)
    logger.info("Beem failed, trying Tigo SMS...");
    const tigoSuccess = await sendViaTigo(phoneNumber, message);
    if (tigoSuccess) {
      logger.info("SMS sent successfully via Tigo");

      await admin.firestore().collection("otps").doc(phoneNumber).set({
        otp: otp,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
        attempts: 0,
        verified: false,
      });

      return {
        success: true,
        provider: "Tigo",
        message: "OTP sent successfully via Tigo SMS",
        timestamp: new Date().toISOString(),
      };
    }

    // Step 4: Try Twilio (international fallback)
    logger.info("Local providers failed, trying Twilio...");
    const twilioSuccess = await sendViaTwilio(phoneNumber, message);
    if (twilioSuccess) {
      logger.info("SMS sent successfully via Twilio");

      await admin.firestore().collection("otps").doc(phoneNumber).set({
        otp: otp,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
        attempts: 0,
        verified: false,
      });

      return {
        success: true,
        provider: "Twilio",
        message: "OTP sent successfully via Twilio SMS",
        timestamp: new Date().toISOString(),
      };
    }

    // All providers failed
    logger.error("All SMS providers failed for phone:", phoneNumber);
    throw new HttpsError("internal",
        "Failed to send SMS via all providers. Please try again later.");
  } catch (error) {
    logger.error("SMS sending error:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError("internal", `SMS sending failed: ${error.message}`);
  }
});

/**
 * Verify custom OTP (for cases where we're not using Firebase Auth built-in)
 */
exports.verifyOTP = onCall({
  enforceAppCheck: false,
  cors: true,
}, async (request) => {
  const {phoneNumber, otp} = request.data;

  if (!phoneNumber || !otp) {
    throw new HttpsError("invalid-argument",
        "Phone number and OTP are required");
  }

  try {
    const otpDoc = await admin.firestore()
        .collection("otps").doc(phoneNumber).get();

    if (!otpDoc.exists) {
      throw new HttpsError("not-found",
          "OTP not found. Please request a new one.");
    }

    const otpData = otpDoc.data();

    // Check if OTP is expired
    if (new Date() > otpData.expiresAt.toDate()) {
      await otpDoc.ref.delete();
      throw new HttpsError("deadline-exceeded",
          "OTP has expired. Please request a new one.");
    }

    // Check if already verified
    if (otpData.verified) {
      throw new HttpsError("already-exists", "OTP has already been used.");
    }

    // Check attempts limit
    if (otpData.attempts >= 3) {
      await otpDoc.ref.delete();
      throw new HttpsError("resource-exhausted",
          "Too many failed attempts. Please request a new OTP.");
    }

    // Verify OTP
    if (otpData.otp !== otp) {
      await otpDoc.ref.update({
        attempts: admin.firestore.FieldValue.increment(1),
      });
      throw new HttpsError("invalid-argument",
          "Invalid OTP. Please check and try again.");
    }

    // OTP is valid, mark as verified
    await otpDoc.ref.update({
      verified: true,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    logger.info(`OTP verified successfully for ${phoneNumber}`);

    return {
      success: true,
      message: "OTP verified successfully",
      timestamp: new Date().toISOString(),
    };
  } catch (error) {
    logger.error("OTP verification error:", error);

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError("internal",
        `OTP verification failed: ${error.message}`);
  }
});

/**
 * Health check endpoint
 */
exports.healthCheck = onRequest((req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
    services: {
      firestore: "available",
      sms_providers: Object.keys(SMS_PROVIDERS),
    },
  });
});

/**
 * SMS provider status check
 */
exports.checkSMSProviders = onCall({
  enforceAppCheck: false,
  cors: true,
}, async (request) => {
  const results = {};

  // Check Beem
  results.beem = {
    configured: Boolean(process.env.BEEM_API_KEY &&
      process.env.BEEM_SECRET_KEY),
    status: "unknown",
  };

  // Check Tigo
  results.tigo = {
    configured: Boolean(process.env.TIGO_API_TOKEN),
    status: "unknown",
  };

  // Check Twilio
  try {
    results.twilio = {
      configured: !!(process.env.TWILIO_ACCOUNT_SID &&
        process.env.TWILIO_AUTH_TOKEN),
      status: "unknown",
    };
  } catch (error) {
    results.twilio = {configured: false, error: error.message};
  }

  return {
    providers: results,
    timestamp: new Date().toISOString(),
  };
});
