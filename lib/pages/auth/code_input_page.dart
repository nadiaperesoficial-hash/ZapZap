import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

const _kGreen = Color(0xFF00BFA5);

class CodeInputPage extends StatefulWidget {
  const CodeInputPage({super.key});

  @override
  State<CodeInputPage> createState() => _CodeInputPageState();
}

class _CodeInputPageState extends State<CodeInputPage> {
  final isLoading = ValueNotifier<bool>(false);
  final TextEditingController _codeController = TextEditingController();
  final hasError = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite o código recebido.')),
      );
      return;
    }
    isLoading.value = true;
    hasError.value = false;
    try {
      final result =
          await TDLibClient.checkAuthenticationCode(code: code);
      if (result == 'PHONE_CODE_INVALID') {
        hasError.value = true;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Código inválido. Tente novamente.'),
              backgroundColor: Colors.red),
        );
        _codeController.clear();
      }
    } catch (e) {
      hasError.value = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Ícone ────────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_rounded,
                    size: 36, color: _kGreen),
              ),
              const SizedBox(height: 20),

              // ── Título ───────────────────────────────────────
              const Text(
                'Inserir Código',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _kGreen,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'O código foi enviado para o seu número.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFAAAAAA),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              // ── Campo de código ──────────────────────────────
              ValueListenableBuilder<bool>(
                valueListenable: hasError,
                builder: (context, error, _) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: error
                          ? Colors.red
                          : const Color(0xFFE0E0E0),
                      width: error ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: error
                            ? Colors.red.withOpacity(0.12)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    autofocus: true,
                    maxLength: 5,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    style: TextStyle(
                      fontSize: 32,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w700,
                      color: error ? Colors.red : const Color(0xFF111111),
                    ),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      hintText: '• • • • •',
                      hintStyle: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 10,
                        color: Color(0xFFCCCCCC),
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 22, horizontal: 16),
                    ),
                    onChanged: (_) {
                      if (hasError.value) hasError.value = false;
                    },
                    onSubmitted: (_) => _verifyCode(),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Botão verificar ──────────────────────────────
              ValueListenableBuilder<bool>(
                valueListenable: isLoading,
                builder: (context, loading, _) => SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(color: _kGreen))
                      : ElevatedButton(
                          onPressed: _verifyCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Verificar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
