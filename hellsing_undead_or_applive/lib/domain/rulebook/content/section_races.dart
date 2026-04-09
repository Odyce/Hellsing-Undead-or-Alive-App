import '../book_index.dart';
import '../book_page.dart';
import '../rich_content.dart';

const sectionRaces = RawSection(
  id: 'races',
  title: 'Choisir sa race',
  pages: [
    // ---- Vampire -----------------------------------------------------------
    RaceSheetPage(
      id: 'race_vampire',
      sectionId: 'races',
      title: 'Vampire',
      raceName: 'Vampire',
      description: RichContent([
        TextNode(
          'Ces êtres des ténèbres n\'ont d\'humain que l\'apparence, se '
          'nourrissent de sang et craignent le soleil. Ce sont les cibles '
          'principales de la Fondation Hellsing, qui visent à les éliminer '
          'pour débarrasser l\'humanité de ces prédateurs. Toutefois certains '
          'de ces damnés continuent de se battre aux côtés des humains, contre '
          'leurs semblables.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Considérés comme des traîtres dans les communautés de Midians, '
          'les vampires de la Fondation sont vus comme des armes au service de '
          'l\'humanité. Ils doivent donc être gardés sous contrôle. Ainsi ils '
          'sont nourris avec le minimum de sang possible et ont interdiction de '
          'se nourrir sans autorisation ou de transformer qui que ce soit sous '
          'peine de passer de chasseur à proie.',
        ),
      ]),
      bonuses: [
        'Régénération de PV passive et lente (1h rend 1PV)',
        'Force musculaire grandement accrue (+10% au jet si force, +2 dégâts CàC)',
        'Peut transformer un humain en vampire ou en goule (test de pouvoir)',
        'Vision Nocturne',
        'Ne peut être mentalement épuisé — peut puiser dans ses PV pour PM (1PV = 1PM)',
      ],
      maluses: [
        'Brûle au soleil (-1 PV par tour, exposition directe)',
        'De jour, impossibilité de récupérer des PE',
        'Diminution du pouvoir vampirique si en manque de sang',
        'Malus de 10% au jet de jour ou en terre consacrée',
        'Inconfort à la vue des symboles sacrés et des miroirs',
      ],
      accessibleClasses: [
        'Classes communes',
        'Noctambule',
        'Nosferatu',
        'Strigoi',
      ],
    ),

    // ---- Demi-Vampire ------------------------------------------------------
    RaceSheetPage(
      id: 'race_demi_vampire',
      sectionId: 'races',
      title: 'Demi-Vampire',
      raceName: 'Demi-Vampire',
      description: RichContent([
        TextNode(
          'Quand un vampire attaque un humain, celui-ci ne meurt pas toujours. '
          'Il développe une partie de pouvoir vampirique qui l\'attire '
          'constamment vers les ténèbres, il devient un Demi-Vampire. Cette '
          'malédiction augmente ses capacités physiques, en faisant un chasseur '
          'plus puissant que la normale, mais à quel prix ?',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Lors de sa mort, la transformation est inévitable. Il perdra toute '
          'forme d\'identité et de personnalité humaine pour renaître sous '
          'forme de vampire. Ainsi la plupart des demi-vampires cherchent à '
          'briser leur malédiction en tuant le vampire qui les a attaqués dans '
          'l\'espoir de regagner leur humanité menacée.',
        ),
      ]),
      bonuses: [
        'Force accrue la nuit (+10% la nuit, +40% si consommation de sang, +1 dégât CàC)',
        'Peut ressentir le pouvoir vampirique chez quelqu\'un par contact visuel',
        'Vision Nocturne',
      ],
      maluses: [
        'Brûle au soleil (-1 PV par tour, exposition directe)',
        'De jour, impossibilité de récupérer des PE',
        'Diminution du pouvoir vampirique si en manque de sang',
        'Malus de 10% au jet de jour ou en terre consacrée',
        'Inconfort à la vue des symboles sacrés et des miroirs',
      ],
      accessibleClasses: [
        'Classes communes',
        'Dampyr',
        'Lamenuit',
      ],
    ),

    // ---- Humain ------------------------------------------------------------
    RaceSheetPage(
      id: 'race_humain',
      sectionId: 'races',
      title: 'Humain',
      raceName: 'Humain',
      description: RichContent([
        TextNode(
          'Les humains sont l\'espèce dominante sur la planète, mais ont '
          'longtemps été sans défense face aux Midians. Cependant les agents '
          'de la Fondation Hellsing sont majoritairement des humains '
          'spécialisés dans la traque et l\'exécution des créatures de la nuit. '
          'Parmi eux, de rares individus ont pu développer des dons mystiques, '
          'propres à l\'humanité et ne sont pas à sous-estimer.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'La force de l\'humanité réside dans sa mortalité, et la conscience '
          'que les Hommes ont de celle-ci, les poussant à repousser toujours '
          'plus loin leurs limites, à aiguiser leurs talents innés et à en '
          'acquérir constamment de nouveaux.',
        ),
      ]),
      bonuses: [],
      maluses: [],
      accessibleClasses: [
        'Classes communes',
        'Mentaliste',
        'Occultiste',
        'Inquisiteur',
        'Homme de Foi',
      ],
    ),

    // ---- Semi-Ange ---------------------------------------------------------
    RaceSheetPage(
      id: 'race_semi_ange',
      sectionId: 'races',
      title: 'Semi-Ange',
      raceName: 'Semi-Ange',
      description: RichContent([
        TextNode(
          'Un Semi-ange est un humain à l\'esprit habité par deux âmes. '
          'Depuis leur naissance, ceux-ci sont possédés par une âme angélique '
          'leur conférant de puissants pouvoirs mystiques. Cette âme angélique '
          'n\'est pas indépendante mais sa présence influence fortement le '
          'comportement du Semi-Ange, le poussant vers un « Bien » abstrait '
          'et absolu parfois au prix de douloureuses contradictions.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'La Fondation Hellsing offre à ces êtres d\'exception un moyen de '
          'canaliser ce besoin de faire le Bien en mettant leur puissance '
          'considérable au service de l\'Humanité.',
        ),
      ]),
      bonuses: [
        '+10% au jet au soleil et en terres consacrées',
        'Sang toxique pour les Vampires',
        'Toucher désagréable pour les Midians (brûle ceux sensibles à l\'Effet Sacré)',
        'Peut ressentir la présence d\'Entités maléfiques majeures',
      ],
      maluses: [
        'Impossibilité de mentir directement',
        'Se sent nauséeux en présence d\'actes ou d\'entités maléfiques ou sur une terre maudite',
      ],
      accessibleClasses: [
        'Classes communes',
        'Néphilim',
        'Séraphin',
        'Chérubin',
      ],
    ),
  ],
);
