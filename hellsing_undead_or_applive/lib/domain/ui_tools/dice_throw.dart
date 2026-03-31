import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

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

  // ─── EXCEPTION : Déclenchement de la carte spéciale ───────────────────────
  if (maxValue == 100 && result == 66) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87, // Un peu plus sombre pour l'animation
      transitionDuration: Duration.zero,
      pageBuilder: (ctx, _, __) => const _CardFlipOverlay(),
    );
    return; // On arrête l'exécution ici pour ne pas afficher l'overlay classique
  }

  // --- Détermination du message et de sa couleur ---
  String message;
  Color messageColor;

  if ((maxValue == 100 && result < threshold) && (result == 65 || result == 67)) {
    message = "Réussite (🤏)";
    messageColor = Colors.green;
  } else if ((maxValue == 100 && result < threshold) && (result == 65 || result == 67)) {
    message = "Échec (🤏)";
    messageColor = Colors.red;
  } else if (maxValue == 100 && result < 6) {
    message = "Réussite Critique";
    messageColor = Colors.green;
  } else if (maxValue == 100 && result > 95) {
    message = "Échec Critique";
    messageColor = Colors.red;
  } else if (maxValue == 100 && result >= 5 && result * 2 <= threshold) {
    // result <= moitié du seuil (comparaison entière : result*2 <= threshold)
    message = "Inesquivable";
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

    return GestureDetector(
      // HitTestBehavior.opaque permet de détecter le clic même dans le vide
      behavior: HitTestBehavior.opaque, 
      onTap: () {
        // Ferme immédiatement l'overlay au clic
        if (mounted) Navigator.of(context).pop();
      },
      child:AnimatedBuilder(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
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
                const SizedBox(width: 10),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: widget.messageColor,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }
}

// ===========================================================================
// Second overlay : Animation de carte 3D avec Audio
// ===========================================================================
class _CardFlipOverlay extends StatefulWidget {
  const _CardFlipOverlay();
  @override
  State<_CardFlipOverlay> createState() => _CardFlipOverlayState();
}
class _CardFlipOverlayState extends State<_CardFlipOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  late final Animation<double> _spinAnimation;

  // Lecteur pour le son final d'impact
  final AudioPlayer _audioPlayerStop = AudioPlayer();
    
  // "Pool" de lecteurs pour éviter que les sons ne se coupent entre eux
  // quand la carte tourne très vite au début
  final List<AudioPlayer> _audioPool = List.generate(4, (_) => AudioPlayer());
  int _poolIndex = 0;
  int _lastCross = 0;

  bool _isFaceA = true;
  bool _animationFinished = false;
  
  @override
  void initState() {
    super.initState();
    
    // 1. Détermination du résultat final (Pile ou Face aléatoire)
    _isFaceA = Random().nextBool();
    
    // 2. Calcul de la rotation cible
    // On fait tourner la carte 8 fois complètes (8 * 2 * pi)
    // Et on rajoute un demi-tour (pi) si on doit atterrir sur la face B
    final double targetRotation = (8 * 2 * pi) + (_isFaceA ? 0 : pi);
    
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Durée du ralentissement
    );
    
    // Curves.easeOutCubic donne cet effet de roue de la fortune qui ralentit
    _spinAnimation = Tween<double>(begin: 0, end: targetRotation).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );

    // On écoute l'animation à chaque frame pour déclencher les sons
    _spinAnimation.addListener(_onSpinUpdate);

    _startSequence();
  }

  void _onSpinUpdate() {
    // Calcul mathématique : On détecte chaque fois que la carte est de "profil"
    // face à la caméra (ce qui correspond à pi/2, 3pi/2, 5pi/2...)
    int currentCross = ((_spinAnimation.value + (pi / 2)) / pi).floor();
    
    if (currentCross > _lastCross) {
      _lastCross = currentCross;
      _playSpinSound();
    }
  }

  Future<void> _playSpinSound() async {
    // On prend un lecteur libre dans notre pool
    final player = _audioPool[_poolIndex];
    _poolIndex = (_poolIndex + 1) % _audioPool.length;

    // Calcul de la vitesse du son.
    // _spinController.value va de 0.0 (début) à 1.0 (fin de l'animation).
    // Au début, on veut lire le son vite (ex: 2.0x). À la fin, plus lentement (ex: 0.5x).
    // On vérifie d'abord si on n'est PAS sur Windows avant de changer la vitesse
    if (defaultTargetPlatform != TargetPlatform.windows) {
      double rate = 0.5 + 1.5 * (1.0 - _spinController.value);
    
      // Sécurité : audioplayers accepte généralement un playbackRate entre 0.5 et 2.0
      rate = rate.clamp(0.5, 2.0);
      try {
        await player.setPlaybackRate(rate);
      } catch (e) {
        // Sécurité supplémentaire : si le lecteur refuse, on ignore l'erreur
        // pour ne pas faire crasher l'animation.
      }
    }

    // On joue le son
    try {
      await player.play(AssetSource('dice_throw/whoosh.mp3')); 
    } catch (e) {
      // Évite que l'appli plante si le fichier n'est pas trouvé
      debugPrint("Erreur de lecture audio : $e");
    }
  }
  
  Future<void> _startSequence() async {
    await _spinController.forward();
    
    // L'animation est terminée
    setState(() {
      _animationFinished = true;
    });
    
    // Joue le son d'impact
    await _audioPlayerStop.play(AssetSource('dice_throw/MEHEH.mp3'));
    
    // Attend 3 secondes pour que l'utilisateur lise la carte, puis ferme l'overlay
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
  @override
  void dispose() {
    _spinController.dispose();
    _audioPlayerStop.dispose();
    for (var player in _audioPool) {
      player.dispose();
    }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        // Optionnel : permettre à l'utilisateur de passer l'animation en cliquant
        if (_animationFinished && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Center(
        child: AnimatedBuilder(
          animation: _spinAnimation,
          builder: (context, child) {
            final angle = _spinAnimation.value;
            // Détermine quelle face on est en train de regarder
            // Si l'angle (divisé par pi) est pair, on regarde l'avant
            final isFrontVisible = (angle / pi).floor().isEven;
            return Transform(
              alignment: Alignment.center,
              // L'astuce magique pour donner un effet de perspective 3D au lieu d'un simple écrasement 2D
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateY(angle),
              child: isFrontVisible
                  ? _buildCardFace(isFaceA: true)
                  // Quand on affiche l'arrière, il faut lui appliquer une rotation miroir de Pi,
                  // sinon son contenu serait affiché à l'envers.
                  : Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..rotateY(pi),
                      child: _buildCardFace(isFaceA: false),
                    ),
            );
          },
        ),
      ),
    );
  }
  
  // Design générique de la carte. Vous pouvez le personnaliser !
  Widget _buildCardFace({required bool isFaceA}) {
    final String imagePath = isFaceA
        ? 'assets/dice_throw/cest_un_66.png'
        : 'assets/dice_throw/cest_un_autre_66.png';

    return Container(
      width: 220,
      height: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 64, 7, 7), width: 4),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))
        ],
      ),
      
      // ClipRRect permet de couper les coins de l'image pour qu'ils respectent
      // le BorderRadius du Container (16 - 4 d'épaisseur de bordure = 12)
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover, // Assure que l'image remplisse toute la carte
          // errorBuilder est toujours utile au cas où le nom du fichier change
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image, color: Colors.white, size: 50),
          ),
        ),
      ),
    );
  }
}
