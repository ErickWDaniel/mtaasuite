import 'package:flutter/material.dart';
import 'package:mtaasuite/services/translation_service.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String languageCode) async {
        await TranslationService.instance.changeLanguage(languageCode);
        // Force rebuild of the entire app
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => _buildAppWithNewLanguage()),
          );
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'en', // Fixed: changed from 'eng' to 'en'
          child: Row(
            children: [
              Text('🇺🇸'),
              const SizedBox(width: 8),
              Text(tr('common.language_english')),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'sw',
          child: Row(
            children: [
              Text('🇹🇿'),
              const SizedBox(width: 8),
              Text(tr('common.language_swahili')),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(Icons.language, color: Theme.of(context).iconTheme.color),
            const SizedBox(width: 4),
            Text(
              TranslationService.instance.currentLocale?.languageCode == 'sw'
                  ? '🇹🇿 SW'
                  : '🇺🇸 EN',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppWithNewLanguage() {
    // This would typically rebuild your main app widget
    // For now, we'll return a placeholder
    return const Scaffold(
      body: Center(
        child: Text('Language changed. Please restart the app.'),
      ),
    );
  }
}