import 'package:flutter/material.dart';
import 'package:nullgram/pages/home/contacts_page.dart';
import 'package:nullgram/pages/home/settings_page.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

const _kGreen = Color(0xFF3DAF5C);
const _kGreenBg = Color(0xFFE8F5EC);
const _kHeaderBg = Color(0xFF1E2A3A);

class HomeMenu extends StatefulWidget {
  const HomeMenu({super.key});

  @override
  State<HomeMenu> createState() => _HomeMenuState();
}

class _HomeMenuState extends State<HomeMenu> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await TDLibClient.getMe();
      if (mounted) setState(() => _user = user);
    } catch (_) {}
  }

  String get _userName {
    if (_user == null) return 'ZapZap';
    final first = _user!['firstName'] ?? '';
    final last = _user!['lastName'] ?? '';
    return '$first $last'.trim();
  }

  String get _userPhone =>
      _user?['phoneNumber'] != null ? '+${_user!['phoneNumber']}' : '';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header azul escuro ────────────────────────────────
          Container(
            width: double.infinity,
            color: _kHeaderBg,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 24,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: _kGreen,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'Z',
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_userPhone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          _userPhone,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Itens ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 6),
              children: [
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Meu Perfil',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()));
                  },
                ),
                const _Divider(),
                _MenuItem(
                  icon: Icons.group_outlined,
                  title: 'Novo Grupo',
                  onTap: () => Navigator.pop(context),
                ),
                _MenuItem(
                  icon: Icons.campaign_outlined,
                  title: 'Novo Canal',
                  onTap: () => Navigator.pop(context),
                ),
                _MenuItem(
                  icon: Icons.person_add_outlined,
                  title: 'Contatos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ContactsPage()));
                  },
                ),
                _MenuItem(
                  icon: Icons.phone_outlined,
                  title: 'Chamadas',
                  onTap: () => Navigator.pop(context),
                ),
                _MenuItem(
                  icon: Icons.bookmark_outline_rounded,
                  title: 'Mensagens Salvas',
                  onTap: () => Navigator.pop(context),
                ),
                const _Divider(),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Configurações',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _kGreen, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111111),
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Color(0xFFF0F0F0),
    );
  }
}
