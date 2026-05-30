import 'package:flutter/material.dart';
import 'package:nullgram/pages/home/app_strings.dart';
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
      final contacts = await TDLibClient.getContacts();
      if (mounted) {
        setState(() {
          _contacts = contacts ?? [];
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('contacts'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppStrings.get('search'),
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
            ),
            onChanged: _filter,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(child: Text(AppStrings.get('contacts')))
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (context, index) {
                        final contact = _filtered[index];
                        final name = '${contact['firstName'] ?? ''} ${contact['lastName'] ?? ''}'.trim();
                        final phone = contact['phoneNumber'] ?? '';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(name),
                          subtitle: phone.isNotEmpty ? Text('+$phone') : null,
                          onTap: () {},
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
