import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../theme_provider.dart';
import '../l10n/app_localizations.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final List<Map<String, String>> _languages = [
    {'name': 'English', 'code': 'en'},
    {'name': 'French', 'code': 'fr'},
    {'name': 'Germany', 'code': 'de'},
    {'name': 'Italian', 'code': 'it'},
    {'name': 'Korean', 'code': 'ko'},
    {'name': 'Hindi', 'code': 'hi'},
    {'name': 'Arabic', 'code': 'ar'},
    {'name': 'Russia', 'code': 'ru'},
    {'name': 'Spanish', 'code': 'es'},
    {'name': 'Gujarati', 'code': 'gu'},
    {'name': 'Bengali', 'code': 'bn'},
    {'name': 'Hebrew', 'code': 'he'},
    {'name': 'Urdu', 'code': 'ur'},
    {'name': 'Ukrainian', 'code': 'uk'},
    {'name': 'Dutch', 'code': 'nl'},
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    String currentLangCode = themeProvider.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('language'), style: const TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _languages.length,
        itemBuilder: (context, index) {
          final lang = _languages[index];
          bool isSelected = currentLangCode == lang['code'];

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: InkWell(
              onTap: () {
                themeProvider.setLanguage(lang['code']!);
              },
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isSelected
                          ? Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    lang['name']!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                      color: AppTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
