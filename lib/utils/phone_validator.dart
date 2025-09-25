/// Tanzanian mobile number validator/normalizer for Firebase Phone Auth.
///
/// Valid operators/prefixes covered:
/// - Vodacom: 074x, 075x, 076x
/// - Tigo:    065x, 067x, 071x
/// - Airtel:  068x, 078x
/// - Halotel: 062x
/// - TTCL:    073x
/// - Zantel:  077x
///
/// Accepted input examples (all normalize to E.164 +255…):
///   "0754 123 456"   -> "+255754123456"
///   "+255754123456"  -> "+255754123456"
///   "255754123456"   -> "+255754123456"
///   "754123456"      -> "+255754123456"
///
/// Usage (before FirebaseAuth.verifyPhoneNumber):
///   final e164 = TzPhone.normalizeTzMsisdn(userInput);
///   if (e164 == null) {
///     // Show validation error
///   } else {
///     await FirebaseAuth.instance.verifyPhoneNumber(phoneNumber: e164);
///   }
class TzPhone {
  // Strict E.164 for Firebase: copy-paste friendly.
  // Matches only allowed TZ mobile operator ranges.
  static const String e164StrictPattern =
      r'^\+255(?:74[0-9]|75[0-9]|76[0-9]|65[0-9]|67[0-9]|71[0-9]|68[0-9]|78[0-9]|62[0-9]|73[0-9]|77[0-9])[0-9]{6}$';
  static final RegExp e164Strict = RegExp(e164StrictPattern);

  // E.164 digits without plus (e.g., "255754123456") — normalized by adding "+".
  static const String e164NoPlusPattern =
      r'^255(?:74[0-9]|75[0-9]|76[0-9]|65[0-9]|67[0-9]|71[0-9]|68[0-9]|78[0-9]|62[0-9]|73[0-9]|77[0-9])[0-9]{6}$';
  static final RegExp e164NoPlus = RegExp(e164NoPlusPattern);

  // National (local) format: "0" followed by 9 digits from allowed ranges.
  static const String nationalPattern =
      r'^0(?:74[0-9]|75[0-9]|76[0-9]|65[0-9]|67[0-9]|71[0-9]|68[0-9]|78[0-9]|62[0-9]|73[0-9]|77[0-9])[0-9]{6}$';
  static final RegExp national = RegExp(nationalPattern);

  // Bare 9-digit local (no leading "0"), e.g., "754123456".
  static const String bareLocalPattern =
      r'^(?:74[0-9]|75[0-9]|76[0-9]|65[0-9]|67[0-9]|71[0-9]|68[0-9]|78[0-9]|62[0-9]|73[0-9]|77[0-9])[0-9]{6}$';
  static final RegExp bareLocal = RegExp(bareLocalPattern);

  // Convenience patterns to paste in form validators:
  // - Strict E.164 (recommended for final phoneNumber to Firebase):
  static const String strictE164CopyPaste = e164StrictPattern;
  // - Accept either +255… or 0… (useful pre-validation before normalization):
  static const String dualModeCopyPaste =
      r'^(?:\+255|0)(?:74[0-9]|75[0-9]|76[0-9]|65[0-9]|67[0-9]|71[0-9]|68[0-9]|78[0-9]|62[0-9]|73[0-9]|77[0-9])[0-9]{6}$';

  // Remove spacing, punctuation, convert leading "00" to "+".
  static String _clean(String input) {
    var s = input.trim();
    s = s.replaceAll(RegExp(r'[\s\-\.\(\)]'), '');
    if (s.startsWith('00')) s = '+${s.substring(2)}';
    return s;
  }

  /// Returns true if `input` is a valid Tanzanian mobile number according to
  /// the allowed operator ranges. When `requireE164` is true, only "+255…" passes.
  static bool isValidTzMobile(String input, {bool requireE164 = false}) {
    final s = _clean(input);
    if (requireE164) return e164Strict.hasMatch(s);

    return e164Strict.hasMatch(s) || // +255…
        e164NoPlus.hasMatch(s) || // 255…
        national.hasMatch(s) || // 0…
        bareLocal.hasMatch(s); // 9-digit bare
  }

  /// Normalizes to E.164 (+255…) or returns null if invalid.
  static String? normalizeTzMsisdn(String input) {
    var s = _clean(input);
    if (e164Strict.hasMatch(s)) {
      return s; // already E.164
    }
    if (e164NoPlus.hasMatch(s)) {
      return '+$s';
    }
    if (national.hasMatch(s)) {
      return '+255${s.substring(1)}';
    }
    if (bareLocal.hasMatch(s)) {
      return '+255$s';
    }
    return null;
  }
}
