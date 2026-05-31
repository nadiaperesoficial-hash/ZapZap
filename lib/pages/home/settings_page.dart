import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';
import 'package:nullgram/pages/home/language_settings_page.dart';
import 'package:nullgram/pages/home/privacy_settings_page.dart';

const _kGreen = Color(0xFF00BFA5);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  Color _wallpaper = const Color(0xFFBDC9D7);

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

  String get _userPhone =>
      _user?['phoneNumber'] != null ? '+${_user!['phoneNumber']}' : '';

  String get _username =>
      _user?['username'] != null ? '@${_user!['username']}' : '';

  void _navigate(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  // ── Mudar nome ──────────────────────────────────────────────
  void _editName() {
    final firstCtrl =
        TextEditingController(text: _user?['firstName'] ?? '');
    final lastCtrl =
        TextEditingController(text: _user?['lastName'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Mudar Nome',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111))),
          const SizedBox(height: 20),
          _inputField(firstCtrl, 'Nome'),
          const SizedBox(height: 12),
          _inputField(lastCtrl, 'Sobrenome'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                // TDLib updateProfile (não implementado no cliente base)
                setState(() {
                  if (_user != null) {
                    _user!['firstName'] = firstCtrl.text.trim();
                    _user!['lastName'] = lastCtrl.text.trim();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Salvar',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Criar/mudar username ────────────────────────────────────
  void _editUsername() {
    final ctrl = TextEditingController(
        text: _user?['username'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Criar Usuário',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111))),
          const SizedBox(height: 8),
          const Text(
            'Outras pessoas podem encontrar você pelo seu @username no Telegram.',
            style: TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E0E0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Text('@',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _kGreen)),
              ),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9_]')),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'seuusername',
                    hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 14),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() {
                  if (_user != null) {
                    _user!['username'] = ctrl.text.trim();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirmar',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Papel de parede ─────────────────────────────────────────
  void _changeWallpaper() {
    final colors = [
      {'name': 'Azul LINE', 'color': const Color(0xFFBDC9D7)},
      {'name': 'Verde suave', 'color': const Color(0xFFD4EDDA)},
      {'name': 'Bege', 'color': const Color(0xFFF5EFE6)},
      {'name': 'Lavanda', 'color': const Color(0xFFE8E0F0)},
      {'name': 'Cinza claro', 'color': const Color(0xFFF0F0F0)},
      {'name': 'Rosa suave', 'color': const Color(0xFFFDE8E8)},
      {'name': 'Amarelo suave', 'color': const Color(0xFFFFF8E1)},
      {'name': 'Branco', 'color': Colors.white},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Papel de Parede',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111))),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: colors.length,
            itemBuilder: (_, i) {
              final item = colors[i];
              final color = item['color'] as Color;
              final isSelected = _wallpaper == color;
              return GestureDetector(
                onTap: () {
                  setState(() => _wallpaper = color);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Papel de parede: ${item['name']}'),
                      backgroundColor: _kGreen,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Column(children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? _kGreen
                            : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: _kGreen, size: 22)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['name'] as String,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF888888)),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: Color(0xFFCCCCCC), fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Configurações',
            style: TextStyle(
                color: Color(0xFF111111),
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _kGreen))
          : ListView(children: [
              // ── Card de perfil ──────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  GestureDetector(
                    onTap: _editName,
                    child: Stack(children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: _kGreen,
                        child: Text(
                          _userName.isNotEmpty
                              ? _userName[0].toUpperCase()
                              : 'Z',
                          style: const TextStyle(
                              fontSize: 30,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: _kGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 13),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userName,
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111))),
                        if (_userPhone.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(_userPhone,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888))),
                        ],
                        if (_username.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(_username,
                              style: const TextStyle(
                                  fontSize: 13, color: _kGreen)),
                        ],
                      ],
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 10),

              // ── Seção: Meu Perfil ───────────────────────────
              _sectionHeader('MEU PERFIL'),
              Container(
                color: Colors.white,
                child: Column(children: [
                  _tile(Icons.edit_outlined, _kGreen,
                      'Mudar Nome', _editName),
                  _divider(),
                  _tile(Icons.alternate_email, const Color(0xFF42A5F5),
                      'Criar Usuário', _editUsername),
                  _divider(),
                  _tile(Icons.wallpaper_outlined,
                      const Color(0xFF26A69A),
                      'Papel de Parede', _changeWallpaper),
                ]),
              ),

              const SizedBox(height: 10),

              // ── Seção: App ──────────────────────────────────
              _sectionHeader('APP'),
              Container(
                color: Colors.white,
                child: Column(children: [
                  _tile(Icons.notifications_outlined, Colors.red,
                      'Notificações', () {}),
                  _divider(),
                  _tile(Icons.lock_outline, const Color(0xFF888888),
                      'Privacidade e Segurança',
                      () => _navigate(const PrivacySettingsPage())),
                  _divider(),
                  _tile(Icons.data_usage_outlined,
                      const Color(0xFF66BB6A),
                      'Dados e Armazenamento', () {}),
                  _divider(),
                  _tile(Icons.battery_charging_full_outlined,
                      Colors.orange, 'Economia de Energia', () {}),
                  _divider(),
                  _tile(Icons.language_outlined,
                      const Color(0xFF26A69A), 'Idioma',
                      () => _navigate(const LanguageSettingsPage()),
                      subtitle: 'Português (Brasil)'),
                ]),
              ),

              const SizedBox(height: 10),

              // ── Seção: Avançado ─────────────────────────────
              _sectionHeader('AVANÇADO'),
              Container(
                color: Colors.white,
                child: Column(children: [
                  _tile(Icons.devices_outlined,
                      const Color(0xFF5C6BC0),
                      'Dispositivos', () {}),
                  _divider(),
                  _tile(Icons.folder_outlined,
                      const Color(0xFFAB47BC),
                      'Pastas de Chat', () {}),
                  _divider(),
                  _tile(Icons.info_outline, const Color(0xFF42A5F5),
                      'Sobre o ZapZap', () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'ZapZap',
                      applicationVersion: '1.0.0',
                      applicationLegalese: '🇧🇷 Feito no Brasil',
                    );
                  }),
                ]),
              ),

              const SizedBox(height: 24),
            ]),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFAAAAAA),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _tile(IconData icon, Color color, String title,
      VoidCallback onTap,
      {String? subtitle}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111111))),
                if (subtitle != null)
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFAAAAAA))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right,
              color: Color(0xFFCCCCCC), size: 20),
        ]),
      ),
    );
  }

  Widget _divider() => const Divider(
      height: 1, indent: 68, color: Color(0xFFF0F0F0));
}
