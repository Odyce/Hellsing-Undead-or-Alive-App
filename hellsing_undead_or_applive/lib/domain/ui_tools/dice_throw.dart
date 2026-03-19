import 'dart:math';

import 'package:flutter/material.dart';

/// Simule un lancer de dé et affiche le résultat dans un carré central
/// avec fade-in (0.5 s), affichage (3 s), puis fade-out (0.8 s).
///
/// [maxValue] : valeur maximale du dé (le résultat sera entre 1 et maxValue).
/// [threshold] : seuil de réussite (résultat <= threshold = réussite).
void showDiceThrow(
  BuildContext context, {
  required int maxValue,
  required int threshold,
}) {
  final result = Random().nextInt(maxValue) + 1;

  // --- Détermination du message et de sa couleur ---
  String message;
  Color messageColor;

  if (maxValue == 100 && result == 66) {
    // 66 : toujours prioritaire
    message = "Dommage :)";
    messageColor = Colors.red;
  } else if (maxValue == 100 && result < 5) {
    message = "Réussite Critique";
    messageColor = Colors.green;
  } else if (maxValue == 100 && result > 95) {
    message = "Échec Critique";
    messageColor = Colors.red;
  } else if (maxValue == 100 && result >= 5 && result * 2 <= threshold) {
    // result <= moitié du seuil (comparaison entière : result*2 <= threshold)
    message = "Inesquivalbe";
    messageColor = Colors.green;
  } else if (result <= threshold) {
    message = "Réussite";
    messageColor = Colors.green;
  } else {
    message = "Échec";
    messageColor = Colors.red;
  }

  showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, __) => _DiceResultOverlay(
      result: result,
      message: message,
      messageColor: messageColor,
    ),
  );
}

// ---------------------------------------------------------------------------
// Overlay animé : fade-in 0.5 s → visible 3 s → fade-out 0.8 s
// ---------------------------------------------------------------------------
class _DiceResultOverlay extends StatefulWidget {
  final int result;
  final String message;
  final Color messageColor;

  const _DiceResultOverlay({
    required this.result,
    required this.message,
    required this.messageColor,
  });

  @override
  State<_DiceResultOverlay> createState() => _DiceResultOverlayState();
}

class _DiceResultOverlayState extends State<_DiceResultOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  // Durées
  static const _fadeIn = Duration(milliseconds: 500);
  static const _visible = Duration(seconds: 3);
  static const _fadeOut = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();

    final totalMs =
        _fadeIn.inMilliseconds + _visible.inMilliseconds + _fadeOut.inMilliseconds;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    // Calcul des fractions de temps pour le TweenSequence
    final fadeInFrac = _fadeIn.inMilliseconds / totalMs;
    final visibleFrac = _visible.inMilliseconds / totalMs;
    final fadeOutFrac = _fadeOut.inMilliseconds / totalMs;

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: fadeInFrac),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: visibleFrac),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: fadeOutFrac),
    ]).animate(_controller);

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final boxSize = screenHeight / 4.5;

    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: child,
      ),
      child: Center(
        child: Container(
          width: boxSize * 1.6,
          height: boxSize,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${widget.result}",
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.messageColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
