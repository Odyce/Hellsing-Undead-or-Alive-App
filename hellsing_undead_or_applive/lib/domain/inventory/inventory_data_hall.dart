import 'package:hellsing_undead_or_applive/domain/models.dart';

class MuniObjectList {
  List<MuniObject> allMuniObject = [

    // Bolt

    MuniObject(
      id: 0, 
      name: "Carreaux d'acier [A]", 
      description: "Munitions de base pour arbalètes.", 
      effect: Effect.none, 
      price: 15, 
      priceFor6: 90,
    ),
    MuniObject(
      id: 1, 
      name: "Carreaux à tête barbelée [B]", 
      description: "+1 dégâts si le carreau est retiré.", 
      effect: Effect.none, 
      price: 20, 
      priceFor6: 120,
    ),
    MuniObject(
      id: 2, 
      name: "Carreaux creux [C]", 
      description: "Permet d'injecter poison et autre liquide.", 
      effect: Effect.none, 
      price: 25, 
      priceFor6: 150,
    ),
    MuniObject(
      id: 3, 
      name: "Carreaux d'argent [Ag]", 
      description: "Ajoute l'effet Argent.", 
      effect: Effect.silver, 
      price: 60, 
      priceFor6: 360,
    ),
    MuniObject(
      id: 4, 
      name: "Carreaux à charge de mercure [Me]", 
      description: "Ajoute l'effet Mercure.", 
      effect: Effect.mercury, 
      price: 30, 
      priceFor6: 180,
    ),
    MuniObject(
      id: 5, 
      name: "Carreaux d'Acier Béni [Bl]", 
      description: "Ajoute l'effet Béni.", 
      effect: Effect.blessed, 
      price: 30, 
      priceFor6: 180,
    ),
    MuniObject(
      id: 6, 
      name: "Carreaux Explosifs [Ex]", 
      description: "+3 dégâts à l'impact.", 
      effect: Effect.none, 
      price: 70, 
      priceFor6: 420,
    ),

    // Small Gun Shots

    MuniObject(
      id: 7, 
      name: "Balle de Plomb [P]", 
      description: "Munitions de base pour petits calibres.", 
      effect: Effect.none, 
      price: 1, 
      priceFor6: 5,
      free: [Calibre.point22LR, Calibre.point22, Calibre.point32Rimfire, Calibre.point41LongColt]
    ),
    MuniObject(
      id: 8, 
      name: "Balle de Sel [Na]", 
      description: "Non-Lethal.", 
      effect: Effect.none, 
      price: 2, 
      priceFor6: 10,
    ),
    MuniObject(
      id: 9, 
      name: "Balle d'Argent [Ag]", 
      description: "Ajoute l'effet Argent.", 
      effect: Effect.silver, 
      price: 25, 
      priceFor6: 125,
    ),
    MuniObject(
      id: 10, 
      name: "Balle à pointe de Mercure [Me]", 
      description: "Ajoute l'effet Mercure.", 
      effect: Effect.mercury, 
      price: 12, 
      priceFor6: 60,
    ),
    MuniObject(
      id: 11, 
      name: "Balle Incendiaire [In]", 
      description: "Ajoute l'effet Incendiaire.", 
      effect: Effect.incendiary, 
      price: 10, 
      priceFor6: 50,
    ),
    MuniObject(
      id: 12, 
      name: "Balle au Magnésium [Mg]", 
      description: "Produit un flash lumineux à l'impact.", 
      effect: Effect.none, 
      price: 2, 
      priceFor6: 10,
    ),
    MuniObject(
      id: 13, 
      name: "Balle Fumigène [F]", 
      description: "Produits un nuage de fumée à l'impact.", 
      effect: Effect.none, 
      price: 2, 
      priceFor6: 10,
    ),
    MuniObject(
      id: 14, 
      name: "Balle à charge de Nitrate d'argent [Nag]", 
      description: "Ralentit la régénération vampirique.", 
      effect: Effect.none, 
      price: 10, 
      priceFor6: 50,
    ),
    MuniObject(
      id: 15, 
      name: "Balle à tête creuse [C]", 
      description: "+1 dégâts à la cible.", 
      effect: Effect.none, 
      price: 15, 
      priceFor6: 75,
    ),

    // Big Gun Shots

    MuniObject(
      id: 16, 
      name: "Balle de Plomb [P]", 
      description: "Munitions de bases pour les gros calibres.", 
      effect: Effect.none, 
      price: 3, 
      priceFor6: 15,
      free: [ Calibre.point44Magnum ]
    ),
    MuniObject(
      id: 17, 
      name: "Balle de Sel [Na]", 
      description: "Non-Lethal.", 
      effect: Effect.none, 
      price: 3, 
      priceFor6: 15,
    ),
    MuniObject(
      id: 18, 
      name: "Balle d'Argent [Ag]", 
      description: "Ajoute l'effet Argent.", 
      effect: Effect.silver, 
      price: 35, 
      priceFor6: 175,
    ),
    MuniObject(
      id: 19, 
      name: "Balle à pointe de Mercure [Me]", 
      description: "Ajoute l'effet Mercure.", 
      effect: Effect.mercury, 
      price: 20, 
      priceFor6: 100,
    ),
    MuniObject(
      id: 20, 
      name: "Balle au Magnésium [Mg]", 
      description: "Produit un flash lumineux à l'impact.", 
      effect: Effect.none, 
      price: 3, 
      priceFor6: 15,
    ),
    MuniObject(
      id: 21, 
      name: "Balle Incendiaire [In]", 
      description: "Ajoute l'effet Incendiaire.", 
      effect: Effect.incendiary, 
      price: 12, 
      priceFor6: 60,
    ),
    MuniObject(
      id: 22, 
      name: "Balle Explosives [Ex]", 
      description: "+3 dégâts à la cible.", 
      effect: Effect.none, 
      price: 20, 
      priceFor6: 100,
    ),
    MuniObject(
      id: 23, 
      name: "Balle Perçantes [Pe]", 
      description: "Ajoute l'effet Perforant.", 
      effect: Effect.piercing, 
      price: 15, 
      priceFor6: 75,
    ),

    // Dispersion Shots

    MuniObject(
      id: 24, 
      name: "Cartouche de Plomb [P]", 
      description: "Munitions de bases pour les fusils à dispersion.", 
      effect: Effect.none, 
      price: 1, 
      priceFor6: 5,
      free: [ Calibre.bore8, Calibre.gauge12 ]
    ),
    MuniObject(
      id: 25, 
      name: "Cartouche à grenaille d'argent [Ag]", 
      description: "Ajoute l'Effet Argent Aggravé.", 
      effect: Effect.silverAggr, 
      price: 30, 
      priceFor6: 150,
    ),
    MuniObject(
      id: 26, 
      name: "Cartouche au gros sel [Na]", 
      description: "Non Léthal.", 
      effect: Effect.none, 
      price: 1, 
      priceFor6: 6,
    ),
    MuniObject(
      id: 27, 
      name: "Cartouche Incendiaire [In]", 
      description: "Ajoute l'effet Incendiaire Aggravé.", 
      effect: Effect.incendiaryAggr, 
      price: 3, 
      priceFor6: 15,
    ),
    MuniObject(
      id: 28, 
      name: "Cartouche au Magnésium [Mg]", 
      description: "Produit un flash lumineux à l'impact, -2 dégâts.", 
      effect: Effect.none, 
      price: 3, 
      priceFor6: 15,
    ),
    MuniObject(
      id: 29, 
      name: "Balle de Fusil Perforante [Pe]", 
      description: "Ajoute l'Effet Perforant.", 
      effect: Effect.piercing, 
      price: 15, 
      priceFor6: 75,
    ),
    MuniObject(
      id: 30, 
      name: "Cartouche Fumigène [F]", 
      description: "Produits un nuage de fumée à l'impact,-2 dégâts.", 
      effect: Effect.none, 
      price: 3, 
      priceFor6: 15,
    ),

    // Rifle Shots

    MuniObject(
      id: 31, 
      name: "Balle de Plomb [P]", 
      description: "Munitions de base pour les fusils et carabines.", 
      effect: Effect.none, 
      price: 4, 
      priceFor6: 20,
      free: [ Calibre.point51Enfield, Calibre.point44Henry, Calibre.point44Winchester, Calibre.point57Enfield ]
    ),
    MuniObject(
      id: 32, 
      name: "Balle Perçantes [Pe]", 
      description: "Ajoute l'effet Perforant.", 
      effect: Effect.piercing, 
      price: 25, 
      priceFor6: 150,
    ),
    MuniObject(
      id: 33, 
      name: "Balle Explosives [Ex]", 
      description: "+3 dégâts à la cible.", 
      effect: Effect.none, 
      price: 30, 
      priceFor6: 180,
    ),
    MuniObject(
      id: 34, 
      name: "Balle Incendiaires [In]", 
      description: "Ajoute l'effet Incendiaire.", 
      effect: Effect.incendiary, 
      price: 15, 
      priceFor6: 90,
    ),
    MuniObject(
      id: 35, 
      name: "Balle d'Argent [Ag]", 
      description: "Ajoute l'effet Argent", 
      effect: Effect.silver, 
      price: 50, 
      priceFor6: 300,
    ),
    MuniObject(
      id: 36, 
      name: "Balle à pointe de Mercure [Me]", 
      description: "Ajoute l'effet Mercure", 
      effect: Effect.mercury, 
      price: 20, 
      priceFor6: 120,
    ),
  ];

  ////////////////////////////////////////
  //                                    //
  // Fonction utiles pour les munitions //
  //                                    //
  ////////////////////////////////////////

  MuniObject getMuniObjectById(int id) {
    MuniObject res = allMuniObject.last;

    for (var muni in allMuniObject) {
      if (muni.id == id) {
        res = muni;
      }
    }

    return res;
  }

  List<MuniObject> getWeaponListById(List<int> id) {
    List<MuniObject> res = [];

    for (var sid in id) {
      for (var muni in allMuniObject) {
        if (muni.id == sid) {
          res.add(muni);
        }
      }
    }

    return res;
  }
}

class MuniCategList {
  final list = MuniObjectList();

  late List<MuniCateg> allMuniCateg = [
    MuniCateg(
      id: 0,
      name: "bolt", 
      description: "Carreaux d’arbalète\n(prix équivalents pour flèches)", 
      included: [ Calibre.bolt ],
      munis: list.getWeaponListById([0, 1, 2, 3, 4, 5, 6]),
    ),
    MuniCateg(
      id: 1,
      name: "smallgun", 
      description: "Munitions de Petit Calibre pour Pistolet et Revolver\n(Jusqu'au .41 inclus)", 
      included: [ 
        Calibre.point22, 
        Calibre.point22LR, 
        Calibre.point32Rimfire, 
        Calibre.point36,
        Calibre.point38d10v4mm,
        Calibre.point40LongRifle,
        Calibre.point41,
        Calibre.point41Comet,
        Calibre.point41LongColt,
        Calibre.point41MoonSlayer,
        ],
      munis: list.getWeaponListById([7, 8, 9, 10, 11, 12, 13, 14, 15]),
    ),
    MuniCateg(
      id: 2,
      name: "biggun", 
      description: "Munitions de Gros Calibre pour Pistolet et Revolver\n(Jusqu'au .454 Casul)", 
      included: [
        Calibre.point41and32,
        Calibre.point426SilverDevil,
        Calibre.point45,
        Calibre.point454Casul,
      ],
      munis: list.getWeaponListById([16, 17, 18, 19, 20, 21, 22, 23]),
    ),
    MuniCateg(
      id: 3,
      name: "dispersion", 
      description: "Cartouches et Munitions pour Tromblons et Fusils à Dispersion", 
      included: [
        Calibre.bore8,
        Calibre.gauge10,
        Calibre.gauge12,
      ],
      munis: list.getWeaponListById([24, 25, 26, 27, 28, 29, 30]),
    ),
    MuniCateg(
      id: 4,
      name: "rifle", 
      description: "Munitions pour Fusils et Carabines", 
      included: [
        Calibre.point51Enfield,
      ],
      munis: list.getWeaponListById([31, 32, 33, 34, 35, 36]),
    ),
  ];
}

class SupportObjectList {
  List<SupportObject> allSupportObject = [
    SupportObject(
      id: 0, 
      name: "Kit de Chirurgie", 
      legend: "Pour découper des g... Pour la Science !", 
      description: "Set d'outils nécessaire à un Chirurgien pour utiliser ses compétences", 
      price: 60, 
      stockage: Stockage.weapon, 
      size: 1,
    ),
    SupportObject(
      id: 1, 
      name: "Kit de Pharmacie", 
      legend: "Des fioles, pleins de fioles ! Rempli de liquides bizarres ! J'aime les fioles.", 
      description: "Set de fioles et de réactifs nécessaire à un Apothicaire pour réaliser ses recettes.", 
      price: 60, 
      stockage: Stockage.weapon, 
      size: 1,
    ),
    SupportObject(
      id: 2, 
      name: "Kit de Création d'Explosifs", 
      legend: "Heureusement, ça n'explose pas. Enfin tant qu'on y met pas le feu.", 
      description: "Set d'outil et de  matières premières nécessaire à un Artificier pour créer des Bombes. Limité aux Artificiers.", 
      price: 80, 
      stockage: Stockage.weapon, 
      size: 1,
    ),
    SupportObject(
      id: 3, 
      name: "Trousse de Création de Munition", 
      legend: "Jamais à court !", 
      description: "Au calme, Permet de créer sur le terrain des munitions en plomb du calibre désiré. Prend du temps.", 
      price: 100, 
      stockage: Stockage.weapon, 
      size: 1,
    ),
    SupportObject(
      id: 4, 
      name: "Passe-Partout", 
      legend: "En l'absence de Mandat....", 
      description: "Jeu de multiples clés. Permet d'ouvrir les serrures les plus communes en Angleterre.", 
      price: 50, 
      stockage: Stockage.bag, 
      size: 1,
    ),
    SupportObject(
      id: 5, 
      name: "Trousse de Soin [ X | X | X ]", 
      legend: "Le pansement des Héros.", 
      description: "Au Calme, permet de panser une blessure et d'interrompre un Effet Saignement. 3 usages", 
      price: 50, 
      stockage: Stockage.weapon, 
      size: 1,
      number: 3,
    ),
    SupportObject(
      id: 6, 
      name: "Corde", 
      legend: "L'Indispensable, l'Alpha et l'Oméga de l'équipement.", 
      description: "Corde de 10m épaisse de 3,5 cm. Peut soutenir le poids d'une personne sans problème.", 
      price: 20, 
      stockage: Stockage.bag, 
      size: 1,
    ),
    SupportObject(
      id: 7, 
      name: "Grappin", 
      legend: "Toujours pratique.", 
      description: "Grappin à lancer au bout de 20m de filin d'acier. Peut soutenir le poids de deux personnes sans problème.", 
      price: 30, 
      stockage: Stockage.bag, 
      size: 1,
    ),
    SupportObject(
      id: 8, 
      name: "Lanterne", 
      legend: "Le problème avec la Nuit, c'est qu'on y voit souvent rien", 
      description: "Lanterne à Huile, éclaire autour du porteur avec une flamme protégé par du verre. Libère de l'Huile Inflammable si brisé.", 
      price: 50, 
      stockage: Stockage.bag, 
      size: 1,
    ),
    SupportObject(
      id: 9, 
      name: "Feu de Signal", 
      legend: "Très pratique pour voir la Nuit. Ou être vu.", 
      description: "Cartouche lumineuse brûlant en créant une forte lumière pendant quelques minutes. Peut être activé manuellement", 
      price: 10, 
      stockage: Stockage.muni, 
      size: 1,
      number: 6,
    ),
    SupportObject(
      id: 10, 
      name: "Fumigène", 
      legend: "La disparition dans un nuage de fumée, propre et distinguée.", 
      description: "Cartouche libérant une grande quantité de fumée  éventuellement colorée quelques secondes après son activation. Peut être activé manuellement.", 
      price: 10, 
      stockage: Stockage.muni, 
      size: 1,
      number: 6,
    ),
    SupportObject(
      id: 11, 
      name: "Pistolet de Signal", 
      legend: "À utiliser en cas de détresse.", 
      description: "Pistolet très imprécis, permettant de tirer des Fumigènes et des Feux de Signal dans une direction générale.", 
      price: 30, 
      stockage: Stockage.weapon, 
      size: 1,
    ),
    SupportObject(
      id: 12, 
      name: "Amulette Mystique", 
      legend: "Votre grand-mère avait raison.", 
      description: "Étrange amulette vibrant à proximité d'une présence immatérielle.", 
      price: 100, 
      stockage: Stockage.bag, 
      size: 1,
    ),
    SupportObject(
      id: 13, 
      name: "Fiole d'Eau Bénite Véritable", 
      legend: "Une aide précieuse du Vatican. Remercions la charité catholique...", 
      description: "Fiole contenant quelques gouttes d'un liquide argentée extrêmement rare. Hautement toxique si sensible à l'Effet Argent, Sacrée ou Bénie.", 
      price: 1000, 
      stockage: Stockage.bag, 
      size: 1,
    ),
    SupportObject(
      id: 14, 
      name: "Déguisement", 
      legend: "Cette fausse moustache vous va à ravir.", 
      description: "Set d'accessoires bien choisis pour altérer grandement votre apparence. Choisir l'apparence alternative à l'achat.", 
      price: 200, 
      stockage: Stockage.bag, 
      size: 3,
    ),
    SupportObject(
      id: 15, 
      name: "Menottes", 
      legend: "Les Bracelets les plus populaires de Whitechapel.", 
      description: "Permet de restreindre les mouvements d'un suspect.", 
      price: 20, 
      stockage: Stockage.bag, 
      size: 1,
    ),
    SupportObject(
      id: 16, 
      name: "Cartouchière", 
      legend: "Il n'y en as jamais assez n'est ce pas ?", 
      description: "Rajoute 1 Emplacement de Munition au porteur, sous la forme d'une poche supplémentaire ou d'une ceinture de munition.", 
      price: 150, 
      stockage: Stockage.bag, 
      size: 1,
    ),
  ];
}
