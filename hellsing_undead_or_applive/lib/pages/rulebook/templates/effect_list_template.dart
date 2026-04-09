import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_page.dart';
import '../widgets/page_frame.dart';

/// Gabarit pour la liste des effets (Béni, Sacré, Argent, etc.).
class EffectListTemplate extends StatelessWidget {
  final EffectListPage page;
  final int? pageNumber;

  const EffectListTemplate({super.key, required this.page, this.pageNumber});

  static const _darkBrown = Color(0xFF3B2410);
  static const _blood = Color(0xFF8B0000);
  static const _midBrown = Color(0xFF5C3A1E);

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      pageNumber: pageNumber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (page.title != null) ...[
            Text(
              page.title!.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Cinzel Decorative',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkBrown,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            const Divider(color: _blood, thickness: 1.5),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: page.effects.map(_effectEntry).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _effectEntry(EffectEntry effect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            effect.name.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Cinzel Decorative',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _blood,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            effect.description,
            style: const TextStyle(
              fontFamily: 'EBGaramond',
              fontSize: 15,
              color: _darkBrown,
              height: 1.4,
            ),
          ),
          if (effect.aggravatedDescription != null) ...[
            const SizedBox(height: 4),
            Text(
              'Aggravé : ${effect.aggravatedDescription}',
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: _midBrown,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
