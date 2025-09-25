#!/usr/bin/env node
/* eslint-disable no-console */

/**
 * Firebase Auth SMS Region Configuration helper.
 *
 * Commands:
 *   node sms_region_config.js list
 *   node sms_region_config.js allowlist 255           # allow only Tanzania
 *   node sms_region_config.js allowlist 255 254 256   # allow TZ, KE, UG only
 *   node sms_region_config.js allowByDefault          # allow all (no block)
 *   node sms_region_config.js allowByDefault 86 91    # allow all except CN, IN
 *
 * Requirements:
 *   - Set GOOGLE_APPLICATION_CREDENTIALS to a Service Account JSON with
 *     firebaseauth.configs.update permission (Owner/Editor works).
 *   - Or run in a trusted environment with Application Default Credentials.
 */

const admin = require("firebase-admin");

if (!admin.apps.length) {
  try {
    admin.initializeApp();
  } catch (e) {
    console.error(
        "Failed to initialize Firebase Admin SDK. " +
        "Ensure credentials are set (GOOGLE_APPLICATION_CREDENTIALS).",
        e,
    );
    process.exit(1);
  }
}

const auth = admin.auth();

const USAGE = `
Usage:
  node sms_region_config.js list
  node sms_region_config.js allowlist <callingCodes...>
  node sms_region_config.js allowByDefault [blockedCallingCodes...]

Examples:
  node sms_region_config.js allowlist 255
  node sms_region_config.js allowlist 255 254 256
  node sms_region_config.js allowByDefault
  node sms_region_config.js allowByDefault 86 91
Notes:
  - Calling codes must be E.164 country calling codes WITHOUT "+"
    (e.g., 255 for Tanzania).
  - "allowlist" is the most restrictive (only listed regions can receive SMS).
  - "allowByDefault" allows all regions except the listed blocked ones.
`;

/**
 * Normalizes a list of E.164 country calling codes:
 * - Strips leading '+' if present
 * - Ensures only digits remain
 * - Filters out empties
 * @param {Array} args - Array of calling codes to normalize
 * @return {Array} - Normalized calling codes
 */
function normalizeCodes(args) {
  return (args || [])
      .map((x) => String(x).trim().replace(/^\+/, ""))
      .filter((x) => x.length > 0)
      .filter((x) => /^\d{1,6}$/.test(x)); // calling codes vary in length
}

/**
 * Lists current SMS region configuration.
 * @return {Promise<void>} - Promise that resolves when listing is complete
 */
async function listSmsRegionConfig() {
  const cfg = await auth.getProjectConfig();
  const sms = cfg.smsRegionConfig || {};
  console.log(JSON.stringify(sms, null, 2));
}

/**
 * Sets allowlist-only policy (only specified calling codes allowed).
 * Example: ["255"] for Tanzania.
 * @param {Array} codes - Array of calling codes to allow
 * @return {Promise<void>} - Promise that resolves when update is complete
 */
async function setAllowlistOnly(codes) {
  if (!Array.isArray(codes) || codes.length === 0) {
    throw new Error("allowlist requires at least one calling code (e.g., 255)");
  }
  // Some Admin SDK versions use "allowlistOnly"; this is the canonical field.
  await auth.updateProjectConfig({
    smsRegionConfig: {
      allowByDefault: false,
      allowlistOnly: codes,
    },
  });
}

/**
 * Sets allow-by-default policy (all allowed except specified blocked codes).
 * @param {Array} disallowed - Array of calling codes to disallow
 * @return {Promise<void>} - Promise that resolves when update is complete
 */
async function setAllowByDefault(disallowed) {
  await auth.updateProjectConfig({
    smsRegionConfig: {
      allowByDefault: true,
      disallowedRegions: Array.isArray(disallowed) ? disallowed : [],
    },
  });
}

/**
 * Orchestrator to call from CLI.
 * @return {Promise<void>} - Promise that resolves when config is complete
 */
async function configureSmsRegion() {
  const [cmd, ...rest] = process.argv.slice(2);

  switch (cmd) {
    case "list": {
      await listSmsRegionConfig();
      break;
    }
    case "allowlist": {
      let codes = normalizeCodes(rest);
      if (codes.length === 0) {
        // Default to Tanzania if not provided
        codes = ["255"];
      }
      await setAllowlistOnly(codes);
      console.log("Updated SMS Region Config to allowlist-only:", codes);
      await listSmsRegionConfig();
      break;
    }
    case "allowByDefault": {
      const blocked = normalizeCodes(rest);
      await setAllowByDefault(blocked);
      console.log(
          "Updated SMS Region Config to allow-by-default with blocklist:",
          blocked,
      );
      await listSmsRegionConfig();
      break;
    }
    default: {
      console.log(USAGE);
      process.exit(2);
    }
  }
}

// Entry
configureSmsRegion().catch((err) => {
  // If you see INVALID_ARGUMENT, your Admin SDK version may differ;
  // ensure firebase-admin is up-to-date or adjust field names accordingly.
  console.error("Failed to update/list SMS Region Config:", err);
  process.exit(1);
});

// Named exports (for clickable reference)
// You can import and call these if needed from elsewhere.
module.exports = {
  listSmsRegionConfig,
  setAllowlistOnly,
  setAllowByDefault,
  configureSmsRegion,
};
