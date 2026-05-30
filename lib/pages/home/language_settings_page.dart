import 'package:flutter/material.dart';
import 'package:nullgram/pages/home/app_strings.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  final List<Map<String, String>> languages = [
    {'name': 'English', 'native': 'English', 'code': 'en'},
    {'name': 'Português', 'native': 'Português (Brasil)', 'code': 'pt'},
    {'name': 'Español', 'native': 'Español', 'code': 'es'},
    {'name': 'Français', 'native': 'Français', 'code': 'fr'},
    {'name': 'Deutsch', 'native': 'Deutsch', 'code': 'de'},
    {'name': 'Italiano', 'native': 'Italiano', 'code': 'it'},
  ];

  String _selectedCode = AppStrings.currentLanguage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('language')),
        elevation: 0,
      ),
      body: ListView.separated(
        itemCount: languages.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = _selectedCode == lang['code'];

          return ListTile(
            title: Text(
              lang['name']!,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(lang['native']!),
            trailing: isSelected
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              setState(() {
                _selectedCode = lang['code']!;
              });
              AppStrings.setLanguage(lang['code']!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${AppStrings.get('language_changed')} ${lang['name']}'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
