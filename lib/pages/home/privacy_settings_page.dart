import 'package:flutter/material.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

class PrivacySettingsPage extends StatelessWidget {
  const PrivacySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and Security')),
      body: ListView(
        children: [
          const SectionHeader(title: 'PRIVACY'),
          // No Telegram, você define regras para quem pode ver
          // Phone Number, Last Seen, etc.
          _buildPrivacyOption(context, 'Phone Number', 'Everybody'),
          _buildPrivacyOption(context, 'Last Seen & Online', 'My contacts'),
          _buildPrivacyOption(context, 'Profile Photos', 'Everybody'),
          const Divider(),
          const SectionHeader(title: 'SECURITY'),
          ListTile(
            title: const Text('Passcode Lock'),
            leading: const Icon(Icons.lock_outline),
            onTap: () {
              // Aqui você chamaria o método setPasscode no seu TDLibClient
            },
          ),
          ListTile(
            title: const Text('Two-Step Verification'),
            leading: const Icon(Icons.verified_user),
            onTap: () {
              // Aqui chamaria checkAuthenticationPassword ou similar
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption(BuildContext context, String title, String subtitle) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // No Telegram, ao clicar aqui, você abre uma tela para escolher:
        // Everybody, My Contacts, or Nobody
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
    );
  }
}
