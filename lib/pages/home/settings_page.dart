import 'package:flutter/material.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

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
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
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

  String get _userPhone {
    return _user?['phoneNumber'] != null
        ? '+${_user!['phoneNumber']}'
        : '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'Z',
                          style: const TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_userPhone.isNotEmpty)
                              Text(
                                _userPhone,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _buildTile(
                  icon: Icons.notifications,
                  color: Colors.red,
                  title: 'Notifications and Sounds',
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.lock,
                  color: Colors.grey,
                  title: 'Privacy and Security',
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.data_usage,
                  color: Colors.green,
                  title: 'Data and Storage',
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.battery_charging_full,
                  color: Colors.orange,
                  title: 'Battery Saving',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildTile(
                  icon: Icons.palette,
                  color: Colors.blue,
                  title: 'Appearance',
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.language,
                  color: Colors.teal,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildTile(
                  icon: Icons.devices,
                  color: Colors.indigo,
                  title: 'Devices',
                  onTap: () {},
                ),
                _buildTile(
                  icon: Icons.folder,
                  color: Colors.purple,
                  title: 'Chat Folders',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildTile(
                  icon: Icons.info,
                  color: Colors.blue,
                  title: 'About ZapZap',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'ZapZap',
                      applicationVersion: '1.0.0',
                    );
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
