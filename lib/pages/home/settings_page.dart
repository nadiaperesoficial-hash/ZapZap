import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';
import 'package:nullgram/pages/home/language_settings_page.dart';
import 'package:nullgram/pages/home/privacy_settings_page.dart';

const _kGreen = Color(0xFF00BFA5);
const _kIconColor = Color(0xFF1E2A3A); // Azul escuro LINE
const _kBg = Color(0xFFF0F0F0);
const _kText = Color(0xFF111111);
const _kSub = Color(0xFF888888);
const _kDivider = Color(0xFFEEEEEE);

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

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (picked == null) return;
    try {
      await TDLibClient.sendRaw({
        "@type": "setProfilePhoto",
        "photo": {
          "@type": "inputChatPhotoStatic",
          "photo": {"@type": "inputFileLocal", "path": picked.path},
        },
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Foto atualizada!'), backgroundColor: _kGreen));
        _loadUser();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')));
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

  void _editName() {
    final firstCtrl = TextEditingController(text: _user?['firstName'] ?? '');
    final lastCtrl = TextEditingController(text: _user?['lastName'] ?? '');
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _handle(),
          const SizedBox(height: 16),
          const Text('Mudar Nome', style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: _kText)),
          const SizedBox(height: 20),
          _inputField(firstCtrl, 'Nome'),
          const SizedBox(height: 12),
          _inputField(lastCtrl, 'Sobrenome'),
          const SizedBox(height: 20),
          _saveButton('Salvar', () {
            Navigator.pop(context);
            setState(() {
              _user?['firstName'] = firstCtrl.text.trim();
              _user?['lastName'] = lastCtrl.text.trim();
            });
          }),
        ]),
      ),
    );
  }

  void _editUsername() {
    final ctrl = TextEditingController(text: _user?['username'] ?? '');
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _handle(),
          const SizedBox(height: 16),
          const Text('Criar Usuário', style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: _kText)),
          const SizedBox(height: 6),
          const Text('Outras pessoas podem encontrar você pelo @username.',
              style: TextStyle(fontSize: 13, color: _kSub),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
                border: Border.all(color: _kDivider),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Padding(padding: EdgeInsets.only(left: 14),
                  child: Text('@', style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: _kGreen))),
              Expanded(child: TextField(
                controller: ctrl,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]'))],
                decoration: const InputDecoration(
                  hintText: 'seuusername',
                  hintStyle: TextStyle(color: Color(0xFFCCCCCC)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14)),
              )),
            ]),
          ),
          const SizedBox(height: 20),
          _saveButton('Confirmar', () {
            Navigator.pop(context);
            setState(() => _user?['username'] = ctrl.text.trim());
          }),
        ]),
      ),
    );
  }

  void _changeWallpaper() {
    final colors = [
      {'name': 'Azul LINE', 'color': const Color(0xFFBDC9D7)},
      {'name': 'Verde', 'color': const Color(0xFFD4EDDA)},
      {'name': 'Bege', 'color': const Color(0xFFF5EFE6)},
      {'name': 'Lavanda', 'color': const Color(0xFFE8E0F0)},
      {'name': 'Cinza', 'color': const Color(0xFFF0F0F0)},
      {'name': 'Rosa', 'color': const Color(0xFFFDE8E8)},
      {'name': 'Amarelo', 'color': const Color(0xFFFFF8E1)},
      {'name': 'Branco', 'color': Colors.white},
    ];
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
        const Padding(padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('Papel de Parede', style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: _kText))),
        Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: colors.length,
            itemBuilder: (_, i) {
              final item = colors[i];
              final color = item['color'] as Color;
              final isSelected = _wallpaper == color;
              return GestureDetector(
                onTap: () {
                  setState(() => _wallpaper = color);
                  Navigator.pop(context);
                },
                child: Column(children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle,
                      border: Border.all(
                          color: isSelected ? _kGreen : Colors.grey.shade300,
                          width: isSelected ? 3 : 1)),
                    child: isSelected
                        ? const Icon(Icons.check, color: _kGreen, size: 22)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(item['name'] as String,
                      style: const TextStyle(fontSize: 10, color: _kSub),
                      textAlign: TextAlign.center, maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }

  Widget _handle() => Container(
    width: 36, height: 4,
    decoration: BoxDecoration(color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2)));

  Widget _inputField(TextEditingController ctrl, String hint) =>
      Container(
        decoration: BoxDecoration(
            border: Border.all(color: _kDivider),
            borderRadius: BorderRadius.circular(12)),
        child: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 15),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
        ),
      );

  Widget _saveButton(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity, height: 50,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
          backgroundColor: _kGreen, foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: _kIconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Configurações',
            style: TextStyle(color: _kText, fontWeight: FontWeight.w700, fontSize: 17)),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _kDivider, height: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : ListView(children: [

              // ── Barra de busca estilo LINE ──────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    SizedBox(width: 10),
                    Icon(Icons.search, color: Color(0xFFAAAAAA), size: 18),
                    SizedBox(width: 8),
                    Text('Buscar', style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14)),
                  ]),
                ),
              ),

              const SizedBox(height: 8),

              // ── Perfil ──────────────────────────────────────
              _lineItem(icon: Icons.person, label: 'Perfil', onTap: _editName,
                  leading: GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(children: [
                      CircleAvatar(
                        radius: 22, backgroundColor: _kGreen,
                        child: Text(
                          _userName.isNotEmpty ? _userName[0].toUpperCase() : 'Z',
                          style: const TextStyle(fontSize: 18, color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      ),
                      Positioned(bottom: 0, right: 0,
                        child: Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: _kGreen, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5)),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 8),
                        ),
                      ),
                    ]),
                  ),
                  subtitle: _userName),

              _lineDivider(),

              // ── Conta ───────────────────────────────────────
              _lineItem(
                icon: Icons.grid_view_rounded,
                label: 'Conta',
                subtitle: _userPhone.isNotEmpty ? _userPhone : null,
                onTap: _editUsername),

              _lineDivider(),

              // ── Privacidade ─────────────────────────────────
              _lineItem(
                icon: Icons.lock_outline,
                label: 'Privacidade',
                onTap: () => _navigate(const PrivacySettingsPage())),

              _lineDivider(),

              // ── Notificações ────────────────────────────────
              _lineItem(
                icon: Icons.volume_up_outlined,
                label: 'Notificações',
                trailing: const Text('On', style: TextStyle(color: _kSub, fontSize: 14)),
                onTap: () {}),

              _lineDivider(),

              // ── Fotos e Vídeos ──────────────────────────────
              _lineItem(
                icon: Icons.play_circle_outline,
                label: 'Fotos e Vídeos',
                onTap: () {}),

              _lineDivider(),

              // ── Chats ───────────────────────────────────────
              _lineItem(
                icon: Icons.chat_bubble_outline,
                label: 'Chats',
                onTap: _changeWallpaper),

              _lineDivider(),

              // ── Chamadas ────────────────────────────────────
              _lineItem(
                icon: Icons.phone_outlined,
                label: 'Chamadas',
                onTap: () {}),

              _lineDivider(),

              // ── Idioma ──────────────────────────────────────
              _lineItem(
                icon: Icons.language_outlined,
                label: 'Idioma',
                subtitle: 'Português (Brasil)',
                onTap: () => _navigate(const LanguageSettingsPage())),

              const SizedBox(height: 8),

              // ── Dispositivos ────────────────────────────────
              _lineItem(
                icon: Icons.devices_outlined,
                label: 'Dispositivos',
                onTap: () {}),

              _lineDivider(),

              // ── Pastas de Chat ──────────────────────────────
              _lineItem(
                icon: Icons.bookmark_outline,
                label: 'Pastas de Chat',
                onTap: () {}),

              _lineDivider(),

              // ── Dados e Armazenamento ───────────────────────
              _lineItem(
                icon: Icons.data_usage_outlined,
                label: 'Dados e Armazenamento',
                onTap: () {}),

              const SizedBox(height: 8),

              // ── Sobre ───────────────────────────────────────
              _lineItem(
                icon: Icons.info_outline,
                label: 'Sobre o ZapZap',
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'ZapZap',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '🇧🇷 Feito no Brasil',
                )),

              const SizedBox(height: 32),
            ]),
    );
  }

  // ── Item estilo LINE ─────────────────────────────────────────
  Widget _lineItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? subtitle,
    Widget? trailing,
    Widget? leading,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          // Ícone escuro estilo LINE
          leading ?? SizedBox(
            width: 44,
            child: Icon(icon, color: _kIconColor, size: 22),
          ),
          if (leading != null) const SizedBox(width: 12),
          if (leading == null) const SizedBox(width: 8),
          // Texto
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w500, color: _kText)),
              if (subtitle != null && subtitle.isNotEmpty)
                Text(subtitle, style: const TextStyle(
                    fontSize: 12, color: _kSub)),
            ],
          )),
          // Trailing
          trailing ?? const Icon(Icons.chevron_right,
              color: Color(0xFFCCCCCC), size: 20),
        ]),
      ),
    );
  }

  Widget _lineDivider() => Container(
    color: Colors.white,
    child: const Divider(height: 1, indent: 52, color: _kDivider));
}
