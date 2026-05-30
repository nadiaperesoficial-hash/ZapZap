import 'package:flutter/material.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  final Map<String, String> _settings = {
    'Phone Number': 'Nobody',
    'Last Seen & Online': 'My Contacts',
    'Profile Photos': 'Everybody',
  };

  void _showOptions(String title) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              for (final option in ['Everybody', 'My Contacts', 'Nobody'])
                RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: _settings[title],
                  onChanged: (val) {
                    setState(() => _settings[title] = val!);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and Security')),
      body: ListView(
        children: [
          const _SectionHeader(title: 'PRIVACY'),
          for (final entry in _settings.entries)
            ListTile(
              title: Text(entry.key),
              subtitle: Text(entry.value),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showOptions(entry.key),
            ),
          const Divider(),
          const _SectionHeader(title: 'SECURITY'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Passcode Lock'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Two-Step Verification'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
