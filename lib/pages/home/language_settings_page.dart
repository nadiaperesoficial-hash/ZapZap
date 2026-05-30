import 'package:flutter/material.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  // Lista de idiomas suportados
  final List<Map<String, String>> languages = [
    {'name': 'English', 'native': 'English', 'code': 'en'},
    {'name': 'Portuguese', 'native': 'Português (Brasil)', 'code': 'pt-br'},
    {'name': 'Spanish', 'native': 'Español', 'code': 'es'},
    {'name': 'French', 'native': 'Français', 'code': 'fr'},
    {'name': 'German', 'native': 'Deutsch', 'code': 'de'},
    {'name': 'Italian', 'native': 'Italiano', 'code': 'it'},
  ];

  String _selectedCode = 'en'; // Idioma padrão

  @override
  void initState() {
    super.initState();
    // Aqui você pode carregar o idioma atual salvo no dispositivo/TDLib
    // _loadCurrentLanguage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
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

              // IMPLEMENTAÇÃO TDLib:
              // Aqui você enviaria a atualização para o TDLib
              // TDLibClient.setOption(name: "language_pack_id", value: _selectedCode);
              
              // Feedback visual rápido
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Idioma alterado para ${lang['name']}'),
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
