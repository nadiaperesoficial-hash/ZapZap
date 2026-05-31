import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nullgram/tdlib/tdlib_client.dart';

const _kGreen = Color(0xFF00BFA5);
const _kGreenDark = Color(0xFF008E76);
const _kBg = Color(0xFFF2F2F2);

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _isSearching = false;
  bool _isSearchLoading = false;
  String _searchQuery = '';
  List<Map<String, dynamic>> _searchResults = [];
  Timer? _debounce;

  // queries são usernames reais de grupos/canais públicos no Telegram
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Amizades',   'icon': '😊', 'queries': ['Amizades77', 'grupo_amizade_namoro_paquera', 'EntreeAmigoss'],          'color': Color(0xFFFF8A65)},
    {'name': 'Encontros',  'icon': '🤝', 'queries': ['amizadesenamorosbrs', 'encontrosbrasil', 'relacionamento'],             'color': Color(0xFF42A5F5)},
    {'name': 'Cidades',    'icon': '🌐', 'queries': ['etdevarginha', 'saopaulocidade', 'brasilia'],                           'color': Color(0xFF26A69A)},
    {'name': 'Cultura',    'icon': '🎭', 'queries': ['bubbletealuv', 'altacultura', 'kpop_songg'],                            'color': Color(0xFFAB47BC)},
    {'name': 'Cinema',     'icon': '🎬', 'queries': ['cinemabrasil', 'filmes', 'cinema'],                                     'color': Color(0xFFEF5350)},
    {'name': 'Diversão',   'icon': '🍺', 'queries': ['humorbrasil', 'memesbr', 'humor'],                                      'color': Color(0xFFFFCA28)},
    {'name': 'Educação',   'icon': '📚', 'queries': ['Brasil_Livros', 'livros', 'cursosonline1k', 'inglespelotelegram', 'dicadeingles'], 'color': Color(0xFF5C6BC0)},
    {'name': 'Esportes',   'icon': '⚽', 'queries': ['ONLINE_BRASILEIRAOLOX', 'futebolbrasil', 'esportesbr'],                 'color': Color(0xFF66BB6A)},
    {'name': 'Música',     'icon': '🎵', 'queries': ['bandaUniVersos', 'musicas_iurd', 'musicasdemais', 'kpop_songg'],        'color': Color(0xFFEC407A)},
    {'name': 'Tecnologia', 'icon': '💻', 'queries': ['programacaobr', 'devbrasil', 'tecnologiabr'],                           'color': Color(0xFF29B6F6)},
    {'name': 'Negócios',   'icon': '💼', 'queries': ['empreendedorismobr', 'negociosbr', 'investir'],                         'color': Color(0xFF8D6E63)},
    {'name': 'Religião',   'icon': '🕌', 'queries': ['Quranpu', 'muslimcentral', 'Muculmanosbra'],                            'color': Color(0xFF7E57C2)},
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() => _isSearching = true);
    _searchFocus.requestFocus();
  }

  void _stopSearch() {
    _debounce?.cancel();
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchResults = [];
      _isSearchLoading = false;
    });
    _searchController.clear();
    _searchFocus.unfocus();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _searchResults = [];
    });
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _isSearchLoading = false);
      return;
    }
    setState(() => _isSearchLoading = true);
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final results =
            await TDLibClient.searchPublicChats(query: value.trim());
        if (!mounted) return;
        setState(() {
          _searchResults = results ?? [];
          _isSearchLoading = false;
        });
      } catch (_) {
        if (mounted) setState(() => _isSearchLoading = false);
      }
    });
  }

  void _openCategory(Map<String, dynamic> cat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _GroupResultsPage(
          title: '${cat['icon']} ${cat['name']}',
          queries: List<String>.from(cat['queries']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Buscar grupos...',
                  hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                  border: InputBorder.none,
                ),
              )
            : const Text(
                'ZapGrupos',
                style: TextStyle(
                  color: Color(0xFF111111),
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: const Color(0xFF111111),
            ),
            onPressed: _isSearching ? _stopSearch : _startSearch,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: _isSearching ? _buildSearchBody() : _buildCategoryBody(),
    );
  }

  // ── Busca ─────────────────────────────────────────────────────────────────
  Widget _buildSearchBody() {
    if (_searchQuery.length < 2) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Digite para buscar grupos',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
        ]),
      );
    }
    if (_isSearchLoading) {
      return const Center(child: CircularProgressIndicator(color: _kGreen));
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.group_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Nenhum grupo encontrado',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
        ]),
      );
    }

    // Grid estilo KakaoGroup para resultados de busca
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.78,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (_, i) => _GroupCircleCard(
        group: _searchResults[i],
        showJoin: true,
      ),
    );
  }

  // ── Categorias estilo KakaoGroup ──────────────────────────────────────────
  Widget _buildCategoryBody() {
    return CustomScrollView(
      slivers: [
        // Banner
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kGreen, _kGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🇧🇷 Grupos Públicos Brasileiros',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Encontre grupos por categoria e participe',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85), fontSize: 13),
                ),
              ],
            ),
          ),
        ),

        // Header
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Text(
              'Categorias',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111)),
            ),
          ),
        ),

        // Grid circular estilo KakaoGroup
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final cat = _categories[i];
                return GestureDetector(
                  onTap: () => _openCategory(cat),
                  child: _CategoryCircleCard(cat: cat),
                );
              },
              childCount: _categories.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.82,
              crossAxisSpacing: 14,
              mainAxisSpacing: 16,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

// ── Card circular de categoria ───────────────────────────────────────────────
class _CategoryCircleCard extends StatelessWidget {
  final Map<String, dynamic> cat;
  const _CategoryCircleCard({required this.cat});

  @override
  Widget build(BuildContext context) {
    final color = cat['color'] as Color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Center(
            child: Text(cat['icon'], style: const TextStyle(fontSize: 34)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          cat['name'],
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF222222),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Card circular de grupo (resultados) ──────────────────────────────────────
class _GroupCircleCard extends StatefulWidget {
  final Map<String, dynamic> group;
  final bool showJoin;
  const _GroupCircleCard({required this.group, this.showJoin = false});

  @override
  State<_GroupCircleCard> createState() => _GroupCircleCardState();
}

class _GroupCircleCardState extends State<_GroupCircleCard> {
  bool _joining = false;
  bool _joined = false;

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await TDLibClient.joinChat(chatId: widget.group['id']);
      if (mounted) setState(() { _joining = false; _joined = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _joining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao entrar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.group['title'] ?? '';
    final memberCount = widget.group['supergroup']?['memberCount'] ??
        widget.group['memberCount'] ?? 0;
    final initial = title.isNotEmpty ? title[0].toUpperCase() : 'G';

    final colors = [
      const Color(0xFF5C6BC0), const Color(0xFF26A69A),
      const Color(0xFFEF5350), const Color(0xFFAB47BC),
      const Color(0xFF42A5F5), const Color(0xFFFF7043),
      const Color(0xFF66BB6A), const Color(0xFFEC407A),
    ];
    final color =
        title.isNotEmpty ? colors[title.codeUnitAt(0) % colors.length] : colors[0];

    return GestureDetector(
      onTap: widget.showJoin && !_joined ? _join : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                ),
              ),
              // Badge de ação
              if (widget.showJoin)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _joined ? _kGreen : Colors.white,
                      border: Border.all(
                          color: _joined ? _kGreen : const Color(0xFFDDDDDD),
                          width: 1.5),
                    ),
                    child: _joining
                        ? const Padding(
                            padding: EdgeInsets.all(5),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _kGreen),
                          )
                        : Icon(
                            _joined ? Icons.check : Icons.add,
                            size: 15,
                            color: _joined ? Colors.white : _kGreen,
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (memberCount > 0)
            Text(
              _formatCount(memberCount),
              style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

// ── Página de resultados por categoria ───────────────────────────────────────
class _GroupResultsPage extends StatefulWidget {
  final String title;
  final List<String> queries;
  const _GroupResultsPage({required this.title, required this.queries});

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
      final seen = <int>{};
      final all = <Map<String, dynamic>>[];

      // Busca cada query em paralelo
      final futures = widget.queries.map((q) =>
          TDLibClient.searchPublicChats(query: q)
              .timeout(const Duration(seconds: 10))
              .catchError((_) => null));

      final results = await Future.wait(futures);

      for (final list in results) {
        for (final g in (list ?? [])) {
          final id = g['id'] as int?;
          if (id != null && !seen.contains(id)) {
            seen.add(id);
            all.add(g);
          }
        }
      }

      if (mounted) setState(() { _groups = all; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() {
        _error = 'Erro ao buscar grupos. Tente novamente.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
              color: Color(0xFF111111),
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFEEEEEE), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : _error != null
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.error_outline, size: 52, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _search,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kGreen, foregroundColor: Colors.white),
                      child: const Text('Tentar novamente'),
                    ),
                  ]),
                )
              : _groups.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.group_off, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text('Nenhum grupo encontrado',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
                      ]),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(20),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.78,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 18,
                      ),
                      itemCount: _groups.length,
                      itemBuilder: (_, i) => _GroupCircleCard(
                        group: _groups[i],
                        showJoin: true,
                      ),
                    ),
    );
  }
}
