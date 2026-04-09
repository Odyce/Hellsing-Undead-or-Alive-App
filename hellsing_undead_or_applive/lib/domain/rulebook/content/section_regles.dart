import '../book_index.dart';
import '../book_page.dart';
import '../rich_content.dart';

const sectionRegles = RawSection(
  id: 'regles',
  title: 'Règles',
  pages: [
    // ---- Contacts -----------------------------------------------------------
    FlowTextPage(
      id: 'regles_contacts',
      sectionId: 'regles',
      title: 'Contacts & Points de Contact',
      body: RichContent([
        TextNode(
          'Les agents de la Fondation Hellsing peuvent parfois compter sur '
          'l\'aide de Contacts, des Personnages Non-Joueurs (PNJ) pouvant '
          'être facilement contactés directement ou indirectement. Ces Contacts '
          'forment le réseau de votre personnage et sont acquis avant ou durant '
          'votre carrière à la Fondation.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Par définition, un Contact est disposé à répondre aux Demandes '
          'd\'un agent pour des renseignements, une action simple ou tout autre '
          'chose sans conséquence. Les Contacts ont cependant des objectifs '
          'indépendants, et les Faveurs (conditionnées à un jet de Relationnel) '
          'peuvent être refusées. Insister ou forcer un Contact risque d\'endommager '
          'la relation, voire de le perdre.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Les Contacts s\'obtiennent de deux façons : par acquisition opportune '
          '(octroyée par le MJ, 0 PC) ou par création via dépense de ',
        ),
        TextNode('Points de Contact (PC)', style: TextStyleHint.bold),
        TextNode('.'),
        ParagraphBreakNode(),
        TextNode('(2 PC) — Civil', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode(
          'Ex : enfants des rues, policier de base, boulanger, journaliste, '
          'artisan, mendiant. Ne connaît pas le Secret Midian.',
        ),
        ParagraphBreakNode(),
        TextNode('(3 PC) — Contact à responsabilité', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode(
          'Ex : inspecteur de police, gradé d\'un gang, médecin, notable, '
          'gentlemen, prêtre, scientifique. Ne connaît pas le Secret Midian.',
        ),
        ParagraphBreakNode(),
        TextNode('(4 PC) — Chefs d\'organisations', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode(
          'Ex : directeur d\'hôpital, chef de gang, commissaire, maire, abbé, '
          'conservateur de musée.',
        ),
        ParagraphBreakNode(),
        TextNode('(4 PC) — Midians vivant dans la société humaine', style: TextStyleHint.bold),
        ParagraphBreakNode(),
        TextNode('(5 PC) — Midians vivant cachés des humains', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode(
          'Ex : habitants du Labyrinthe, résidents des forêts. '
          'À la création, seuls les Vampires ont accès à ces contacts.',
        ),
      ]),
    ),

    // ---- Équipement ---------------------------------------------------------
    FlowTextPage(
      id: 'regles_equipement',
      sectionId: 'regles',
      title: 'Équipement & Gestion',
      body: RichContent([
        TextNode('Il y a ', style: TextStyleHint.bold),
        TextNode('6 classes d\'armements', style: TextStyleHint.bold),
        TextNode(
          ' : Armes Blanches à une main, Armes Blanches à deux mains, '
          'Armes d\'Archerie, Armes de Lancer, Armes à Feu, Explosifs. '
          'Sans Affinité pour une classe, un malus de ',
        ),
        TextNode('−20%', style: TextStyleHint.bold),
        TextNode(' s\'applique à l\'utilisation de l\'arme.'),
        ParagraphBreakNode(),
        TextNode(
          'L\'équipement de base est offert (qualité faible, sigle *). '
          'On peut porter jusqu\'à 6 armes à une main. Une arme à deux mains '
          'prend 2 emplacements, 2 armes de lancer en prennent un.',
        ),
        ParagraphBreakNode(),
        TextNode('Portées pratiques :', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode('· Armes de lancer : 10 m'),
        LineBreakNode(),
        TextNode('· Armes de poing / fusils à dispersion : 50 m'),
        LineBreakNode(),
        TextNode('· Fusils : 300 m'),
        LineBreakNode(),
        TextNode('· Carabines / fusils de précision : 700 m'),
        ParagraphBreakNode(),
        TextNode('Cadences de tir :', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode('· Mécanisme à Verrou (M.Ver) : 1 balle/tour'),
        LineBreakNode(),
        TextNode('· Single Action (S.A) : 1 balle/tour'),
        LineBreakNode(),
        TextNode('· Mécanisme à Levier (M.Lev) : jusqu\'à 2 balles/tour'),
        LineBreakNode(),
        TextNode('· Double Action (D.A) : jusqu\'à 2 balles/tour'),
        LineBreakNode(),
        TextNode('· Semi-Automatique (Sem.A) : jusqu\'à 3 balles/tour'),
        ParagraphBreakNode(),
        TextNode('Armes blanches :', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode(
          'En Coupe (Cpe), une arme blanche infligeant 6+ dégâts déclenche l\'Effet '
          'Saignement. En Estoc (Est), 6+ dégâts avec une arme assez longue est '
          'considéré comme Perforant.',
        ),
      ]),
    ),

    // ---- Munitions ----------------------------------------------------------
    FlowTextPage(
      id: 'regles_munitions',
      sectionId: 'regles',
      title: 'Munitions & Emplacements',
      body: RichContent([
        TextNode(
          'La réserve de munitions d\'un personnage comporte plusieurs '
          'Emplacements de Munitions (6 maximum). Chaque emplacement ne peut '
          'contenir que des munitions d\'un même calibre : soit un Magasin, '
          'soit jusqu\'à 8 munitions.',
        ),
        ParagraphBreakNode(),
        TextNode('Exemple de remplissage :', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode(
          '· Magasin calibre .32 Rimfire [P/P/Me/Ag/Ag/Ag]',
          style: TextStyleHint.small,
        ),
        LineBreakNode(),
        TextNode(
          '· Munitions calibre .32 Rimfire [P]×2 [Ag]×3 [Me]×1',
          style: TextStyleHint.small,
        ),
        ParagraphBreakNode(),
        TextNode(
          'Ces emplacements peuvent aussi stocker des objets créés par les '
          'personnages de certaines classes (impossible de mélanger munitions et '
          'objets créés).',
        ),
        ParagraphBreakNode(),
        TextNode('Calibres couverts par la logistique Fondation :', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode(
          '.22 / .22LR / .32 Rimfire / .41 Long Colt / .44 Magnum / 8bore / '
          '12gauge / .51 Enfield / .44 Henry / .44 Winchester / .57 Enfield.',
          style: TextStyleHint.small,
        ),
      ]),
    ),

    // ---- Compte bancaire ----------------------------------------------------
    FlowTextPage(
      id: 'regles_argent',
      sectionId: 'regles',
      title: 'Compte Bancaire & Rémunération',
      body: RichContent([
        TextNode(
          'La monnaie du jeu est la ',
        ),
        TextNode('Livre Sterling (£)', style: TextStyleHint.bold),
        TextNode(
          '. La Fondation couvre vos frais de logement et de bouche, '
          'et verse des primes selon la difficulté des missions :',
        ),
        ParagraphBreakNode(),
        TextNode('· Difficulté Basse : 300£ – 600£'),
        LineBreakNode(),
        TextNode('· Difficulté Moyenne : 400£ – 800£'),
        LineBreakNode(),
        TextNode('· Difficulté Haute : 500£ – 1 000£'),
        ParagraphBreakNode(),
        TextNode(
          'La rédaction d\'un rapport est récompensée de ',
        ),
        TextNode('150£ supplémentaires', style: TextStyleHint.bold),
        TextNode(
          ' (sous réserve d\'acceptation par le MJ). La Fondation demande '
          'd\'éviter tout conflit d\'intérêts politique ou financier.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Note : Le système monétaire est équilibré pour la jouabilité et '
          'ne correspond pas à la valeur historique réelle de la Livre Sterling.',
          style: TextStyleHint.small,
        ),
      ]),
    ),

    // ---- Résolution des actions ---------------------------------------------
    FlowTextPage(
      id: 'regles_resolution',
      sectionId: 'regles',
      title: 'Résolution des actions',
      body: RichContent([
        TextNode(
          'Au cours d\'une partie, les personnages se retrouvent dans deux types '
          'de situations : à ',
        ),
        TextNode('rythme lent', style: TextStyleHint.bold),
        TextNode(
          ' (investigation, préparation, recherches…) et à ',
        ),
        TextNode('rythme rapide', style: TextStyleHint.bold),
        TextNode(' (combat, poursuite…) à l\'appréciation du MJ.'),
        ParagraphBreakNode(),
        TextNode(
          'Un Test standard se fait sur l\'une des trois Caractéristiques '
          '(D100, réussi si inférieur à la valeur cible). ',
        ),
        TextNode('1–5 = Réussite Critique', style: TextStyleHint.bold),
        TextNode(' ; '),
        TextNode('95–100 = Échec Critique', style: TextStyleHint.bold),
        TextNode(', avec effets contextuels supplémentaires.'),
        ParagraphBreakNode(),
        TextNode('Bonus/Malus', style: TextStyleHint.bold),
        TextNode(
          ' agissent sur la valeur cible du jet. Les ',
        ),
        TextNode('Modificateurs (Mod/Modneg)', style: TextStyleHint.bold),
        TextNode(' agissent sur la valeur du jet lui-même.'),
        ParagraphBreakNode(),
        TextNode('PE à 0', style: TextStyleHint.bold),
        TextNode(
          ' : le personnage est épuisé — Modneg 10% à toutes ses actions, '
          'impossible de dépenser des PE. Récupération : 6 PE/heure depuis la '
          'dernière dépense.',
        ),
        ParagraphBreakNode(),
        TextNode('PM à 0', style: TextStyleHint.bold),
        TextNode(
          ' : le personnage est mentalement épuisé — Modneg 10% à toutes ses '
          'actions, vulnérable aux effets psychiques. Il peut puiser dans ses PV '
          '(−2 PV = −1 PM, ne peut pas descendre sous 0 PV). '
          'Récupération : 1 PM par heure de sommeil consécutive '
          '(1h: 1PM, 2h: 3PM, 3h: 6PM…).',
        ),
        ParagraphBreakNode(),
        TextNode('Actions relationnelles :', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode(
          'Le roleplay module les chances (bonus/malus MJ), mais le jet de '
          'Relationnel a le dernier mot sur la qualité de l\'interaction.',
        ),
        ParagraphBreakNode(),
        TextNode('Tests de perception :', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode('· Physique : percevoir une menace via les sens'),
        LineBreakNode(),
        TextNode('· Mental : déduire la présence d\'une menace'),
        LineBreakNode(),
        TextNode('· Social : deviner une menace via le comportement d\'un groupe'),
        ParagraphBreakNode(),
        TextNode('Attaques désarmées :', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode(
          'D4/2 arrondi au supérieur. Les bonus raciaux (Vampire, Demi-Vampire) '
          's\'appliquent. Pas de malus de précision sur les attaques ciblées désarmées.',
        ),
        ParagraphBreakNode(),
        TextNode('Attaques ciblées :', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode('· −10% : partie de la cible (membre, tête)'),
        LineBreakNode(),
        TextNode('· −20% : point faible précis (œil, cœur)'),
      ]),
    ),

    // ---- Les combats --------------------------------------------------------
    FlowTextPage(
      id: 'regles_combats',
      sectionId: 'regles',
      title: 'Les combats',
      body: RichContent([
        TextNode(
          'L\'ordre de jeu est défini par le MJ en début de combat. L\'initiative '
          'revient au personnage ayant effectué la première action. Cet ordre '
          'peut être modifié par des événements au cours du combat.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Au cours d\'un tour, le personnage peut se ',
        ),
        TextNode('déplacer et agir', style: TextStyleHint.bold),
        TextNode(
          '. Cette action peut être défensive (couverture, soin…) ou offensive '
          '(tir, pouvoir mystique…), mais pas un second déplacement. '
          'Les Compétences peuvent être combinées, sauf celles marquées ',
        ),
        TextNode('(L)', style: TextStyleHint.bold),
        TextNode(' (Limitées).'),
        ParagraphBreakNode(),
        TextNode('Résolution d\'une attaque :', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode(
          'L\'attaquant effectue un test de la Caractéristique correspondante '
          '(Physique, Relationnel ou Mental).',
        ),
        ParagraphBreakNode(),
        TextNode('· Jet < Caractéristique ', style: TextStyleHint.bold),
        TextNode(': attaque réussie.'),
        LineBreakNode(),
        TextNode('· Jet < Caractéristique/2 ', style: TextStyleHint.bold),
        TextNode(': attaque imparable et inesquivable.'),
        LineBreakNode(),
        TextNode('· Jet ≥ Caractéristique/2 ', style: TextStyleHint.bold),
        TextNode(
          ': la cible peut se Défendre (parade, esquive…) si le contexte le '
          'permet, en réussissant un jet inférieur au jet d\'attaque ET à sa '
          'propre Caractéristique.',
        ),
        ParagraphBreakNode(),
        TextNode('Couverture :', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode(
          'La cible d\'un tir ne peut se défendre qu\'à couvert — jet inférieur '
          'au jet d\'attaque ET à sa Caractéristique. Un personnage à couvert '
          's\'oppose au tir avec un obstacle (arbre, caisse, coin de mur…) qui '
          'subit le tir en cas de défense réussie.',
        ),
        ParagraphBreakNode(),
        TextNode('Actions de tir :', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode(
          '· Cible fixe : un unique jet de tir, quel que soit le nombre de '
          'munitions tirées.',
        ),
        LineBreakNode(),
        TextNode('· Cible mouvante : un jet par munition tirée.'),
      ]),
    ),
  ],
);
