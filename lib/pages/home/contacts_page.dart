import 'dart:io';
import 'package:flutter/material.dart';
import 'package:nullgram/pages/chat/chat_page.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      // Sincroniza contatos do telefone com Telegram
      await TDLibClient.sendRaw({
        '@type': 'changeImportedContacts',
        'contacts': [],
      });

      final contacts = await TDLibClient.getContacts();
      if (mounted) {
        setState(() {
          _contacts = (contacts ?? [])
              .where((c) {
                final name = '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.trim();
                return name.isNotEmpty;
              })
              .toList()
            ..sort((a, b) {
              final nameA = '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'.trim().toLowerCase();
              final nameB = '${b['firstName'] ?? ''} ${b['lastName'] ?? ''}'.trim().toLowerCase();
              return nameA.compareTo(nameB);
            });
          _filtered = _contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filter(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? _contacts
          : _contacts.where((c) {
              final name = '${c['firstName'] ?? ''} ${c['lastName'] ?? ''}'.toLowerCase();
              return name.contains(query.toLowerCase());
            }).toList();
    });
  }

  String _lastSeen(Map<String, dynamic> contact) {
    final status = contact['status'];
    if (status == null) return '';
    final type = status['@type'];
    if (type == 'UserStatusOnline') return 'online';
    if (type == 'UserStatusOffline') {
      final wasOnline = status['wasOnline'] as int?;
      if (wasOnline == null) return 'visto recentemente';
      final dt = DateTime.fromMillisecondsSinceEpoch(wasOnline * 1000);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'visto agora';
      if (diff.inDays == 0) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return 'visto às $h:$m';
      } else if (diff.inDays == 1) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return 'visto ontem, $h:$m';
      } else {
        const months = ['', 'jan.', 'fev.', 'mar.', 'abr.', 'mai.', 'jun.',
            'jul.', 'ago.', 'set.', 'out.', 'nov.', 'dez.'];
        return 'visto ${dt.day} de ${months[dt.month]}';
      }
    }
    if (type == 'UserStatusRecently') return 'visto recentemente';
    if (type == 'UserStatusLastWeek') return 'visto esta semana';
    if (type == 'UserStatusLastMonth') return 'visto este mês';
    return '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildAvatar(Map<String, dynamic> contact, String name, Color color) {
    final photo = contact['profilePhoto'];
    final path = photo?['small']?['local']?['path'] as String?;

    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return CircleAvatar(
          radius: 26,
          backgroundImage: FileImage(file),
        );
      }
      // Baixa a foto se ainda não existe
      final fileId = photo?['small']?['id'] as int?;
      if (fileId != null) {
        TDLibClient.downloadFile(fileId: fileId);
      }
    }

    return CircleAvatar(
      radius: 26,
      backgroundColor: color,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Contatos',
            style: TextStyle(
              color: Color(0xFF111111),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            )),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0F0F0), height: 1),
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              decoration: const InputDecoration(
                hintText: 'Buscar',
                hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 15,
                    letterSpacing: 0),
                prefixIcon: Icon(Icons.search, color: Color(0xFFAAAAAA), size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00BFA5)))
              : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Nenhum contato',
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 15,
                                  letterSpacing: 0)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 76,
                        color: Color(0xFFF0F0F0),
                      ),
                      itemBuilder: (context, index) {
                        final contact = _filtered[index];
                        final name =
                            '${contact['firstName'] ?? ''} ${contact['lastName'] ?? ''}'
                                .trim();
                        final lastSeen = _lastSeen(contact);
                        final isOnline = contact['status']?['@type'] ==
                            'UserStatusOnline';

                        final colors = [
                          const Color(0xFF5C6BC0),
                          const Color(0xFF26A69A),
                          const Color(0xFFEF5350),
                          const Color(0xFFAB47BC),
                          const Color(0xFF42A5F5),
                          const Color(0xFFFF7043),
                          const Color(0xFF66BB6A),
                          const Color(0xFFEC407A),
                        ];
                        final color = name.isNotEmpty
                            ? colors[name.codeUnitAt(0) % colors.length]
                            : colors[0];

                        return InkWell(
                          onTap: () async {
                            // Abre ou cria chat com o contato
                            final result = await TDLibClient.sendRaw({
                              '@type': 'createPrivateChat',
                              'userId': contact['id'],
                              'force': true,
                            });
                            if (result != null && mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatPage(chat: result),
                                ),
                              );
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(children: [
                              _buildAvatar(contact, name, color),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF000000),
                                        letterSpacing: 0,
                                        height: 1.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (lastSeen.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        lastSeen,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isOnline
                                              ? const Color(0xFF00BFA5)
                                              : const Color(0xFF8D8D93),
                                          fontWeight: FontWeight.normal,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
