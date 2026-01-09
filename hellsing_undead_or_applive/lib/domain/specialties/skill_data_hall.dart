import 'package:hellsing_undead_or_applive/domain/models.dart';

class SkillList {
  List<Skill> allSkills =  [
    
    //
    // Compétences de Fusiller
    //
    
    Skill(
      id: 0,
      name: "Double Tir", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Si l'armement le permet, tire avec deux armes sur la même cible, -10% au jet à chaque tir."
    ),
    Skill(
      id: 1,
      name: "Tir de Suppression", 
      cost: 1,
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Force la cible à se mettre derrière une couverture. N'inflige pas de dégâts. +20% de bonus par tir successifs."
    ),
    Skill(
      id: 2,
      name: "Tir de Sommation", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Gratuit hors combat. Ajoute un Mod 15% a toutes tentatives de menace."
    ),
    Skill(
      id: 3,
      name: "Tir Réflexe", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Mod négatif 5%, permet un tir lors de la défense."
    ),
    Skill(
      id: 4, 
      name: "Tir Rapide", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Mod négatif 5%, peut agir en premier avec une action de tir."
    ),
    Skill(
      id: 5,
      name: "Tir Chirurgical", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Tire dans une zone précise de la cible sans subir le malus de 20%."
    ),
    Skill(
      id: 6,
      name: "Recharge Rapide", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Ignore le temps de rechargement de l'arme."
    ),
    Skill(
      id: 7, 
      name: "Tir au Jugé", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Tire sans perdre la protection de la couverture."
    ),
    Skill(
      id: 8, 
      name: "Tir Assuré", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "1 Tour d' attente, +30% au jet, Mod 15%. inefficace au delà de la portée pratique de l'arme."
    ),
    Skill(
      id: 9, 
      name: "Tir d'interruption", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: true, 
      description: "Peut agir durant le tour ennemi avec une action de tir."
    ),
    Skill(
      id: 10, 
      name: "Ricochet", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Tire en ricochet avec un Mod 10%."
    ),
    Skill(
      id: 11, 
      name: "Rafales", 
      cost: 4, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Enchaîne les tir sur une cible jusqu'à ce que l'un rate ou que le chargeur soit épuisé."
    ),
    Skill(
      id: 12, 
      name: "Pluie de Balles", 
      cost: 5, 
      costType: CostType.pe, 
      multiCost: false,
      limited: true, 
      description: "Tire sur un nombre illimité de cibles, jusqu'à épuisement des munitions chargées. Peut être interrompue."
    ),


    //
    // Compétences d'Artificier
    //
    
    Skill(
      id: 13, 
      name: "Déminage", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "En combat, désamorce un explosif."
    ),
    Skill(
      id: 14, 
      name: "Jonglage Explosif", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "1 PE par bombe, lance un nombre illimité de bombe dans la même action."
    ),
    Skill(
      id: 15, 
      name: "Plan de Démolition", 
      cost: 0,
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Permet de planifier la destruction d'une structure avec le minimum d'explosifs."
    ),
    Skill(
      id: 16, 
      name: "Grenade à Main", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "D6 de dégâts, Mod10% au jet de Lancer."
    ),
    Skill(
      id: 17, 
      name: "Bâton de Dynamite", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "D8 de dégâts, Peut être lancé comme posé."
    ),
    Skill(
      id: 18, 
      name: "Cocktail Molotov", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "D4 de dégâts, inflige l'Effet Incendiaire autour de l'impact."
    ),
    Skill(
      id: 19, 
      name: "Bombe Tuyau", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "D10 de dégâts, doit être posé et déclenché via un détonateur."
    ),
    Skill(
      id: 20, 
      name: "Mine", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "D12 de dégâts, se déclenche via un piège."
    ),
    Skill(
      id: 21, 
      name: "Charge de Démolition", 
      cost: 6, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "2D20, Dégâts doublés au structures, doit être posée et déclenchée via un détonateur. Prend la place de 3 bombes dans l'inventaire."
    ),
    Skill(
      id: 22, 
      name: "Bombe à Clous", 
      cost: 4, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "3D4 de dégâts, peut être lancée ou posée au choix."
    ),
    Skill(
      id: 23, 
      name: "Bombe Incendiaire", 
      cost: 5, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "2D10 de dégâts, Effet Incendiaire, doit être posé et déclenchée, prend la place de 2 Bombes dans l'inventaire."
    ),
    Skill(
      id: 24, 
      name: "Flasque de Nitroglycérine", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "D8 de dégâts, explose à l'impact. Peut exploser en cas de choc violent."
    ),
    Skill(
      id: 25, 
      name: "Bombe Fumigène", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Crée un épais nuage de fumée pouvant servir de couverture."
    ),
    Skill(
      id: 26, 
      name: "Bombe Aveuglante", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Crée un puissant flash lumineux."
    ),
    Skill(
      id: 27, 
      name: "Bombe Sonore", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Crée une puissante détonation qui désoriente."
    ),


    //
    // Compétences de Bretteur
    //

    Skill(
      id: 28, 
      name: "Enchaînement", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Si une première attaque touche, lance une seconde attaque sur la même cible. Peut être répété avec une Arme Blanche à une main."
    ),

    // UNE MAIN SEULEMENT
    Skill(
      id: 29, 
      name: "Parade Fluide", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Mod négatif 5%, lance une attaque d'opportunité après une parade réussie"
    ),
    Skill(
      id: 30, 
      name: "Passe d'armes", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Vise l'arme, désarme l'adversaire en cas de réussite."
    ),
    Skill(
      id: 31, 
      name: "Pugilat", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Attaque d'une main libre ou désarmé à D4 contondants."
    ),
    Skill(
      id: 32, 
      name: "Riposte", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Suite à une attaque parée ou subie, lance une attaque d'opportunité avec -2 dégâts."
    ),
    Skill(
      id: 33, 
      name: "Estoc Précis", 
      cost: 2,
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Vise une partie précise avec Mod 10% sans subir le malus de précision."
    ),
    Skill(
      id: 34, 
      name: "Fente", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: true, 
      description: "Attaque en premier un ennemi déjà à portée, dégât +2."
    ),
    Skill(
      id: 35, 
      name: "Attaque Ambidextre", 
      cost: 3,
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Si l'armement le permet, attaque avec deux armes dans le même tour."
    ),
    Skill(
      id: 36, 
      name: "Feinte", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: true, 
      description: "Ignore l'action défensive de la cible."
    ),
    Skill(
      id: 37, 
      name: "Coupe-Jarret", 
      cost: 4, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Attaque en visant les artères de la cible, inflige l'Effet Saignement Aggravée."
    ),
    Skill(
      id: 38, 
      name: "Danse de Lame / d'Estoc", 
      cost: 6, 
      costType: CostType.pe, 
      multiCost: false,
      limited: true, 
      description: "-20% à la parade ennemie, lance 5 attaques."
    ),

    // DEUX MAINS SEULEMENT
    Skill(
      id: 39, 
      name: "Garde Solide", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "1PE par tour, Mod 20% parade"
    ),
    Skill(
      id: 40, 
      name: "Étourdissement", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Les dégâts de l'attaque sont infligés aux PE de la cible."
    ),
    Skill(
      id: 41, 
      name: "Brise-garde", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Si la cible pare, l'attaque est quand même une réussite, mais dégâts -3."
    ),
    Skill(
      id: 42, 
      name: "Grande Taille", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: true, 
      description: "Mod négatif 10% , lance 2 fois les dés de dégâts, peut attaquer plusieurs cibles."
    ),
    Skill(
      id: 43, 
      name: "Charge", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Attaque en premier dans le tour sur une cible à portée de déplacement."
    ),
    Skill(
      id: 44, 
      name: "Feinte Lourde", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Malus à la défense adverse de 40%"
    ),
    Skill(
      id: 45, 
      name: "Démembrement", 
      cost: 4, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Cible un membre, si les dégâts sont supérieurs à 6, le sectionne."
    ),
    Skill(
      id: 46, 
      name: "Contre Mortel", 
      cost: 5, 
      costType: CostType.pe, 
      multiCost: false,
      limited: true,
      description: "Sur une parade réussie, lance 3 fois les dégâts."
    ),


    //
    // Compétences d'Apothicaire
    //

    Skill(
      id: 47, 
      name: "Identification", 
      cost: 0, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Au calme, permet d'analyser une substance et d'en déterminer la nature."
    ),
    Skill(
      id: 48, 
      name: "Mithridatisation", 
      cost: 0, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Immunité à la plupart des poisons."
    ),
    Skill(
      id: 49, 
      name: "Poudre urticante", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Inflige un malus de -40% à la cible pour le prochain tour."
    ),
    Skill(
      id: 50, 
      name: "Cataplasme Curatif", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Rend D4+2 PV, demande 2 tours d'immobilité."
    ),
    Skill(
      id: 51, 
      name: "Antidote", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Nécessite un échantillon du poison, soigne de ce poison."
    ),
    Skill(
      id: 52, 
      name: "Graine de rage", 
      cost: 2,
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "L'utilisateur perd 1PV/tour, est pris d'une rage incontrôlable et à sa force grandement accrue (+2 dégâts aux attaques de corps à corps) pendant D4 tours."
    ),
    Skill(
      id: 53, 
      name: "Huile Inflammable", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Donne l'effet Incendiaire à une Arme Blanche pendant D6 tours."
    ),
    Skill(
      id: 54, 
      name: "Sang noir", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Empoisonne violemment le vampire s’il boit le sang de l'utilisateur, protège du vampirisme."
    ),
    Skill(
      id: 55, 
      name: "Poudre Somnifère", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "4/6 chance d'endormir la cible, inflige un malus de 20% pendant D4 tours. Effets pouvant varier selon la taille de la cible."
    ),
    Skill(
      id: 56, 
      name: "Tue-Loup", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Donne l'effet Argent à une Arme Blanche pendant D6 tours."
    ),
    Skill(
      id: 57, 
      name: "Décoction d'Angélique", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Donne l'effet Béni à une Arme Blanche pendant D6 tours."
    ),
    Skill(
      id: 58, 
      name: "Drogue d’Hypersensibilité", 
      cost: 4, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "-2PV à l’utilisateur +30% à tout test de perception, Mod 10% à la visée, dure 2D4 tours."
    ),
    Skill(
      id: 59, 
      name: "Cercle de Protection Botanique", 
      cost: 4, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Empêche les Midians de pénétrer dans ce cercle, place pour 3 personnes maximum."
    ),
    Skill(
      id: 60, 
      name: "Laudanum", 
      cost: 4, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Supprime la douleur et rend 1PV/tour pendant D4 tours."
    ),
    Skill(
      id: 61, 
      name: "Chloroforme", 
      cost: 5, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Endors la cible, doit être au contact."
    ),


    //
    // Compétences de Chirurgien
    //

    Skill(
      id: 62,
      name: "Autopsie",
      cost: 0,
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Au calme, permet de déterminer les circonstances de la mort d'une créature."
    ),
    Skill(
      id: 63, 
      name: "Transfusion", 
      cost: 0, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Prend plusieurs tour, permet de protéger du vampirisme et autres effets liés au sang. Inflige un désavantage de 2PE au donneur."
    ),
    Skill(
      id: 64, 
      name: "Dissection", 
      cost: 0, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Au calme, permet à partir de l'anatomie d'une créature de déterminer sa nature et ses capacités."
    ),
    Skill(
      id: 65, 
      name: "Analyse d'échantillon", 
      cost: 0, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Au calme, détermine l'origine d'échantillons biologiques."
    ),
    Skill(
      id: 66, 
      name: "Sutures", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Rend 1PV par tour durant D6 tours."
    ),
    Skill(
      id: 67, 
      name: "Extraction de Balle", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Sur une blessure par balle, réduit les dégâts à 1."
    ),
    Skill(
      id: 68, 
      name: "Bandages Hémostatiques", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "+3PV temporaire à la cible, arrête les saignements."
    ),
    Skill(
      id: 69, 
      name: "Analyse anatomique", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Déduit la position d'organes vitaux de la cible."
    ),
    Skill(
      id: 70, 
      name: "Stimulation Stéroïdienne", 
      cost: 2,
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Force grandement accrue : +2 dégâts au corps à corps pendant 2 tours."
    ),
    Skill(
      id: 71, 
      name: "Réduction de Fracture", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Rend un membre fracturé douloureux mais utilisable."
    ),
    Skill(
      id: 72, 
      name: "Opération Chirurgicale", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: true,
      description: "Sur une blessure, réduit les dégâts à 1, prend 1 tour par tranche de 2PV."
    ),
    Skill(
      id: 73, 
      name: "Dislocation", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Au contact, disloque un membre de la cible si elle est humanoïde."
    ),
    Skill(
      id: 74, 
      name: "Stabilisation", 
      cost: 4, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Permet de stabiliser un patient et d’empêcher la mort."
    ),
    Skill(
      id: 75, 
      name: "Chirurgie de la dernière chance", 
      cost: 6, 
      costType: CostType.pe, 
      multiCost: false,
      limited: true,
      description: "Prend D6 tour, permet de sauver un personnage au delà de l'agonie en le ramenant à 2PV."
    ),


    //
    // Compétences de Pisteur
    //

    Skill(
      id: 76, 
      name: "Cible Favorite", 
      cost: 0, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Spécifique à une espèce, quand la nature de la cible est confirmée, tout jet de recherche ou de combat contre cette créature reçoit un Mod 10%."
    ),
    Skill(
      id: 77, 
      name: "Art du déplacement", 
      cost: 0, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Permet d'ignorer les malus de déplacements d'un environnement."
    ),
    Skill(
      id: 78, 
      name: "Maître-Chien", 
      cost: 0, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Permet d'avoir un chien dressé pour suivre des pistes et obéir des ordres simples. D4 d'attaque."
    ),
    Skill(
      id: 79, 
      name: "Piste", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Permet de suivre une piste indiscernable normalement."
    ),
    Skill(
      id: 80, 
      name: "Intuition", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Devine la prochaine action de la cible."
    ),
    Skill(
      id: 81, 
      name: "Investigation totale", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Repère rapidement tous les indices d'un lieu."
    ),
    Skill(
      id: 82, 
      name: "Esprit de la Bête", 
      cost: 4, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Si la cible est identifié et connue, permet de se mettre à la place de la cible et reconstitue son parcours ou ses actions."
    ),
    Skill(
      id: 83, 
      name: "Dissimulation", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "1PE par tour, indétectable sauf critique mais immobile."
    ),
    Skill(
      id: 84, 
      name: "Position de tir", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "1PE par tour passé dans cette position, Mod10% au jet de tir."
    ),
    Skill(
      id: 85, 
      name: "Embuscade", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Octroie un Mod 15% à la prochaine action si non repéré."
    ),
    Skill(
      id: 86, 
      name: "Poursuite", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Permet d'interrompre la fuite d'une cible en agissant durant son tour."
    ),
    Skill(
      id: 87, 
      name: "Tension Réflexe", 
      cost: 2,
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Donne une esquive à Mod 10% à toute attaque."
    ),
    Skill(
      id: 88, 
      name: "Prévision des trajectoires d'esquive", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Touche même si la cible tente d'esquiver."
    ),
    Skill(
      id: 89, 
      name: "Instinct de Chasseur", 
      cost: 5, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Pousse les sens au maximum et repère toutes les entités physiques présentes pendant D8 tour."
    ),


    //
    // Compétences d'Assassin
    //

    Skill(
      id: 90, 
      name: "Coup en traître", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: true,
      description: "Si non repéré, lance 2 fois les dégâts."
    ),
    Skill(
      id: 91, 
      name: "Effacement", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Mod 10% à l'esquive."
    ),
    Skill(
      id: 92, 
      name: "Jongleur de couteaux", 
      cost: 1, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "1 PE par lancer, nombre de lancer illimités dans cette action."
    ),
    Skill(
      id: 93, 
      name: "Attaque Ambidextre", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Attaque avec deux armes dans le même tour."
    ),
    Skill(
      id: 94, 
      name: "Disparition", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Si l'attention de la cible est ailleurs, permet de disparaître à ses yeux."
    ),
    Skill(
      id: 95, 
      name: "Attaque Précise", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Permet d'attaquer une zone précise de la cible en ignorant les malus."
    ),
    Skill(
      id: 96, 
      name: "Pas de l'ombre", 
      cost: 2, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Utilise les ombres pour se déplacer sans être vu, -60% au jet de perception adverse."
    ),
    Skill(
      id: 97, 
      name: "Camouflage", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "3PE par tour, déplacement indétectable sauf critique adverse."
    ),
    Skill(
      id: 98, 
      name: "Coup Vicieux", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false,
      description: "Attaque en visant les artères de la cible, inflige l'Effet Saignement Aggravée."
    ),
    Skill(
      id: 99, 
      name: "Coup critique", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: true,
      description: "Lors d'une attaque, lance un dé de dégâts supplémentaire, si valeur max, relancez ce dé pour des dégâts supplémentaires jusqu'à ne pas tomber sur la valeur max."
    ),
    Skill(
      id: 100, 
      name: "Assassinat", 
      cost: 3, 
      costType: CostType.pe, 
      multiCost: false,
      limited: true, 
      description: "Lance 4 fois les dégâts, si attaque dans le dos non repéré"
    ),
    Skill(
      id: 101, 
      name: "Épinglage", 
      cost: 4, 
      costType: CostType.pe, 
      multiCost: false,
      limited: false, 
      description: "Utilise 5 armes de lancer pour épingler une cible contre une surface, le joueur choisit d'infliger ou pas des dégâts."
    ),



    Skill(
      id: 102,
      name: "Régénération Vampirique", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Sur une réussite au test de pouvoir vampirique, rend 2PV. Chaque palier de 100% atteint garantit 1 PV de soin supplémentaire, même en cas d’échec."
    ),


    //
    // Compétences de Nosferatu
    //

    Skill(
      id: 103, 
      name: "Armurerie Mondiale", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: true,
      costs: [0, 2, 4, 6],
      descriptions: [
        "Crée une Arme Blanche à une main, limitée à D6.",
        "Crée une Arme Blanche à deux main, limitée à D8.",
        "Crée une Arme Blanche à deux main, limitée à D10.",
        "Crée une Lame Vampirique de dégâts D12."
        ],
      limited: false,
      description: "Crée une Arme Blanche à une main, limitée à D6."
    ),
    Skill(
      id: 107, 
      name: "Traque de Sang", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Après avoir goûté au sang d'un être, peut suivre sa trace et sentir sa présence."
    ),
    Skill(
      id: 108, 
      name: "Construction Vampirique", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Crée un objet simple, coût dépendant de la taille."
    ),
    Skill(
      id: 109, 
      name: "Perception des Liens de Sang", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "En cas de contact physique, peut ressentir les liens de sang liant des individus."
    ),
    Skill(
      id: 110, 
      name: "Force Démoniaque", 
      cost: 1, 
      costType: CostType.pm,
      secondCost: 2,
      secondCostType: CostType.pv,
      multiCost: false,
      limited: true, 
      description: "Lance 3 fois les dégâts sur la prochaine action d'attaque au corps à corps."
    ),
    Skill(
      id: 111, 
      name: "Tranchant Obscur", 
      cost: 0, 
      costType: CostType.pm,
      multiCost: false,
      limited: false, 
      description: "X PM, la cible subit X dégâts sous la forme d'une coupure."
    ),
    Skill(
      id: 112, 
      name: "Aura de Prédateur", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Impressionne les vivants, +30% au jet de menace, peut induire une panique."
    ),
    Skill(
      id: 113, 
      name: "Possession", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Prend le contrôle mental d'un PNJ, contact visuel nécessaire, malus possible suivant le contexte."
    ),
    Skill(
      id: 114, 
      name: "Regard de Prédateur", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Saisit de peur la cible pouvant mener jusqu'à la tétanie."
    ),
    Skill(
      id: 115, 
      name: "Soin Vampirique", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Se rend D6 PV."
    ),
    Skill(
      id: 116, 
      name: "Éclair Vampirique", 
      cost: 4, 
      costType: CostType.pm,
      secondCost: 1,
      secondCostType: CostType.pv,
      multiCost: false,
      limited: false, 
      description: "Lance un éclair imparable, 2D4 de dégâts."
    ),
    Skill(
      id: 117, 
      name: "Rituel de sang", 
      cost: 6, 
      costType: CostType.pm,
      secondCost: 6,
      secondCostType: CostType.pv,
      multiCost: false,
      limited: true, 
      description: "Trace un cercle de sang sur le sol, Mod 30% à l'intérieur de ce cercle, coût en PM/2, min 1PM."
    ),


    //
    // Compétence de Noctambule
    //

    Skill(
      id: 118, 
      name: "Cape d'Ombre", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "1PM par tour actif, devient invisible dans les espaces sombres, seuls les yeux sont visibles."
    ),
    Skill(
      id: 119, 
      name: "Brume", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Conjure un nuage de brume autour de soi, peut recouvrir une grande zone avec du temps."
    ),
    Skill(
      id: 120, 
      name: "Voix Ténébreuses", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Fait entendre sa voix depuis une ombre. Malus si l'ombre n'est pas visible par le lanceur."
    ),
    Skill(
      id: 121, 
      name: "Écran Noir", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Plonge la zone dans l'obscurité quasi totale sauf ceux au contact du lanceur."
    ),
    Skill(
      id: 122, 
      name: "Télépathie", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Uniquement la nuit, permet d'ouvrir une connexion mentale entre deux personnes, 1PM/personne supplémentaire."
    ),
    Skill(
      id: 123, 
      name: "Lévitation", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "2PM/tour, uniquement la nuit, permet de s'élever du sol et de se déplacer dans les airs."
    ),
    Skill(
      id: 124, 
      name: "Lame d’Ombres", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Crée des lames à partir d'une ombre, D6 de dégâts."
    ),
    Skill(
      id: 125, 
      name: "Mesmer", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "L'interlocuteur est fasciné par vos paroles et aura tendance à les suivre."
    ),
    Skill(
      id: 126, 
      name: "Télékinésie", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "PM suivant la taille de l'objet a déplacer. Ne peut bouger que les objets inanimés."
    ),
    Skill(
      id: 127, 
      name: "Forme de Brume", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Invulnérable aux attaques mais ne peut attaquer physiquement."
    ),
    Skill(
      id: 128, 
      name: "Assassinat d'Ombre", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "Envoie une ombre attaquer l'adversaire dans le dos pour une action."
    ),
    Skill(
      id: 129, 
      name: "Ombre Autonome", 
      cost: 6, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Détache l'ombre du corps et y transfère la conscience. Le corps est inconscient."
    ),


    //
    // Compétences de Strigoï
    //

    Skill(
      id: 130, 
      name: "Langage des bêtes", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Permet de communiquer verbalement avec un animal."
    ),
    Skill(
      id: 131, 
      name: "Communion animale", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Ressent les émotions et les souvenirs de l'animal."
    ),
    Skill(
      id: 132, 
      name: "Sensitivité Bestiale", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Augmente drastiquement un de ses sens."
    ),
    Skill(
      id: 133, 
      name: "Hybridation", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Transfère l'attribut d'une forme animale sur sa forme humaine."
    ),
    Skill(
      id: 134, 
      name: "Transformation Canine", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Se transforme en canidé au choix, une seule espèce ,D6 de dégâts."
    ),
    Skill(
      id: 135, 
      name: "Transformation Féline", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Se transforme en félin au choix, une seule espèce, D4 de dégâts pour les Chats, D6 pour les Panthères."
    ),
    Skill(
      id: 136, 
      name: "Transformation Mammalienne", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Se transforme en un mammifère non prédateur au choix, une seule espèce."
    ),
    Skill(
      id: 137, 
      name: "Transformation Chiroptérienne", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Se transforme en Chauve-souris, une seule espèce."
    ),
    Skill(
      id: 138, 
      name: "Transformation Reptilienne", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Se transforme en reptile au choix, une seule espèce, D4 de dégâts, serpents exclus."
    ),
    Skill(
      id: 139, 
      name: "Transformation Ophidienne", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Se transforme en serpent au choix, une seule espèce, D4 et effets du venin."
    ),
    Skill(
      id: 140, 
      name: "Transformation Aviaire", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Se transforme en oiseau au choix, une seule espèce, D4 de dégâts."
    ),
    Skill(
      id: 141, 
      name: "Domination Animale", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Prend le contrôle des animaux aux esprits faibles pendant D6 tours."
    ),
    Skill(
      id: 142, 
      name: "Frénésie Bestiale", 
      cost: 6, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Pendant un certain temps, peut changer de forme sans limitation durant D6 tours."
    ),


    //
    // Compétences de Dampyr
    //

    Skill(
      id: 143, 
      name: "Volonté d'Humanité", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet de résister à la soif vampirique."
    ),
    Skill(
      id: 144, 
      name: "Sixième Sens", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "+20% au jets de perception, Mod 10% aux esquives."
    ),
    Skill(
      id: 145, 
      name: "Arme de Sang", 
      cost: 1, 
      costType: CostType.pm, 
      secondCost: 2,
      secondCostType: CostType.pv,
      multiCost: true,
      costs: [2, 3, 4, 6],
      descriptions: [
        "Créé une arme de sang qui inflige D4 de dégâts.",
        "Créé une arme de sang qui inflige D6 de dégâts.",
        "Créé une arme de sang qui inflige D8 de dégâts.",
        "Créé une arme de sang qui inflige D10 de dégâts."
        ],
      limited: false, 
      description: "Créé une arme de sang qui inflige D4 de dégâts."
    ),
    Skill(
      id: 149, 
      name: "Extraction de Sang", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Attire le sang d'une blessure ouverte, Inflige D4 dégâts et l'Effet Saignement."
    ),
    Skill(
      id: 150, 
      name: "Régénération Dampyrique", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Régénère le corps, -2PM pour 1 PV."
    ),
    Skill(
      id: 151, 
      name: "Absorption", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "-20% au jet, absorbe les PM d'une créature vampirique. +5% temporaire au pouvoir vampirique par PM absorbé."
    ),
    Skill(
      id: 152, 
      name: "Tranchant Sanglant", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Utilise du sang pour augmenter de deux les dés de dégâts d'une Arme Blanche."
    ),
    Skill(
      id: 153, 
      name: "Pantin Dampyrique", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Réanime et contrôle un cadavre récent pendant D6 tour en mêlant son sang au sien."
    ),
    Skill(
      id: 154, 
      name: "Armure de sang", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Nécessite du sang, peut être placé sur un d'autre, Absorbe D6 dégâts avant de disparaître."
    ),
    Skill(
      id: 155, 
      name: "Sang Maudit", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Mod 15% aux jets de Physique, +3PV, entre en frénésie si blessé dans cet état."
    ),
    Skill(
      id: 156, 
      name: "Marionnette", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "Contrôle le corps d'une créature si elle contient du sang, nécessite une blessure ouverte."
    ),
    Skill(
      id: 157, 
      name: "Retournement des liens de sang", 
      cost: 5, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "Permet de contrôler mentalement un vampire durant contact physique."
    ),
    Skill(
      id: 158, 
      name: "Aura de Dampyr", 
      cost: 6, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Dissipe toute influence vampirique aux alentours pendant d4 tours."
    ),
    Skill(
      id: 159, 
      name: "Éveil Vampirique", 
      cost: 7, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Si mis à 0 PV ou en dessous, se rend 3D4 PV, et augmente le pouvoir de 20%."
    ),


    //
    // Compétences de Lamenuit
    //

    Skill(
      id: 160, 
      name: "Sceau Lunaire", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Résiste au pouvoir vampirique tant que le sceau est présent."
    ),
    Skill(
      id: 161, 
      name: "Saut Vampirique", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet de couvrir une très grande distance d'un bond."
    ),
    Skill(
      id: 162, 
      name: "Reflet de Lune", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "De nuit, lance une seconde attaque si une première touche."
    ),
    Skill(
      id: 163, 
      name: "Lame de Corps", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet d'attaquer avec son corps comme avec une Arme Blanche (Cpe D4, Est D6)."
    ),
    Skill(
      id: 164, 
      name: "OEil Nocturne", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Contre les effets des illusions."
    ),
    Skill(
      id: 165, 
      name: "Miroir Nocturne", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "De nuit, crée une illusion d'un double. Peut copier une autre personne."
    ),
    Skill(
      id: 166, 
      name: "Tranchant Lunaire", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Attaque la cible à distance avec une Arme Blanche, -2 dégât."
    ),
    Skill(
      id: 167, 
      name: "Appui aérien", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "De nuit, prend appui sur l'air pour se déplacer."
    ),
    Skill(
      id: 168, 
      name: "Bénédiction de la Lune", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Rend D6 de PM à la cible, non valable pour le lanceur."
    ),
    Skill(
      id: 169, 
      name: "Traque Nocturne", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "De nuit, permet de tracer les déplacements d'un individu à partir d'un objet lui appartenant."
    ),
    Skill(
      id: 170, 
      name: "Bilocation", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Projette sa présence mentale dans un lieu précédemment visité. Interaction avec ce dernier possible uniquement de nuit."
    ),
    Skill(
      id: 171, 
      name: "Envol de Lame", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Change la direction d'une arme de lancer en plein vol."
    ),
    Skill(
      id: 172, 
      name: "Regard d'Argent", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Contact visuel, Brûle D4 PM à la cible, D6 si la cible est sensible à l'effet Argent."
    ),
    Skill(
      id: 173, 
      name: "Éclair d’argent", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Attaque éclair à +1 dégât, -15% à la parade adverse."
    ),
    Skill(
      id: 174, 
      name: "Phase de la Lune", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "De nuit, permet de se rendre intangible pour D6 tour."
    ),
    Skill(
      id: 175, 
      name: "Voile Lunaire", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "De nuit, permet de se rendre invisible pour D4 tours, 2PM par tour supplémentaire."
    ),
    Skill(
      id: 176, 
      name: "Inversion Lunaire", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "De nuit, peut échanger sa position avec un objet visible. Cet objet ne doit pas être en contact avec une surface."
    ),
    Skill(
      id: 177, 
      name: "Ubiquité", 
      cost: 5, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "De nuit permet de se dédoubler pour un court moment, 2 actions possibles."
    ),
    Skill(
      id: 178, 
      name: "Abandon du Sceau", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Double le nombre de PM restant pour D6 tour, le pouvoir vampirique augmente de 5 par tour, test de pouvoir au dernier tour."
    ),


    //
    // Compétences de Mentaliste
    //

    Skill(
      id: 179, 
      name: "Scanner Mental", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet d'appréhender l'ambiance mentale d'une zone."
    ),
    Skill(
      id: 180, 
      name: "Immersion Mentale", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Permet de rentrer dans le monde mental formé par une oeuvre originale."
    ),
    Skill(
      id: 181, 
      name: "Télékinésie", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Pour un objet pouvant être bougé sans effort à une main, coût en PM augmentant avec le poids et la taille."
    ),
    Skill(
      id: 182, 
      name: "Connexion Mentale", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "1PM pour une connexion entre deux personnes, +1PM par personne supplémentaires. Ne peut être imposée."
    ),
    Skill(
      id: 183, 
      name: "Multi-kinésie", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "Coût en PM augmentant avec le poids et la taille, peut bouger plusieurs objets à la fois, 2PM minimum par objet."
    ),
    Skill(
      id: 184, 
      name: "Traque Mentale", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet de traquer la présence mentale d'un être."
    ),
    Skill(
      id: 185, 
      name: "Télépathie", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Contact visuel nécessaire, permet de lire les pensées de la cible."
    ),
    Skill(
      id: 186, 
      name: "Coquille Mentale", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "2PM / tour, empêche d'utiliser des pouvoirs mentaux mais prévient toute intrusion mentale chez la cible."
    ),
    Skill(
      id: 187, 
      name: "Précognition", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet de s'ouvrir aux visions d'événements futures probables en lien avec un sujet."
    ),
    Skill(
      id: 188, 
      name: "Rétrocognition", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet de voir des événements passés en lien avec un lieu."
    ),
    Skill(
      id: 189, 
      name: "Intrusion mentale", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Entre dans l'esprit de la cible, +1 PM si la cible n'est pas en contact visuel direct."
    ),
    Skill(
      id: 190, 
      name: "Canalisation", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Permet de rentrer en contact avec un esprit qui s'exprime par la bouche du mentaliste."
    ),
    Skill(
      id: 191, 
      name: "Lance d'esprit", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Inflige D8 de dégâts au PM adverse, 1/6 chance d’assommer."
    ),
    Skill(
      id: 192, 
      name: "Scalpel Mental", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet de faire une incision sur n'importe quelle surface."
    ),
    Skill(
      id: 193, 
      name: "Vague Télékinétique", 
      cost: 5, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Repousse tout en face du lanceur."
    ),
    Skill(
      id: 194, 
      name: "Lien Psychique", 
      cost: 5, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Permet d'entrer dans l'esprit d'une entité de manières prolongé, voire de la contrôler si elle est faible."
    ),
    Skill(
      id: 195, 
      name: "Inception",
      cost: 7, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Introduit discrètement une idée dans la psyché de la cible."
    ),
    Skill(
      id: 196, 
      name: "Choc mental", 
      cost: 10, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Brûle l'esprit de de la cible qui perds ses PM et tombe dans l’inconscience si elle ne réussit pas un test de Mental avec un malus de 30%."
    ),


    //
    // Compétences d'Occultiste
    //

    Skill(
      id: 197, 
      name: "Appel", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Attire à soi une entité dont on connaît le n."
    ),
    Skill(
      id: 198, 
      name: "Pacte démoniaque", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Se lie avec un démon au travers d'un pacte, proposé par le MJ et spécifiant 3 choses : L'Effet, que le démon offre quand on fait appel à lui. Le Tribut, que demande le démon afin de manifester l'Effet. La Condition maintient le pacte tant qu'elle est remplie. Effectuer plusieurs pactes est particulièrement dangereux."
    ),
    Skill(
      id: 199, 
      name: "Exorcisme", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Contact physique nécessaire, brise le lien de possession ou de servitude entre un démon et sa cible en y opposant sa volonté propre. Coût dépendant de l'entité adverse."
    ),
    Skill(
      id: 200, 
      name: "Interdiction", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Interdit à une entité l’accès à un lieu. Nécessite son Nom pour lui emprunter sa puissance."
    ),
    Skill(
      id: 201, 
      name: "Sigil de Traque", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "1PM à l'activation, permet de ressentir la localisation de ce symbole."
    ),
    Skill(
      id: 202, 
      name: "Mot de Charisme", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "2PM par mot prononcé, ceux-ci s'impriment fortement sur la volonté de leurs auditeurs."
    ),
    Skill(
      id: 203, 
      name: "Don des langues", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Peut comprendre toutes les langues, au moins partiellement."
    ),
    Skill(
      id: 204, 
      name: "Reconstruction Occulte", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Régénère le corps de la cible via des symboles tracés sur le corps, +1D6 PV, Effets secondaire sur le Pouvoir de la Cible."
    ),
    Skill(
      id: 205, 
      name: "Sceau de Sang", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "3PM à l'activation par une incantation, placé sur une surface ou un corps, ce sceau restreint la cible pendant D6 tours, nécessite du sang de la cible."
    ),
    Skill(
      id: 206, 
      name: "Sceau Démoniaque", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "4PM à l'activation par une incantation, placé sur une surface, restreint les PM d'un démon de D20 et le scelle si ses PM sont amenés à 0. Nécessite son Nom."
    ),
    Skill(
      id: 207, 
      name: "Malédiction", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "La cible subit un Mod négatif 20% pendant D10 tours."
    ),
    Skill(
      id: 208, 
      name: "Convocation", 
      cost: 5, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Force une entité à se révéler sous sa forme véritable, nécessite son Nom."
    ),
    Skill(
      id: 209, 
      name: "Révélation du Nom", 
      cost: 6, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Force une entité à révéler son Nom"
    ),
    Skill(
      id: 210, 
      name: "Poésie Majestueuse", 
      cost: 6, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "Donne un ordre à une cible en un Alexandrin. Chaque Alexandrin supplémentaire coûte 1PM de plus."
    ),


    //
    // Compétences d'Inquisiteurs
    //

    Skill(
      id: 211, 
      name: "Protection Divine", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Permet de retarder les dégâts d'une attaque subie de D6 tours."
    ),
    Skill(
      id: 212, 
      name: "Prière", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Rend 1 PM par tour de combat passé en position de prière."
    ),
    Skill(
      id: 213, 
      name: "Provocation", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Focalise l'attention de la cible sur soi."
    ),
    Skill(
      id: 214, 
      name: "Confession", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Obtient une confession par la peur, Mod 15% au jet de social."
    ),
    Skill(
      id: 215, 
      name: "Marque de Jugement", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Chauffe l'arme blanche au rouge, la cible marqué subira 1 dégâts supplémentaire par attaque de l'inquisiteur réussie."
    ),
    Skill(
      id: 216, 
      name: "Bénédiction de l’Épée", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Donne l'Effet Sacrée à une arme blanche pendant D6 tours."
    ),
    Skill(
      id: 217, 
      name: "Zèle d'Inquisiteur", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Double les dégâts pour une attaque en récitant une prière."
    ),
    Skill(
      id: 218, 
      name: "Purification", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Brise l'emprise mentale qu'une entité possède sur la cible."
    ),
    Skill(
      id: 219, 
      name: "Bénédiction des Flammes", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Donne l'Effet Incendiaire et l'Effet Sacré à une arme blanche pendant D4 tours."
    ),
    Skill(
      id: 220, 
      name: "Présentation", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Brandit un symbole sacré, les attaques de lames alentours ont l'Effet Sacré."
    ),
    Skill(
      id: 221, 
      name: "Volonté Divine", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Ajoute un Mod 15% à n'importe quelle action en accord avec la foi du personnage."
    ),


    //
    // Compétence d'Homme de Foi
    //

    Skill(
      id: 222, 
      name: "Lumière Sacrée", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Génère de la lumière à Effet Sacrée de sa paume levée."
    ),
    Skill(
      id: 223, 
      name: "Sermon", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Enveloppe le discours de passion captant l'attention, Mod 30% au jet de social."
    ),
    Skill(
      id: 224, 
      name: "Concentration", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "1PM/tour, Donne un Mod 10% par tour passé dans cette position sans être interrompue."
    ),
    Skill(
      id: 225, 
      name: "Inspiration", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Confère un Mod 10% à tout ses alliés pour la prochaine action."
    ),
    Skill(
      id: 226, 
      name: "Prière", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Rend 2PM par tour de combat passé à prier, peut être utilisé une fois par heure hors combat."
    ),
    Skill(
      id: 227, 
      name: "Don de Soi", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Permet à la cible de consommer les PM du lanceur au lieu des siens."
    ),
    Skill(
      id: 228, 
      name: "Confession", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Obtient une confession par la confiance, Mod 15% au jet de social."
    ),
    Skill(
      id: 229, 
      name: "Consécration", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Consacre le sol autour de lui."
    ),
    Skill(
      id: 230, 
      name: "Bénédiction de l'Esprit", 
      cost: 2,
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Donne 2PM à la cible."
    ),
    Skill(
      id: 231, 
      name: "Bénédiction des Armes", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Donne l'effet Bénie à une arme ou un projectile pour D6 tours"
    ),
    Skill(
      id: 232, 
      name: "Sceau de l'Esprit", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Rend la cible insensible aux intrusions mentales pendant 2D4 tours."
    ),
    Skill(
      id: 233, 
      name: "Miséricorde", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Rend D8 PM à la cible si il lui reste moins de 3 PV."
    ),
    Skill(
      id: 234, 
      name: "Exorcisme Religieux", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Au contact, retire 2D6 PM à la cible en récitant un verset d'un livre saint."
    ),
    Skill(
      id: 235, 
      name: "Miracle", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Rend D6 PV et D6 PM à la cible."
    ),
    Skill(
      id: 236, 
      name: "Commandement Sacré", 
      cost: 5, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Si la cible est sensible à l'Effet Sacré, la fait obéir à un ordre simple."
    ),
    Skill(
      id: 237, 
      name: "Bannissement", 
      cost: 6, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "Au contact, si la cible n'a plus de PM, permet de bannir son esprit. Chaque tour au contact retire D6 PM à la cible, D12 si elle est sensible à l'Effet Bénie."
    ),


    //
    // Compétence de Néphilim
    //

    Skill(
      id: 238, 
      name: "Perception accélérée", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Ralentis la perception du temps, Mod15% à la perception, Mod5% à la visée et à l'esquive."
    ),
    Skill(
      id: 239, 
      name: "Double Tir", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Si l'armement le permet, tire avec deux armes dans la même action."
    ),
    Skill(
      id: 240, 
      name: "Vision Angélique", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "1PM/tour, permet de voir, peu importe l'environnement ou l'état des yeux."
    ),
    Skill(
      id: 241, 
      name: "Acuité Visuelle", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet de remarquer des détails même à grande distance."
    ),
    Skill(
      id: 242, 
      name: "Vision Future", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "Permet de connaître la prochaine action de la cible."
    ),
    Skill(
      id: 243, 
      name: "Vision des Auras", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Détecte les intentions et l'humeur de la cible, peut révéler son identité."
    ),
    Skill(
      id: 244, 
      name: "Éclat de Lumière", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Crée un flash lumineux aveuglant."
    ),
    Skill(
      id: 245, 
      name: "Verrouillage", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "La cible ne peut échapper au regard du lanceur, même lorsque le contact visuel est brisé."
    ),
    Skill(
      id: 246, 
      name: "Évaluation", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet de jauger la puissance d'une entité par rapport à soi ou à d'autres."
    ),
    Skill(
      id: 247, 
      name: "Détection des Hostiles", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Ressent la présence des entités hostiles aux alentours."
    ),
    Skill(
      id: 248, 
      name: "OEil de Néphilim", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Pause la perception du temps durant son action."
    ),
    Skill(
      id: 249, 
      name: "Rayon de Lumière", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Génère un rayon lumineux depuis la main, D6 de dégâts."
    ),
    Skill(
      id: 250, 
      name: "Marque de Chasse", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Marque la cible et permet de ressentir sa présence. Mod 10% pour toutes les prochaines attaques sur cette cible."
    ),
    Skill(
      id: 251, 
      name: "Vision Prédictive", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Permet de voir la cible quelques instants dans le futur, empêche l'esquive."
    ),
    Skill(
      id: 252, 
      name: "Divine Vélocité", 
      cost: 5, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Arrête le temps pour le joueur durant 2 actions. -2PM par actions supplémentaires. Seul le lanceur est conscient et peut agir durant ce temps-là."
    ),


    //
    // Compétences de Séraphin
    //

    Skill(
      id: 253, 
      name: "Sentence", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "Accuse la Cible en l'attaquant, lance un deuxième dés de dégâts si la cible est coupable, -3PM supplémentaire si la cible est innocente de cette accusation"
    ),
    Skill(
      id: 254, 
      name: "Injonction", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Pose une question à la cible, elle perd D4 PM si elle répond par un mensonge"
    ),
    Skill(
      id: 255, 
      name: "Purification", 
      cost: 1, 
      costType: CostType.pm, 
      secondCost: 1,
      secondCostType: CostType.pv,
      multiCost: false,
      limited: false,
      description: "Donne du sang pour purifier un liquide, lui conférant l'Effet Sacré."
    ),
    Skill(
      id: 256, 
      name: "Aura Angélique", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "1PM/tour, émet une lumière autour de lui."
    ),
    Skill(
      id: 257, 
      name: "Pardon", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Contact nécessaire, brûle l'esprit de la cible et inflige D6 dégâts aux PM de la cible."
    ),
    Skill(
      id: 258, 
      name: "Jugement", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet de percevoir les péchés d’un individu, contact visuel nécessaire et conséquences importantes sur la cible."
    ),
    Skill(
      id: 259, 
      name: "Volonté de Fer", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Réduit de D4 les dégâts subis lors d'une attaque."
    ),
    Skill(
      id: 260, 
      name: "Flambeau", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Enflamme son arme créant de la lumière et lui donne l'Effet Incendiaire."
    ),
    Skill(
      id: 261, 
      name: "Abnégation", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "Divise tout dégât subi par 2 pendant D8 tours. Si impair, arrondir à l’inférieur."
    ),
    Skill(
      id: 262, 
      name: "Auréole", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Irradie de lumière à Effet Sacré."
    ),
    Skill(
      id: 263, 
      name: "Second Souffle", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet de garder 1PV en cas de dégât mortel."
    ),
    Skill(
      id: 264, 
      name: "Condamnation", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Déclenche une combustion spontanée de la cible qui subit l'effet Enflammé Aggravé."
    ),
    Skill(
      id: 265, 
      name: "Représailles", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "Riposte en ajoutant la moitié des dégâts subi de la dernière attaque au jet de dégâts"
    ),
    Skill(
      id: 266, 
      name: "Bûcher Sacré", 
      cost: 5, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "Enflamme une zone autour de lui, toute entité dans cette zone subit les Effets Incendiaire Aggravé et Sacré, dure D6+2 tours."
    ),
    Skill(
      id: 267, 
      name: "Sanctification", 
      cost: 6, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Rend une zone consacrée, ou l'utilisation de PM est impossible sauf pour le lanceur."
    ),


    //
    // Compétences de Chérubin
    //

    Skill(
      id: 268, 
      name: "Imposition des Mains", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false, 
      description: "X PM, rend X PV à la Cible, au contact."
    ),
    Skill(
      id: 269, 
      name: "Don des langues", 
      cost: 0, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Peut communiquer oralement dans n'importe quel langage."
    ),
    Skill(
      id: 270, 
      name: "Soin Rapide", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true, 
      description: "Rend Immédiatement 2PV à une cible visible."
    ),
    Skill(
      id: 271, 
      name: "Anesthésie", 
      cost: 1, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Inhibe la sensation de douleur, retire les malus de blessures."
    ),
    Skill(
      id: 272, 
      name: "Compassion", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Ressent les émotions et le vécu d'une créature, consciente ou non."
    ),
    Skill(
      id: 273, 
      name: "Bénédiction du Seuil", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Sur un seuil, empêche les créatures sensibles à l'Effet Sacré de passer ce seuil."
    ),
    Skill(
      id: 274, 
      name: "Lumière Intérieure", 
      cost: 2, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Renforce la volonté de la cible, lui rend D4 PM."
    ),
    Skill(
      id: 275, 
      name: "Accélération métabolique", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "La cible se soigne d'1PV en dépensant 1PE par tour pendant D6 tours."
    ),
    Skill(
      id: 276, 
      name: "Cercle de Soin", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Tous les êtres alentours se soignent de 1D4 PV."
    ),
    Skill(
      id: 277, 
      name: "Ataraxie", 
      cost: 3, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Permet à la cible d'ignorer les dégâts subis pendant D4 tours, ces dégâts sont pris en compte à la fin du dernier tour."
    ),
    Skill(
      id: 278, 
      name: "Guérison", 
      cost: 4, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Guérit entièrement une blessure subie il y a moins de 3 tours."
    ),
    Skill(
      id: 279, 
      name: "Nexus Mental", 
      cost: 5, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Crée une connexion entre les PJ mettant en commun les PM."
    ),
    Skill(
      id: 280, 
      name: "Miroir Défensif", 
      cost: 6, 
      costType: CostType.pm, 
      multiCost: false,
      limited: true,
      description: "Permet d'ignorer les dégâts d'une attaque subie et de les renvoyer à son lanceur."
    ),
    Skill(
      id: 281, 
      name: "Lazare", 
      cost: 6, 
      costType: CostType.pm, 
      multiCost: false,
      limited: false,
      description: "Ramène un mort récent à la vie avec 2PV, 2PM. -1PM par PV ou PM additionnel."
    ),
  ];



  //////////////////////////////////////////
  //                                      //
  // Fonction utiles pour les compétences //
  //                                      //
  //////////////////////////////////////////

  Skill getSkillById(int id) {
    Skill res = allSkills.last;

    for (var skill in allSkills) {
      if (skill.id == id) {
        res = skill;
      }
    }

    return res;
  }

  List<Skill> getSkillListByIds(int first, int last) {
    List<Skill> res = [];

    for (var skill in allSkills) {
      if (skill.id >= first && skill.id <= last) {
        res.add(skill);
      }
    }

    return res;
  }

  Skill getSkillByName(String name) {
    Skill res = allSkills.last;

    for (var skill in allSkills) {
      if (skill.name == name) {
        res = skill;
      }
    }

    return res;
  }

  int getLastSkillId() {
    int res = allSkills.last.id;

    return res;
  }
}
