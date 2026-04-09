import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'book_index.dart';
import 'book_index_provider.dart';
import 'book_page.dart';

// ---------------------------------------------------------------------------
// Modèle de résultat
// ---------------------------------------------------------------------------

/// Un résultat de recherche dans le livre de règles.
class SearchResult {
  /// Id stable de la page cible.
  final String pageId;

  /// Titre affiché dans la liste de résultats.
  final String title;

  /// Extrait de texte autour du premier match (jusqu'à [_excerptLength] chars).
  final String excerpt;

  /// Numéro de page affiché (index + 1).
  final int pageNumber;

  const SearchResult({
    required this.pageId,
    required this.title,
    required this.excerpt,
    required this.pageNumber,
  });
}

// ---------------------------------------------------------------------------
// Service de recherche
// ---------------------------------------------------------------------------

/// Parcourt l'intégralité du [BookIndex] et retourne les pages dont le contenu
/// textuel contient [query] (insensible à la casse, accents inclus).
///
/// La recherche sur les annexes est incluse (elles apparaissent en fin de liste
/// avec un label distinctif dans le titre).
class BookSearch {
  static const int _excerptLength = 90;
  static const int _excerptPadding = 20;

  /// Effectue la recherche et retourne les résultats triés par pertinence.
  /// L'ordre est : résultats avec match dans le titre en premier,
  /// puis résultats avec match uniquement dans le corps.
  static List<SearchResult> search(BookIndex index, String query) {
    if (query.trim().isEmpty) return [];

    final q = query.toLowerCase();
    final titleMatches = <SearchResult>[];
    final bodyMatches = <SearchResult>[];

    // -- Pages du livre -------------------------------------------------------
    for (int i = 0; i < index.pageCount; i++) {
      final page = index.pageAt(i);
      final text = _extractText(page);
      if (text.isEmpty) continue;

      final lowerText = text.toLowerCase();
      if (!lowerText.contains(q)) continue;

      final title = page.title ?? _fallbackTitle(page);
      final excerpt = _buildExcerpt(text, q);
      final result = SearchResult(
        pageId: page.id,
        title: title,
        excerpt: excerpt,
        pageNumber: i + 1,
      );

      if ((title.toLowerCase()).contains(q)) {
        titleMatches.add(result);
      } else {
        bodyMatches.add(result);
      }
    }

    // -- Fiches annexes -------------------------------------------------------
    for (final annex in index.annexes.values) {
      final text = annex.body.toPlainText();
      final lowerText = text.toLowerCase();
      final titleLower = annex.title.toLowerCase();
      if (!lowerText.contains(q) && !titleLower.contains(q)) continue;

      final excerpt = lowerText.contains(q)
          ? _buildExcerpt(text, q)
          : annex.title;

      final result = SearchResult(
        pageId: annex.id,
        title: '📎 ${annex.title}',
        excerpt: excerpt,
        pageNumber: 0, // hors pagination
      );

      if (titleLower.contains(q)) {
        titleMatches.add(result);
      } else {
        bodyMatches.add(result);
      }
    }

    return [...titleMatches, ...bodyMatches];
  }

  // -------------------------------------------------------------------------
  // Extraction de texte par type de page
  // -------------------------------------------------------------------------

  static String _extractText(BookPage page) {
    return switch (page) {
      BlankPage() => '',
      CoverPage p => p.title ?? '',
      FullIllustrationPage p => p.title ?? '',
      ChapterIntroPage p =>
        '${p.title ?? ''}\n${p.body.toPlainText()}',
      FlowTextPage p =>
        '${p.title ?? ''}\n${p.body.toPlainText()}',
      RaceSheetPage p => [
          p.title ?? '',
          p.raceName,
          p.description.toPlainText(),
          ...p.bonuses,
          ...p.maluses,
          ...p.accessibleClasses,
        ].join('\n'),
      ClassSheetPage p => [
          p.title ?? '',
          p.className,
          p.classCategory,
          p.quote,
          ...p.classBonuses,
          ...p.equipment.map((e) => '${e.label} ${e.detail}'),
          ...p.affinities,
          p.skillFormula,
          ...p.freeSkills,
          ...p.accessibleSkills,
          if (p.note != null) p.note!,
        ].join('\n'),
      WeaponTablePage p => [
          p.title ?? '',
          p.category,
          ...p.weapons.map((w) => [
                w.name,
                w.flavorText,
                w.damage,
                w.effect ?? '',
                w.characteristics ?? '',
              ].join(' ')),
        ].join('\n'),
      EffectListPage p => [
          p.title ?? '',
          ...p.effects.map((e) => [
                e.name,
                e.description,
                e.aggravatedDescription ?? '',
              ].join(' ')),
        ].join('\n'),
    };
  }

  static String _fallbackTitle(BookPage page) => switch (page) {
        RaceSheetPage p => p.raceName,
        ClassSheetPage p => p.className,
        WeaponTablePage p => p.category,
        _ => page.id,
      };

  // -------------------------------------------------------------------------
  // Extrait de texte
  // -------------------------------------------------------------------------

  /// Coupe un extrait de [_excerptLength] caractères autour du premier match.
  static String _buildExcerpt(String text, String query) {
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query);
    if (idx < 0) return text.substring(0, text.length.clamp(0, _excerptLength));

    final start = (idx - _excerptPadding).clamp(0, text.length);
    final end = (idx + query.length + _excerptLength).clamp(0, text.length);

    final raw = text.substring(start, end).replaceAll('\n', ' ').trim();
    final prefix = start > 0 ? '…' : '';
    final suffix = end < text.length ? '…' : '';
    return '$prefix$raw$suffix';
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Notifier pour la query de recherche courante.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
  void clear() => state = '';
}

/// Query de recherche courante. Vide = pas de recherche active.
final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Résultats dérivés de la query et du BookIndex.
final searchResultsProvider = Provider<List<SearchResult>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final index = ref.watch(bookIndexProvider);
  return BookSearch.search(index, query);
});
