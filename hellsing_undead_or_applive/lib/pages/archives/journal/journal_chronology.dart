import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    _pageController?.dispose();
    super.dispose();
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
        // ── Strips de date (jour / mois romain / année) ──────────────────
        SizedBox(
          height: 70,
          child: _buildDateStrips(),
        ),
        // ── Carousel horizontal ─────────────────────────────────────────
        Expanded(child: _buildPagesStack()),
        // ── Indicateur de page (seulement si >1 même jour) ──────────────
        SizedBox(
          height: 32,
          child: _buildPageIndicator(),
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

        return Row(
          children: [
            Expanded(
              child: _HorizontalStrip(
                values: _uniqueDays.map((d) => d.toString()).toList(),
                centerPage: dayPage,
              ),
            ),
            Expanded(
              child: _HorizontalStrip(
                values:
                    _uniqueMonths.map((m) => _romanMonths[m - 1]).toList(),
                centerPage: monthPage,
              ),
            ),
            Expanded(
              child: _HorizontalStrip(
                values: _uniqueYears.map((y) => y.toString()).toList(),
                centerPage: yearPage,
              ),
            ),
          ],
        );
      },
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
/// glissant uniquement quand la valeur centrale change. Visuellement :
/// valeurs PETITES à gauche (= passé), GROSSES au centre (= courante).
class _HorizontalStrip extends StatelessWidget {
  final List<String> values;
  final double centerPage;

  const _HorizontalStrip({
    required this.values,
    required this.centerPage,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemSpacing = width * 0.45;

        return ClipRect(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: List.generate(values.length, (i) {
              final offset = i - centerPage;
              final distance = offset.abs();
              if (distance > 3.5) return const SizedBox.shrink();

              final dx = offset * itemSpacing;
              final scale = (1.0 - distance * 0.22).clamp(0.3, 1.0);
              final opacity = (1.0 - distance * 0.3).clamp(0.0, 1.0);
              final currentBoost = (1.0 - distance).clamp(0.0, 1.0);
              final fontSize = 16.0 + 10.0 * currentBoost;
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
