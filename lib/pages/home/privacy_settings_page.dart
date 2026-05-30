import 'package:flutter/material.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy and Security'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Privacy',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Phone Number'),
            subtitle: const Text('Visible to everyone'),
            value: true,
            onChanged: (bool value) {},
          ),
          SwitchListTile(
            title: const Text('Last Seen'),
            subtitle: const Text('My contacts'),
            value: true,
            onChanged: (bool value) {},
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Security',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Passcode Lock'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Adicione lógica de senha aqui
            },
          ),
          ListTile(
            title: const Text('Two-Step Verification'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Adicione lógica de verificação em duas etapas aqui
            },
          ),
        ],
      ),
    );
  }
}
