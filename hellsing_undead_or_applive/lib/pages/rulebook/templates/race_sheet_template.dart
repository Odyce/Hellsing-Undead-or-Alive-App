import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_page.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/rich_content.dart';
import '../widgets/page_frame.dart';
import '../widgets/rich_content_renderer.dart';

/// Gabarit pour une fiche de race (Vampire, Demi-Vampire, Humain, Semi-Ange).
class RaceSheetTemplate extends StatelessWidget {
  final RaceSheetPage page;
  final int? pageNumber;
  final void Function(String targetId, LinkStyle style, Offset globalPosition)?
      onLinkTap;

  const RaceSheetTemplate({
    super.key,
    required this.page,
    this.pageNumber,
    this.onLinkTap,
  });

  static const _darkBrown = Color(0xFF3B2410);
  static const _blood = Color(0xFF8B0000);
  static const _midBrown = Color(0xFF5C3A1E);

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      pageNumber: pageNumber,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Text(
              page.raceName.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Cinzel Decorative',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _darkBrown,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            const Divider(color: _blood, thickness: 1.5),
            const SizedBox(height: 12),

            // Description
            RichContentRenderer(
              content: page.description,
              onLinkTap: onLinkTap,
            ),
            const SizedBox(height: 16),

            // Bonus
            if (page.bonuses.isNotEmpty) ...[
              _sectionHeader('BONUS', _blood),
              const SizedBox(height: 6),
              ...page.bonuses.map((b) => _bulletRow('✦', b, _blood)),
              const SizedBox(height: 14),
            ],

            // Malus
            if (page.maluses.isNotEmpty) ...[
              _sectionHeader('MALUS', _midBrown),
              const SizedBox(height: 6),
              ...page.maluses.map((m) => _bulletRow('✗', m, _midBrown)),
              const SizedBox(height: 14),
            ],

            // Classes accessibles
            if (page.accessibleClasses.isNotEmpty) ...[
              _sectionHeader('CLASSES ACCESSIBLES', _darkBrown),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: page.accessibleClasses
                    .map((c) => _classChip(c))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: 'Cinzel Decorative',
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _bulletRow(String bullet, String text, Color bulletColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$bullet  ',
            style: TextStyle(
              color: bulletColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 15,
                color: _darkBrown,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _classChip(String className) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: _midBrown, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        className,
        style: const TextStyle(
          fontFamily: 'EBGaramond',
          fontSize: 14,
          color: _darkBrown,
        ),
      ),
    );
  }
}
