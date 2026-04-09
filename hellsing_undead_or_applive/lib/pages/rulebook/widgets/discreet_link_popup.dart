import 'package:flutter/material.dart';

/// Popup positionnée pour les liens discrets du livre de règles.
///
/// Insérée dans l'[Overlay] via [DiscreetLinkPopupController.show].
/// Apparaît en dessous (ou au-dessus) du mot tapé. Un tap en dehors la ferme.
/// Un tap sur le bouton de confirmation déclenche le saut.
///
/// Usage :
/// ```dart
/// final ctrl = DiscreetLinkPopupController();
/// ctrl.show(
///   context: context,
///   targetTitle: 'Choisir sa race',
///   anchorPosition: globalOffset,
///   onConfirm: () => jumpTo('race_vampire'),
/// );
/// ```
class DiscreetLinkPopupController {
  OverlayEntry? _entry;

  bool get isVisible => _entry != null;

  void show({
    required BuildContext context,
    required String targetTitle,
    required Offset anchorPosition,
    required VoidCallback onConfirm,
  }) {
    dismiss();

    _entry = OverlayEntry(
      builder: (_) => _DiscreetLinkPopupOverlay(
        targetTitle: targetTitle,
        anchorPosition: anchorPosition,
        onConfirm: () {
          dismiss();
          onConfirm();
        },
        onDismiss: dismiss,
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

// ---------------------------------------------------------------------------
// Widget interne
// ---------------------------------------------------------------------------

class _DiscreetLinkPopupOverlay extends StatefulWidget {
  final String targetTitle;
  final Offset anchorPosition;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  const _DiscreetLinkPopupOverlay({
    required this.targetTitle,
    required this.anchorPosition,
    required this.onConfirm,
    required this.onDismiss,
  });

  @override
  State<_DiscreetLinkPopupOverlay> createState() =>
      _DiscreetLinkPopupOverlayState();
}

class _DiscreetLinkPopupOverlayState
    extends State<_DiscreetLinkPopupOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  static const _popupWidth = 220.0;
  static const _popupHeight = 82.0;
  static const _verticalOffset = 12.0; // espace sous le mot tapé

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculer la position en clampant aux bords de l'écran.
    double left = widget.anchorPosition.dx - _popupWidth / 2;
    double top = widget.anchorPosition.dy + _verticalOffset;

    left = left.clamp(8.0, screenSize.width - _popupWidth - 8);

    // Si le popup dépasserait en bas, on l'affiche au-dessus du tap.
    if (top + _popupHeight > screenSize.height - 16) {
      top = widget.anchorPosition.dy - _popupHeight - _verticalOffset;
    }

    return Stack(
      children: [
        // Barrière transparente — tap en dehors ferme la popup.
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),

        // Popup elle-même.
        Positioned(
          left: left,
          top: top,
          width: _popupWidth,
          child: FadeTransition(
            opacity: _opacity,
            child: ScaleTransition(
              scale: _scale,
              alignment: Alignment.topCenter,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF5EDD8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF8B0000),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.targetTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Cinzel Decorative',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3B2410),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: widget.onConfirm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B0000),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Aller à cette page  →',
                              style: TextStyle(
                                fontFamily: 'EBGaramond',
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
    );
  }
}
