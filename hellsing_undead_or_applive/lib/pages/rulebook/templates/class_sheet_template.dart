import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_page.dart';
import '../widgets/page_frame.dart';

/// Gabarit pour une fiche de classe (Fusiller, Bretteur, Nosferatu…).
class ClassSheetTemplate extends StatelessWidget {
  final ClassSheetPage page;
  final int? pageNumber;

  const ClassSheetTemplate({super.key, required this.page, this.pageNumber});

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
            // Titre de classe
            Text(
              page.className.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Cinzel Decorative',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _darkBrown,
                letterSpacing: 2,
              ),
            ),
            Text(
              page.classCategory,
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: _midBrown,
              ),
            ),
            const SizedBox(height: 4),
            const Divider(color: _blood, thickness: 1.5),
            const SizedBox(height: 6),

            // Citation
            Text(
              '« ${page.quote} »',
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: _midBrown,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Bonus de classe
            _sectionHeader('BONUS DE CLASSE'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: page.classBonuses.map(_bonusChip).toList(),
            ),
            const SizedBox(height: 12),

            // Emplacements d'équipement
            _sectionHeader('ÉQUIPEMENT'),
            const SizedBox(height: 4),
            ...page.equipment.map(_equipmentSlotWidget),
            const SizedBox(height: 10),

            // Affinités + munitions sur la même ligne
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('AFFINITÉS'),
                      const SizedBox(height: 4),
                      Text(
                        page.affinities.join(', '),
                        style: const TextStyle(
                          fontFamily: 'EBGaramond',
                          fontSize: 14,
                          color: _darkBrown,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _sectionHeader('MUNITIONS'),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        page.munitionSlots,
                        (_) => const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.circle_outlined,
                            size: 16,
                            color: _midBrown,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Formule de compétences
            _sectionHeader('COMPÉTENCES'),
            const SizedBox(height: 4),
            Text(
              page.skillFormula,
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 14,
                color: _darkBrown,
              ),
            ),
            const SizedBox(height: 10),

            // Compétences gratuites
            if (page.freeSkills.isNotEmpty) ...[
              _sectionHeader('COMPÉTENCES GRATUITES'),
              const SizedBox(height: 4),
              ...page.freeSkills
                  .map((s) => _skillRow(s, free: true)),
              const SizedBox(height: 10),
            ],

            // Compétences accessibles
            if (page.accessibleSkills.isNotEmpty) ...[
              _sectionHeader('COMPÉTENCES ACCESSIBLES'),
              const SizedBox(height: 4),
              ...page.accessibleSkills
                  .map((s) => _skillRow(s, free: false)),
            ],

            // Note optionnelle
            if (page.note != null) ...[
              const SizedBox(height: 10),
              Text(
                page.note!,
                style: const TextStyle(
                  fontFamily: 'EBGaramond',
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: _midBrown,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Cinzel Decorative',
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: _blood,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _bonusChip(String bonus) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: _blood, width: 0.8),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        bonus,
        style: const TextStyle(
          fontFamily: 'EBGaramond',
          fontSize: 13,
          color: _darkBrown,
        ),
      ),
    );
  }

  Widget _equipmentSlotWidget(EquipmentSlot slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: _midBrown, width: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${slot.label} : ',
            style: const TextStyle(
              fontFamily: 'EBGaramond',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _darkBrown,
            ),
          ),
          Expanded(
            child: Text(
              slot.detail,
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 13,
                color: _midBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillRow(String skill, {required bool free}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            free ? '✦  ' : '·  ',
            style: TextStyle(
              color: free ? _blood : _midBrown,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              skill,
              style: const TextStyle(
                fontFamily: 'EBGaramond',
                fontSize: 14,
                color: _darkBrown,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
