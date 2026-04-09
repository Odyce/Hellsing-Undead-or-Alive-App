import '../annex_sheet.dart';
import '../book_index.dart';
import '../book_page.dart';
import '../rich_content.dart';

// ---------------------------------------------------------------------------
// Contenu d'exemple pour tester l'infrastructure (étape 1).
// Couvre : couverture, intro, création de personnage, fiche race Vampire,
// fiche classe Fusiller, une page blanche, et une fiche annexe.
// ---------------------------------------------------------------------------

// ---- Section : Couverture -------------------------------------------------

const _sectionCover = RawSection(
  id: 'cover',
  title: 'Couverture',
  pages: [
    CoverPage(
      id: 'couverture',
      sectionId: 'cover',
      title: 'Undead or Alive — Hellsing Foundation V5.3',
      assetPath: 'assets/book/cover.png',
    ),
  ],
);

// ---- Section : Introduction -----------------------------------------------

const _sectionIntro = RawSection(
  id: 'intro',
  title: 'Introduction',
  pages: [
    ChapterIntroPage(
      id: 'intro_londres',
      sectionId: 'intro',
      title: 'Londres, 1873',
      body: RichContent([
        TextNode('Les monstres existent. ', style: TextStyleHint.bold),
        TextNode(
          'Cette peur universelle de l\'obscurité et des créatures '
          'qui s\'y cachent est parfaitement justifiée. Vampires, '
          'loups-garous, spectres et croque-mitaines sont autant de '
          'menaces pesant sur l\'humanité quand le soleil se couche.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Ainsi est née la Fondation Hellsing, une organisation '
          'rassemblant dans un même effort des chasseurs venus de '
          'tout l\'empire britannique.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Vous êtes un agent de la Fondation Hellsing. '
          'Menez l\'enquête, éliminez vos cibles, résolvez les crimes '
          'de la Nuit. Si par hasard vous en revenez vivant, '
          'de nouvelles affaires vous attendent toujours…',
        ),
        ParagraphBreakNode(),
        TextNode('Combien de temps tiendrez-vous ?',
            style: TextStyleHint.boldItalic),
      ]),
    ),
  ],
);

// ---- Section : Création de personnage -------------------------------------

const _sectionCreation = RawSection(
  id: 'creation',
  title: 'Création personnage',
  pages: [
    FlowTextPage(
      id: 'creation_personnage',
      sectionId: 'creation',
      title: 'Création personnage',
      body: RichContent([
        TextNode(
          'Un personnage est avant tout défini par son histoire et '
          'sa personnalité, qui vont conditionner le Roleplay de celui-ci.',
        ),
        ParagraphBreakNode(),
        TextNode('Un personnage possède 3 '),
        TextNode('Caractéristiques principales', style: TextStyleHint.bold),
        TextNode('. Le '),
        TextNode('Physique', style: TextStyleHint.bold),
        TextNode(' représente sa capacité à utiliser son corps, le '),
        TextNode('Relationnel', style: TextStyleHint.bold),
        TextNode(' représente son aisance dans les rapports sociaux, le '),
        TextNode('Mental', style: TextStyleHint.bold),
        TextNode(' représente sa capacité à réfléchir et à utiliser des '
            'pouvoirs mystiques.'),
        ParagraphBreakNode(),
        TextNode('Vous disposez à la création de '),
        TextNode('180 points', style: TextStyleHint.bold),
        TextNode(' à répartir entre Physique, Relationnel et Mental. '
            'Ces Caractéristiques ne peuvent '),
        TextNode('pas dépasser 80 ni être inférieure à 10',
            style: TextStyleHint.bold),
        TextNode('. Elles doivent également être un multiple de 5.'),
        ParagraphBreakNode(),
        TextNode('Consultez la section '),
        LinkNode(
          text: 'Choisir sa race',
          targetId: 'race_vampire',
          linkStyle: LinkStyle.direct,
        ),
        TextNode(' pour les détails sur les races disponibles.'),
        ParagraphBreakNode(),
        TextNode('Voir aussi : '),
        LinkNode(
          text: 'Règles de résolution des actions',
          targetId: 'resolution_actions',
          linkStyle: LinkStyle.discreet,
        ),
        TextNode('.'),
      ]),
    ),
  ],
);

// ---- Section : Races ------------------------------------------------------

const _sectionRaces = RawSection(
  id: 'races',
  title: 'Choisir sa race',
  pages: [
    RaceSheetPage(
      id: 'race_vampire',
      sectionId: 'races',
      title: 'Vampire',
      raceName: 'Vampire',
      description: RichContent([
        TextNode(
          'Ces êtres des ténèbres n\'ont d\'humain que l\'apparence, '
          'se nourrissent de sang et craignent le soleil. Ce sont les '
          'cibles principales de la Fondation Hellsing.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Considérés comme des traîtres dans les communautés de Midians, '
          'les vampires de la Fondation sont vus comme des armes au '
          'service de l\'humanité.',
        ),
      ]),
      bonuses: [
        'Régénération de PV passive et lente (1h rend 1PV)',
        'Force musculaire grandement accrue (+10% au jet, +2 dégâts CàC)',
        'Peut transformer un humain en vampire ou en goule',
        'Vision Nocturne',
        'Ne peut être mentalement épuisé (puise PV pour PM)',
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
  ],
);

// ---- Section : Classes (échantillon) --------------------------------------

const _sectionClasses = RawSection(
  id: 'classes',
  title: 'Choisir sa classe',
  pages: [
    ClassSheetPage(
      id: 'classe_fusiller',
      sectionId: 'classes',
      title: 'Fusiller',
      className: 'Fusiller',
      classCategory: 'Classes communes',
      quote: 'Dieu à créer tout les êtres rampant sur cette Terre, '
          'Samuel Colt les as rendues égaux.',
      classBonuses: ['/6 Fin Tireur', '/6 Réflexe', '/6 Vue Perçante'],
      equipment: [
        EquipmentSlot(
          label: 'Arme à Feu',
          detail: 'DX (Effet) Calibre Rechargement:x Bar[-/-/-/-/-/-] S.A',
        ),
        EquipmentSlot(
          label: 'Arme à Feu',
          detail: 'DX (Effet) Calibre Rechargement:x Bar[-/-/-/-/-/-] S.A',
        ),
      ],
      affinities: ['Armes à Feu'],
      munitionSlots: 3,
      skillFormula: 'Physique/20 compétences, PE=Physique/10',
      freeSkills: [
        'Double Tir (-2PE, tire avec deux armes, -10% au jet à chaque tir)',
      ],
      accessibleSkills: [
        'Tir de Suppression (-1PE, force la cible à couvert, +20% par tir)',
        'Tir de Sommation (-1PE, gratuit hors combat, Mod 15% menace)',
        'Tir réflexe (-2PE, Mod négatif 5%, tir lors de la défense)',
        'Tir Rapide (-2PE, Mod négatif 5%, agir en premier)',
        'Tir Chirurgical (-2PE, zone précise sans malus de 20%)',
        'Recharge Rapide (-2PE, ignore le rechargement)',
        'Tir au Jugé (-2PE, tire sans perdre la couverture)',
        'Tir assuré (-3PE, 1 Tour d\'attente, +30%, Mod 15%)',
        'Tir d\'interruption (-3PE, agir durant le tour ennemi) (L)',
        'Ricochet (-3PE, tire en ricochet, Mod 10%)',
        'Rafales (-4PE, enchaîne les tirs jusqu\'à raté ou chargeur vide)',
        'Pluie de Balles (-5PE, cibles illimitées, épuise les munitions) (L)',
      ],
    ),
  ],
);

// ---- Section : Résolution des actions (page cible du lien discret) --------

const _sectionRegles = RawSection(
  id: 'regles',
  title: 'Résolution des actions',
  pages: [
    FlowTextPage(
      id: 'resolution_actions',
      sectionId: 'regles',
      title: 'Résolution des actions',
      body: RichContent([
        TextNode(
          'Un Test standard se fait sur une des Caractéristiques. '
          'Il s\'agit d\'un D100, considéré comme réussi s\'il est '
          'en dessous de la valeur cible.',
        ),
        ParagraphBreakNode(),
        TextNode('Obtenir une valeur de '),
        TextNode('1 à 5', style: TextStyleHint.bold),
        TextNode(' équivaut à une '),
        TextNode('Réussite Critique', style: TextStyleHint.bold),
        TextNode(', une valeur de '),
        TextNode('95 à 100', style: TextStyleHint.bold),
        TextNode(' à un '),
        TextNode('Échec Critique', style: TextStyleHint.bold),
        TextNode('.'),
      ]),
    ),
  ],
);

// ---- Fiche annexe de test -------------------------------------------------

const sampleAnnexes = [
  AnnexSheet(
    id: 'annexe_pouvoir_vampirique',
    title: 'Le Pouvoir Vampirique',
    body: RichContent([
      TextNode('Le '),
      TextNode('Pouvoir', style: TextStyleHint.bold),
      TextNode(
        ' détermine l\'intensité des pouvoirs mystiques influençant '
        'les personnages non-humains. Il est déterminé par un D100 '
        'arrondi au multiple de 5 le plus proche.',
      ),
      ParagraphBreakNode(),
      TextNode(
        'Pour les Demi-Vampires, même si le D100 est supérieur à 70, '
        'le pouvoir vampirique de départ est de 70 maximum.',
      ),
    ]),
  ),
];

// ---- Assemblage -----------------------------------------------------------

/// Toutes les sections brutes de l'échantillon de test.
const sampleSections = [
  _sectionCover,
  _sectionIntro,
  _sectionCreation,
  _sectionRaces,
  _sectionClasses,
  _sectionRegles,
];

/// Construit un BookIndex à partir du contenu d'exemple.
BookIndex buildSampleBookIndex() {
  return BookIndex.build(
    rawSections: sampleSections,
    rawAnnexes: sampleAnnexes,
  );
}
