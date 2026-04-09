import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'annex_sheet.dart';
import 'book_index.dart';
import 'book_index_provider.dart';

// ---------------------------------------------------------------------------
// État
// ---------------------------------------------------------------------------

/// État immutable du navigateur de livre.
class BookNavigatorState {
  /// Index de la page courante dans [BookIndex.orderedPages].
  final int currentPageIndex;

  /// Pile d'historique : chaque entrée est l'index de page d'où on a sauté.
  /// Alimentée uniquement par des sauts explicites (liens, recherche, annexes).
  final List<int> history;

  /// Fiche annexe actuellement ouverte, ou null si on est dans le livre.
  final AnnexSheet? openAnnex;

  const BookNavigatorState({
    this.currentPageIndex = 0,
    this.history = const [],
    this.openAnnex,
  });

  bool get canGoBack => history.isNotEmpty || openAnnex != null;

  BookNavigatorState copyWith({
    int? currentPageIndex,
    List<int>? history,
    AnnexSheet? openAnnex,
    bool clearAnnex = false,
  }) {
    return BookNavigatorState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      history: history ?? this.history,
      openAnnex: clearAnnex ? null : (openAnnex ?? this.openAnnex),
    );
  }
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Gère la navigation dans le livre de règles.
///
/// - [goToPageById] / [openAnnexById] : sauts explicites → alimentent l'historique.
/// - [nextPage] / [previousPage] / [goToPageIndex] : feuilletage → pas d'historique.
/// - [back] : dépile l'historique (ou ferme l'annexe si une est ouverte).
class BookNavigator extends Notifier<BookNavigatorState> {
  @override
  BookNavigatorState build() => const BookNavigatorState();

  BookIndex get _index => ref.read(bookIndexProvider);

  // -------------------------------------------------------------------------
  // Sauts qui alimentent l'historique
  // -------------------------------------------------------------------------

  /// Saute à la page identifiée par [id].
  /// Si [id] est un id d'annexe, ouvre l'annexe à la place.
  /// Push l'index courant dans l'historique.
  void goToPageById(String id) {
    final pageIndex = _index.indexOfPage(id);
    if (pageIndex != null) {
      _pushHistory();
      state = state.copyWith(currentPageIndex: pageIndex, clearAnnex: true);
      return;
    }
    final annex = _index.annex(id);
    if (annex != null) {
      _pushHistory();
      state = state.copyWith(openAnnex: annex);
    }
  }

  /// Ouvre une fiche annexe par son id.
  /// Push l'index courant dans l'historique.
  void openAnnexById(String id) {
    final annex = _index.annex(id);
    if (annex == null) return;
    _pushHistory();
    state = state.copyWith(openAnnex: annex);
  }

  // -------------------------------------------------------------------------
  // Feuilletage — pas d'historique
  // -------------------------------------------------------------------------

  /// Avance d'une page (ne touche pas à l'historique).
  void nextPage() {
    if (state.openAnnex != null) return;
    final next = state.currentPageIndex + 1;
    if (next < _index.pageCount) {
      state = state.copyWith(currentPageIndex: next);
    }
  }

  /// Recule d'une page (ne touche pas à l'historique).
  void previousPage() {
    if (state.openAnnex != null) return;
    final prev = state.currentPageIndex - 1;
    if (prev >= 0) {
      state = state.copyWith(currentPageIndex: prev);
    }
  }

  /// Va directement à un index (utilisé par le PageFlipWidget).
  /// [pushHistory] permet de l'alimenter exceptionnellement (ex. recherche).
  void goToPageIndex(int index, {bool pushHistory = false}) {
    if (index < 0 || index >= _index.pageCount) return;
    if (pushHistory) _pushHistory();
    state = state.copyWith(currentPageIndex: index, clearAnnex: true);
  }

  // -------------------------------------------------------------------------
  // Navigation par double page (spreads) — pas d'historique
  // -------------------------------------------------------------------------

  /// Numéro de planche (spread) courant.
  ///
  /// Convention occidental : page[0] est la page de droite de la planche 0.
  /// - spread 0 → gauche : vide, droite : page[0]
  /// - spread k>0 → gauche : page[2k-1], droite : page[2k]
  ///
  /// Formule : spreadIndex = (pageIndex + 1) ~/ 2  (valide pour tout index ≥ 0)
  int get currentSpreadIndex => (state.currentPageIndex + 1) ~/ 2;

  /// Index de la première page (gauche) d'un spread donné.
  /// spread 0 → page 0 (qui s'affiche à droite seule)
  /// spread k → page 2k-1 (page gauche)
  int firstPageOfSpread(int spread) => spread == 0 ? 0 : 2 * spread - 1;

  /// Nombre total de planches.
  int get spreadCount =>
      (_index.pageCount + 1) ~/ 2 + (_index.pageCount.isOdd ? 0 : 0);

  /// Avance d'une planche (2 pages).
  void nextSpread() {
    if (state.openAnnex != null) return;
    final nextSpreadIdx = currentSpreadIndex + 1;
    final nextPageIdx = firstPageOfSpread(nextSpreadIdx);
    if (nextPageIdx < _index.pageCount) {
      state = state.copyWith(currentPageIndex: nextPageIdx);
    }
  }

  /// Recule d'une planche (2 pages).
  void prevSpread() {
    if (state.openAnnex != null) return;
    final prevSpreadIdx = currentSpreadIndex - 1;
    if (prevSpreadIdx < 0) return;
    state = state.copyWith(
      currentPageIndex: firstPageOfSpread(prevSpreadIdx),
    );
  }

  // -------------------------------------------------------------------------
  // Historique
  // -------------------------------------------------------------------------

  /// Dépile l'historique.
  /// Si une annexe est ouverte, la ferme d'abord (retour au livre).
  void back() {
    if (state.openAnnex != null) {
      // Fermer l'annexe : l'entrée au top de la pile est l'index d'avant l'annexe.
      if (state.history.isNotEmpty) {
        final prev = state.history.last;
        state = BookNavigatorState(
          currentPageIndex: prev,
          history: state.history.sublist(0, state.history.length - 1),
          openAnnex: null,
        );
      } else {
        state = state.copyWith(clearAnnex: true);
      }
      return;
    }
    if (state.history.isNotEmpty) {
      final prev = state.history.last;
      state = BookNavigatorState(
        currentPageIndex: prev,
        history: state.history.sublist(0, state.history.length - 1),
        openAnnex: null,
      );
    }
  }

  /// Ferme l'annexe ouverte (sans modifier l'historique au-delà).
  void closeAnnex() {
    if (state.openAnnex == null) return;
    back(); // back() gère correctement la fermeture d'annexe
  }

  // -------------------------------------------------------------------------
  // Interne
  // -------------------------------------------------------------------------

  void _pushHistory() {
    state = state.copyWith(
      history: [...state.history, state.currentPageIndex],
    );
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final bookNavigatorProvider =
    NotifierProvider<BookNavigator, BookNavigatorState>(BookNavigator.new);
