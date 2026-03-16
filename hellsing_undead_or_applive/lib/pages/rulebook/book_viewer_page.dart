import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';

import 'package:hellsing_undead_or_applive/pages/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class BookViewerPage extends StatefulWidget {
  const BookViewerPage({super.key});

  @override
  State<BookViewerPage> createState() => _BookViewerPageState();
}

class _BookViewerPageState extends State<BookViewerPage> {
  final _controller = GlobalKey<PageFlipWidgetState>();

  Widget _buildPage(Widget child) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 194, 116, 47), // fond bois sombre
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                width: 600,
                height: 800,
                child: PageFlipWidget(
                  key: _controller,
                  backgroundColor: Colors.transparent,
                  children: [
                    _buildPage(
                      BookPageTemplate(
                        title: "Undead or alive\nHellsing fondation",
                        content: " ",
                      ),
                    ),
                    _buildPage(
                      BookPageTemplate(
                        title: "Londres, 1873",
                        content: "Les monstres existent. Cette peur universelle de l'obscurité et des créatures qui s'y cachent est parfaitement justifiée. Vampires, loups-garous, spectres et croque-mitaines sont autant de menaces pesant sur l'humanité quand le soleil se couche. Pendant des siècles, ces créatures, les Midians, sont restés des légendes, intangibles, irréels, telle une calamité invisible et invincible. Mais un jour un homme s'est dressé contre la nuit. Alliant connaissances occultes et technologie moderne, et avec l'aide de valeureux camarades, il traqua et élimina l'une des plus grandes menaces pesant sur l'humanité : le Comte Dracula. Cet homme, Abraham Van Hellsing, prouva alors que l'humanité n'était pas sans défense. Une riposte était possible ! Mais un seul homme ne pouvait protéger l'humanité à lui seul.\n\nAinsi est né la Fondation Hellsing, une organisation rassemblant dans un même effort des chasseurs venus de tout l'empire britannique. Rendant compte directement à la couronne et considéré comme service secret, elle a pour mission de protéger l'humanité des créatures de la nuit, phénomènes paranormaux et autres menaces surnaturelles. Pour se faire elle apporte son soutien logistique et coordonne un grand nombre d'agents indépendants ou non dans la lutte contre les menaces Midianes. Depuis plus de 30 ans, elle mène une guerre secrète contre les Midians, perpétuant l'héritage de Van Hellsing pour qu'un jour, nos enfants n'ai plus peur de l'obscurité.\n\nVous êtes un agent de la Fondation Hellsing, un chasseur ou un détective, un docteur ou même un gentlemen. Pour vous, c'est un travail, un hobby, une vocation, une mission divine. Peu importe vos raisons, qui vous êtes, d'où vous venez, vous avez rejoint la Fondation Hellsing dans son monde occulte et secret. Menez l'enquête, éliminez vos cibles, résolvez les crimes de la Nuit. Si par hasard vous en revenez vivant, et bien de nouvelles affaires vous attendent toujours...\n\n\nCombien de temps tiendrez-vous ?",
                      ),
                    ),
                    _buildPage(
                      BookPageTemplate(
                        title: "Création personnage",
                        content: "Un personnage est avant tout défini par son histoire et sa personnalité, qui vont conditionner le Roleplay de celui ci. Quelques lignes de biographie et une personnalité définie donneront de la profondeur et du sens à votre personnage.\n\nUn personnage possède 3 Caractéristiques principales. Le Physique représente sa capacité à utiliser son corps, le Relationnel représente son aisance dans les rapports sociaux, le Mental représente sa capacité à réfléchir et à utiliser des pouvoirs mystiques.\n\nCes trois Caractéristique sont notés sur 100. Vous disposez à la création de 180 points à répartir entre Physique, Relationnel et Mental. Ces Caractéristiques ne peuvent pas dépasser 80 ni être inférieure à 10. Elles doivent également être un multiple de 5.\n\nLes PV sont déterminé par la plus haute Caractéristique divisé par 10, auquel on rajoute 2 points si il s'agit du Physique. Les Vampires sont une exception à cette règle et commence avec 13 PV.\n\nLes PE, les PC et les PM sont déterminé respectivement par le Physique, le Relationnel et par le Mental, divisé par 10.\n\nLes Caractéristiques Raciales, les Affinités et les Bonus de Classe dépendent de la Race et de la Classe du Personnage.\n\nLes Bonus de Classe permettent d'obtenir des modificateur contextuels (voir Règles de Résolutions des Actions) en cas de réussite. Vous disposez à la création de 9 points à répartir parmi les Bonus de Classe.\n\nVotre personnage possède des Compétences dont le nombre dépend de ses Caractéristiques selon une formule propre à chaque Classe. Choisissez vos compétences avec sagesse, et utilisez les à propos. Si le résultat d'un calcul ne tombe pas sur un nombre entier, on arrondira au supérieur.\n\n",
                      ),
                    ),
                    _buildPage(
                      BookPageTemplate(
                        title: "Choisir sa race : Vampire",
                        content: "Ces êtres des ténèbres n'ont d'humain que l'apparence, se nourrissent de sang et craignent le soleil. Ce sont les cibles principales de la Fondation Hellsing, qui visent à les éliminer pour débarrasser l'humanité de ces prédateurs. Toutefois certains de ces damnés continuent de se battre aux cotés des humains, contre leurs semblables.\n\nConsidérés comme des traîtres dans les communautés de Midians, les vampires de la Fondation sont vus comme des armes au service de l'humanité. Ils doivent donc être gardés sous contrôle. Ainsi ils sont nourris avec le minimum de sang possible et ont interdiction de se nourrir sans autorisation ou de transformer qui que ce soit sous peine de passer de chasseur à proie.\n\nBONUS\n\n- Régénération de PV passive et lente (1h rend 1PV)\n- Force musculaire grandement accrue (+10% au jet si l'action nécessite de la force, +2 dégâts au attaque de corps à corps).\n- Peut transformer un humain en vampire ou en goule en buvant tout son sang ( soumis à un test de pouvoir vampirique).\n- Vision Nocturne.\n- Ne peut être mentalement épuisé, peut effectuer des actions demandant une dépense de PM en puisant dans ses PV, à raison d'1 PM par PV sacrifié.",
                      ),
                    ),
                    _buildPage(
                      BookPageTemplate(
                        title: "Choisir sa race : Demi-vampire",
                        content: "Quand un vampire attaque un humain, celui ci ne meurs pas toujours. Il développe une partie de pouvoir vampirique qui l'attire constamment vers les ténèbres, il devient un Demi-Vampire. Cette malédiction augmente ses capacités physiques, en faisant un chasseur plus puissant que la normale, mais à quel prix ?\n\nLors de sa mort, la transformation est inévitable. Il perdra toute forme d'identité et de personnalité humaine pour renaître sous forme de vampire. Ainsi la plupart des demi-vampire cherchent à briser leur malédiction en tuant le vampire qui les a attaqués dans l'espoir de regagner leur humanité menacé.\n\nBONUS\n- Force accrue la nuit (+10% la nuit, +40% si consommation de sang, si l'action met en jeu de la force pure. +1 dégâts aux attaques de corps à corps).\n- Peut ressentir le pouvoir vampirique chez quelqu'un par contact visuel.\n- Vision Nocturne.",
                      ),
                    ),
                    _buildPage(
                      BookPageTemplate(
                        title: "Choisir sa race : Humain",
                        content: "Les humains sont l'espèce dominante sur la planète, mais ont longtemps été sans défense face aux Midians. Cependant les agents de la Fondation Hellsing sont majoritairement des humains spécialisés dans la traque et l'exécution des créatures de la nuit. Parmi eux, de rares individus ont pu développer des dons mystiques, propre à l'humanité et ne sont pas à sous-estimer.\n\nEn effet, la force de l'humanité réside dans sa mortalité, et la conscience que les Hommes ont de celle-ci, les poussant à repousser toujours plus loin leurs limites, à aiguiser leurs talents innés et à en acquérir constamment de nouveaux.",
                      ),
                    ),
                    _buildPage(
                      BookPageTemplate(
                        title: "Choisir sa race : Semi-Anges",
                        content: "Un Semi-ange est un humain à l'esprit habité par deux âmes. Depuis leurs naissances, ceux-ci sont possédés par une âme angélique leur conférant de puissants pouvoirs mystiques. Cet âme angélique n'est pas indépendante mais sa présence influence fortement le comportement du Semi-Ange, le poussant vers un « Bien » abstrait et absolu parfois au prix de douloureuses contradictions. Ainsi, il est courant que les Semi-anges succombent à des profonds troubles psychologiques ou se tourne vers la religion sans même être conscient de leurs conditions.\n\nLa Fondation Hellsing offre à ces êtres d'exception un moyen de canaliser ce besoin de faire le Bien en mettant leur puissance considérable au service de l'Humanité.\n\nBONUS\n10% au jet au soleil et en terres consacrées.\n- Sang toxique pour les Vampires.\n- toucher désagréable pour les Midians (Brûle les Midians sensibles à l'Effet Sacré).\n- Peut ressentir la présence d'Entités maléfiques majeures .",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Align(
              alignment: Alignment.bottomLeft,
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, Routes.home),
                child: const Text("Retour"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
