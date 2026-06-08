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

  // Couleurs précalculées par id de mission (blending lookahead + lookbehind)
  Map<int, Color> _bgCurveById = {};

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

  // Liste des clads UNIQUES dans l'ordre d'apparition dans les missions filtrées.
  List<CladeName> get _filteredClades {
    final seen = <CladeName>{};
    final clades = <CladeName>[];
    for (final m in _filteredMissions) {
      if (seen.add(m.clade)) clades.add(m.clade);
    }
    return clades;
  }

  static const Map<CladeName, Color> _cladeColors = {
    CladeName.origins: Color(0xFFB05070),
    CladeName.western: Color(0xFFD4B896),
    CladeName.beginning: Color(0xFF8BC87A),
    CladeName.unNeufTroisZero: Color(0xFF8B1A1A),
    CladeName.arthur: Color(0xFF87CEEB),
    CladeName.osiris: Color(0xFFB8860B),
    CladeName.blackOrchid: Color(0xFF7B2D8B),
    CladeName.pennyDreadful: Color(0xFF1B5E20),
  };

  static const Map<CladeName, String> _cladeDisplayNames = {
    CladeName.origins: 'Origins',
    CladeName.western: 'Western',
    CladeName.beginning: 'The Beginning',
    CladeName.unNeufTroisZero: '1930',
    CladeName.arthur: 'The Legend of King Arthur',
    CladeName.osiris: 'Osiris',
    CladeName.blackOrchid: 'Black Orchid',
    CladeName.pennyDreadful: 'Penny Dreadful',
  };

  // Hermite cubic : démarre et finit en douceur (accélération/décélération)
  static double _smoothStep(double t) => t * t * (3.0 - 2.0 * t);

  // Précalcule, une seule fois après le chargement, la couleur de fond pour
  // chaque mission en tenant compte des clads voisins (fenêtre de ±2 missions).
  // Stocké par id pour rester valide même quand la recherche filtre la liste.
  void _precomputeBgCurve(List<Mission> missions) {
    const window = 2;
    final n = missions.length;
    _bgCurveById = {};

    for (int i = 0; i < n; i++) {
      final myColor = _cladeColors[missions[i].clade] ?? Colors.grey;
      // Utilise les canaux normalisés [0,1] (API non dépréciée)
      double r = myColor.r;
      double g = myColor.g;
      double b = myColor.b;
      double totalW = 1.0;

      // Lookahead : bleed vers la couleur du prochain clad
      for (int k = 1; k <= window; k++) {
        final j = i + k;
        if (j >= n) break;
        if (missions[j].clade != missions[i].clade) {
          final c = _cladeColors[missions[j].clade] ?? Colors.grey;
          final w = (window - k + 1) / (window + 1.0);
          r += c.r * w; g += c.g * w; b += c.b * w;
          totalW += w;
          break;
        }
      }

      // Lookbehind : bleed depuis la couleur du clad précédent
      for (int k = 1; k <= window; k++) {
        final j = i - k;
        if (j < 0) break;
        if (missions[j].clade != missions[i].clade) {
          final c = _cladeColors[missions[j].clade] ?? Colors.grey;
          final w = (window - k + 1) / (window + 1.0);
          r += c.r * w; g += c.g * w; b += c.b * w;
          totalW += w;
          break;
        }
      }

      _bgCurveById[missions[i].id] = Color.from(
        alpha: 1.0,
        red:   (r / totalW).clamp(0.0, 1.0),
        green: (g / totalW).clamp(0.0, 1.0),
        blue:  (b / totalW).clamp(0.0, 1.0),
      ).withValues(alpha: 0.22);
    }
  }

  Color _fallbackBg(CladeName c) =>
      (_cladeColors[c] ?? Colors.grey).withValues(alpha: 0.22);

  Color _backgroundColorAt(double page) {
    final missions = _filteredMissions;
    if (missions.isEmpty) return Colors.transparent;
    final iLow  = page.floor().clamp(0, missions.length - 1);
    final iHigh = page.ceil().clamp(0, missions.length - 1);
    final t     = _smoothStep(page - page.floor());
    final colorA = _bgCurveById[missions[iLow].id]  ?? _fallbackBg(missions[iLow].clade);
    final colorB = _bgCurveById[missions[iHigh].id] ?? _fallbackBg(missions[iHigh].clade);
    return Color.lerp(colorA, colorB, t)!;
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
      //
      // Cas spécial : les missions du Clad 1930 (unNeufTroisZero) sont intercalées
      // APRÈS toutes les missions "arthur" et AVANT toutes les missions "beginning",
      // indépendamment de leurs dates réelles. On sépare donc les 1930 du reste,
      // on trie chaque groupe par date, puis on insère le bloc 1930 au bon endroit.
      int descendingByDate(Mission a, Mission b) {
        if (a.completedAt == null && b.completedAt == null) return 0;
        if (a.completedAt == null) return 1;
        if (b.completedAt == null) return -1;

        // Comparaison par jour uniquement (ignore l'heure)
        final aDay = DateTime(a.completedAt!.year, a.completedAt!.month, a.completedAt!.day);
        final bDay = DateTime(b.completedAt!.year, b.completedAt!.month, b.completedAt!.day);
        final cmp  = bDay.compareTo(aDay);
        if (cmp != 0) return cmp;

        // Même jour : décroissant sur playedAt → jouée en dernier en haut, jouée en premier en bas
        if (a.playedAt == null && b.playedAt == null) return 0;
        if (a.playedAt == null) return 1;
        if (b.playedAt == null) return -1;
        return b.playedAt!.compareTo(a.playedAt!);
      }

      final missions1930 = missions
          .where((m) => m.clade == CladeName.unNeufTroisZero)
          .toList()
        ..sort(descendingByDate);
      final sortedMissions = missions
          .where((m) => m.clade != CladeName.unNeufTroisZero)
          .toList()
        ..sort(descendingByDate);

      final insertAt = sortedMissions.indexWhere((m) => m.clade == CladeName.beginning);
      sortedMissions.insertAll(
        insertAt == -1 ? sortedMissions.length : insertAt,
        missions1930,
      );

      _precomputeBgCurve(sortedMissions);

      _pageController = PageController(
        viewportFraction: _itemSpacingFraction,
      );

      setState(() {
        _allMissions = sortedMissions;
        _loading = false;
      });

      // Préchargement des illustrations dès que le contexte est prêt :
      // évite que le scroll ne déclenche un fetch réseau pour chaque mission qui
      // entre dans la fenêtre visible (cause du tressautement intermittent).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final m in sortedMissions) {
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
          // ── Fond coloré animé selon le clad courant ───────────────────────────
          if (!_loading && _filteredMissions.isNotEmpty)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  final page = _pageController.hasClients
                      ? (_pageController.page ?? 0.0)
                      : 0.0;
                  return ColoredBox(color: _backgroundColorAt(page));
                },
              ),
            ),

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

            // ── Clad courant ──────────────────────────────────────────────────
            if (!_loading && _filteredMissions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Clad : ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(
                      height: 56,
                      width: 240,
                      child: _buildCladeStrip(),
                    ),
                  ],
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
  // N'affiche que les années UNIQUES. yearPage reste un entier exact quand on
  // est posé sur une mission (pas de dérive) ; le smoothStep sur t assure un
  // démarrage et une fin de transition en douceur lors du scroll.
  Widget _buildYearStrip() {
    final years = _filteredYears;
    if (years.isEmpty) return const SizedBox.shrink();

    final missionYearIndex = List<int>.generate(_filteredMissions.length, (i) {
      return years.indexOf(_filteredMissions[i].completedAt!.year);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalHeight = constraints.maxHeight;

        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, _) {
            final page  = _pageController.hasClients
                ? (_pageController.page ?? 0.0)
                : 0.0;
            final iLow  = page.floor().clamp(0, _filteredMissions.length - 1);
            final iHigh = page.ceil().clamp(0, _filteredMissions.length - 1);
            final t     = _smoothStep(page - page.floor());

            final yearLow  = missionYearIndex[iLow];
            final yearHigh = missionYearIndex[iHigh];
            final yearPage = (iLow == iHigh)
                ? yearLow.toDouble()
                : yearLow + (yearHigh - yearLow) * t;

            final itemHeight = totalHeight * _itemSpacingFraction;

            return ClipRect(
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: List.generate(years.length, (i) {
                  final offset   = i - yearPage;
                  final distance = offset.abs();
                  if (distance > 3.5) return const SizedBox.shrink();

                  final dy           = offset * itemHeight;
                  final scale        = (1.0 - distance * 0.18).clamp(0.3, 1.0);
                  final opacity      = (1.0 - distance * 0.25).clamp(0.0, 1.0);
                  final isCurrent    = yearPage.round() == i;
                  final currentBoost = (1.0 - distance).clamp(0.0, 1.0);
                  final fontSize     = 15.0 + 7.0 * currentBoost;

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

  // ─── Bande des noms de clad (en-tête) ────────────────────────────────────────
  //
  // Même mécanique que _buildYearStrip : les noms de clad UNIQUES (dans l'ordre
  // d'apparition) défilent verticalement. Le clad central est mis en valeur ;
  // les voisins s'estompent au-dessus et en dessous.
  Widget _buildCladeStrip() {
    final missions = _filteredMissions;
    final clades   = _filteredClades;
    if (clades.isEmpty) return const SizedBox.shrink();

    final rawIdx = missions.map((m) => clades.indexOf(m.clade)).toList();

    const window   = 2;
    const maxDrift = 0.38;
    final smoothIdx = List<double>.generate(missions.length, (i) {
      final myIdx = rawIdx[i].toDouble();
      for (int k = 1; k <= window; k++) {
        final j = i + k;
        if (j >= missions.length) break;
        if (rawIdx[j] != rawIdx[i]) {
          return myIdx +
              (rawIdx[j] - rawIdx[i]) * maxDrift * (window - k + 1) / window;
        }
      }
      return myIdx;
    });

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, _) {
        final page  = _pageController.hasClients
            ? (_pageController.page ?? 0.0)
            : 0.0;
        final iLow  = page.floor().clamp(0, missions.length - 1);
        final iHigh = page.ceil().clamp(0, missions.length - 1);
        final t     = _smoothStep(page - page.floor());

        final cLow  = smoothIdx[iLow];
        final cHigh = smoothIdx[iHigh];
        final cladePage = (iLow == iHigh)
            ? cLow
            : cLow + (cHigh - cLow) * t;

        const itemHeight = 26.0;

        return ClipRect(
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: List.generate(clades.length, (i) {
              final offset   = i - cladePage;
              final distance = offset.abs();
              if (distance > 2.5) return const SizedBox.shrink();

              final dy           = offset * itemHeight;
              final scale        = (1.0 - distance * 0.18).clamp(0.3, 1.0);
              final opacity      = (1.0 - distance * 0.35).clamp(0.0, 1.0);
              final isCurrent    = cladePage.round() == i;
              final currentBoost = (1.0 - distance).clamp(0.0, 1.0);
              final fontSize     = 13.0 + 5.0 * currentBoost;

              return Transform.translate(
                offset: Offset(0, dy),
                child: Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Text(
                      _cladeDisplayNames[clades[i]] ?? clades[i].name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
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
