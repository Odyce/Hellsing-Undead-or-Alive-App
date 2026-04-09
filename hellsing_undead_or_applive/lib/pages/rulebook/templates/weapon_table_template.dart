import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_page.dart';
import '../widgets/page_frame.dart';

/// Gabarit pour un tableau d'armes.
class WeaponTableTemplate extends StatelessWidget {
  final WeaponTablePage page;
  final int? pageNumber;

  const WeaponTableTemplate({super.key, required this.page, this.pageNumber});

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
          Text(
            page.category.toUpperCase(),
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: page.weapons.map(_weaponRow).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weaponRow(WeaponEntry weapon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: _midBrown, width: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                weapon.name,
                style: const TextStyle(
                  fontFamily: 'EBGaramond',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _darkBrown,
                ),
              ),
              Text(
                '${weapon.price} £',
                style: const TextStyle(
                  fontFamily: 'EBGaramond',
                  fontSize: 14,
                  color: _midBrown,
                ),
              ),
            ],
          ),
          if (weapon.flavorText.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              weapon.flavorText,
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: _midBrown,
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Dégâts : ${weapon.damage}',
            style: const TextStyle(
              fontFamily: 'EBGaramond',
              fontSize: 14,
              color: _darkBrown,
            ),
          ),
          if (weapon.effect != null)
            Text(
              'Effet : ${weapon.effect}',
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 14,
                color: _darkBrown,
              ),
            ),
          if (weapon.characteristics != null)
            Text(
              weapon.characteristics!,
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 13,
                color: _midBrown,
              ),
            ),
        ],
      ),
    );
  }
}
