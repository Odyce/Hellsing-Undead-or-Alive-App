import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

class MissionChronologyPage extends StatefulWidget {
  const MissionChronologyPage({super.key});

  @override
  State<MissionChronologyPage> createState() => _MissionChronologyPageState();
}

class _MissionChronologyPageState extends State<MissionChronologyPage> {
  // Fraction de la hauteur totale occupée par chaque item du carousel
  static const double _viewportFraction = 0.38;

  late final PageController _pageController = PageController(
    viewportFraction: _viewportFraction,
  );

  List<Mission> _missions = [];
  bool _loading = true;
  String? _error;

  // ─── Chargement ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchMissions();
  }

  Future<void> _fetchMissions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('common')
          .doc('archives')
          .collection('missions')
          .get();

      final missions = snapshot.docs
          .map((doc) => Mission.fromMap(doc.data()))
          .toList();

      // La plus ancienne completedAt tout en haut — nulls à la fin
      missions.sort((a, b) {
        if (a.completedAt == null && b.completedAt == null) return 0;
        if (a.completedAt == null) return 1;
        if (b.completedAt == null) return -1;
        return a.completedAt!.compareTo(b.completedAt!);
      });

      setState(() {
        _missions = missions;
        _loading = false;
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
    _pageController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── En-tête ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: const Text(
                  'Chronologie',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ── Contenu principal ────────────────────────────────────────────
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
                      : _missions.isEmpty
                          ? const Center(
                              child: Text('Aucune mission enregistrée.'),
                            )
                          : _buildCarousel(),
            ),

            // ── Bouton retour en bas ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/missions'),
                  child: const Text('Retour'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Carousel principal ───────────────────────────────────────────────────────
  Widget _buildCarousel() {
    return Row(
      children: [
        // Bande des années à gauche
        SizedBox(
          width: 70,
          child: _buildYearStrip(),
        ),

        // Carousel des missions au centre
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _missions.length,
            itemBuilder: (context, index) => _buildMissionItem(index),
          ),
        ),
      ],
    );
  }

  // ─── Bande des années (gauche) ────────────────────────────────────────────────
  Widget _buildYearStrip() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;

        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, _) {
            final page = _pageController.hasClients
                ? (_pageController.page ?? 0.0)
                : 0.0;
            final itemHeight = totalHeight * _viewportFraction;

            return ClipRect(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: List.generate(_missions.length, (i) {
                  final offset   = i - page;
                  final distance = offset.abs();
                  final dy       = offset * itemHeight;
                  final scale    = (1.0 - distance * 0.25).clamp(0.3, 1.0);
                  final opacity  = (1.0 - distance * 0.45).clamp(0.0, 1.0);
                  final isCurrent = page.round() == i;

                  final year =
                      _missions[i].completedAt?.year.toString() ?? '?';

                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Text(
                          year,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
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
      },
    );
  }

  // ─── Item mission du carousel (centre) ────────────────────────────────────────
  Widget _buildMissionItem(int index) {
    final mission = _missions[index];

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        double scale    = 1.0;
        bool isCurrent  = false;

        if (_pageController.hasClients && _pageController.page != null) {
          final distance = (_pageController.page! - index).abs();
          scale      = (1.0 - distance * 0.22).clamp(0.5, 1.0);
          isCurrent  = distance < 0.5;
        }

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            // Cliquable uniquement lorsque la mission est au centre
            onTap: isCurrent
                ? () => Navigator.pushNamed(
                      context,
                      '/missionsheet',
                      arguments: mission,
                    )
                : null,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: isCurrent ? 6 : 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      mission.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isCurrent ? 18 : 15,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (mission.illustrationPath != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          mission.illustrationPath!,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) => progress == null
                              ? child
                              : const SizedBox(
                                  height: 110,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
