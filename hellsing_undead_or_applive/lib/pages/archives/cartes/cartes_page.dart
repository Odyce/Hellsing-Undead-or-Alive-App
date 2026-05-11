import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class CartesPage extends StatelessWidget {
  const CartesPage({super.key});

  static const _activitesMidianes =
      'assets/map/Hellsing__Activites_Midianes_V1 (1).jpg';
  static const _railways =
      'assets/map/Hellsing__Great_Britain_Railways_V2.1.jpg';
  static const _londonSurface =
      'assets/map/Hellsing_Foundation__London_surface_V1.jpg';
  static const _londonUnderground =
      'assets/map/Hellsing_Foundation__London_Underground.jpg';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/backgrounds/Archives.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Cartes",
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    isScrollable: true,
                    labelStyle: GoogleFonts.cinzelDecorative(fontSize: 13),
                    unselectedLabelStyle:
                        GoogleFonts.cinzelDecorative(fontSize: 13),
                    tabs: const [
                      Tab(text: "Activités Midianes"),
                      Tab(text: "Chemins de fer"),
                      Tab(text: "Londres"),
                    ],
                  ),
                  const Expanded(
                    child: TabBarView(
                      children: [
                        _SingleMapViewer(
                          assetPath: _activitesMidianes,
                          label: 'Carte des Activités Midianes Anglaises',
                        ),
                        _SingleMapViewer(
                          assetPath: _railways,
                          label: 'Carte des chemins de fers britanniques',
                        ),
                        _LondonMapViewer(
                          surfacePath: _londonSurface,
                          undergroundPath: _londonUnderground,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SafeBackButtonOverlay(),
          ],
        ),
      ),
    );
  }
}

/// Viewer zoomable simple : pinch/pan + double-tap pour reset.
class _SingleMapViewer extends StatefulWidget {
  final String assetPath;
  final String label;

  const _SingleMapViewer({required this.assetPath, required this.label});

  @override
  State<_SingleMapViewer> createState() => _SingleMapViewerState();
}

class _SingleMapViewerState extends State<_SingleMapViewer> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    // Reset si déjà zoomé, sinon zoom x2.5 centré sur le point tappé.
    final currentScale = _controller.value.getMaxScaleOnAxis();
    if (currentScale > 1.01) {
      _controller.value = Matrix4.identity();
    } else if (_doubleTapDetails != null) {
      final position = _doubleTapDetails!.localPosition;
      const targetScale = 2.5;
      final x = -position.dx * (targetScale - 1);
      final y = -position.dy * (targetScale - 1);
      _controller.value = Matrix4.identity()
        ..translateByDouble(x, y, 0, 1)
        ..scaleByDouble(targetScale, targetScale, targetScale, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: Colors.black.withValues(alpha: 0.35),
          child: GestureDetector(
            onDoubleTapDown: (d) => _doubleTapDetails = d,
            onDoubleTap: _handleDoubleTap,
            child: InteractiveViewer(
              transformationController: _controller,
              minScale: 1.0,
              maxScale: 8.0,
              child: Image.asset(
                widget.assetPath,
                fit: BoxFit.contain,
                semanticLabel: widget.label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Viewer pour Londres : Surface ↔ Sous-sol, zoom/pan partagé.
///
/// Un seul TransformationController est utilisé par l'InteractiveViewer ;
/// l'enfant est un IndexedStack qui swappe l'image affichée sans détruire
/// la transformation, donc la position de zoom est conservée au switch.
class _LondonMapViewer extends StatefulWidget {
  final String surfacePath;
  final String undergroundPath;

  const _LondonMapViewer({
    required this.surfacePath,
    required this.undergroundPath,
  });

  @override
  State<_LondonMapViewer> createState() => _LondonMapViewerState();
}

class _LondonMapViewerState extends State<_LondonMapViewer> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _showUnderground = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final currentScale = _controller.value.getMaxScaleOnAxis();
    if (currentScale > 1.01) {
      _controller.value = Matrix4.identity();
    } else if (_doubleTapDetails != null) {
      final position = _doubleTapDetails!.localPosition;
      const targetScale = 2.5;
      final x = -position.dx * (targetScale - 1);
      final y = -position.dy * (targetScale - 1);
      _controller.value = Matrix4.identity()
        ..translateByDouble(x, y, 0, 1)
        ..scaleByDouble(targetScale, targetScale, targetScale, 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: GestureDetector(
                  onDoubleTapDown: (d) => _doubleTapDetails = d,
                  onDoubleTap: _handleDoubleTap,
                  child: InteractiveViewer(
                    transformationController: _controller,
                    minScale: 1.0,
                    maxScale: 8.0,
                    child: IndexedStack(
                      sizing: StackFit.expand,
                      index: _showUnderground ? 1 : 0,
                      children: [
                        Image.asset(widget.surfacePath, fit: BoxFit.contain),
                        Image.asset(widget.undergroundPath, fit: BoxFit.contain),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _LevelToggle(
                showUnderground: _showUnderground,
                onChanged: (v) => setState(() => _showUnderground = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelToggle extends StatelessWidget {
  final bool showUnderground;
  final ValueChanged<bool> onChanged;

  const _LevelToggle({
    required this.showUnderground,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SegmentButton(
              label: 'Surface',
              selected: !showUnderground,
              onTap: () => onChanged(false),
            ),
            _SegmentButton(
              label: 'Sous-sol',
              selected: showUnderground,
              onTap: () => onChanged(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: GoogleFonts.cinzelDecorative(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
