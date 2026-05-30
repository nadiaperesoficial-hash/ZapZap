import 'package:flutter/material.dart';
import 'package:nullgram/pages/home/contacts_page.dart';
import 'package:nullgram/pages/home/groups_page.dart';
import 'package:nullgram/pages/home/settings_page.dart';

class HomeMenu extends StatelessWidget {
  const HomeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: theme.colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 32),
                ),
                const SizedBox(height: 8),
                Text('ZapZap', style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Meu Perfil'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Novo Grupo'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.campaign),
            title: const Text('Novo Canal'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Contatos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.phone),
            title: const Text('Chamadas'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Mensagens Salvas'),
            onTap: () => Navigator.pop(context),
          ),
          // Novo item ZapGrupos
          ListTile(
            leading: Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.groups, color: Colors.white, size: 18),
            ),
            title: const Text('ZapGrupos', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Grupos públicos brasileiros', style: TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GroupsPage()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configurações'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
        ],
      ),
    );
  }
}
