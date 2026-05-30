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

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Amizades', 'icon': '😊', 'query': 'amizades', 'desc': 'Faça novas amizades'},
    {'name': 'Encontros', 'icon': '🤝', 'query': 'encontros', 'desc': 'Conecte-se pessoalmente'},
    {'name': 'Cidades', 'icon': '🌐', 'query': 'cidade', 'desc': 'Grupos por cidade'},
    {'name': 'Cultura', 'icon': '🎭', 'query': 'cultura', 'desc': 'Cultura nacional e regional'},
    {'name': 'Cinema', 'icon': '🎬', 'query': 'cinema', 'desc': 'Para amantes do cinema'},
    {'name': 'Diversão', 'icon': '🍺', 'query': 'humor', 'desc': 'Humor e entretenimento'},
    {'name': 'Educação', 'icon': '📚', 'query': 'educacao', 'desc': 'Grupos educacionais'},
    {'name': 'Esportes', 'icon': '⚽', 'query': 'futebol', 'desc': 'Futebol e esportes'},
    {'name': 'Música', 'icon': '🎵', 'query': 'musica', 'desc': 'Amantes da música'},
    {'name': 'Tecnologia', 'icon': '💻', 'query': 'programacao', 'desc': 'Tech e programação'},
    {'name': 'Negócios', 'icon': '💼', 'query': 'negocios', 'desc': 'Empreendedorismo'},
    {'name': 'Games', 'icon': '🎮', 'query': 'games', 'desc': 'Jogos e gaming'},
  ];

  void _openCategory(Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GroupResultsPage(
          title: '${category['icon']} ${category['name']}',
          query: category['query'],
        ),
      ),
    );
  }

  void _openSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() { _isSearching = false; });
    _searchController.clear();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GroupResultsPage(
          title: 'Busca: $query',
          query: query.trim(),
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
                textInputAction: TextInputAction.search,
                onSubmitted: _openSearch,
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
                const Text('🇧🇷 Grupos Públicos Brasileiros',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Encontre grupos por categoria e participe',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Categorias',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
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
                            Text(cat['desc'],
                              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
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

class _GroupResultsPage extends StatefulWidget {
  final String title;
  final String query;

  const _GroupResultsPage({required this.title, required this.query});

  @override
  State<_GroupResultsPage> createState() => _GroupResultsPageState();
}

class _GroupResultsPageState extends State<_GroupResultsPage> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final results = await TDLibClient.searchPublicChats(query: widget.query)
          .timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _groups = results ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao buscar grupos. Tente novamente.';
          _isLoading = false;
        });
      }
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
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _search, child: const Text('Tentar novamente')),
                  ]),
                )
              : _groups.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.group_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Nenhum grupo encontrado', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text('Tente buscar com outro termo', style: TextStyle(color: Colors.grey[500])),
                      ]),
                    )
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
                              ? Text('$memberCount membros',
                                  style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)))
                              : null,
                          trailing: OutlinedButton(
                            onPressed: () => _joinGroup(group),
                            child: const Text('Entrar'),
                          ),
                        );
                      },
                    ),
    );
  }
}
