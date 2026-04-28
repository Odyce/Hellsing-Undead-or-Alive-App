import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:page_flip/page_flip.dart';

import 'package:hellsing_undead_or_applive/domain/rulebook/book_index.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_index_provider.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_navigator.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_page.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_search.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/rich_content.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

import 'layouts/single_page_layout.dart';
import 'layouts/double_page_layout.dart';
import 'templates/annex_template.dart';
import 'templates/cover_template.dart';
import 'templates/chapter_intro_template.dart';
import 'templates/flow_text_template.dart';
import 'templates/race_sheet_template.dart';
import 'templates/class_sheet_template.dart';
import 'templates/weapon_table_template.dart';
import 'templates/effect_list_template.dart';
import 'templates/blank_template.dart';
import 'templates/full_illustration_template.dart';
import 'widgets/book_opening_animation.dart';
import 'widgets/discreet_link_popup.dart';
import 'widgets/search_overlay.dart';

/// Seuil en pixels logiques à partir duquel on bascule en double page.
const double _kDoublePageBreakpoint = 900;

class BookViewerPage extends ConsumerStatefulWidget {
  const BookViewerPage({super.key});

  @override
  ConsumerState<BookViewerPage> createState() => _BookViewerPageState();
}

class _BookViewerPageState extends ConsumerState<BookViewerPage> {
  final _flipController = GlobalKey<PageFlipWidgetState>();
  final _popupCtrl = DiscreetLinkPopupController();
  bool _searchOpen = false;

  @override
  void dispose() {
    _popupCtrl.dismiss();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Construction d'une page Flutter depuis son index
  // -------------------------------------------------------------------------

  Widget _widgetForPage(BookPage page, int displayNumber) {
    final pageNumber = switch (page) {
      CoverPage() => null,
      BlankPage() => null,
      FullIllustrationPage() => null,
      _ => displayNumber,
    };

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: switch (page) {
        CoverPage p => CoverTemplate(page: p),
        ChapterIntroPage p => ChapterIntroTemplate(
            page: p,
            pageNumber: pageNumber,
            onLinkTap: _handleLinkTap,
          ),
        FlowTextPage p => FlowTextTemplate(
            page: p,
            pageNumber: pageNumber,
            onLinkTap: _handleLinkTap,
          ),
        RaceSheetPage p => RaceSheetTemplate(
            page: p,
            pageNumber: pageNumber,
            onLinkTap: _handleLinkTap,
          ),
        ClassSheetPage p =>
          ClassSheetTemplate(page: p, pageNumber: pageNumber),
        WeaponTablePage p =>
          WeaponTableTemplate(page: p, pageNumber: pageNumber),
        EffectListPage p =>
          EffectListTemplate(page: p, pageNumber: pageNumber),
        BlankPage p => BlankTemplate(page: p, pageNumber: pageNumber),
        FullIllustrationPage p => FullIllustrationTemplate(page: p),
      },
    );
  }

  // -------------------------------------------------------------------------
  // Gestion des liens
  // -------------------------------------------------------------------------

  void _handleLinkTap(
    String targetId,
    LinkStyle style,
    Offset globalPosition,
  ) {
    _popupCtrl.dismiss();
    if (style == LinkStyle.direct) {
      _jumpTo(targetId);
    } else {
      final index = ref.read(bookIndexProvider);
      _popupCtrl.show(
        context: context,
        targetTitle: _titleForTarget(targetId, index),
        anchorPosition: globalPosition,
        onConfirm: () => _jumpTo(targetId),
      );
    }
  }

  String _titleForTarget(String targetId, BookIndex index) {
    final pageIdx = index.indexOfPage(targetId);
    if (pageIdx != null) return index.pageAt(pageIdx).title ?? targetId;
    return index.annex(targetId)?.title ?? targetId;
  }

  void _jumpTo(String targetId) {
    final navigator = ref.read(bookNavigatorProvider.notifier);
    navigator.goToPageById(targetId);
    final newState = ref.read(bookNavigatorProvider);
    if (newState.openAnnex == null) {
      _flipController.currentState?.goToPage(newState.currentPageIndex);
    }
  }

  void _goBack() {
    _popupCtrl.dismiss();
    final navigator = ref.read(bookNavigatorProvider.notifier);
    navigator.back();
    final newState = ref.read(bookNavigatorProvider);
    if (newState.openAnnex == null) {
      _flipController.currentState?.goToPage(newState.currentPageIndex);
    }
  }

  // -------------------------------------------------------------------------
  // Recherche
  // -------------------------------------------------------------------------

  void _openSearch() {
    _popupCtrl.dismiss();
    setState(() => _searchOpen = true);
  }

  void _closeSearch() {
    setState(() => _searchOpen = false);
    ref.read(searchQueryProvider.notifier).clear();
  }

  /// Appelé quand l'utilisateur sélectionne un résultat.
  /// Alimente l'historique (pushHistory = true) puisque c'est un saut explicite.
  void _onSearchResult(String pageId) {
    _closeSearch();
    final index = ref.read(bookIndexProvider);

    // Si c'est une annexe, on passe par goToPageById qui la détectera.
    if (index.annex(pageId) != null) {
      _jumpTo(pageId);
      return;
    }

    final pageIdx = index.indexOfPage(pageId);
    if (pageIdx == null) return;

    ref.read(bookNavigatorProvider.notifier)
        .goToPageIndex(pageIdx, pushHistory: true);
    _flipController.currentState?.goToPage(pageIdx);
  }

  // -------------------------------------------------------------------------
  // TopBar (mode livre uniquement)
  // -------------------------------------------------------------------------

  Widget _bookTopBar(BookNavigatorState navState) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Fermer le livre
              TextButton.icon(
                onPressed: () => SafeBackButton.pop(context),
                icon: const Icon(Icons.close, size: 18, color: Colors.white),
                label: const Text('Fermer',
                    style: TextStyle(color: Colors.white)),
              ),
              const Spacer(),
              // Bouton loupe
              IconButton(
                onPressed: _openSearch,
                icon: const Icon(Icons.search, color: Colors.white, size: 22),
                tooltip: 'Rechercher',
              ),
              // Retour historique
              if (navState.canGoBack)
                TextButton.icon(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back,
                      size: 18, color: Colors.white),
                  label: Text(
                    navState.history.length > 1
                        ? 'Retour (${navState.history.length})'
                        : 'Retour',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(bookIndexProvider);
    final navState = ref.watch(bookNavigatorProvider);
    final navigator = ref.read(bookNavigatorProvider.notifier);

    ref.listen(bookNavigatorProvider, (_, __) => _popupCtrl.dismiss());

    final isAnnexMode = navState.openAnnex != null;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 194, 116, 47),
      body: Stack(
        children: [
          // ---- Contenu principal (enveloppé par l'animation d'ouverture) -----
          BookOpeningAnimation(
            child: _BookAnnexSwitcher(
              isAnnexMode: isAnnexMode,
              bookChild: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= _kDoublePageBreakpoint) {
                      return DoublePageLayout(
                        navState: navState,
                        navigator: navigator,
                        pageCount: index.pageCount,
                        pageWidgetAt: (i) =>
                            _widgetForPage(index.pageAt(i), i + 1),
                      );
                    } else {
                      return SinglePageLayout(
                        controller: _flipController,
                        pages: [
                          for (int i = 0; i < index.pageCount; i++)
                            _widgetForPage(index.pageAt(i), i + 1),
                        ],
                      );
                    }
                  },
                ),
              ),
              annexChild: isAnnexMode
                  ? SafeArea(
                      child: Center(
                        child: SizedBox(
                          width: 600,
                          height: 800,
                          child: AnnexTemplate(
                            key: ValueKey(navState.openAnnex!.id),
                            annex: navState.openAnnex!,
                            onClose: _goBack,
                            onLinkTap: _handleLinkTap,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // ---- TopBar (masquée en mode annexe) -----------------------------
          if (!isAnnexMode) _bookTopBar(navState),

          // ---- Overlay de recherche ----------------------------------------
          if (_searchOpen)
            Positioned.fill(
              child: SearchOverlay(
                onClose: _closeSearch,
                onResultSelected: _onSearchResult,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transition slide livre ↔ annexe
// ---------------------------------------------------------------------------

class _BookAnnexSwitcher extends StatefulWidget {
  final bool isAnnexMode;
  final Widget bookChild;
  final Widget annexChild;

  const _BookAnnexSwitcher({
    required this.isAnnexMode,
    required this.bookChild,
    required this.annexChild,
  });

  @override
  State<_BookAnnexSwitcher> createState() => _BookAnnexSwitcherState();
}

class _BookAnnexSwitcherState extends State<_BookAnnexSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slideIn;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);

    if (widget.isAnnexMode) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_BookAnnexSwitcher old) {
    super.didUpdateWidget(old);
    if (widget.isAnnexMode && !old.isAnnexMode) {
      _ctrl.forward(from: 0);
    } else if (!widget.isAnnexMode && old.isAnnexMode) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.bookChild,
        AnimatedBuilder(
          animation: _ctrl,
          child: widget.annexChild,
          builder: (_, child) {
            if (_ctrl.value == 0) return const SizedBox.shrink();
            return FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: child,
              ),
            );
          },
        ),
      ],
    );
  }
}
