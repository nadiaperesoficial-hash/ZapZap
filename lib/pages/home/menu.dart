import 'package:flutter/material.dart';
import 'package:nullgram/pages/home/contacts_page.dart';
import 'package:nullgram/pages/home/groups_page.dart';
import 'package:nullgram/pages/home/settings_page.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

const _kGreen = Color(0xFF00BFA5);

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

  String get _userPhone => _user?['phoneNumber'] != null
      ? '+${_user!['phoneNumber']}'
      : '';

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header verde estilo LINE ──────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kGreen, Color(0xFF008E76)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      _userName.isNotEmpty
                          ? _userName[0].toUpperCase()
                          : 'Z',
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Nome e telefone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_userPhone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          _userPhone,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Itens do menu ─────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _MenuItem(
                  icon: Icons.person_outline,
                  color: _kGreen,
                  title: 'Meu Perfil',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsPage()),
                    );
                  },
                ),
                const _Divider(),
                _MenuItem(
                  icon: Icons.group_outlined,
                  color: const Color(0xFF42A5F5),
                  title: 'Novo Grupo',
                  onTap: () => Navigator.pop(context),
                ),
                _MenuItem(
                  icon: Icons.campaign_outlined,
                  color: const Color(0xFF26A69A),
                  title: 'Novo Canal',
                  onTap: () => Navigator.pop(context),
                ),
                _MenuItem(
                  icon: Icons.person_add_outlined,
                  color: const Color(0xFF5C6BC0),
                  title: 'Contatos',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ContactsPage()),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.phone_outlined,
                  color: const Color(0xFF66BB6A),
                  title: 'Chamadas',
                  onTap: () => Navigator.pop(context),
                ),
                _MenuItem(
                  icon: Icons.bookmark_outline,
                  color: const Color(0xFFFF7043),
                  title: 'Mensagens Salvas',
                  onTap: () => Navigator.pop(context),
                ),
                const _Divider(),
                // ZapGrupos destaque
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GroupsPage()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _kGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.groups,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'ZapGrupos',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                              ),
                            ),
                            Text(
                              'Grupos públicos brasileiros',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFAAAAAA)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const _Divider(),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  color: const Color(0xFF888888),
                  title: 'Configurações',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsPage()),
                    );
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
  final Color color;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111111),
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
        height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F0F0));
  }
}
