import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_navigator.dart';

/// Layout desktop : deux pages côte à côte (planche ouverte façon livre).
///
/// Convention occidentale :
/// - Planche 0 → gauche vide, droite = page[0] (couverture).
/// - Planche k (k > 0) → gauche = page[2k-1], droite = page[2k].
///
/// Navigation :
/// - Swipe horizontal ou flèches latérales → planche suivante / précédente.
/// - Transition : CrossFade entre les planches.
///
/// Le parent doit fournir [pageWidgetAt] pour construire la page à un index donné
/// (identique à `_widgetForPage` dans BookViewerPage).
class DoublePageLayout extends StatefulWidget {
  final BookNavigatorState navState;
  final BookNavigator navigator;

  /// Construit le widget Flutter pour la page à [index].
  final Widget Function(int index) pageWidgetAt;

  /// Nombre total de pages dans le BookIndex.
  final int pageCount;

  const DoublePageLayout({
    super.key,
    required this.navState,
    required this.navigator,
    required this.pageWidgetAt,
    required this.pageCount,
  });

  @override
  State<DoublePageLayout> createState() => _DoublePageLayoutState();
}

class _DoublePageLayoutState extends State<DoublePageLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;

  // Planche affichée avant la transition (pour le fondu).
  int _displayedSpread = 0;
  bool _animating = false;

  /// Largeur maximale d'une page en mode double (points Flutter).
  static const double _pageMaxWidth = 520;
  static const double _pageMaxHeight = 780;
  static const double _pageGutterWidth = 12; // gouttière entre les deux pages
  static const double _arrowZoneWidth = 48;

  @override
  void initState() {
    super.initState();
    _displayedSpread = widget.navigator.currentSpreadIndex;
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeInOut);
  }

  @override
  void didUpdateWidget(DoublePageLayout old) {
    super.didUpdateWidget(old);
    final newSpread = widget.navigator.currentSpreadIndex;
    if (newSpread != _displayedSpread && !_animating) {
      _animateTo(newSpread);
    }
  }

  Future<void> _animateTo(int spread) async {
    _animating = true;
    await _anim.forward(from: 0);
    if (!mounted) return;
    setState(() => _displayedSpread = spread);
    await _anim.reverse();
    if (mounted) _animating = false;
  }

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  void _onHorizontalDrag(DragEndDetails details) {
    const threshold = 60.0;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -threshold) {
      widget.navigator.nextSpread();
    } else if (velocity > threshold) {
      widget.navigator.prevSpread();
    }
  }

  // -------------------------------------------------------------------------
  // Construction des pages d'une planche
  // -------------------------------------------------------------------------

  /// Retourne (leftIndex, rightIndex) pour la planche [spread].
  /// leftIndex peut être null (planche 0 = couverture seule à droite).
  (int?, int?) _indicesForSpread(int spread) {
    if (spread == 0) return (null, 0);
    final left = 2 * spread - 1;
    final right = 2 * spread;
    return (
      left < widget.pageCount ? left : null,
      right < widget.pageCount ? right : null,
    );
  }

  Widget _pageSlot(int? index, {required bool isRight}) {
    return SizedBox(
      width: _pageMaxWidth,
      height: _pageMaxHeight,
      child: index != null
          ? widget.pageWidgetAt(index)
          : _EmptyPageSlot(isRight: isRight),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final (leftIdx, rightIdx) = _indicesForSpread(_displayedSpread);
    final canGoNext = widget.navigator.firstPageOfSpread(
          _displayedSpread + 1,
        ) <
        widget.pageCount;
    final canGoPrev = _displayedSpread > 0;

    return GestureDetector(
      onHorizontalDragEnd: _onHorizontalDrag,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ---- Flèche gauche ----
            _NavArrow(
              icon: Icons.chevron_left,
              enabled: canGoPrev,
              onTap: widget.navigator.prevSpread,
              width: _arrowZoneWidth,
            ),

            // ---- Planche ----
            FadeTransition(
              opacity: _fade.drive(
                Tween<double>(begin: 1.0, end: 0.0),
              ),
              child: _SpreadWidget(
                leftSlot: _pageSlot(leftIdx, isRight: false),
                rightSlot: _pageSlot(rightIdx, isRight: true),
                gutterWidth: _pageGutterWidth,
                pageHeight: _pageMaxHeight,
              ),
            ),

            // ---- Flèche droite ----
            _NavArrow(
              icon: Icons.chevron_right,
              enabled: canGoNext,
              onTap: widget.navigator.nextSpread,
              width: _arrowZoneWidth,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets internes
// ---------------------------------------------------------------------------

/// Affiche deux pages côte à côte avec une gouttière (reliure simulée).
class _SpreadWidget extends StatelessWidget {
  final Widget leftSlot;
  final Widget rightSlot;
  final double gutterWidth;
  final double pageHeight;

  const _SpreadWidget({
    required this.leftSlot,
    required this.rightSlot,
    required this.gutterWidth,
    required this.pageHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: pageHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page gauche avec ombre intérieure droite (reliure).
          _PageShadow(side: _ShadowSide.right, child: leftSlot),
          // Gouttière (dos du livre).
          Container(
            width: gutterWidth,
            height: pageHeight,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B2410), Color(0xFF5C3A1E), Color(0xFF3B2410)],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
          // Page droite avec ombre intérieure gauche (reliure).
          _PageShadow(side: _ShadowSide.left, child: rightSlot),
        ],
      ),
    );
  }
}

enum _ShadowSide { left, right }

/// Ajoute une ombre intérieure sur un côté pour simuler la courbure de reliure.
class _PageShadow extends StatelessWidget {
  final Widget child;
  final _ShadowSide side;

  const _PageShadow({required this.child, required this.side});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: side == _ShadowSide.left
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  end: side == _ShadowSide.left
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  colors: const [
                    Color(0x33000000),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.12],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Emplacement vide (quand une planche n'a pas de page d'un côté).
/// Affiche le même fond bois que le Scaffold pour paraître "invisible".
class _EmptyPageSlot extends StatelessWidget {
  final bool isRight;

  const _EmptyPageSlot({required this.isRight});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}

/// Flèche de navigation latérale semi-transparente.
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final double width;

  const _NavArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: enabled
          ? GestureDetector(
              onTap: onTap,
              child: Icon(
                icon,
                size: 36,
                color: const Color(0xCCF3E6C8),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
