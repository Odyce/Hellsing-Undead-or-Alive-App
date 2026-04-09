import 'annex_sheet.dart';
import 'book_page.dart';

/// Métadonnées d'une section du livre.
class SectionInfo {
  final String id;
  final String title;
  final int startPageIndex;
  final int pageCount;

  const SectionInfo({
    required this.id,
    required this.title,
    required this.startPageIndex,
    required this.pageCount,
  });
}

/// Section brute avant normalisation : juste un id, un titre et des pages.
class RawSection {
  final String id;
  final String title;
  final List<BookPage> pages;

  const RawSection({
    required this.id,
    required this.title,
    required this.pages,
  });
}

/// Index complet du livre de règles.
///
/// Construit une seule fois au démarrage. Source de vérité pour toute
/// la pagination, la résolution des liens, et les fiches annexes.
class BookIndex {
  /// Toutes les pages dans l'ordre, y compris les pages blanches insérées.
  final List<BookPage> orderedPages;

  /// Résolution rapide id → index dans [orderedPages].
  final Map<String, int> pageIdToIndex;

  /// Fiches annexes, indexées par id.
  final Map<String, AnnexSheet> annexes;

  /// Métadonnées de chaque section.
  final List<SectionInfo> sections;

  const BookIndex._({
    required this.orderedPages,
    required this.pageIdToIndex,
    required this.annexes,
    required this.sections,
  });

  // -----------------------------------------------------------------------
  // Accesseurs
  // -----------------------------------------------------------------------

  int get pageCount => orderedPages.length;

  /// Résout un id vers un index de page, ou null si inconnu.
  int? indexOfPage(String id) => pageIdToIndex[id];

  /// Retourne la page à l'index donné.
  BookPage pageAt(int index) => orderedPages[index];

  /// Retourne la section à laquelle appartient la page à [index].
  SectionInfo sectionForPageAt(int index) {
    for (final section in sections) {
      final end = section.startPageIndex + section.pageCount;
      if (index >= section.startPageIndex && index < end) {
        return section;
      }
    }
    return sections.last;
  }

  /// Retourne une fiche annexe par id, ou null.
  AnnexSheet? annex(String id) => annexes[id];

  /// Vérifie si un targetId pointe vers une page ou une annexe existante.
  bool isValidTarget(String targetId) =>
      pageIdToIndex.containsKey(targetId) || annexes.containsKey(targetId);

  // -----------------------------------------------------------------------
  // Construction
  // -----------------------------------------------------------------------

  /// Construit l'index à partir de sections brutes et de fiches annexes.
  ///
  /// - Insère des [BlankPage] en fin de section pour que chaque section
  ///   suivante commence sur une page impaire (page de droite en double page).
  /// - Valide que tous les liens internes pointent vers un id existant.
  factory BookIndex.build({
    required List<RawSection> rawSections,
    List<AnnexSheet> rawAnnexes = const [],
  }) {
    final orderedPages = <BookPage>[];
    final pageIdToIndex = <String, int>{};
    final sectionInfos = <SectionInfo>[];

    // 1. Aplatir les sections en insérant des pages blanches si nécessaire.
    for (final section in rawSections) {
      final startIndex = orderedPages.length;

      for (final page in section.pages) {
        // Vérifier l'unicité des id
        assert(
          !pageIdToIndex.containsKey(page.id),
          'Id de page dupliqué : "${page.id}"',
        );
        pageIdToIndex[page.id] = orderedPages.length;
        orderedPages.add(page);
      }

      // Si la section se termine sur une page paire (index impair = page de
      // gauche en convention occidentale page 1 = droite), insérer une page
      // blanche pour que la section suivante commence à droite.
      if (orderedPages.length.isOdd == false && section != rawSections.last) {
        // orderedPages.length est pair → le prochain index sera pair
        // → c'est déjà une page de droite, pas besoin de blank.
      }
      // Si length est impair → le prochain index serait impair = page de gauche
      // → on insère une blank pour sauter à un index pair = page de droite.
      if (orderedPages.length.isOdd && section != rawSections.last) {
        final blankId = '_blank_after_${section.id}';
        pageIdToIndex[blankId] = orderedPages.length;
        orderedPages.add(BlankPage(
          id: blankId,
          sectionId: section.id,
        ));
      }

      sectionInfos.add(SectionInfo(
        id: section.id,
        title: section.title,
        startPageIndex: startIndex,
        pageCount: orderedPages.length - startIndex,
      ));
    }

    // 2. Indexer les annexes.
    final annexMap = <String, AnnexSheet>{};
    for (final annex in rawAnnexes) {
      assert(
        !annexMap.containsKey(annex.id),
        'Id d\'annexe dupliqué : "${annex.id}"',
      );
      assert(
        !pageIdToIndex.containsKey(annex.id),
        'Id d\'annexe "${annex.id}" entre en conflit avec un id de page',
      );
      annexMap[annex.id] = annex;
    }

    final index = BookIndex._(
      orderedPages: List.unmodifiable(orderedPages),
      pageIdToIndex: Map.unmodifiable(pageIdToIndex),
      annexes: Map.unmodifiable(annexMap),
      sections: List.unmodifiable(sectionInfos),
    );

    // 3. Valider tous les liens internes.
    _validateLinks(index);

    return index;
  }

  /// Parcourt tout le contenu et vérifie que chaque LinkNode.targetId
  /// pointe vers un id existant (page ou annexe).
  static void _validateLinks(BookIndex index) {
    final allTargetIds = <String>[];

    // Collecter les liens de toutes les pages
    for (final page in index.orderedPages) {
      allTargetIds.addAll(_extractLinkTargets(page));
    }

    // Collecter les liens de toutes les annexes
    for (final annex in index.annexes.values) {
      allTargetIds.addAll(annex.allLinkTargetIds);
    }

    // Vérifier chaque lien
    for (final targetId in allTargetIds) {
      assert(
        index.isValidTarget(targetId),
        'Lien cassé : targetId "$targetId" ne pointe vers aucune page ni annexe',
      );
    }
  }

  /// Extrait les targetId de tous les RichContent d'une page.
  static Iterable<String> _extractLinkTargets(BookPage page) {
    return switch (page) {
      CoverPage() => const <String>[],
      BlankPage() => const <String>[],
      FullIllustrationPage() => const <String>[],
      ChapterIntroPage p => p.body.allLinkTargetIds,
      FlowTextPage p => p.body.allLinkTargetIds,
      RaceSheetPage p => p.description.allLinkTargetIds,
      ClassSheetPage() => const <String>[],
      WeaponTablePage() => const <String>[],
      EffectListPage() => const <String>[],
    };
  }
}
