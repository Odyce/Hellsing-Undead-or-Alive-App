import 'package:hellsing_undead_or_applive/domain/models.dart';

class RaceList {
  List<Race> allRaces = [
    Race(
      id: 0, 
      name: "Humain", 
      description: "Les humains sont l’espèce dominante sur la planète, mais ont longtemps été sans défense face aux Midians. Cependant les agents de la Fondation Hellsing sont majoritairement des humains spécialisés dans la traque et l’exécution des créatures de la nuit. Parmi eux, de rares individus ont pu développer des dons mystiques, propre à l'humanité et ne sont pas à sous-estimer.\n\nEn effet, la force de l'humanité réside dans sa mortalité, et la conscience que les Hommes ont de celle-ci, les poussant à repousser toujours plus loin leurs limites, à aiguiser leurs talents innés et à en acquérir constamment de nouveaux.", 
      availableClasses: ClassList().getClassListByIds(0, 6) + ClassList().getClassListByIds(12, 15)
    ),


    Race(
      id: 1, 
      name: "Semi-Ange", 
      description: "Un Semi-ange est un humain à l'esprit habité par deux âmes. Depuis leurs naissances, ceux-ci sont possédés par une âme angélique leur conférant de puissants pouvoirs mystiques. Cet âme angélique n'est pas indépendante mais sa présence influence fortement le comportement du Semi-Ange, le poussant vers un « Bien » abstrait et absolu parfois au prix de douloureuses contradictions. Ainsi, il est courant que les Semi-anges succombent à des profonds troubles psychologiques ou se tourne vers la religion sans même être conscient de leurs conditions.\n\nLa Fondation Hellsing offre à ces êtres d'exception un moyen de canaliser ce besoin de faire le Bien en mettant leur puissance considérable au service de l'Humanité.", 
      bonuses: [
        "10% au jet au soleil et en terres consacrées.", 
        "Sang toxique pour les Vampires.", 
        "Toucher désagréable pour les Midians (Brûle les Midians sensibles à l'Effet Sacré).",
        "Peut ressentir la présence d'Entités maléfiques majeures ."
      ], 
      maluses: [
        "Impossibilité de mentir directement.",
        "Se sent nauséeux / malade en présence d'actes ou d'entités maléfiques ou sur une terre maudite."
      ], 
      availableClasses: ClassList().getClassListByIds(0, 6) + ClassList().getClassListByIds(16, 18)
    ),


    Race(
      id: 2, 
      name: "Vampire", 
      description: "Ces êtres des ténèbres n'ont d'humain que l'apparence, se nourrissent de sang et craignent le soleil. Ce sont les cibles principales de la Fondation Hellsing, qui visent à les éliminer pour débarrasser l'humanité de ces prédateurs. Toutefois certains de ces damnés continuent de se battre aux cotés des humains, contre leurs semblables.\n\nConsidérés comme des traîtres dans les communautés de Midians, les vampires de la Fondation sont vus comme des armes au service de l'humanité. Ils doivent donc être gardés sous contrôle. Ainsi ils sont nourris avec le minimum de sang possible et ont interdiction de se nourrir sans autorisation ou de transformer qui que ce soit sous peine de passer de chasseur à proie.", 
      bonuses: [
        "Régénération de PV passive et lente (1h rend 1PV).",
        "Force musculaire grandement accrue (+10% au jet si l'action nécessite de la force, +2 dégâts au attaque de corps à corps).",
        "Peut transformer un humain en vampire ou en goule en buvant tout son sang ( soumis à un test de pouvoir vampirique).",
        "Vision Nocturne.",
        "Ne peut être mentalement épuisé, peut effectuer des actions demandant une dépense de PM en puisant dans ses PV, à raison d'1 PM par PV sacrifié."
      ], 
      maluses: [
        "Brûle au soleil (-1 PV par tour, nécessite une exposition directe.)",
        "De jour, impossibilité de récupérer des PE",
        "Diminution du pouvoir vampirique si en manque de sang.",
        "Malus de 10% au jet de jour ou en terre consacrée.",
        "Inconfort à la vue des symboles sacrés et des miroirs."
      ], 
      availableClasses: ClassList().getClassListByIds(0, 6) + ClassList().getClassListByIds(7, 9)
    ),


    Race(
      id: 3, 
      name: "Demi-Vampire", 
      description: "Quand un vampire attaque un humain, celui ci ne meurs pas toujours. Il développe une partie de pouvoir vampirique qui l'attire constamment vers les ténèbres, il devient un Demi-Vampire. Cette malédiction augmente ses capacités physiques, en faisant un chasseur plus puissant que la normale, mais à quel prix ?\n\nLors de sa mort, la transformation est inévitable. Il perdra toute forme d'identité et de personnalité humaine pour renaître sous forme de vampire. Ainsi la plupart des demi-vampire cherchent à briser leur malédiction en tuant le vampire qui les a attaqués dans l'espoir de regagner leur humanité menacé.", 
      bonuses: [
        "Force accrue la nuit (+10% la nuit, +40% si consommation de sang, si l'action met en jeu de la force pure. +1 dégâts aux attaques de corps à corps).",
        "Peut ressentir le pouvoir vampirique chez quelqu'un par contact visuel.",
        "Vision Nocturne."
      ], 
      maluses: [
        "Malus de 5% au jet au soleil ou en terre consacrée.",
        "Attiré par le sang, chaque consommation de sang augmente le pouvoir vampirique jusqu'à la transformation."
      ], 
      availableClasses: ClassList().getClassListByIds(0, 6) + ClassList().getClassListByIds(10, 11)
    ),
  ];

  ////////////////////////////////////
  //                                //
  // Fonction utiles pour les races //
  //                                //
  ////////////////////////////////////

  Race getRaceById(int id) {
    Race res = allRaces.last;

    for (var race in allRaces) {
      if (race.id == id) {
        res = race;
      }
    }

    return res;
  }

  Race getRaceByName(String name) {
    Race res = allRaces.last;

    for (var race in allRaces) {
      if (race.name == name) {
        res = race;
      }
    }

    return res;
  }
}
