import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:apsl_sun_calc/apsl_sun_calc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hellsing_undead_or_applive/domain/archives/missions_model.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

enum MoonMajorPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

class MoonPhaseInfo {
  final MoonMajorPhase phase;
  final String label;
  final String emoji;

  const MoonPhaseInfo(this.phase, this.label, this.emoji);
}

class MoonCalendarPage extends StatefulWidget {
  const MoonCalendarPage({super.key});

  @override
  State<MoonCalendarPage> createState() => _MoonCalendarPageState();
}

class _MoonCalendarPageState extends State<MoonCalendarPage> {
  static final DateTime _initialMonth = DateTime.utc(1877, 3, 1);

  // Bornes larges pour naviguer
  static final DateTime _firstDay = DateTime.utc(1600, 1, 1);
  static final DateTime _lastDay = DateTime.utc(2200, 12, 31);

  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final CalendarFormat _format = CalendarFormat.month;

  // Missions indexées par date normalisée "yyyy-M-d"
  Map<String, List<Mission>> _completedByDay = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = _initialMonth;
    _loadCompletedMissions();
  }

  Future<void> _loadCompletedMissions() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('common')
        .doc('archives')
        .collection('missions')
        .get();

    final Map<String, List<Mission>> result = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['completedAt'] == null) continue;

      final mission = Mission.fromMap(data);
      if (mission.completedAt == null) continue;

      final key = _dateKey(mission.completedAt!);
      result.putIfAbsent(key, () => []).add(mission);
    }

    if (mounted) {
      setState(() => _completedByDay = result);
    }
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  List<Mission> _missionsForDay(DateTime day) =>
      _completedByDay[_dateKey(day)] ?? [];

  DateTime _asUtcMidday(DateTime d) {
    return DateTime.utc(d.year, d.month, d.day, 12);
  }

  double _circularDistance(double a, double b) {
    final d = (a - b).abs();
    return d > 0.5 ? 1.0 - d : d;
  }

  double _moonPhaseValue(DateTime day) {
    final d = _asUtcMidday(day);
    final moon = SunCalc.getMoonIllumination(d);
    final p = ((moon['phase'] ?? 0)).toDouble() % 1.0;
    return p < 0 ? p + 1.0 : p;
  }

  MoonPhaseInfo? _transitionPhaseForDay(DateTime day) {
    final pPrev = _moonPhaseValue(day.subtract(const Duration(days: 1)));
    final pNow  = _moonPhaseValue(day);
    final pNext = _moonPhaseValue(day.add(const Duration(days: 1)));

    const tol = 0.03;

    const targets = <double>[
      0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875,
    ];

    int bestIdx = -1;
    double bestD = 999;

    for (int i = 0; i < targets.length; i++) {
      final t = targets[i];
      final dPrev = _circularDistance(pPrev, t);
      final dNow  = _circularDistance(pNow, t);
      final dNext = _circularDistance(pNext, t);

      final isLocalMin = (dNow <= dPrev) && (dNow < dNext);

      if (isLocalMin && dNow < bestD) {
        bestD = dNow;
        bestIdx = i;
      }
    }

    if (bestIdx == -1 || bestD > tol) return null;

    switch (bestIdx) {
      case 0:
        return const MoonPhaseInfo(MoonMajorPhase.newMoon, "Nouvelle Lune", "🌑");
      case 1:
        return const MoonPhaseInfo(MoonMajorPhase.waxingCrescent, "Premier Croissant", "🌒");
      case 2:
        return const MoonPhaseInfo(MoonMajorPhase.firstQuarter, "Premier Quartier", "🌓");
      case 3:
        return const MoonPhaseInfo(MoonMajorPhase.waxingGibbous, "Lune Gibbeuse Croissante", "🌔");
      case 4:
        return const MoonPhaseInfo(MoonMajorPhase.fullMoon, "Pleine Lune", "🌕");
      case 5:
        return const MoonPhaseInfo(MoonMajorPhase.waningGibbous, "Lune Gibbeuse Décroissante", "🌖");
      case 6:
        return const MoonPhaseInfo(MoonMajorPhase.lastQuarter, "Dernier Quartier", "🌗");
      default:
        return const MoonPhaseInfo(MoonMajorPhase.waningCrescent, "Dernier Croissant", "🌘");
    }
  }

  MoonPhaseInfo _moonPhaseForDay(DateTime day) {
    final d = _asUtcMidday(day);

    final moon = SunCalc.getMoonIllumination(d);
    final double p = ((moon['phase'] ?? 0)).toDouble() % 1.0;

    int idx = ((p * 8.0).round()) % 8;

    switch (idx) {
      case 0:
        return const MoonPhaseInfo(MoonMajorPhase.newMoon, "Nouvelle Lune", "🌑");
      case 1:
        return const MoonPhaseInfo(MoonMajorPhase.waxingCrescent, "Premier Croissant", "🌒");
      case 2:
        return const MoonPhaseInfo(MoonMajorPhase.firstQuarter, "Premier Quartier", "🌓");
      case 3:
        return const MoonPhaseInfo(MoonMajorPhase.waxingGibbous, "Lune Gibbeuse Croissante", "🌔");
      case 4:
        return const MoonPhaseInfo(MoonMajorPhase.fullMoon, "Pleine Lune", "🌕");
      case 5:
        return const MoonPhaseInfo(MoonMajorPhase.waningGibbous, "Lune Gibbeuse Décroissante", "🌖");
      case 6:
        return const MoonPhaseInfo(MoonMajorPhase.lastQuarter, "Dernier Quartier", "🌗");
      default:
        return const MoonPhaseInfo(MoonMajorPhase.waningCrescent, "Dernier Croissant", "🌘");
    }
  }

  void _showMonthYearPicker(BuildContext context) {
    int pickedYear = _focusedDay.year;
    int pickedMonth = _focusedDay.month;

    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Aller à…'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sélecteur d'année
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () =>
                            setDialogState(() => pickedYear--),
                      ),
                      Text(
                        '$pickedYear',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () =>
                            setDialogState(() => pickedYear++),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Grille des mois
                  SizedBox(
                    width: 280,
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.2,
                      children: List.generate(12, (i) {
                        final isSelected = i + 1 == pickedMonth;
                        return Material(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () =>
                                setDialogState(() => pickedMonth = i + 1),
                            child: Center(
                              child: Text(
                                months[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimary
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime.utc(pickedYear, pickedMonth, 1);
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMissions =
        _selectedDay != null ? _missionsForDay(_selectedDay!) : <Mission>[];

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: const Text("Calendrier"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/backgrounds/Calendar.png',
              // Cover : remplit tout l'écran sans déformer, quitte à recadrer les bords
              fit: BoxFit.cover, 
              // Center : garde le milieu de l'image toujours visible
              alignment: Alignment.center, 
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Intensité du flou
              child: Container(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TableCalendar(
                  firstDay: _firstDay,
                  lastDay: _lastDay,
                  focusedDay: _focusedDay,
                  calendarFormat: _format,
                  availableCalendarFormats: const {CalendarFormat.month: "Mois"},
                  startingDayOfWeek: StartingDayOfWeek.monday,

                  rowHeight: 64,
                  daysOfWeekHeight: 24,

                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    leftChevronVisible: true,
                    rightChevronVisible: true,
                  ),

                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: true,
                    isTodayHighlighted: true,
                    cellMargin: EdgeInsets.zero,
                    cellPadding: EdgeInsets.zero,
                  ),

                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });

                    final info = _moonPhaseForDay(selected);

                    final messenger = ScaffoldMessenger.of(context);
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      SnackBar(
                        duration: const Duration(milliseconds: 900),
                        content: Text(
                          "${selected.day}/${selected.month}/${selected.year} — ${info.emoji} ${info.label}",
                        ),
                      ),
                    );
                  },

                  onPageChanged: (focused) {
                    setState(() => _focusedDay = focused);
                  },

                  calendarBuilders: CalendarBuilders(
                    headerTitleBuilder: (context, day) {
                      const months = [
                        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
                        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
                      ];
                      return GestureDetector(
                        onTap: () => _showMonthYearPicker(context),
                        child: Center(
                          child: Text(
                            '${months[day.month - 1]} ${day.year}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      );
                    },

                    defaultBuilder: (context, day, focusedDay) {
                      final transition = _transitionPhaseForDay(day);
                      return _DayCell(
                        day: day,
                        focusedDay: _focusedDay,
                        selected: isSameDay(_selectedDay, day),
                        emoji: transition?.emoji,
                        missionTitles: _missionsForDay(day)
                            .map((m) => m.title)
                            .toList(),
                      );
                    },

                    todayBuilder: (context, day, focusedDay) {
                      final transition = _transitionPhaseForDay(day);
                      return _DayCell(
                        day: day,
                        focusedDay: _focusedDay,
                        selected: isSameDay(_selectedDay, day),
                        emoji: transition?.emoji,
                        isToday: true,
                        missionTitles: _missionsForDay(day)
                            .map((m) => m.title)
                            .toList(),
                      );
                    },

                    selectedBuilder: (context, day, focusedDay) {
                      final transition = _transitionPhaseForDay(day);
                      return _DayCell(
                        day: day,
                        focusedDay: _focusedDay,
                        selected: true,
                        emoji: transition?.emoji,
                        missionTitles: _missionsForDay(day)
                            .map((m) => m.title)
                            .toList(),
                      );
                    },
                  ),
                ),
              ),

              // ── Missions du jour sélectionné ──────────────────────────────────────
              if (selectedMissions.isNotEmpty) ...[
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: selectedMissions.length,
                    itemBuilder: (context, index) {
                      final mission = selectedMissions[index];
                      return _MissionButton(
                        mission: mission,
                        onTap: () => Navigator.pushNamed(
                          context,
                          Routes.missionSheet,
                          arguments: mission,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ]
      ),
    );
  }
}

// ─── Bouton de mission ────────────────────────────────────────────────────────

class _MissionButton extends StatelessWidget {
  final Mission mission;
  final VoidCallback onTap;

  const _MissionButton({required this.mission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // Miniature illustration
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: mission.illustrationPath != null
                      ? Image.network(
                          mission.illustrationPath!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const _PlaceholderThumbnail(),
                        )
                      : const _PlaceholderThumbnail(),
                ),
              ),
              const SizedBox(width: 12),
              // Titre
              Expanded(
                child: Text(
                  mission.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderThumbnail extends StatelessWidget {
  const _PlaceholderThumbnail();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.image_not_supported_outlined, size: 24),
    );
  }
}

// ─── Cellule calendrier ───────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final DateTime day;
  final DateTime focusedDay;
  final bool selected;
  final bool isToday;
  final String? emoji;
  final List<String> missionTitles;

  const _DayCell({
    required this.day,
    required this.focusedDay,
    required this.selected,
    required this.emoji,
    this.isToday = false,
    this.missionTitles = const [],
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutside = day.month != focusedDay.month;

    final borderColor = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).dividerColor;

    final bgColor = selected
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;

    return SizedBox.expand(
      child: Opacity(
        opacity: isOutside ? 0.35 : 1.0,
        child: Container(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${day.day}",
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              if (emoji != null) ...[
                const SizedBox(height: 1),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(emoji!, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ],
              if (missionTitles.isNotEmpty) ...[
                const SizedBox(height: 1),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      missionTitles.join('\n'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
