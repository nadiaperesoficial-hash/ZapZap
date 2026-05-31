import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({super.key});

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final isLoading = ValueNotifier<bool>(false);
  final TextEditingController _phoneController = TextEditingController();

  // País selecionado
  _Country _selectedCountry = _countries.firstWhere((c) => c.code == 'BR');

  void _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    isLoading.value = true;
    try {
      final fullPhone = '${_selectedCountry.dialCode}$phone';
      await TDLibClient.setAuthenticationPhoneNumber(phoneNumber: fullPhone);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateToQrLogin() async {
    await TDLibClient.requestQrCodeAuthentication();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CountryPickerSheet(
        selected: _selectedCountry,
        onSelect: (c) {
          setState(() => _selectedCountry = c);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 32),

                // ── Logo ZapZap ──────────────────────────────────
                Column(
                  children: [
                    // Ícone arredondado
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BFA5),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00BFA5).withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Nome ZapZap
                    const Text(
                      'ZapZap',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF00BFA5),
                        letterSpacing: -1.5,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Feito no Brasil
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text('🇧🇷',
                            style: TextStyle(fontSize: 13)),
                        SizedBox(width: 5),
                        Text(
                          'Feito no Brasil',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF888888),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 52),

                // ── Seletor de país ──────────────────────────────
                GestureDetector(
                  onTap: _showCountryPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFDDDDDD)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _selectedCountry.flag,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedCountry.name,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF111111),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          _selectedCountry.dialCode,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF888888),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down,
                            color: Color(0xFFAAAAAA), size: 20),
                      ],
                    ),
                  ),
                ),

                // ── Campo de telefone ────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 14, right: 10, top: 4, bottom: 4),
                        child: Text(
                          _selectedCountry.dialCode,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF111111),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 22,
                          color: const Color(0xFFDDDDDD)),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF111111),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Número de telefone',
                            hintStyle: TextStyle(
                                color: Color(0xFFBBBBBB), fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Botão entrar ─────────────────────────────────
                ValueListenableBuilder<bool>(
                  valueListenable: isLoading,
                  builder: (context, loading, _) => SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: loading
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF00BFA5)))
                        : ElevatedButton(
                            onPressed: _sendCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BFA5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Texto informativo ────────────────────────────
                const Text(
                  'Um código de verificação será enviado\npara o número informado.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFAAAAAA),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 36),

                // ── Divisor ──────────────────────────────────────
                Row(children: [
                  const Expanded(
                      child: Divider(color: Color(0xFFEEEEEE))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('ou',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13)),
                  ),
                  const Expanded(
                      child: Divider(color: Color(0xFFEEEEEE))),
                ]),

                const SizedBox(height: 20),

                // ── Login por QR ─────────────────────────────────
                OutlinedButton(
                  onPressed: _navigateToQrLogin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00BFA5),
                    side: const BorderSide(color: Color(0xFF00BFA5)),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Entrar com QR Code',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom sheet seletor de país ─────────────────────────────────────────────
class _CountryPickerSheet extends StatefulWidget {
  final _Country selected;
  final void Function(_Country) onSelect;

  const _CountryPickerSheet(
      {required this.selected, required this.onSelect});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<_Country> _filtered = _countries;

  void _filter(String q) {
    setState(() {
      _filtered = q.isEmpty
          ? _countries
          : _countries
              .where((c) =>
                  c.name.toLowerCase().contains(q.toLowerCase()) ||
                  c.dialCode.contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Selecionar país',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111)),
            ),
          ),
          // Busca
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _filter,
                decoration: const InputDecoration(
                  hintText: 'Buscar país...',
                  hintStyle:
                      TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                  prefixIcon: Icon(Icons.search,
                      color: Color(0xFFAAAAAA), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final c = _filtered[i];
                final isSelected = c.code == widget.selected.code;
                return ListTile(
                  leading: Text(c.flag,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(
                    c.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: isSelected
                          ? const Color(0xFF00BFA5)
                          : const Color(0xFF111111),
                    ),
                  ),
                  trailing: Text(
                    c.dialCode,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF888888)),
                  ),
                  onTap: () => widget.onSelect(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Model de país ────────────────────────────────────────────────────────────
class _Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;

  const _Country(
      {required this.name,
      required this.code,
      required this.dialCode,
      required this.flag});
}

const List<_Country> _countries = [
  _Country(name: 'Brasil', code: 'BR', dialCode: '+55', flag: '🇧🇷'),
  _Country(name: 'Portugal', code: 'PT', dialCode: '+351', flag: '🇵🇹'),
  _Country(name: 'Estados Unidos', code: 'US', dialCode: '+1', flag: '🇺🇸'),
  _Country(name: 'Reino Unido', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
  _Country(name: 'Alemanha', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
  _Country(name: 'França', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
  _Country(name: 'Itália', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
  _Country(name: 'Espanha', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
  _Country(name: 'Argentina', code: 'AR', dialCode: '+54', flag: '🇦🇷'),
  _Country(name: 'México', code: 'MX', dialCode: '+52', flag: '🇲🇽'),
  _Country(name: 'Colômbia', code: 'CO', dialCode: '+57', flag: '🇨🇴'),
  _Country(name: 'Chile', code: 'CL', dialCode: '+56', flag: '🇨🇱'),
  _Country(name: 'Peru', code: 'PE', dialCode: '+51', flag: '🇵🇪'),
  _Country(name: 'Venezuela', code: 'VE', dialCode: '+58', flag: '🇻🇪'),
  _Country(name: 'Uruguai', code: 'UY', dialCode: '+598', flag: '🇺🇾'),
  _Country(name: 'Paraguai', code: 'PY', dialCode: '+595', flag: '🇵🇾'),
  _Country(name: 'Bolívia', code: 'BO', dialCode: '+591', flag: '🇧🇴'),
  _Country(name: 'Equador', code: 'EC', dialCode: '+593', flag: '🇪🇨'),
  _Country(name: 'Japão', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
  _Country(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
  _Country(name: 'Índia', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
  _Country(name: 'Rússia', code: 'RU', dialCode: '+7', flag: '🇷🇺'),
  _Country(name: 'Canadá', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
  _Country(name: 'Austrália', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
  _Country(name: 'África do Sul', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
  _Country(name: 'Angola', code: 'AO', dialCode: '+244', flag: '🇦🇴'),
  _Country(name: 'Moçambique', code: 'MZ', dialCode: '+258', flag: '🇲🇿'),
  _Country(name: 'Cabo Verde', code: 'CV', dialCode: '+238', flag: '🇨🇻'),
  _Country(name: 'Turquia', code: 'TR', dialCode: '+90', flag: '🇹🇷'),
  _Country(name: 'Coreia do Sul', code: 'KR', dialCode: '+82', flag: '🇰🇷'),
];
