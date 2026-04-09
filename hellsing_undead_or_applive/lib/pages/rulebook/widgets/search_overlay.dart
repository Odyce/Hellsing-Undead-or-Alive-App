import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_search.dart';

/// Overlay de recherche textuelle du livre de règles.
///
/// S'affiche par-dessus le livre (fond semi-transparent) avec :
/// - Champ de saisie autofocusé.
/// - Liste des résultats scrollable.
/// - Tap sur un résultat → [onResultSelected] puis fermeture.
/// - Tap sur le fond ou bouton ✕ → fermeture sans navigation.
///
/// Gestion d'état (query + résultats) via Riverpod [searchQueryProvider].
class SearchOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final void Function(String pageId) onResultSelected;

  const SearchOverlay({
    super.key,
    required this.onClose,
    required this.onResultSelected,
  });

  @override
  ConsumerState<SearchOverlay> createState() => _SearchOverlayState();
}

class _SearchOverlayState extends ConsumerState<SearchOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  final _textCtrl = TextEditingController();

  static const _parchment = Color(0xFFF3E6C8);
  static const _blood = Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));

    // Réinitialise la query à l'ouverture.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).clear();
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _close() {
    ref.read(searchQueryProvider.notifier).clear();
    widget.onClose();
  }

  void _onResultTap(SearchResult result) {
    ref.read(searchQueryProvider.notifier).clear();
    widget.onResultSelected(result.pageId);
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Stack(
          children: [
            // Fond semi-transparent — tap = fermeture.
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                behavior: HitTestBehavior.opaque,
                child: const ColoredBox(color: Color(0x8C000000)),
              ),
            ),

            // Panneau de recherche centré en haut.
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Material(
                    elevation: 12,
                    borderRadius: BorderRadius.circular(10),
                    color: _parchment,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _blood, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        maxWidth: 640,
                        maxHeight: 520,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ---- Barre de recherche -------------------------
                          _SearchBar(
                            controller: _textCtrl,
                            onChanged: (v) =>
                                ref.read(searchQueryProvider.notifier).set(v),
                            onClose: _close,
                          ),

                          // ---- Résultats ----------------------------------
                          if (query.trim().isNotEmpty)
                            Flexible(
                              child: results.isEmpty
                                  ? _EmptyState(query: query)
                                  : _ResultList(
                                      results: results,
                                      query: query,
                                      onTap: _onResultTap,
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Barre de saisie
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  static const _darkBrown = Color(0xFF3B2410);
  static const _blood = Color(0xFF8B0000);

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
      child: Row(
        children: [
          const Icon(Icons.search, color: _blood, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: onChanged,
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 17,
                color: _darkBrown,
              ),
              decoration: const InputDecoration(
                hintText: 'Rechercher dans le livre…',
                hintStyle: TextStyle(
                  fontFamily: 'EBGaramond',
                  fontSize: 16,
                  color: Color(0xFF9B8060),
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: _blood),
            onPressed: onClose,
            tooltip: 'Fermer la recherche',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Liste de résultats
// ---------------------------------------------------------------------------

class _ResultList extends StatelessWidget {
  final List<SearchResult> results;
  final String query;
  final void Function(SearchResult) onTap;

  static const _midBrown = Color(0xFF5C3A1E);

  const _ResultList({
    required this.results,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1, color: Color(0xFFD4B896)),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: results.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFD4B896), indent: 16, endIndent: 16),
            itemBuilder: (_, i) => _ResultTile(
              result: results[i],
              query: query,
              onTap: () => onTap(results[i]),
            ),
          ),
        ),
        // Compteur en bas
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${results.length} résultat${results.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: _midBrown,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SearchResult result;
  final String query;
  final VoidCallback onTap;

  static const _darkBrown = Color(0xFF3B2410);
  static const _blood = Color(0xFF8B0000);
  static const _midBrown = Color(0xFF5C3A1E);

  const _ResultTile({
    required this.result,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Numéro de page (ou "annexe")
            SizedBox(
              width: 44,
              child: Text(
                result.pageNumber > 0 ? 'p. ${result.pageNumber}' : 'annexe',
                style: const TextStyle(
                  fontFamily: 'Cinzel Decorative',
                  fontSize: 9,
                  color: _blood,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre avec highlight
                  _HighlightText(
                    text: result.title,
                    query: query,
                    baseStyle: const TextStyle(
                      fontFamily: 'EBGaramond',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _darkBrown,
                    ),
                    highlightStyle: const TextStyle(
                      fontFamily: 'EBGaramond',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _blood,
                      backgroundColor: Color(0x33FF0000),
                    ),
                  ),
                  // Extrait
                  if (result.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    _HighlightText(
                      text: result.excerpt,
                      query: query,
                      baseStyle: const TextStyle(
                        fontFamily: 'EBGaramond',
                        fontSize: 13,
                        color: _midBrown,
                      ),
                      highlightStyle: const TextStyle(
                        fontFamily: 'EBGaramond',
                        fontSize: 13,
                        color: _blood,
                        backgroundColor: Color(0x22FF0000),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Color(0xFFD4B896)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Highlight du terme recherché dans le texte
// ---------------------------------------------------------------------------

/// Affiche [text] en mettant en valeur toutes les occurrences de [query].
class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;
  final TextStyle highlightStyle;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.baseStyle,
    required this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: baseStyle);

    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final idx = lower.indexOf(lowerQuery, start);
      if (idx < 0) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: baseStyle));
        }
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx), style: baseStyle));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: highlightStyle,
      ));
      start = idx + query.length;
    }

    return Text.rich(TextSpan(children: spans));
  }
}

// ---------------------------------------------------------------------------
// État vide
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final String query;

  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Text(
        'Aucun résultat pour « $query »',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'EBGaramond',
          fontSize: 15,
          fontStyle: FontStyle.italic,
          color: Color(0xFF9B8060),
        ),
      ),
    );
  }
}
