import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';

/// Page de transition : joue le GIF "OpenDoorAlpha.gif" une seule fois
/// par-dessus la [HomePage], puis laisse la HomePage visible.
class DoorTransitionPage extends StatefulWidget {
  const DoorTransitionPage({super.key});

  @override
  State<DoorTransitionPage> createState() => _DoorTransitionPageState();
}

class _DoorTransitionPageState extends State<DoorTransitionPage> {
  ui.Image? _currentFrame;
  bool _animationDone = false;

  @override
  void initState() {
    super.initState();
    _playGif();
  }

  Future<void> _playGif() async {
    final data = await rootBundle.load('assets/backgrounds/OpenDoorAlpha.gif');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());

    for (int i = 0; i < codec.frameCount; i++) {
      final frameInfo = await codec.getNextFrame();
      if (!mounted) {
        frameInfo.image.dispose();
        codec.dispose();
        return;
      }

      final oldFrame = _currentFrame;
      setState(() => _currentFrame = frameInfo.image);
      oldFrame?.dispose();

      await Future.delayed(frameInfo.duration);
    }

    codec.dispose();
    if (mounted) {
      final lastFrame = _currentFrame;
      setState(() {
        _animationDone = true;
        _currentFrame = null;
      });
      lastFrame?.dispose();
    }
  }

  @override
  void dispose() {
    _currentFrame?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // HomePage visible derrière le GIF (transparence alpha)
        const HomePage(),

        // Overlay GIF — affiché tant que l'animation n'est pas terminée
        if (!_animationDone)
          Positioned.fill(
            child: _currentFrame != null
                ? RawImage(
                    image: _currentFrame,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : const ColoredBox(color: Colors.black),
          ),
      ],
    );
  }
}
