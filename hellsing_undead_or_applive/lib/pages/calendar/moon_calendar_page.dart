import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:apsl_sun_calc/apsl_sun_calc.dart';

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

  @override
  void initState() {
    super.initState();
    _focusedDay = _initialMonth; // => s’ouvre toujours sur Mars 1877
  }

  DateTime _asUtcMidday(DateTime d) {
    // Midi UTC = évite les soucis de changement d’heure / minuit local
    return DateTime.utc(d.year, d.month, d.day, 12);
  }

  double _circularDistance(double a, double b) {
    final d = (a - b).abs();
    return d > 0.5 ? 1.0 - d : d; // distance sur un cercle
  }

  double _moonPhaseValue(DateTime day) {
    final d = _asUtcMidday(day);
    final moon = SunCalc.getMoonIllumination(d); // Map<String, num>
    final p = ((moon['phase'] ?? 0)).toDouble() % 1.0;
    return p < 0 ? p + 1.0 : p;
  }

  /// Retourne la phase majeure si "transition day", sinon null.
  MoonPhaseInfo? _transitionPhaseForDay(DateTime day) {
    final pPrev = _moonPhaseValue(day.subtract(const Duration(days: 1)));
    final pNow  = _moonPhaseValue(day);
    final pNext = _moonPhaseValue(day.add(const Duration(days: 1)));

    // tolérance en fraction de cycle : plus petit = moins de jours marqués.
    // ~0.03 ≈ 0.03 * 29.53j ≈ 0.9 jour
    const tol = 0.03;

    // 8 repères
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

      // "minimum local" : aujourd’hui est le plus proche de ce repère
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

    // apsl_sun_calc calcule une phase continue (0..1)
    // 0 = nouvelle lune, 0.25 = premier quartier, 0.5 = pleine lune, 0.75 = dernier quartier.
    final moon = SunCalc.getMoonIllumination(d);
    final double p = ((moon['phase'] ?? 0)).toDouble() % 1.0;

    // Mapping en 8 catégories (octants)
    // 0.000  New
    // 0.125  Waxing Crescent
    // 0.250  First Quarter
    // 0.375  Waxing Gibbous
    // 0.500  Full
    // 0.625  Waning Gibbous
    // 0.750  Last Quarter
    // 0.875  Waning Crescent
    int idx = ((p * 8.0).round()) % 8;

    // Pour éviter qu’un round pile sur la frontière fasse “sauter” de manière bizarre,
    // tu peux remplacer round() par floor() si tu préfères :
    // int idx = ((p * 8.0).floor()) % 8;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendrier"),
        centerTitle: true,
      ),
      body: Column(
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
                    content: Text("${selected.day}/${selected.month}/${selected.year} — ${info.emoji} ${info.label}"),
                  ),
                );
              },

              onPageChanged: (focused) {
                setState(() => _focusedDay = focused);
              },

              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final transition = _transitionPhaseForDay(day);
                  return _DayCell(
                    day: day,
                    focusedDay: _focusedDay,
                    selected: isSameDay(_selectedDay, day),
                    emoji: transition?.emoji,
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
                  );
                },

                selectedBuilder: (context, day, focusedDay) {
                  final transition = _transitionPhaseForDay(day);
                  return _DayCell(
                    day: day,
                    focusedDay: _focusedDay,
                    selected: true,
                    emoji: transition?.emoji,
                  );
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              child: const Text("Retour"),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final DateTime focusedDay;
  final bool selected;
  final bool isToday;
  final String? emoji;

  const _DayCell({
    required this.day,
    required this.focusedDay,
    required this.selected,
    required this.emoji,
    this.isToday = false,
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
          margin: EdgeInsets.zero, // important
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(0), // style "papier"
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${day.day}",
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              // Empêche tout overflow de l’emoji
              if (emoji != null) ...[
                const SizedBox(height: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(emoji!, style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
