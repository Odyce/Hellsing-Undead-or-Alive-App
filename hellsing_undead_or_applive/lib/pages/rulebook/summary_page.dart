import 'package:flutter/material.dart';

class VictorianTocPage extends StatelessWidget {
  final void Function(int pageIndex) onGoToPage;

  const VictorianTocPage({super.key, required this.onGoToPage});

  static const List<_TocEntry> entries = [
    // IMPORTANT: index = numéro de page (0..47)
    _TocEntry("Couverture", 0, level: 0),
    _TocEntry("Sommaire", 1, level: 0),
    _TocEntry("Intro", 2, level: 0),

    _TocEntry("Race", 3, level: 0, isCategory: true),
    _TocEntry("Page 1 de race", 4, level: 1),
    _TocEntry("Page 2 de race", 5, level: 1),
    _TocEntry("Page 3 de race", 6, level: 1),
    _TocEntry("Page 4 de race", 7, level: 1),

    _TocEntry("Classe", 8, level: 0, isCategory: true),
    _TocEntry("Page 1 de classe", 9, level: 1),
    _TocEntry("Page 2 de classe", 10, level: 1),
    _TocEntry("Page 3 de classe", 11, level: 1),
    _TocEntry("Page 4 de classe", 12, level: 1),
    _TocEntry("Page 5 de classe", 13, level: 1),
    _TocEntry("Page 6 de classe", 14, level: 1),
    _TocEntry("Page 7 de classe", 15, level: 1),
    _TocEntry("Page 8 de classe", 16, level: 1),
    _TocEntry("Page 9 de classe", 17, level: 1),
    _TocEntry("Page 10 de classe", 18, level: 1),
    _TocEntry("Page 11 de classe", 19, level: 1),
    _TocEntry("Page 12 de classe", 20, level: 1),
    _TocEntry("Page 13 de classe", 21, level: 1),
    _TocEntry("Page 14 de classe", 22, level: 1),
    _TocEntry("Page 15 de classe", 23, level: 1),
    _TocEntry("Page 16 de classe", 24, level: 1),
    _TocEntry("Page 17 de classe", 25, level: 1),
    _TocEntry("Page 18 de classe", 26, level: 1),
    _TocEntry("Page 19 de classe", 27, level: 1),

    _TocEntry("Règles", 28, level: 0, isCategory: true),
    _TocEntry("Page 1 de règles", 29, level: 1),
    _TocEntry("Page 2 de règles", 30, level: 1),
    _TocEntry("Page 3 de règles", 31, level: 1),
    _TocEntry("Page 4 de règles", 32, level: 1),
    _TocEntry("Page 5 de règles", 33, level: 1),
    _TocEntry("Page 6 de règles", 34, level: 1),
    _TocEntry("Page 7 de règles", 35, level: 1),

    _TocEntry("Boutique", 36, level: 0, isCategory: true),
    _TocEntry("Page 1 de boutique", 37, level: 1),
    _TocEntry("Page 2 de boutique", 38, level: 1),
    _TocEntry("Page 3 de boutique", 39, level: 1),
    _TocEntry("Page 4 de boutique", 40, level: 1),
    _TocEntry("Page 5 de boutique", 41, level: 1),
    _TocEntry("Page 6 de boutique", 42, level: 1),
    _TocEntry("Page 7 de boutique", 43, level: 1),
    _TocEntry("Page 8 de boutique", 44, level: 1),
    _TocEntry("Page 9 de boutique", 45, level: 1),
    _TocEntry("Page 10 de boutique", 46, level: 1),

    _TocEntry("4e de Couverture", 47, level: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return _VictorianPaper(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Sommaire",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: const Color(0xFF2B1C0D),
                  ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),

            const SizedBox(height: 10),

            // Scroll automatique si trop long
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      for (final e in entries) ...[
                        _TocLine(
                          entry: e,
                          onTap: () => onGoToPage(e.pageIndex),
                        ),
                        const SizedBox(height: 2),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TocEntry {
  final String title;
  final int pageIndex;
  final int level; // 0 = normal, 1 = sous-item
  final bool isCategory;

  const _TocEntry(this.title, this.pageIndex, {required this.level, this.isCategory = false});
}

class _TocLine extends StatelessWidget {
  final _TocEntry entry;
  final VoidCallback onTap;

  const _TocLine({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final leftPad = entry.level == 0 ? 0.0 : 18.0;

    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: const Color(0xFF2B1C0D),
          fontWeight: entry.isCategory ? FontWeight.w800 : FontWeight.w500,
          letterSpacing: entry.isCategory ? 0.6 : 0.2,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.fromLTRB(leftPad + 10, 10, 10, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // “points de conduite” simples (look victorien sans prise de tête)
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Opacity(
                  opacity: 0.55,
                  child: Text(
                    "• " * 60,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF2B1C0D),
                          letterSpacing: 1.2,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              Text(
                entry.pageIndex.toString(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF2B1C0D),
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VictorianPaper extends StatelessWidget {
  final Widget child;
  const _VictorianPaper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Parchemin (sans assets, donc plug&play)
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF3E6C8),
            Color(0xFFE7D3A4),
            Color(0xFFF5EBD3),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6B4B21), width: 1.2),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 10),
            color: Colors.black26,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: child,
      ),
    );
  }
}
