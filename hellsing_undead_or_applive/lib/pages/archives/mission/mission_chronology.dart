import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

class MissionChronologyPage extends StatefulWidget {
  const MissionChronologyPage({super.key});

  @override
  State<MissionChronologyPage> createState() => _MissionChronologyPageState();
}

class _MissionChronologyPageState extends State<MissionChronologyPage> {
  // Espacement entre items en fraction de la hauteur totale (7 items visibles)
  static const double _itemSpacingFraction = 0.145;

  // PageController sans viewportFraction custom — utilisé uniquement pour le snap
  late final PageController _pageController = PageController();

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
          // Seules les missions terminées apparaissent dans la chronologie
          .where((m) => m.completedAt != null)
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
        Expanded(child: _buildMissionStack()),
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
            final itemHeight = totalHeight * _itemSpacingFraction;

            return ClipRect(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: List.generate(_missions.length, (i) {
                  final offset   = i - page;
                  final distance = offset.abs();
                  if (distance > 3.5) return const SizedBox.shrink();

                  final dy      = offset * itemHeight;
                  final scale   = (1.0 - distance * 0.18).clamp(0.3, 1.0);
                  final opacity = (1.0 - distance * 0.25).clamp(0.0, 1.0);
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

  // ─── Stack des missions (droite) ──────────────────────────────────────────────
  //
  // Séparation en deux couches :
  //   1. PageView invisible → gère uniquement le scroll/snap vertical
  //   2. Stack animé → rendu visuel dans le bon z-order (éloignés peints
  //      en premier, central peint en dernier donc par-dessus)
  Widget _buildMissionStack() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;

        return Stack(
          children: [
            // ── Couche 1 : scroll/snap invisible ────────────────────────────
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _missions.length,
              // Items vides — uniquement pour la mécanique de défilement
              itemBuilder: (_, __) => const SizedBox.expand(),
            ),

            // ── Couche 2 : rendu visuel des cartes ───────────────────────────
            AnimatedBuilder(
              animation: _pageController,
              builder: (context, _) {
                final page = _pageController.hasClients
                    ? (_pageController.page ?? 0.0)
                    : 0.0;

                // Trier les indices : les plus éloignés du centre en premier,
                // le central en dernier → peint par-dessus ses voisins (z-order).
                final indices = List.generate(_missions.length, (i) => i)
                  ..sort((a, b) {
                    final da = (a - page).abs();
                    final db = (b - page).abs();
                    return db.compareTo(da);
                  });

                return Stack(
                  alignment: Alignment.center,
                  children: indices.map((i) {
                    final dist = (i - page).abs();
                    // N'afficher que les 3 de chaque côté + le central
                    if (dist > 3.5) return const SizedBox.shrink();

                    final dy       = (i - page) * _itemSpacingFraction * totalHeight;
                    final scale    = (1.0 - dist * 0.18).clamp(0.46, 1.0);
                    final opacity  = (1.0 - dist * 0.25).clamp(0.15, 1.0);
                    final isCurrent = page.round() == i;

                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: IgnorePointer(
                        // Seule la carte centrale reçoit les taps ;
                        // les autres laissent passer les événements au PageView.
                        ignoring: !isCurrent,
                        child: Transform.scale(
                          scale: scale,
                          child: Opacity(
                            opacity: opacity,
                            child: _buildMissionCard(i, isCurrent),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ─── Carte individuelle d'une mission ────────────────────────────────────────
  Widget _buildMissionCard(int index, bool isCurrent) {
    final mission = _missions[index];

    return GestureDetector(
      onTap: isCurrent
          ? () => Navigator.pushNamed(
                context,
                '/missionsheet',
                arguments: mission,
              )
          : null,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: isCurrent ? 6 : 2,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Illustration à gauche (toutes les cartes) ───────────────
              if (mission.illustrationPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    mission.illustrationPath!,
                    // Taille fixe : le Transform.scale du parent la réduit
                    // proportionnellement pour les cartes non-centrales.
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const SizedBox(
                            width: 64,
                            height: 64,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),

              if (mission.illustrationPath != null) const SizedBox(width: 10),

              // ── Titre à droite ──────────────────────────────────────────
              Expanded(
                child: Text(
                  mission.title,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: isCurrent ? 18 : 13,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
