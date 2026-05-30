import 'package:flutter/material.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  // Lista de idiomas suportados (simulando a estrutura do Telegram)
  final List<Map<String, String>> languages = [
    {'name': 'English', 'native': 'English', 'code': 'en'},
    {'name': 'Portuguese', 'native': 'Português (Brasil)', 'code': 'pt-br'},
    {'name': 'Spanish', 'native': 'Español', 'code': 'es'},
    {'name': 'Russian', 'native': 'Русский', 'code': 'ru'},
  ];

  String selectedCode = 'en'; // Código padrão

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Language'),
      ),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          return ListTile(
            title: Text(lang['name']!),
            subtitle: Text(lang['native']!),
            trailing: selectedCode == lang['code']
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              setState(() {
                selectedCode = lang['code']!;
              });
              // AQUI VOCÊ CHAMARIA O TDLib PARA MUDAR O IDIOMA
              // Ex: TDLibClient.setOption(name: "language_pack_id", value: selectedCode);
              
              // Feedback visual
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language changed to ${lang['name']}')),
              );
            },
          );
        },
      ),
    );
  }
}
a
