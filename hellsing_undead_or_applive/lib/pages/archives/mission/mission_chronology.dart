import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class MissionChronologyPage extends StatefulWidget {
  const MissionChronologyPage({super.key});

  @override
  State<MissionChronologyPage> createState() => _MissionChronologyPageState();
}

class _MissionChronologyPageState extends State<MissionChronologyPage> {
  // Espacement entre items en fraction de la hauteur totale (7 items visibles)
  static const double _itemSpacingFraction = 0.145;

  // L'ajout du viewportFraction synchronise la physique du scroll avec le visuel
  late PageController _pageController;

  // Variables pour la recherche
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Mission> _allMissions = [];
  bool _loading = true;
  String? _error;

  // Getter dynamique pour filtrer les missions en temps réel
  List<Mission> get _filteredMissions {
    if (_searchQuery.trim().isEmpty) {
      return _allMissions;
    }
    final query = _searchQuery.trim().toLowerCase();
    return _allMissions.where((m) => m.title.toLowerCase().contains(query)).toList();
  }

  // Liste des années UNIQUES présentes dans les missions filtrées,
  // dans le même ordre que la liste (donc décroissant : plus récente en index 0).
  List<int> get _filteredYears {
    final years = <int>{};
    for (final m in _filteredMissions) {
      if (m.completedAt != null) years.add(m.completedAt!.year);
    }
    return years.toList();
  }

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

      // Tri DÉCROISSANT : la mission la plus récente en index 0, la plus ancienne en dernier.
      // → la page s'ouvre naturellement sur la plus récente sans avoir besoin
      //   de fixer un initialPage, ce qui évite la désynchro entre la position
      //   du PageController et le rendu de l'AnimatedBuilder avant le premier layout
      //   (cause probable du "lag" au démarrage du scroll signalé par l'utilisateur).
      missions.sort((a, b) {
        if (a.completedAt == null && b.completedAt == null) return 0;
        if (a.completedAt == null) return 1;
        if (b.completedAt == null) return -1;
        return b.completedAt!.compareTo(a.completedAt!);
      });

      _pageController = PageController(
        viewportFraction: _itemSpacingFraction,
      );

      setState(() {
        _allMissions = missions;
        _loading = false;
      });

      // Préchargement des illustrations dès que le contexte est prêt :
      // évite que le scroll ne déclenche un fetch réseau pour chaque mission qui
      // entre dans la fenêtre visible (cause du tressautement intermittent).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final m in missions) {
          final path = m.illustrationPath;
          if (path != null && path.isNotEmpty) {
            precacheImage(NetworkImage(path), context).catchError((_) {});
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
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ── En-tête ──────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Text(
                  'Chronologie',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // ── Barre de recherche ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher une mission...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              if (_pageController.hasClients && _filteredMissions.isNotEmpty) {
                                _pageController.jumpToPage(0);
                              }
                            });
                          },
                        )
                      : null,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    // On ramène l'utilisateur sur la mission la plus récente du sous-ensemble filtré (index 0).
                    if (_pageController.hasClients && _filteredMissions.isNotEmpty) {
                      _pageController.jumpToPage(0);
                    }
                  });
                },
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
                      : _filteredMissions.isEmpty
                          ? const Center(
                              child: Text('Aucune mission correspondante.'),
                            )
                          : _buildCarousel(),
            ),

              ],
            ),
          ),
          const SafeBackButtonOverlay(),
        ],
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
  //
  // N'affiche que les années UNIQUES (pas une entrée par mission).
  // Le strip reste immobile tant que la mission centrale ne change pas d'année,
  // et glisse uniquement au franchissement d'une frontière d'année.
  //
  // Mécanique : la "yearPage" est dérivée de la mission page par interpolation
  // linéaire entre les year-index des deux missions encadrant la page courante.
  // Si elles partagent la même année, yearPage est constante → strip immobile.
  // Sinon, yearPage transitionne linéairement de l'une à l'autre.
  Widget _buildYearStrip() {
    final years = _filteredYears;
    if (years.isEmpty) return const SizedBox.shrink();

    // Pour chaque mission, l'index de son année dans la liste unique.
    final missionYearIndex = List<int>.generate(_filteredMissions.length, (i) {
      final year = _filteredMissions[i].completedAt!.year;
      return years.indexOf(year);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;

        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, _) {
            final page = _pageController.hasClients
                ? (_pageController.page ?? 0.0)
                : 0.0;

            final iLow = page.floor().clamp(0, _filteredMissions.length - 1);
            final iHigh = page.ceil().clamp(0, _filteredMissions.length - 1);
            final yearLow = missionYearIndex[iLow];
            final yearHigh = missionYearIndex[iHigh];
            final yearPage = (iLow == iHigh)
                ? yearLow.toDouble()
                : yearLow + (yearHigh - yearLow) * (page - iLow);

            final itemHeight = totalHeight * _itemSpacingFraction;

            return ClipRect(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: List.generate(years.length, (i) {
                  final offset   = i - yearPage;
                  final distance = offset.abs();
                  if (distance > 3.5) return const SizedBox.shrink();

                  final dy      = offset * itemHeight;
                  final scale   = (1.0 - distance * 0.18).clamp(0.3, 1.0);
                  final opacity = (1.0 - distance * 0.25).clamp(0.0, 1.0);
                  final isCurrent = yearPage.round() == i;

                  // Boost de taille pour l'année centrale, lissé sur les voisines
                  // pour que la transition d'une année à l'autre ne fasse pas
                  // de saut visuel.
                  final currentBoost = (1.0 - distance).clamp(0.0, 1.0);
                  final fontSize = 15.0 + 7.0 * currentBoost;

                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Text(
                          years[i].toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSize,
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
              physics: const SlowPageScrollPhysics(),
              itemCount: _filteredMissions.length,
              // Items vides — uniquement pour la mécanique de défilement
              itemBuilder: (_, __) => const SizedBox.expand(),
            ),

            // ── Couche 2 : rendu visuel des cartes ───────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  final page = _pageController.hasClients
                      ? (_pageController.page ?? 0.0)
                      : 0.0;

                  // Trier les indices : les plus éloignés du centre en premier,
                  // le central en dernier → peint par-dessus ses voisins (z-order).
                  final indices = List.generate(_filteredMissions.length, (i) => i)
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
            ),
          ],
        );
      },
    );
  }

  // ─── Carte individuelle d'une mission ────────────────────────────────────────
  Widget _buildMissionCard(int index, bool isCurrent) {
    final mission = _filteredMissions[index];

    return GestureDetector(
      onTap: isCurrent
          ? () => Navigator.pushNamed(
                context,
                Routes.missionSheet,
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
                    // Placeholder STATIQUE : pas de CircularProgressIndicator pour
                    // éviter une animation parasite qui force des repaints pendant
                    // qu'une nouvelle carte entre dans la fenêtre du carousel.
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const SizedBox(width: 64, height: 64),
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

              Expanded(
                child: Text(
                  "${mission.completedAt!.year}/${mission.completedAt!.month}/${mission.completedAt!.day}",
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

class SlowPageScrollPhysics extends PageScrollPhysics {
  const SlowPageScrollPhysics({super.parent});
  @override
  SlowPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SlowPageScrollPhysics(parent: buildParent(ancestor));
  }
  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // Le multiplicateur détermine la vitesse.
    // 0.5 signifie que ça défilera 2x moins vite par rapport au mouvement du doigt.
    // Vous pouvez l'ajuster (ex: 0.3 pour très lent, 0.7 pour un poil plus lent)
    return super.applyPhysicsToUserOffset(position, offset) * 0.66;
  }
}
