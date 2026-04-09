import 'package:flutter/material.dart';

/// Animation d'ouverture du livre de règles.
///
/// Séquence en 3 phases :
/// 1. La couverture apparaît en fondu + légère montée (livre "saisi").
/// 2. La couverture pivote en perspective vers la gauche (page qui tourne).
/// 3. Le contenu du livre apparaît en fondu.
///
/// Durée totale : ~1 600 ms.
/// Après la fin, [child] est rendu directement sans overhead.
class BookOpeningAnimation extends StatefulWidget {
  /// Contenu du livre affiché une fois l'animation terminée.
  final Widget child;

  /// Titre affiché sur la fausse couverture pendant l'animation.
  final String bookTitle;

  const BookOpeningAnimation({
    super.key,
    required this.child,
    this.bookTitle = 'Undead or Alive\nHellsing Foundation',
  });

  @override
  State<BookOpeningAnimation> createState() => _BookOpeningAnimationState();
}

class _BookOpeningAnimationState extends State<BookOpeningAnimation>
    with TickerProviderStateMixin {
  // ---- Couverture : apparition + pivotement --------------------------------
  late final AnimationController _coverCtrl;

  // Fondu de la couverture (apparaît puis disparaît).
  late final Animation<double> _coverOpacity;

  // Montée de la couverture (slide depuis légèrement en bas).
  late final Animation<Offset> _coverSlide;

  // Pivotement en Y (0 → -π/2 = fermer vers la gauche).
  late final Animation<double> _coverPivot;

  // ---- Livre : apparition --------------------------------------------------
  late final AnimationController _bookCtrl;
  late final Animation<double> _bookOpacity;
  late final Animation<double> _bookScale;

  bool _coverDone = false;

  // Timings (en fractions de la durée totale du coverCtrl).
  static const Duration _coverDuration = Duration(milliseconds: 1500);
  static const Duration _bookDuration = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();

    // ---- Couverture ---------------------------------------------------------
    _coverCtrl = AnimationController(vsync: this, duration: _coverDuration);

    // Fondu : 0→1 sur les 20 premiers %, 1 sur 20-55 %, 1→0 sur 55-100 %.
    _coverOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 35),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 45,
      ),
    ]).animate(_coverCtrl);

    // Slide : monte légèrement dans la première moitié, puis immobile.
    _coverSlide = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween(Offset.zero), weight: 70),
    ]).animate(_coverCtrl);

    // Pivot : commence à 55 % → s'achève à 100 %.
    _coverPivot = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 55),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -1.5708) // -π/2
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 45,
      ),
    ]).animate(_coverCtrl);

    // ---- Livre --------------------------------------------------------------
    _bookCtrl = AnimationController(vsync: this, duration: _bookDuration);
    _bookOpacity =
        CurvedAnimation(parent: _bookCtrl, curve: Curves.easeIn);
    _bookScale = Tween<double>(begin: 0.97, end: 1.0)
        .animate(CurvedAnimation(parent: _bookCtrl, curve: Curves.easeOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Petite pause avant que tout commence (le Scaffold a le temps de se poser).
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    await _coverCtrl.forward();
    if (!mounted) return;

    setState(() => _coverDone = true);
    _bookCtrl.forward();
  }

  @override
  void dispose() {
    _coverCtrl.dispose();
    _bookCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_coverDone) {
      // Animation terminée : on affiche le livre directement (fondu final).
      return FadeTransition(
        opacity: _bookOpacity,
        child: ScaleTransition(
          scale: _bookScale,
          child: widget.child,
        ),
      );
    }

    return Stack(
      children: [
        // Le contenu du livre est en dessous (invisible, prêt à apparaître).
        Opacity(opacity: 0, child: widget.child),

        // Couverture par-dessus.
        AnimatedBuilder(
          animation: _coverCtrl,
          builder: (_, __) {
            return SlideTransition(
              position: _coverSlide,
              child: Opacity(
                opacity: _coverOpacity.value.clamp(0.0, 1.0),
                child: Transform(
                  alignment: Alignment.centerLeft,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0008) // perspective
                    ..rotateY(_coverPivot.value),
                  child: _AnimatedCover(title: widget.bookTitle),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Fausse couverture
// ---------------------------------------------------------------------------

class _AnimatedCover extends StatelessWidget {
  final String title;

  const _AnimatedCover({required this.title});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fond parchemin.
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF3E6C8),
              image: DecorationImage(
                image: AssetImage("assets/images/parchment.jpg"),
                fit: BoxFit.fill,
              ),
            ),
          ),

          // Bordure rouge sang simulant la tranche.
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF8B0000), width: 3),
            ),
          ),

          // Ornement haut.
          const Positioned(
            top: 32,
            left: 0,
            right: 0,
            child: _HorizontalRule(),
          ),

          // Titre centré.
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cinzel Decorative',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B2410),
                  height: 1.4,
                ),
              ),
            ),
          ),

          // Ornement bas.
          const Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: _HorizontalRule(),
          ),

          // Ombre intérieure gauche (simulation de reliure).
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withAlpha(80),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.08],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trait décoratif horizontal avec petits ornements.
class _HorizontalRule extends StatelessWidget {
  const _HorizontalRule();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          const _Diamond(),
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFF8B0000),
            ),
          ),
          const _Diamond(),
        ],
      ),
    );
  }
}

class _Diamond extends StatelessWidget {
  const _Diamond();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.785, // 45°
      child: Container(
        width: 7,
        height: 7,
        color: const Color(0xFF8B0000),
      ),
    );
  }
}
