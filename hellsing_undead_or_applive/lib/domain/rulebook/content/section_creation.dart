import '../book_index.dart';
import '../book_page.dart';
import '../rich_content.dart';

const sectionCreation = RawSection(
  id: 'creation',
  title: 'Création de personnage',
  pages: [
    FlowTextPage(
      id: 'creation_personnage',
      sectionId: 'creation',
      title: 'Création de personnage',
      body: RichContent([
        TextNode(
          'Un personnage est avant tout défini par son histoire et sa '
          'personnalité, qui vont conditionner le Roleplay de celui-ci. '
          'Quelques lignes de biographie et une personnalité définie '
          'donneront de la profondeur et du sens à votre personnage.',
        ),
        ParagraphBreakNode(),
        TextNode('Un personnage possède '),
        TextNode('3 Caractéristiques principales', style: TextStyleHint.bold),
        TextNode(
          '. Le Physique représente sa capacité à utiliser son corps, '
          'le Relationnel représente son aisance dans les rapports sociaux, '
          'le Mental représente sa capacité à réfléchir et à utiliser des '
          'pouvoirs mystiques.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Ces trois Caractéristiques sont notées sur 100. Vous disposez à '
          'la création de ',
        ),
        TextNode('180 points', style: TextStyleHint.bold),
        TextNode(
          ' à répartir entre Physique, Relationnel et Mental. Ces '
          'Caractéristiques ne peuvent ',
        ),
        TextNode(
          'pas dépasser 80 ni être inférieures à 10',
          style: TextStyleHint.bold,
        ),
        TextNode('. Elles doivent également être un multiple de 5.'),
        ParagraphBreakNode(),
        TextNode('Les '),
        TextNode('PV', style: TextStyleHint.bold),
        TextNode(
          ' sont déterminés par la plus haute Caractéristique divisée par 10, '
          'auquel on rajoute 2 points si il s\'agit du Physique. Les Vampires '
          'sont une exception à cette règle et commencent avec 13 PV.',
        ),
        ParagraphBreakNode(),
        TextNode('Les '),
        TextNode('PE, PC et PM', style: TextStyleHint.bold),
        TextNode(
          ' sont déterminés respectivement par le Physique, le Relationnel '
          'et par le Mental, divisés par 10.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Les Caractéristiques Raciales, les Affinités et les Bonus de '
          'Classe dépendent de la Race et de la Classe du Personnage.',
        ),
        ParagraphBreakNode(),
        TextNode('Les '),
        TextNode('Bonus de Classe', style: TextStyleHint.bold),
        TextNode(
          ' permettent d\'obtenir des modificateurs contextuels en cas de '
          'réussite. Vous disposez à la création de ',
        ),
        TextNode('9 points', style: TextStyleHint.bold),
        TextNode(' à répartir parmi les Bonus de Classe.'),
        ParagraphBreakNode(),
        TextNode('Votre personnage possède des '),
        TextNode('Compétences', style: TextStyleHint.bold),
        TextNode(
          ' dont le nombre dépend de ses Caractéristiques selon une formule '
          'propre à chaque Classe. Choisissez vos compétences avec sagesse, '
          'et utilisez-les à propos. Si le résultat d\'un calcul ne tombe '
          'pas sur un nombre entier, on arrondira au supérieur.',
        ),
        ParagraphBreakNode(),
        TextNode('Le '),
        TextNode('Pouvoir', style: TextStyleHint.bold),
        TextNode(
          ' détermine l\'intensité des pouvoirs mystiques influençant les '
          'personnages non-humains. Il est déterminé par un D100 arrondi au '
          'multiple de 5 le plus proche et peut évoluer au cours de la vie '
          'du personnage. Vous ne tirez votre Pouvoir que si vous n\'êtes pas '
          'Humain. Pour les Demi-Vampires, même si le D100 est supérieur à 70, '
          'le pouvoir vampirique de départ est de 70 maximum.',
        ),
        ParagraphBreakNode(),
        TextNode('La '),
        TextNode('Fortune de départ', style: TextStyleHint.bold),
        TextNode(
          ' des personnages (en Livres Sterling) est obtenue via un D1000 '
          'ou 3D10 (pour centaine, dizaine, unité).',
        ),
      ]),
    ),
    FlowTextPage(
      id: 'level_up',
      sectionId: 'creation',
      title: 'Montée de niveau',
      body: RichContent([
        TextNode(
          'À la montée de niveau, l\'évolution du personnage dépend de sa race.',
        ),
        ParagraphBreakNode(),
        TextNode('Vampires', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode('· +1PM OU +2PE'),
        LineBreakNode(),
        TextNode('· +1PC'),
        LineBreakNode(),
        TextNode('· +20% de Pouvoir Vampirique & +1PC OU +1 Compétence'),
        ParagraphBreakNode(),
        TextNode('Demi-Vampires', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode('· +1PE OU +1PM'),
        LineBreakNode(),
        TextNode('· +1PV OU +1PC'),
        LineBreakNode(),
        TextNode('· +1 pt de Bonus de classe & +1PC OU +5% dans une Caractéristique'),
        LineBreakNode(),
        TextNode('· +1 Compétence OU -10% de Pouvoir Vampirique'),
        ParagraphBreakNode(),
        TextNode('Humains', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode('· +2 PE OU +2PM OU +1PE & +1PM'),
        LineBreakNode(),
        TextNode('· +1PV OU +1PC'),
        LineBreakNode(),
        TextNode('· +2 pt de Bonus de classe OU +5% dans une Caractéristique'),
        LineBreakNode(),
        TextNode('· +1 Compétence & +1PC'),
        ParagraphBreakNode(),
        TextNode('Semi-Anges', style: TextStyleHint.bold),
        LineBreakNode(),
        TextNode('· +1PE OU +1PM'),
        LineBreakNode(),
        TextNode('· +1PV OU +1PC'),
        LineBreakNode(),
        TextNode('· +1 pt de Bonus de classe & +1PC'),
        LineBreakNode(),
        TextNode('· +1 Compétence OU +5% dans une Caractéristique'),
        ParagraphBreakNode(),
        TextNode(
          'Au ',
        ),
        TextNode('Niveau 5', style: TextStyleHint.bold),
        TextNode(
          ', le personnage peut choisir une Classe Commune comme Classe '
          'Secondaire. Il pourra alors accéder à ses compétences et ses bonus '
          'de classe lors des montées de niveau. Il héritera également des '
          'Affinités de cette classe, mais pas de l\'équipement de départ.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Une fois arrivé au ',
        ),
        TextNode('Niveau Légendaire', style: TextStyleHint.bold),
        TextNode(
          ', un personnage atteint l\'apogée de sa puissance physique et '
          'mentale. Il ne peut alors plus augmenter ses PE, ses PV ou ses PM. '
          'Tous les 7 scénarios effectués, un personnage légendaire a le choix '
          'entre :',
        ),
        ParagraphBreakNode(),
        TextNode('· +2 Pt de Bonus de Classe & +1 PC'),
        LineBreakNode(),
        TextNode('· OU +1 Compétence déjà existante & +1PC'),
        LineBreakNode(),
        TextNode(
          '· OU Créer une nouvelle compétence ou transformer une de ses '
          'compétences en légendaire (à la discrétion du MJ).',
        ),
        ParagraphBreakNode(),
        TextNode('Tableau de progression :', style: TextStyleHint.bold),
        ParagraphBreakNode(),
        TextNode(
          'Niv. 1 : 0 affaires | Niv. 2 : 3 | Niv. 3 : 6 | Niv. 4 : 10 | '
          'Niv. 5 : 15 | Niv. 6 : 21 | Niv. 7 : 28 | Niv. 8 : 36 | '
          'Niv. 9 : 45 | Niv. 10 : 55 | Légendaire : 66',
          style: TextStyleHint.small,
        ),
      ]),
    ),
  ],
);
