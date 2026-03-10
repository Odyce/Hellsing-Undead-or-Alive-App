import 'package:hellsing_undead_or_applive/domain/models.dart';

enum SkillNumberCases {
  first,  // Physique/20 compétences, PE=Physique/10
  second, // Mental/20 compétences, PE=Physique/10
  third,  // Physique/20 compétences, PM = Mental/10
  fourth, // Mental/20 compétences, PM = Mental/10
  fifth,  // Mental/20 compétences, PM = 2x[Mental/10]
  sixth,  // Relationnel/20 compétences, PM = Mental/10
}

class ClassList {
  List<AgentClass> allClasses = [
    AgentClass(
      id: 0,
      name: "Fusiller", 
      quote: "Dieu à créer tout les êtres rampant sur cette Terre, Samuel Colt les as rendues égaux.", 
      classBonus: ["Fin Tireur", "Réflexe", "Vue Perçante"], 
      affinities: [Affinities.firearm], 
      muniSlotNumber: 3,
      freeSkill: [SkillList().getSkillById(0)], 
      skillNumberReminder: "Physique/20 compétences, PE=Physique/10", 
      skillNumberCases: SkillNumberCases.first,
      classType: CostType.pe, 
      allSkills: SkillList().getSkillListByIds(1, 12)
    ),

    AgentClass(
      id: 1, 
      name: "Artificier", 
      quote: "La poudre, c'est la solution universelle. Faut juste en mettre la bonne quantité.", 
      classBonus: ["Lancer", "Sapeur", "Artisanat"], 
      affinities: [Affinities.firearm, Affinities.explosive],
      muniSlotNumber: 2,
      freeSkill: [SkillList().getSkillById(13)], 
      skillNumberReminder: "Mental/20 compétences, PE=Physique/10", 
      skillNumberCases: SkillNumberCases.second,
      classType: CostType.pe, 
      allSkills: SkillList().getSkillListByIds(14, 27)
    ),

    AgentClass(
      id: 2, 
      name: "Bretteur", 
      quote: "La plupart des créatures de cette Terre restent sensibles à une chose : une bonne toise d'acier en travers du corps.", 
      classBonus: ["Escrime", "Garde", "Premier Soin"], 
      affinities: [Affinities.oneHandBlade, Affinities.twoHandBlade],
      muniSlotNumber: 0,
      freeSkill: [SkillList().getSkillById(28)], 
      skillNumberReminder: "Physique/20 compétences, PE=Physique/10", 
      skillNumberCases: SkillNumberCases.first,
      classType: CostType.pe, 
      allSkills: SkillList().getSkillListByIds(29, 46)
    ),

    AgentClass(
      id: 3, 
      name: "Apothicaire", 
      quote: "Les plantes sont des choses étranges et mystérieuses, elles peuvent aussi bien vous sauver la vie que vous mener à la mort. Un thé ?", 
      classBonus: ["Soin", "Herbologie", "Chimie"], 
      affinities: [Affinities.oneHandBlade],
      muniSlotNumber: 1,
      freeSkill: [SkillList().getSkillById(47), SkillList().getSkillById(48)], 
      skillNumberReminder: "Mental/20 compétences, PE=Physique/10", 
      skillNumberCases: SkillNumberCases.second,
      classType: CostType.pe, 
      allSkills: SkillList().getSkillListByIds(49, 61)
    ),

    AgentClass(
      id: 4, 
      name: "Chirurgien", 
      quote: "Si on part chasser des créatures légendaires sans aide médicale, ce n'est plus de la stupidité mais du darwinisme.", 
      classBonus: ["Chirurgie", "Anatomie", "Diagnostique"], 
      affinities: [Affinities.oneHandBlade],
      muniSlotNumber: 0,
      freeSkill: [SkillList().getSkillById(62)], 
      skillNumberReminder: "Mental/20 compétences, PE=Physique/10", 
      skillNumberCases: SkillNumberCases.second,
      classType: CostType.pe, 
      allSkills: SkillList().getSkillListByIds(63, 75)
    ),

    AgentClass(
      id: 5, 
      name: "Pisteur", 
      quote: "Vous savez, c'est bien beau de savoir écharper un vampire, si vous êtes incapable de le dénicher...", 
      classBonus: ["Poursuite", "Sens Affutés", "Traque"], 
      affinities: [Affinities.bow, Affinities.firearm],
      muniSlotNumber: 1,
      freeSkill: [SkillList().getSkillById(76)], 
      skillNumberReminder: "Physique/20 compétences, PE=Physique/10",
      skillNumberCases: SkillNumberCases.first,
      classType: CostType.pe, 
      allSkills: SkillList().getSkillListByIds(77, 89)
    ),

    AgentClass(
      id: 6, 
      name: "Assassin", 
      quote: "Travailler et se battre dans l'ombre et au secret ? Je connais oui...", 
      classBonus: ["Furtivité", "Lancer", "Coup en traître"], 
      affinities: [Affinities.oneHandBlade, Affinities.throwable],
      muniSlotNumber: 0,
      freeSkill: [SkillList().getSkillById(90)], 
      skillNumberReminder: "Physique/20 compétences, PE=Physique/10",
      skillNumberCases: SkillNumberCases.first,
      classType: CostType.pe, 
      allSkills: SkillList().getSkillListByIds(91, 101)
    ),

    AgentClass(
      id: 7, 
      name: "Nosferatu", 
      quote: "Soyons honnête. L'humanité c'est très bien, jusqu'à ce qu'on ait besoin de puissance.", 
      classBonus: ["Magie Noire", "Force Vampirique", "Flair de Prédateur"], 
      affinities: [Affinities.oneHandBlade, Affinities.twoHandBlade],
      muniSlotNumber: 0,
      freeSkill: [SkillList().getSkillById(102), SkillList().getSkillById(103)], 
      skillNumberReminder: "Physique/20 compétences, PM = Mental/10", 
      skillNumberCases: SkillNumberCases.third,
      classType: CostType.pm, 
      allSkills: SkillList().getSkillListByIds(107, 117)
    ),

    AgentClass(
      id: 8, 
      name: "Noctambule", 
      quote: "Vous souvenez vous de la présence que vous sentez sans cesse dans votre dos quand vous êtes seul la nuit ? Vous ne m'auriez pas oublié quand même ?", 
      classBonus: ["Magie Nocturne", "Ombre parmi les ombres", "Espionnage"], 
      affinities: [Affinities.choiceNonExplosive],
      muniSlotNumber: 1,
      freeSkill: [SkillList().getSkillById(102), SkillList().getSkillById(118)], 
      skillNumberReminder: "Physique/20 compétences, PM = Mental/10", 
      skillNumberCases: SkillNumberCases.third,
      classType: CostType.pm, 
      allSkills: SkillList().getSkillListByIds(119, 129)
    ),

    AgentClass(
      id: 9, 
      name: "Strigoï", 
      quote: "On a tous un petit côté bestial...", 
      classBonus: ["Bestialité", "Instinct Animal", "Sens Sauvages"], 
      affinities: [Affinities.choiceNonExplosive],
      muniSlotNumber: 1,
      freeSkill: [SkillList().getSkillById(102), SkillList().getSkillById(130)], 
      skillNumberReminder: "Physique/20 compétences, PM = Mental/10",
      skillNumberCases: SkillNumberCases.third,
      classType: CostType.pm, 
      allSkills: SkillList().getSkillListByIds(131, 142)
    ),

    AgentClass(
      id: 10, 
      name: "Dampyr", 
      quote: "S’il me faut devenir un monstre pour abattre les monstres, alors je leur conseille de se cacher sous leurs lits.", 
      classBonus: ["Sanguimancie", "Sens Vampiriques", "Aura de Prédateur"], 
      affinities: [Affinities.choiceNonExplosive],
      muniSlotNumber: 1,
      freeSkill: [SkillList().getSkillById(143)], 
      skillNumberReminder: "Mental/20 compétences, PM = Mental/10",
      skillNumberCases: SkillNumberCases.fourth,
      classType: CostType.pm, 
      allSkills: SkillList().getSkillListByIds(144, 159)
    ),

    AgentClass(
      id: 11, 
      name: "Lamenuit", 
      quote: "Je ne suis plus un humain, je ne suis pas un monstre. Je suis une arme.", 
      classBonus: ["Agilité", "Puissance Lunaire", "Détection de mensonges"], 
      affinities: [Affinities.throwable, Affinities.oneHandBlade, Affinities.twoHandBlade],
      muniSlotNumber: 0,
      freeSkill: [SkillList().getSkillById(160)], 
      skillNumberReminder: "Mental/20 compétences, PM = Mental/10",
      skillNumberCases: SkillNumberCases.fourth,
      classType: CostType.pm, 
      allSkills: SkillList().getSkillListByIds(161, 178)
    ),

    AgentClass(
      id: 12, 
      name: "Mentaliste", 
      quote: "L'esprit humain peut être considéré comme une horloge fragile et sensible. Moi ? Je suis l'horloger.", 
      classBonus: ["Sensibilité Psychique", "Raisonnement", "Force mentale"], 
      affinities: [Affinities.none],
      muniSlotNumber: 0,
      freeSkill: [SkillList().getSkillById(179)], 
      skillNumberReminder: "Mental/20 compétences, PM = 2x[Mental/10]",
      skillNumberCases: SkillNumberCases.fifth,
      classType: CostType.pm, 
      allSkills: SkillList().getSkillListByIds(180, 196)
    ),

    AgentClass(
      id: 13, 
      name: "Occultiste", 
      quote: "Pour combattre le Mal, il faut le connaître. Et nous sommes justement de vieux amis...", 
      classBonus: ["Savoir Occulte", "Symbolique", "Artefact"], 
      affinities: [Affinities.none],
      muniSlotNumber: 1,
      freeSkill: [SkillList().getSkillById(197)], 
      skillNumberReminder: "Relationnel/20 compétences, PM = Mental/10",
      skillNumberCases: SkillNumberCases.sixth,
      classType: CostType.pm, 
      allSkills: SkillList().getSkillListByIds(198, 210)
    ),

    AgentClass(
      id: 14, 
      name: "Inquisiteur", 
      quote: "Les créatures des abysses brûleront toutes en enfer, et j’espère pouvoir tenir l'allumette.", 
      classBonus: ["Foi", "Inquisition", "Théologie"], 
      affinities: [Affinities.firearm, Affinities.oneHandBlade],
      muniSlotNumber: 1,
      freeSkill: [SkillList().getSkillById(211)], 
      skillNumberReminder: "Physique/20 compétences, PM = Mental/10",
      skillNumberCases: SkillNumberCases.third,
      classType: CostType.pm, 
      allSkills: SkillList().getSkillListByIds(212, 221)
    ),

    AgentClass(
      id: 15, 
      name: "Homme de Foi", 
      quote: "Le Seigneur dans son infinie bonté a fait les vampires faciles à brûler.", 
      classBonus: ["Foi", "Compassion", "Théologie"], 
      affinities: [Affinities.oneHandBlade], 
      muniSlotNumber: 0,
      freeSkill: [SkillList().getSkillById(222)], 
      skillNumberReminder: "Relationnel/20 compétences, PM = Mental/10",
      skillNumberCases: SkillNumberCases.sixth,
      classType: CostType.pm, 
      allSkills: SkillList().getSkillListByIds(223, 237)
    ),

    AgentClass(
      id: 16, 
      name: "Nephilim", 
      quote: "Tout ce que je vois je peux l'abattre. Et j'ai de très bons yeux.", 
      classBonus: ["Temporalité Différée", "Tir", "Perception Globale"], 
      affinities: [Affinities.firearm, Affinities.bow],
      muniSlotNumber: 4,
      freeSkill: [SkillList().getSkillById(238)], 
      skillNumberReminder: "Physique/20 compétences, PM = Mental/10",
      skillNumberCases: SkillNumberCases.third,
      classType: CostType.pm, 
      allSkills: SkillList().getSkillListByIds(239, 252)
    ),

    AgentClass(
      id: 17, 
      name: "Seraphin", 
      quote: "Démon, vampire, lycanthropes, goules... Tant de nom pour un seul adjectif : coupable.", 
      classBonus: ["Escrime", "Présence", ""], 
      affinities: [Affinities.twoHandBlade],
      muniSlotNumber: 0,
      freeSkill: [SkillList().getSkillById(253)], 
      skillNumberReminder: "Physique/20 compétences, PM = Mental/10",
      skillNumberCases: SkillNumberCases.third,
      classType: CostType.pm, 
      allSkills: SkillList().getSkillListByIds(254, 267)
    ),

    AgentClass(
      id: 18, 
      name: "Cherubin", 
      quote: "Le monde ne serait pas si dangereux si le bien et le mal était clairement défini.", 
      classBonus: ["Soin", "Empathie", "Intuition Médicale"], 
      affinities: [Affinities.oneHandBlade],
      muniSlotNumber: 1,
      freeSkill: [SkillList().getSkillById(268)], 
      skillNumberReminder: "Mental/20 compétences, PM = Mental/10",
      skillNumberCases: SkillNumberCases.fourth,
      classType: CostType.pm, 
      allSkills: SkillList().getSkillListByIds(269, 281)
    ),
  ];

  //////////////////////////////////////
  //                                  //
  // Fonction utiles pour les classes //
  //                                  //
  //////////////////////////////////////

  AgentClass getClassById(int id) {
    AgentClass res = allClasses.last;

    for (var clas in allClasses) {
      if (clas.id == id) {
        res = clas;
      }
    }

    return res;
  }

  List<AgentClass> getClassListByIds(int first, int last) {
    List<AgentClass> res = [];

    for (var clas in allClasses) {
      if (clas.id >= first && clas.id <= last) {
        res.add(clas);
      }
    }

    return res;
  }

  AgentClass getClassByName(String name) {
    AgentClass res = allClasses.last;

    for (var clas in allClasses) {
      if (clas.name == name) {
        res = clas;
      }
    }

    return res;
  }

  int easyCalculus(int attr, int div) {
    if (div == 0) {
      throw ArgumentError("Nope, pas de destruction de l'univers aujourd'hui.");
    }

    return (attr / div).ceil();
  }
}
