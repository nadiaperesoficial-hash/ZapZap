import 'package:flutter/material.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';
import 'package:nullgram/pages/home/app_strings.dart';
import 'package:nullgram/pages/home/language_settings_page.dart';
import 'package:nullgram/pages/home/privacy_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await TDLibClient.getMe();
      if (mounted) setState(() { _user = user; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _userName {
    if (_user == null) return 'ZapZap';
    final first = _user!['firstName'] ?? '';
    final last = _user!['lastName'] ?? '';
    return '$first $last'.trim();
  }

  String get _userPhone => _user?['phoneNumber'] != null ? '+${_user!['phoneNumber']}' : '';

  void _navigate(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('settings'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'Z',
                      style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (_userPhone.isNotEmpty)
                      Text(_userPhone, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ])),
                  IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
                ]),
              ),
              const Divider(height: 1),
              _tile(Icons.notifications, Colors.red, AppStrings.get('notifications'), () {}),
              _tile(Icons.lock, Colors.grey, AppStrings.get('privacy'), () => _navigate(const PrivacySettingsPage())),
              _tile(Icons.data_usage, Colors.green, AppStrings.get('data_storage'), () {}),
              _tile(Icons.battery_charging_full, Colors.orange, AppStrings.get('battery'), () {}),
              const Divider(height: 1),
              _tile(Icons.palette, Colors.blue, AppStrings.get('appearance'), () {}),
              _tile(Icons.language, Colors.teal, AppStrings.get('language'), () => _navigate(const LanguageSettingsPage()), subtitle: 'English'),
              const Divider(height: 1),
              _tile(Icons.devices, Colors.indigo, AppStrings.get('devices'), () {}),
              _tile(Icons.folder, Colors.purple, AppStrings.get('chat_folders'), () {}),
              const Divider(height: 1),
              _tile(Icons.info, Colors.blue, AppStrings.get('about'), () {
                showAboutDialog(context: context, applicationName: 'ZapZap', applicationVersion: '1.0.0');
              }),
            ]),
    );
  }

  Widget _tile(IconData icon, Color color, String title, VoidCallback onTap, {String? subtitle}) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
