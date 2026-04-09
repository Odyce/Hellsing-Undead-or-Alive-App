import '../book_index.dart';
import '../book_page.dart';
import '../rich_content.dart';

const sectionCover = RawSection(
  id: 'cover',
  title: 'Couverture',
  pages: [
    CoverPage(
      id: 'couverture',
      sectionId: 'cover',
      title: 'Undead or Alive — Hellsing Foundation V5.3',
    ),
  ],
);

const sectionIntro = RawSection(
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
          'Cette peur universelle de l\'obscurité et des créatures qui s\'y '
          'cachent est parfaitement justifiée. Vampires, loups-garous, spectres '
          'et croque-mitaines sont autant de menaces pesant sur l\'humanité '
          'quand le soleil se couche. Pendant des siècles, ces créatures, les '
          'Midians, sont restés des légendes, intangibles, irréels, telle une '
          'calamité invisible et invincible.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Mais un jour un homme s\'est dressé contre la nuit. Alliant '
          'connaissances occultes et technologie moderne, et avec l\'aide de '
          'valeureux camarades, il traqua et élimina l\'une des plus grandes '
          'menaces pesant sur l\'humanité : le Comte Dracula. Cet homme, '
          'Abraham Van Hellsing, prouva alors que l\'humanité n\'était pas '
          'sans défense. Une riposte était possible ! Mais un seul homme ne '
          'pouvait protéger l\'humanité à lui seul.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Ainsi est née la Fondation Hellsing, une organisation rassemblant '
          'dans un même effort des chasseurs venus de tout l\'empire britannique. '
          'Rendant compte directement à la couronne et considéré comme service '
          'secret, elle a pour mission de protéger l\'humanité des créatures de '
          'la nuit, phénomènes paranormaux et autres menaces surnaturelles. '
          'Depuis plus de 30 ans, elle mène une guerre secrète contre les '
          'Midians, perpétuant l\'héritage de Van Hellsing pour qu\'un jour, '
          'nos enfants n\'ai plus peur de l\'obscurité.',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Vous êtes un agent de la Fondation Hellsing, un chasseur ou un '
          'détective, un docteur ou même un gentlemen. Pour vous, c\'est un '
          'travail, un hobby, une vocation, une mission divine. Peu importe '
          'vos raisons, qui vous êtes, d\'où vous venez, vous avez rejoint '
          'la Fondation Hellsing dans son monde occulte et secret. Menez '
          'l\'enquête, éliminez vos cibles, résolvez les crimes de la Nuit. '
          'Si par hasard vous en revenez vivant, et bien de nouvelles affaires '
          'vous attendent toujours…',
        ),
        ParagraphBreakNode(),
        TextNode(
          'Combien de temps tiendrez-vous ?',
          style: TextStyleHint.boldItalic,
        ),
      ]),
    ),
  ],
);
