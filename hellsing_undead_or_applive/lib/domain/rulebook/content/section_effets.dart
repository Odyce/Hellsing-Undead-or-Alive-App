import '../book_index.dart';
import '../book_page.dart';

const sectionEffets = RawSection(
  id: 'effets',
  title: 'Liste des effets',
  pages: [
    EffectListPage(
      id: 'effets_liste',
      sectionId: 'effets',
      title: 'Liste des effets',
      effects: [
        EffectEntry(
          name: 'Béni',
          description:
              'Possède une forte présence spirituelle. +3 dégâts contre les entités démoniaques et de plans différents.',
          aggravatedDescription:
              '+5 dégâts contre les entités démoniaques et de plans différents.',
        ),
        EffectEntry(
          name: 'Sacré',
          description:
              'Reproduit l\'effet de l\'exposition au soleil sur les créatures sensibles.',
        ),
        EffectEntry(
          name: 'Argent',
          description:
              'Brûle la chair de la plupart des Midians. +3 dégâts contre les créatures sensibles.',
          aggravatedDescription: '+5 dégâts contre les créatures sensibles.',
        ),
        EffectEntry(
          name: 'Mercure',
          description:
              'Alourdit les balles, empoisonne la plupart des Midians. '
              '+1 dégât, −1 PM/tour pour les créatures sensibles tant que le Mercure n\'est pas éliminé.',
          aggravatedDescription:
              '+3 dégâts, −2 PM/tour pour les créatures sensibles tant que le Mercure n\'est pas éliminé.',
        ),
        EffectEntry(
          name: 'Perforant',
          description: 'Optimise la pénétration pour passer une armure. Ignore jusqu\'à 3 points d\'armure.',
          aggravatedDescription: 'Ignore jusqu\'à 6 points d\'armure.',
        ),
        EffectEntry(
          name: 'Incendiaire',
          description:
              'Enflamme la cible. 1/6 de chance d\'infliger l\'Effet Enflammé, augmente d\'un à chaque coup successif.',
          aggravatedDescription:
              '2/4 de chance d\'infliger l\'Effet Enflammé, augmente d\'un à chaque coup successif.',
        ),
        EffectEntry(
          name: 'Enflammé',
          description:
              'Consume la cible. La cible subit 1 dégât/tour jusqu\'à ce que les flammes soient éteintes.',
          aggravatedDescription:
              'La cible subit 3 dégâts/tour jusqu\'à ce que les flammes soient éteintes.',
        ),
        EffectEntry(
          name: 'Saignement',
          description:
              'Fait saigner la cible. La cible perd 1 PV/tour jusqu\'à ce que la blessure soit refermée.',
          aggravatedDescription:
              'La cible perd 3 PV/tour jusqu\'à ce que la blessure soit refermée.',
        ),
      ],
    ),
  ],
);
