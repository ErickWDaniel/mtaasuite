import 'package:flutter_test/flutter_test.dart';
import 'package:mtaasuite/utils/phone_validator.dart';

void main() {
  group('TzPhone.normalizeTzMsisdn', () {
    test('accepts Vodacom 076x in E.164 format', () {
      final s = TzPhone.normalizeTzMsisdn('+255764123456');
      expect(s, '+255764123456');
    });

    test('accepts Vodacom 076x without plus (255...)', () {
      final s = TzPhone.normalizeTzMsisdn('255764123456');
      expect(s, '+255764123456');
    });

    test('accepts national 076x (0...)', () {
      final s = TzPhone.normalizeTzMsisdn('0764123456');
      expect(s, '+255764123456');
    });

    test('accepts bare local 76x (9 digits)', () {
      final s = TzPhone.normalizeTzMsisdn('764123456');
      expect(s, '+255764123456');
    });

    test('rejects invalid 079x', () {
      final s = TzPhone.normalizeTzMsisdn('0794123456');
      expect(s, isNull);
    });
  });

  group('TzPhone.isValidTzMobile', () {
    test('true for +255764123456 with requireE164', () {
      expect(
        TzPhone.isValidTzMobile('+255764123456', requireE164: true),
        isTrue,
      );
    });

    test('false for +255079123456 with requireE164', () {
      expect(
        TzPhone.isValidTzMobile('+255791234567', requireE164: true),
        isFalse,
      );
    });
  });

  group('TzPhone.dualModeCopyPaste regex', () {
    test('matches +255764123456', () {
      final re = RegExp(TzPhone.dualModeCopyPaste);
      expect(re.hasMatch('+255764123456'), isTrue);
    });

    test('matches 0764123456', () {
      final re = RegExp(TzPhone.dualModeCopyPaste);
      expect(re.hasMatch('0764123456'), isTrue);
    });
  });
}
