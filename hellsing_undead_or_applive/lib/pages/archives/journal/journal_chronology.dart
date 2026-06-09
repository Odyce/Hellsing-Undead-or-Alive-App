import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart' show PointerScrollEvent, PointerSignalEvent;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hellsing_undead_or_applive/domain/archives/journal_entry.dart';
import 'package:hellsing_undead_or_applive/pages/archives/mission/mission_chronology.dart'
    show SlowPageScrollPhysics;
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

const List<String> _romanMonths = [
  'I', 'II', 'III', 'IV', 'V', 'VI',
  'VII', 'VIII', 'IX', 'X', 'XI', 'XII',
];

class JournalChronologyPage extends StatefulWidget {
  const JournalChronologyPage({super.key});

  @override
  State<JournalChronologyPage> createState() => _JournalChronologyPageState();
}

class _JournalChronologyPageState extends State<JournalChronologyPage> {
  // Espacement entre items en fraction de la LARGEUR totale.
  static const double _itemSpacingFraction = 0.30;

  PageController? _pageController;

  // Recale le carousel sur la page la plus proche quand la molette s'arrête.
  Timer? _wheelSettleTimer;

  List<JournalEntry> _entries = [];
  bool _loading = true;
  String? _error;

  bool _isAdmin = false;

  // ─── Valeurs uniques pour chaque strip (triées ascendant : ancien → récent)
  late List<int> _uniqueYears = const [];
  late List<int> _uniqueMonths = const [];
  late List<int> _uniqueDays = const [];

  // ─── Chargement ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _checkAdmin();
    _fetchEntries();
  }

  Future<void> _checkAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final role = doc.data()?['role'];
    if (mounted) {
      setState(() => _isAdmin = role == 'admin');
    }
  }

  Future<void> _fetchEntries() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('common')
          .doc('archives')
          .collection('journal')
          .get();

      final entries = snapshot.docs
          .map((doc) => JournalEntry.fromMap(doc.data()))
          .toList();

      // Tri DÉCROISSANT par date, puis DÉCROISSANT par pageNumber au sein
      // d'une même date. Combiné à reverse:true sur le PageView, la plus
      // récente s'ouvre naturellement à droite sans initialPage (évite la
      // désynchro PageController/AnimatedBuilder décrite dans mission_chronology).
      entries.sort((a, b) {
        final cmp = b.date.compareTo(a.date);
        if (cmp != 0) return cmp;
        return b.pageNumber.compareTo(a.pageNumber);
      });

      _uniqueYears = (entries.map((e) => e.date.year).toSet().toList()..sort());
      _uniqueMonths =
          (entries.map((e) => e.date.month).toSet().toList()..sort());
      _uniqueDays = (entries.map((e) => e.date.day).toSet().toList()..sort());

      _pageController =
          PageController(viewportFraction: _itemSpacingFraction);

      setState(() {
        _entries = entries;
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final e in entries) {
          if (e.imageUrl.isNotEmpty) {
            precacheImage(NetworkImage(e.imageUrl), context).catchError((_) {});
          }
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _wheelSettleTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  // ─── Molette souris → défilement horizontal ─────────────────────────────────
  //
  // Le scroll horizontal natif (touchpad) reste géré par le PageView. Ici on
  // capte EN PLUS le scroll vertical de la molette pour le convertir en
  // défilement horizontal du carousel, puis on recale (snap) sur la page la
  // plus proche dès que la molette s'arrête.
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final controller = _pageController;
    if (controller == null || !controller.hasClients) return;

    // On privilégie l'axe vertical (molette classique), tout en acceptant un
    // delta horizontal éventuel.
    final delta = event.scrollDelta.dy.abs() >= event.scrollDelta.dx.abs()
        ? event.scrollDelta.dy
        : event.scrollDelta.dx;
    if (delta == 0) return;

    final pos = controller.position;
    final target = (pos.pixels + delta)
        .clamp(pos.minScrollExtent, pos.maxScrollExtent)
        .toDouble();
    controller.jumpTo(target);

    _wheelSettleTimer?.cancel();
    _wheelSettleTimer =
        Timer(const Duration(milliseconds: 120), _settleWheelScroll);
  }

  void _settleWheelScroll() {
    final controller = _pageController;
    if (!mounted || controller == null || !controller.hasClients) return;
    final page = controller.page ?? 0.0;
    final target = page.round().clamp(0, _entries.length - 1).toInt();
    controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.pushNamed(context, Routes.journalCreate);
                if (mounted) {
                  setState(() => _loading = true);
                  await _fetchEntries();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Center(
                    child: Text(
                      'Journal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            )
                          : _entries.isEmpty
                              ? const Center(
                                  child: Text('Aucune entrée pour le moment.'),
                                )
                              : _buildBody(),
                ),
              ],
            ),
          ),
          const SafeBackButtonOverlay(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // ── Strips de date (jour · mois romain · année) ──────────────────
        SizedBox(
          height: 70,
          child: _buildDateStrips(),
        ),
        // ── Carousel horizontal ─────────────────────────────────────────
        // Listener : convertit la molette verticale de la souris en
        // défilement horizontal (le scroll touchpad natif reste intact).
        Expanded(
          child: Listener(
            onPointerSignal: _handlePointerSignal,
            child: _buildPagesStack(),
          ),
        ),
        // ── Indicateur de page (seulement si >1 même jour) ──────────────
        SizedBox(
          height: 32,
          child: _buildPageIndicator(),
        ),
        // ── Barre de défilement horizontale cliquable / déplaçable ──────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
          child: _TimelineScrollbar(
            controller: _pageController!,
            itemCount: _entries.length,
          ),
        ),
      ],
    );
  }

  // ─── Strips de date ────────────────────────────────────────────────────────
  //
  // Trois strips côte à côte : jour, mois (en chiffres romains), année. Chaque
  // strip n'affiche que ses valeurs UNIQUES (pas une par entrée) et glisse
  // uniquement quand le central change de valeur — donc l'année reste
  // immobile si on ne change que de mois, etc.
  Widget _buildDateStrips() {
    return AnimatedBuilder(
      animation: _pageController!,
      builder: (context, _) {
        final page = _pageController!.hasClients
            ? (_pageController!.page ?? 0.0)
            : 0.0;
        final iLow = page.floor().clamp(0, _entries.length - 1);
        final iHigh = page.ceil().clamp(0, _entries.length - 1);
        final t = (iLow == iHigh) ? 0.0 : (page - iLow);

        final dayPage = _interpolatedIndex(
          values: _uniqueDays,
          entryLow: _entries[iLow].date.day,
          entryHigh: _entries[iHigh].date.day,
          t: t,
        );
        final monthPage = _interpolatedIndex(
          values: _uniqueMonths,
          entryLow: _entries[iLow].date.month,
          entryHigh: _entries[iHigh].date.month,
          t: t,
        );
        final yearPage = _interpolatedIndex(
          values: _uniqueYears,
          entryLow: _entries[iLow].date.year,
          entryHigh: _entries[iHigh].date.year,
          t: t,
        );

        // Row compacte centrée : « jour · mois · année ». Chaque strip
        // s'auto-dimensionne et se clippe pour ne montrer que sa valeur
        // centrale au repos, les voisines restant hors champ (cf. _HorizontalStrip).
        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HorizontalStrip(
                values: _uniqueDays.map((d) => d.toString()).toList(),
                centerPage: dayPage,
              ),
              _dateSeparator(context),
              _HorizontalStrip(
                values: _uniqueMonths.map((m) => _romanMonths[m - 1]).toList(),
                centerPage: monthPage,
              ),
              _dateSeparator(context),
              _HorizontalStrip(
                values: _uniqueYears.map((y) => y.toString()).toList(),
                centerPage: yearPage,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Point séparateur statique entre deux dimensions de date.
  Widget _dateSeparator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '·',
        style: GoogleFonts.cinzelDecorative(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Interpolation linéaire entre les indices des valeurs des deux entrées
  /// encadrant la page courante. Si elles ont la même valeur, l'index est
  /// constant → strip immobile.
  double _interpolatedIndex({
    required List<int> values,
    required int entryLow,
    required int entryHigh,
    required double t,
  }) {
    final iLow = values.indexOf(entryLow).toDouble();
    final iHigh = values.indexOf(entryHigh).toDouble();
    return iLow + (iHigh - iLow) * t;
  }

  // ─── Stack des pages (carousel horizontal) ─────────────────────────────────
  Widget _buildPagesStack() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return Stack(
          children: [
            // ── Couche 1 : PageView invisible (scroll/snap) ─────────────
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              // reverse:true → page 0 (la plus récente) s'affiche à droite,
              // page N (la plus ancienne) à gauche. L'ouverture initiale est
              // naturellement sur la plus récente, sans initialPage.
              reverse: true,
              physics: const SlowPageScrollPhysics(),
              itemCount: _entries.length,
              itemBuilder: (_, __) => const SizedBox.expand(),
            ),

            // ── Couche 2 : rendu visuel des cartes ──────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pageController!,
                builder: (context, _) {
                  final page = _pageController!.hasClients
                      ? (_pageController!.page ?? 0.0)
                      : 0.0;

                  final indices = List.generate(_entries.length, (i) => i)
                    ..sort((a, b) {
                      final da = (a - page).abs();
                      final db = (b - page).abs();
                      return db.compareTo(da);
                    });

                  return Stack(
                    alignment: Alignment.center,
                    children: indices.map((i) {
                      final dist = (i - page).abs();
                      if (dist > 3.5) return const SizedBox.shrink();

                      // Signe inversé par rapport à mission_chronology pour
                      // suivre reverse:true : index plus élevé (plus ancien)
                      // → à gauche (dx négatif).
                      final dx = -(i - page) * _itemSpacingFraction * totalWidth;
                      final scale = (1.0 - dist * 0.18).clamp(0.46, 1.0);
                      final opacity = (1.0 - dist * 0.25).clamp(0.15, 1.0);
                      final isCurrent = page.round() == i;

                      return Transform.translate(
                        offset: Offset(dx, 0),
                        child: IgnorePointer(
                          ignoring: !isCurrent,
                          child: Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: _buildPageCard(i, isCurrent),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPageCard(int index, bool isCurrent) {
    final entry = _entries[index];
    return GestureDetector(
      onTap: isCurrent
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      _JournalFullscreenViewer(imageUrl: entry.imageUrl),
                ),
              )
          : null,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        elevation: isCurrent ? 8 : 2,
        clipBehavior: Clip.antiAlias,
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Image.network(
            entry.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : const SizedBox.expand(),
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, size: 32),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Indicateur "Page X sur Y" (uniquement si plusieurs même jour) ─────────
  Widget _buildPageIndicator() {
    return AnimatedBuilder(
      animation: _pageController!,
      builder: (context, _) {
        if (!_pageController!.hasClients) return const SizedBox.shrink();
        final idx = (_pageController!.page ?? 0.0)
            .round()
            .clamp(0, _entries.length - 1);
        final current = _entries[idx];
        final sameDay = _entries
            .where((e) =>
                e.date.year == current.date.year &&
                e.date.month == current.date.month &&
                e.date.day == current.date.day)
            .toList();
        if (sameDay.length < 2) return const SizedBox.shrink();
        return Center(
          child: Text(
            'Page ${current.pageNumber} sur ${sameDay.length}',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}

/// Strip horizontal d'une dimension de date (jour, mois ou année).
///
/// Affiche les valeurs uniques de cette dimension empilées horizontalement,
/// glissant uniquement quand la valeur centrale change. Le strip est large de
/// juste UNE valeur (+ un peu d'air) et se clippe : au repos on ne voit que la
/// valeur centrale, mais pendant une transition on devine brièvement la voisine
/// qui entre/sort — effet « compteur » fluide sans montrer toute la pile.
class _HorizontalStrip extends StatelessWidget {
  final List<String> values;
  final double centerPage;

  const _HorizontalStrip({
    required this.values,
    required this.centerPage,
  });

  static const double _centralFontSize = 26.0;
  static const double _baseFontSize = 16.0;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    // Largeur de la plus longue valeur rendue à la taille centrale : sert à
    // dimensionner la fenêtre visible (clip) et l'espacement entre valeurs.
    final measureStyle = GoogleFonts.cinzelDecorative(
      fontSize: _centralFontSize,
      fontWeight: FontWeight.bold,
    );
    double maxW = 0;
    for (final v in values) {
      final tp = TextPainter(
        text: TextSpan(text: v, style: measureStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      if (tp.width > maxW) maxW = tp.width;
    }

    final clipWidth = maxW + 16.0; // 8 px d'air de chaque côté
    final itemSpacing =
        maxW + 18.0; // voisins hors champ au repos, visibles en transition

    return SizedBox(
      width: clipWidth,
      child: ClipRect(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: List.generate(values.length, (i) {
            final offset = i - centerPage;
            final distance = offset.abs();
            if (distance > 2.5) return const SizedBox.shrink();

            final dx = offset * itemSpacing;
            final scale = (1.0 - distance * 0.22).clamp(0.3, 1.0);
            final opacity = (1.0 - distance * 0.45).clamp(0.0, 1.0);
            final currentBoost = (1.0 - distance).clamp(0.0, 1.0);
            final fontSize =
                _baseFontSize + (_centralFontSize - _baseFontSize) * currentBoost;
            final isCurrent = centerPage.round() == i;

            return Transform.translate(
              offset: Offset(dx, 0),
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Text(
                    values[i],
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: fontSize,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Barre de défilement horizontale cliquable et déplaçable, pilotant le
/// [PageController] du carousel.
///
/// Cohérente avec `reverse: true` : la poignée est à DROITE pour l'entrée la
/// plus récente (page 0) et à GAUCHE pour la plus ancienne (page N-1).
class _TimelineScrollbar extends StatelessWidget {
  final PageController controller;
  final int itemCount;

  const _TimelineScrollbar({
    required this.controller,
    required this.itemCount,
  });

  // Convertit une position locale X (en pixels du track) en position du
  // PageController. `animate` = true pour un clic (saut fluide), false pour
  // un glissement (suivi direct du doigt).
  void _seekToLocalX(
    double x,
    double trackWidth,
    double thumbWidth, {
    bool animate = false,
  }) {
    if (!controller.hasClients || itemCount <= 1) return;
    final maxLeft = trackWidth - thumbWidth;
    if (maxLeft <= 0) return;

    final thumbLeft = (x - thumbWidth / 2).clamp(0.0, maxLeft);
    final fractionFromLeft = thumbLeft / maxLeft;
    // reverse:true → gauche = ancien (page élevée), droite = récent (page 0).
    final pageFraction = 1.0 - fractionFromLeft;
    final pixels = pageFraction * controller.position.maxScrollExtent;

    if (animate) {
      controller.animateTo(
        pixels,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      controller.jumpTo(pixels);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final thumbWidth = itemCount <= 1
            ? trackWidth
            : (trackWidth / itemCount).clamp(48.0, trackWidth).toDouble();
        final maxLeft = (trackWidth - thumbWidth).clamp(0.0, trackWidth).toDouble();

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _seekToLocalX(
            d.localPosition.dx,
            trackWidth,
            thumbWidth,
            animate: true,
          ),
          onHorizontalDragStart: (d) =>
              _seekToLocalX(d.localPosition.dx, trackWidth, thumbWidth),
          onHorizontalDragUpdate: (d) =>
              _seekToLocalX(d.localPosition.dx, trackWidth, thumbWidth),
          child: SizedBox(
            height: 18,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // Piste
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                // Poignée (suit la position courante du PageController)
                AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) {
                    final page = (controller.hasClients
                            ? (controller.page ?? 0.0)
                            : 0.0)
                        .clamp(0.0, (itemCount - 1).toDouble());
                    final pageFraction =
                        itemCount <= 1 ? 0.0 : page / (itemCount - 1);
                    final fractionFromLeft = 1.0 - pageFraction;
                    final thumbLeft = fractionFromLeft * maxLeft;

                    return Padding(
                      padding: EdgeInsets.only(left: thumbLeft),
                      child: Container(
                        width: thumbWidth,
                        height: 14,
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.35),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Visionneuse plein écran zoomable d'une page de journal.
class _JournalFullscreenViewer extends StatefulWidget {
  final String imageUrl;
  const _JournalFullscreenViewer({required this.imageUrl});

  @override
  State<_JournalFullscreenViewer> createState() =>
      _JournalFullscreenViewerState();
}

class _JournalFullscreenViewerState extends State<_JournalFullscreenViewer> {
  final TransformationController _controller = TransformationController();
  TapDownDetails? _doubleTapDetails;

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (d) => _doubleTapDetails = d,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 1.0,
                maxScale: 8.0,
                child: Center(
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white, size: 48),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SafeBackButtonOverlay(color: Colors.white),
        ],
      ),
    );
  }
}
