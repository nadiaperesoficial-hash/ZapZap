import 'package:flutter/material.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Amizades', 'icon': '😊', 'query': 'amizades brasil', 'desc': 'Faça novas amizades'},
    {'name': 'Encontros', 'icon': '🤝', 'query': 'encontros brasil', 'desc': 'Conecte-se pessoalmente'},
    {'name': 'Cidades', 'icon': '🌐', 'query': 'grupo cidade brasil', 'desc': 'Grupos por cidade'},
    {'name': 'Cultura', 'icon': '🎭', 'query': 'cultura brasil', 'desc': 'Cultura nacional e regional'},
    {'name': 'Cinema', 'icon': '🎬', 'query': 'cinema filmes brasil', 'desc': 'Para amantes do cinema'},
    {'name': 'Diversão', 'icon': '🍺', 'query': 'diversão humor brasil', 'desc': 'Humor e entretenimento'},
    {'name': 'Educação', 'icon': '📚', 'query': 'educação estudantes brasil', 'desc': 'Grupos educacionais'},
    {'name': 'Esportes', 'icon': '⚽', 'query': 'esportes futebol brasil', 'desc': 'Futebol e esportes'},
    {'name': 'Música', 'icon': '🎵', 'query': 'musica brasil', 'desc': 'Amantes da música'},
    {'name': 'Tecnologia', 'icon': '💻', 'query': 'tecnologia programação brasil', 'desc': 'Tech e programação'},
    {'name': 'Negócios', 'icon': '💼', 'query': 'negócios empreendedorismo brasil', 'desc': 'Empreendedorismo'},
    {'name': 'Games', 'icon': '🎮', 'query': 'games jogos brasil', 'desc': 'Jogos e gaming'},
  ];

  Future<void> _searchGroups(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await TDLibClient.searchPublicChats(query: query);
      setState(() {
        _searchResults = results ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _openCategory(Map<String, dynamic> category) {
    setState(() => _selectedCategory = category['name']);
    _searchGroups(category['query']);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryGroupsPage(
          category: category,
          searchGroups: _searchGroups,
        ),
      ),
    );
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
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar grupos...',
                  border: InputBorder.none,
                ),
                onSubmitted: (q) {
                  if (q.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _SearchResultsPage(query: q),
                      ),
                    );
                  }
                },
              )
            : const Text('ZapGrupos'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) _searchController.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🇧🇷 Grupos Públicos Brasileiros',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Encontre grupos por categoria e participe',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Categorias',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return GestureDetector(
                  onTap: () => _openCategory(cat),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(children: [
                      Text(cat['icon'], style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(cat['desc'], style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGroupsPage extends StatefulWidget {
  final Map<String, dynamic> category;
  final Future<void> Function(String) searchGroups;

  const _CategoryGroupsPage({required this.category, required this.searchGroups});

  @override
  State<_CategoryGroupsPage> createState() => _CategoryGroupsPageState();
}

class _CategoryGroupsPageState extends State<_CategoryGroupsPage> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await TDLibClient.searchPublicChats(query: widget.category['query']);
      setState(() {
        _groups = (results ?? []).where((g) {
          final type = g['type']?['@type'] ?? '';
          return type == 'chatTypeSupergroup' || type == 'chatTypeBasicGroup';
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGroup(Map<String, dynamic> chat) async {
    try {
      await TDLibClient.joinChat(chatId: chat['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entrou em ${chat['title']}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao entrar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category['icon']} ${widget.category['name']}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? const Center(child: Text('Nenhum grupo encontrado'))
              : ListView.separated(
                  itemCount: _groups.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final group = _groups[index];
                    final title = group['title'] ?? '';
                    final memberCount = group['supergroup']?['memberCount'] ?? 0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          title.isNotEmpty ? title[0].toUpperCase() : 'G',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: memberCount > 0
                          ? Text('$memberCount membros', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)))
                          : null,
                      trailing: TextButton(
                        onPressed: () => _joinGroup(group),
                        child: const Text('Entrar'),
                      ),
                      onTap: () => _joinGroup(group),
                    );
                  },
                ),
    );
  }
}

class _SearchResultsPage extends StatefulWidget {
  final String query;
  const _SearchResultsPage({required this.query});

  @override
  State<_SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<_SearchResultsPage> {
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    try {
      final results = await TDLibClient.searchPublicChats(query: widget.query);
      setState(() {
        _results = results ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Resultados: ${widget.query}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? const Center(child: Text('Nenhum resultado encontrado'))
              : ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final group = _results[index];
                    final title = group['title'] ?? '';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          title.isNotEmpty ? title[0].toUpperCase() : 'G',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(title),
                      trailing: const Icon(Icons.chevron_right),
                    );
                  },
                ),
    );
  }
}
