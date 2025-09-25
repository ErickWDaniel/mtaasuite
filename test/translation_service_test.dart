import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtaasuite/services/translation_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TranslationService', () {
    late TranslationService service;

    setUp(() {
      service = TranslationService.instance;
    });

    test('singleton instance returns the same object', () {
      final instance1 = TranslationService.instance;
      final instance2 = TranslationService.instance;
      expect(instance1, same(instance2));
    });

    test('initialize loads translations correctly', () async {
      const mockTranslations = '{"app": {"title": "Test App", "loading": "Loading..."}}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          if (message != null && String.fromCharCodes(message.buffer.asUint8List()) == 'assets/translation/en.json') {
            return ByteData.sublistView(Uint8List.fromList(mockTranslations.codeUnits));
          }
          return null;
        },
      );

      await service.initialize(const Locale('en'));

      expect(service.tr('app.title'), 'Test App');
      expect(service.tr('app.loading'), 'Loading...');
    });

    test('tr returns key if translation not found', () {
      expect(service.tr('nonexistent.key'), 'nonexistent.key');
    });

    test('tr handles nested keys', () async {
      const mockTranslations = '{"app": {"nested": {"title": "Nested Title"}}}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          if (message != null && String.fromCharCodes(message.buffer.asUint8List()) == 'assets/translation/en.json') {
            return ByteData.sublistView(Uint8List.fromList(mockTranslations.codeUnits));
          }
          return null;
        },
      );

      await service.initialize(const Locale('en'));

      expect(service.tr('app.nested.title'), 'Nested Title');
    });

    test('tr replaces arguments correctly', () async {
      const mockTranslations = '{"greeting": "Hello {name}!"}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          if (message != null && String.fromCharCodes(message.buffer.asUint8List()) == 'assets/translation/en.json') {
            return ByteData.sublistView(Uint8List.fromList(mockTranslations.codeUnits));
          }
          return null;
        },
      );

      await service.initialize(const Locale('en'));

      expect(service.tr('greeting', args: {'name': 'World'}), 'Hello World!');
    });

    test('hasTranslation returns true for existing key', () async {
      const mockTranslations = '{"test": "value"}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          if (message != null && String.fromCharCodes(message.buffer.asUint8List()) == 'assets/translation/en.json') {
            return ByteData.sublistView(Uint8List.fromList(mockTranslations.codeUnits));
          }
          return null;
        },
      );

      await service.initialize(const Locale('en'));

      expect(service.hasTranslation('test'), true);
    });

    test('hasTranslation returns false for non-existing key', () async {
      const mockTranslations = '{"test": "value"}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          if (message != null && String.fromCharCodes(message.buffer.asUint8List()) == 'assets/translation/en.json') {
            return ByteData.sublistView(Uint8List.fromList(mockTranslations.codeUnits));
          }
          return null;
        },
      );

      await service.initialize(const Locale('en'));

      expect(service.hasTranslation('nonexistent'), false);
    });

    test('changeLanguage updates locale and translations', () async {
      const engTranslations = '{"lang": "English"}';
      const swTranslations = '{"lang": "Swahili"}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          final path = String.fromCharCodes(message!.buffer.asUint8List());
          if (path == 'assets/translation/en.json') {
            return ByteData.sublistView(Uint8List.fromList(engTranslations.codeUnits));
          } else if (path == 'assets/translation/sw.json') {
            return ByteData.sublistView(Uint8List.fromList(swTranslations.codeUnits));
          }
          return null;
        },
      );

      await service.initialize(const Locale('en'));
      expect(service.tr('lang'), 'English');

      await service.changeLanguage('sw');
      expect(service.tr('lang'), 'Swahili');
    });

    test('initialize falls back to English if translation file not found', () async {
      const engTranslations = '{"fallback": "English Fallback"}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          final path = String.fromCharCodes(message!.buffer.asUint8List());
          if (path == 'assets/translation/en.json') {
            return ByteData.sublistView(Uint8List.fromList(engTranslations.codeUnits));
          }
          // Return null for other languages to simulate file not found
          return null;
        },
      );

      await service.initialize(const Locale('unknown'));
      expect(service.tr('fallback'), 'English Fallback');
    });
  });

  group('Global tr function', () {
    test('tr function uses TranslationService instance', () async {
      const mockTranslations = '{"test": "Global Test"}';

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets',
        (ByteData? message) async {
          if (message != null && String.fromCharCodes(message.buffer.asUint8List()) == 'assets/translation/en.json') {
            return ByteData.sublistView(Uint8List.fromList(mockTranslations.codeUnits));
          }
          return null;
        },
      );

      await TranslationService.instance.initialize(const Locale('en'));

      expect(tr('test'), 'Global Test');
    });
  });
}