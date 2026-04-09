import '../book_index.dart';
import '../book_page.dart';

const sectionClassesSpeciales = RawSection(
  id: 'classes_speciales',
  title: 'Classes spéciales',
  pages: [
    // =========================================================================
    // CLASSES VAMPIRIQUES
    // =========================================================================

    // ---- Nosferatu ----------------------------------------------------------
    ClassSheetPage(
      id: 'classe_nosferatu',
      sectionId: 'classes_speciales',
      title: 'Nosferatu',
      className: 'Nosferatu',
      classCategory: 'Classes Vampiriques',
      quote:
          'Soyons honnête. L\'humanité c\'est très bien, jusqu\'à ce qu\'on ait besoin de puissance.',
      classBonuses: [
        '/6 Magie Noire',
        '/6 Force Vampirique',
        '/6 Flair de Prédateur',
      ],
      equipment: [],
      affinities: ['Armes blanche à une main', 'Armes blanche à deux mains'],
      munitionSlots: 0,
      skillFormula: 'Physique/20 compétences — PM = Mental/10',
      freeSkills: [
        'Armurerie Mondiale (0PM : Arme Blanche à une main D6 | -2PM : Arme Blanche à deux mains D8 | -4PM : Arme Blanche à deux mains D10 | -6PM : Lame Vampirique D12)',
        'Régénération Vampirique (réussite au test de Pouvoir → +2PV ; chaque palier de 100% garantit +1PV même en cas d\'échec)',
      ],
      accessibleSkills: [
        'Traque de Sang (après avoir goûté au sang d\'un être, peut suivre sa trace et sentir sa présence)',
        'Construction Vampirique (crée un objet simple, coût dépendant de la taille)',
        'Perception des Liens de Sang (en cas de contact physique, ressentir les liens de sang entre individus)',
        'Force démoniaque (-1PM, -2PV, lance 3× les dégâts sur la prochaine attaque CàC) (L)',
        'Tranchant obscur (-X PM, la cible subit X dégâts sous forme d\'une coupure)',
        'Aura de prédateur (-2PM, +30% au jet de menace, peut induire une panique)',
        'Possession (-3PM, prend le contrôle mental d\'un PNJ, contact visuel nécessaire)',
        'Regard de prédateur (-3PM, saisit de peur la cible jusqu\'à la tétanie)',
        'Soin Vampirique (-4PM, se rend D6 PV)',
        'Éclair Vampirique (-4PM, -1PV, éclair imparable, 2D4 dégâts)',
        'Rituel de sang (-6PM, -6PV, cercle de sang : Mod30% à l\'intérieur, coût PM/2 min 1PM) (L)',
      ],
    ),

    // ---- Noctambule ---------------------------------------------------------
    ClassSheetPage(
      id: 'classe_noctambule',
      sectionId: 'classes_speciales',
      title: 'Noctambule',
      className: 'Noctambule',
      classCategory: 'Classes Vampiriques',
      quote:
          'Vous souvenez-vous de la présence que vous sentez sans cesse dans votre dos quand vous êtes seul la nuit ? Vous ne m\'auriez pas oublié quand même ?',
      classBonuses: [
        '/6 Magie Nocturne',
        '/6 Ombre parmi les ombres',
        '/6 Espionnage',
      ],
      equipment: [
        EquipmentSlot(label: 'Arme', detail: '1 arme au choix'),
        EquipmentSlot(label: 'Munitions', detail: '1 emplacement'),
      ],
      affinities: ['1 Affinité au choix (sauf Explosifs)'],
      munitionSlots: 1,
      skillFormula: 'Physique/20 compétences — PM = Mental/10',
      freeSkills: [
        'Cape d\'Ombre (-1PM/tour, invisible dans les espaces sombres, seuls les yeux restent visibles)',
        'Régénération Vampirique (réussite au test de Pouvoir → +2PV ; chaque palier de 100% garantit +1PV même en cas d\'échec)',
      ],
      accessibleSkills: [
        'Brume (-1PM, conjure un nuage de brume autour de soi, peut couvrir une grande zone)',
        'Voix Ténébreuses (-1PM, projette sa voix depuis une ombre visible)',
        'Écran Noir (-2PM, plonge la zone dans l\'obscurité quasi totale)',
        'Télépathie (-2PM, uniquement la nuit, connexion mentale entre deux personnes, +1PM/pers. suppl.)',
        'Lévitation (-2PM/tour, uniquement la nuit, s\'élever et se déplacer dans les airs)',
        'Lame d\'Ombres (-2PM, crée des lames depuis une ombre, D6 dégâts)',
        'Mesmer (-3PM, l\'interlocuteur est fasciné et aura tendance à suivre vos paroles)',
        'Télékinésie (PM selon la taille et le poids, ne déplace que les objets inanimés)',
        'Forme de Brume (-3PM, invulnérable aux attaques mais ne peut attaquer physiquement)',
        'Assassinat d\'Ombre (-4PM, envoie une ombre attaquer l\'adversaire dans le dos) (L)',
        'Ombre Autonome (-6PM, détache l\'ombre du corps et y transfère la conscience, le corps est inconscient)',
      ],
    ),

    // ---- Strigoi ------------------------------------------------------------
    ClassSheetPage(
      id: 'classe_strigoi',
      sectionId: 'classes_speciales',
      title: 'Strigoi',
      className: 'Strigoi',
      classCategory: 'Classes Vampiriques',
      quote: 'On a tous un petit côté bestial...',
      classBonuses: [
        '/6 Bestialité',
        '/6 Instinct Animal',
        '/6 Sens Sauvages',
      ],
      equipment: [
        EquipmentSlot(label: 'Arme', detail: '1 arme au choix'),
        EquipmentSlot(label: 'Munitions', detail: '1 emplacement'),
      ],
      affinities: ['1 Affinité au choix (sauf Explosifs)'],
      munitionSlots: 1,
      skillFormula: 'Physique/20 compétences — PM = Mental/10',
      freeSkills: [
        'Langage des bêtes (-1PM, communiquer verbalement avec un animal)',
        'Régénération Vampirique (réussite au test de Pouvoir → +2PV ; chaque palier de 100% garantit +1PV même en cas d\'échec)',
      ],
      accessibleSkills: [
        'Communion animale (-1PM, ressent les émotions et souvenirs d\'un animal)',
        'Sensitivité Bestiale (-2PM, augmente drastiquement un de ses sens)',
        'Hybridation (-2PM, transfère l\'attribut d\'une forme animale sur sa forme humaine)',
        'Transformation Canine (-3PM, se transforme en canidé, D6 dégâts)',
        'Transformation Féline (-3PM, se transforme en félin, D4 dégâts Chats / D6 Panthères)',
        'Transformation Mammalienne (-3PM, se transforme en mammifère non prédateur)',
        'Transformation Chiroptérienne (-2PM, se transforme en Chauve-souris)',
        'Transformation Reptilienne (-3PM, se transforme en reptile, D4 dégâts, serpents exclus)',
        'Transformation Ophidienne (-3PM, se transforme en serpent, D4 + effets du venin)',
        'Transformation Aviaire (-3PM, se transforme en oiseau, D4 dégâts)',
        'Domination Animale (-4PM, prend le contrôle des animaux aux esprits faibles pendant D6 tours)',
        'Frénésie Bestiale (-6PM, change de forme sans limitation pendant D6 tours)',
      ],
    ),

    // =========================================================================
    // CLASSES DEMI-VAMPIRIQUES
    // =========================================================================

    // ---- Dampyr -------------------------------------------------------------
    ClassSheetPage(
      id: 'classe_dampyr',
      sectionId: 'classes_speciales',
      title: 'Dampyr',
      className: 'Dampyr',
      classCategory: 'Classes Demi-Vampiriques',
      quote:
          'S\'il me faut devenir un monstre pour abattre les monstres, alors je leur conseille de se cacher sous leurs lits.',
      classBonuses: [
        '/6 Sanguimancie',
        '/6 Sens Vampiriques',
        '/6 Aura de Prédateur',
      ],
      equipment: [
        EquipmentSlot(label: 'Arme', detail: '1 arme au choix'),
        EquipmentSlot(label: 'Munitions', detail: '1 emplacement'),
      ],
      affinities: ['1 Affinité au choix (sauf Explosifs)'],
      munitionSlots: 1,
      skillFormula: 'Mental/20 compétences — PM = Mental/10',
      freeSkills: [
        'Volonté d\'Humanité (-3PM, permet de résister à la soif vampirique)',
      ],
      accessibleSkills: [
        'Sixième Sens (-1PM, +20% aux jets de perception, Mod10% aux esquives)',
        'Arme de Sang (-1PM, D4=-2PV | D6=-3PV | D8=-4PV | D10=-6PV)',
        'Extraction de Sang (-1PM, attire le sang d\'une blessure ouverte, D4 dégâts + Effet Saignement)',
        'Régénération Dampyrique (-2PM pour régénérer 1PV)',
        'Absorption (-20% au jet, absorbe les PM d\'une créature vampirique, +5% au Pouvoir/PM absorbé)',
        'Tranchant Sanglant (-2PM, augmente de deux les dés de dégâts d\'une Arme Blanche)',
        'Pantin Dampyrique (-3PM, réanime et contrôle un cadavre récent pendant D6 tours) (L)',
        'Armure de sang (-3PM, nécessite du sang, absorbe D6 dégâts avant de disparaître)',
        'Sang Maudit (-4PM, Mod15% aux jets Physique, +3PV, frénésie si blessé dans cet état)',
        'Marionnette (-4PM, contrôle le corps d\'une créature contenant du sang, blessure ouverte requise) (L)',
        'Retournement des liens de sang (-5PM, contrôle mental d\'un vampire durant contact physique) (L)',
        'Aura de Dampyr (-6PM, dissipe toute influence vampirique pendant D4 tours)',
        'Éveil Vampirique (-7PM, si mis à 0PV ou moins, se rend 3D4 PV et +20% au Pouvoir)',
      ],
    ),

    // ---- Lamenuit -----------------------------------------------------------
    ClassSheetPage(
      id: 'classe_lamenuit',
      sectionId: 'classes_speciales',
      title: 'Lamenuit',
      className: 'Lamenuit',
      classCategory: 'Classes Demi-Vampiriques',
      quote: 'Je ne suis plus un humain, je ne suis pas un monstre. Je suis une arme.',
      classBonuses: [
        '/6 Agilité',
        '/6 Puissance lunaire',
        '/6 Détection de mensonges',
      ],
      equipment: [
        EquipmentSlot(label: 'Arme de Lancer', detail: 'DX (Effet) Nbr: 3 (×2)'),
        EquipmentSlot(label: 'Arme Blanche', detail: 'Coupe:DX (Effet) Estoc:DX (×2)'),
      ],
      affinities: [
        'Armes de Lancer',
        'Armes Blanches à Une Main',
        'Armes Blanches à Deux Mains',
      ],
      munitionSlots: 0,
      skillFormula: 'Mental/20 compétences — PM = Mental/10',
      freeSkills: [
        'Sceau Lunaire (résiste au pouvoir vampirique tant que le sceau est présent)',
      ],
      accessibleSkills: [
        'Saut Vampirique (-1PM, couvre une très grande distance d\'un bond)',
        'Reflet de Lune (-1PM, de nuit, lance une seconde attaque si la première touche)',
        'Lame de Corps (-1PM, attaque avec son corps comme une Arme Blanche, Cpe D4 / Est D6)',
        'Œil Nocturne (-2PM, contre les effets des illusions)',
        'Miroir Nocturne (-2PM, de nuit, crée l\'illusion d\'un double ou copie une autre personne)',
        'Tranchant Lunaire (-2PM, attaque à distance avec une Arme Blanche, -2 dégâts) (L)',
        'Appui aérien (-2PM, de nuit, prend appui sur l\'air pour se déplacer)',
        'Bénédiction de la Lune (-2PM, rend D6 PM à une cible, non valable pour le lanceur)',
        'Traque Nocturne (-3PM, de nuit, trace les déplacements d\'un individu à partir d\'un objet lui appartenant)',
        'Bilocation (-3PM, projette sa présence mentale dans un lieu précédemment visité, interaction possible uniquement de nuit)',
        'Envol de Lame (-3PM, change la direction d\'une arme de lancer en plein vol)',
        'Regard d\'Argent (-3PM, contact visuel, brûle D4 PM à la cible, D6 si sensible à l\'Effet Argent) (L)',
        'Éclair d\'argent (-3PM, attaque éclair +1 dégât, -15% à la parade adverse) (L)',
        'Phase de la Lune (-4PM, de nuit, se rend intangible pour D6 tours) (L)',
        'Voile Lunaire (-4PM, de nuit, se rend invisible pour D4 tours, +2PM/tour supplémentaire)',
        'Inversion Lunaire (-4PM, de nuit, échange sa position avec un objet visible non posé sur une surface)',
        'Ubiquité (-5PM, de nuit, se dédouble pour un court moment — 2 actions possibles)',
        'Abandon du Sceau (double les PM restants pour D6 tours, +5% Pouvoir/tour, test de Pouvoir au dernier tour)',
      ],
    ),

    // =========================================================================
    // CLASSES HUMAINES
    // =========================================================================

    // ---- Mentaliste ---------------------------------------------------------
    ClassSheetPage(
      id: 'classe_mentaliste',
      sectionId: 'classes_speciales',
      title: 'Mentaliste',
      className: 'Mentaliste',
      classCategory: 'Classes Humaines',
      quote:
          'L\'esprit humain peut être considéré comme une horloge fragile et sensible. Moi ? Je suis l\'horloger.',
      classBonuses: [
        '/6 Sensibilité Psychique',
        '/6 Raisonnement',
        '/6 Force mentale',
      ],
      equipment: [],
      affinities: [],
      munitionSlots: 0,
      skillFormula: 'Mental/20 compétences — PM = 2×[Mental/10] (Don héréditaire : PM doublés)',
      freeSkills: [
        'Scanner Mental (-1PM, appréhende l\'ambiance mentale d\'une zone)',
      ],
      accessibleSkills: [
        'Immersion Mentale (entre dans le monde mental formé par une œuvre originale)',
        'Télékinésie (-1PM pour un objet léger, coût PM augmentant avec poids et taille)',
        'Connexion Mentale (-1PM pour deux personnes, +1PM/pers. supplémentaire, ne peut être imposée)',
        'Multi-kinésie (coût PM selon poids/taille, déplace plusieurs objets, 2PM min./objet) (L)',
        'Traque Mentale (-2PM, traque la présence mentale d\'un être)',
        'Télépathie (-2PM, contact visuel requis, lit les pensées de la cible)',
        'Coquille Mentale (-2PM/tour, empêche toute intrusion mentale chez la cible) (L)',
        'Précognition (-3PM, visions d\'événements futurs probables en lien avec un sujet)',
        'Rétrocognition (-3PM, voit des événements passés liés à un lieu)',
        'Intrusion mentale (-3PM, entre dans l\'esprit de la cible, +1PM si sans contact visuel direct)',
        'Canalisation (-3PM, contact avec un esprit qui s\'exprime par la bouche du Mentaliste) (L)',
        'Lance d\'esprit (-4PM, D8 dégâts aux PM adverses, 1/6 chance d\'assommer) (L)',
        'Scalpel Mental (-4PM, incision sur n\'importe quelle surface)',
        'Vague Télékinétique (-5PM, repousse tout ce qui se trouve devant le lanceur)',
        'Lien Psychique (-5PM, entre dans l\'esprit d\'une entité de manière prolongée, voire la contrôle si faible) (L)',
        'Inception (-7PM, introduit discrètement une idée dans la psyché de la cible)',
        'Choc mental (-10PM, brûle l\'esprit : la cible perd ses PM et tombe inconsciente sans test Mental -30%) (L)',
      ],
    ),

    // ---- Occultiste ---------------------------------------------------------
    ClassSheetPage(
      id: 'classe_occultiste',
      sectionId: 'classes_speciales',
      title: 'Occultiste',
      className: 'Occultiste',
      classCategory: 'Classes Humaines',
      quote: 'Pour combattre le Mal, il faut le connaître. Et nous sommes justement de vieux amis...',
      classBonuses: [
        '/6 Savoir Occulte',
        '/6 Symbolique',
        '/6 Artefact',
      ],
      equipment: [
        EquipmentSlot(label: 'Arme', detail: '1 arme au choix'),
      ],
      affinities: [],
      munitionSlots: 0,
      skillFormula:
          'Relationnel/20 compétences — PM = Mental/10 (Don Héréditaire : présence immatérielle accrue)',
      freeSkills: [
        'Appel (-2PM, attire à soi une entité dont on connaît le nom)',
      ],
      accessibleSkills: [
        'Pacte démoniaque (lie avec un démon via un pacte : Effet / Tribut / Condition — plusieurs pactes sont dangereux)',
        'Exorcisme (contact physique requis, brise une possession ou servitude, coût selon l\'entité)',
        'Interdiction (-1PM, interdit à une entité l\'accès à un lieu, nécessite son Nom)',
        'Sigil de Traque (1PM à l\'activation, ressent la localisation de ce symbole)',
        'Mot de Charisme (-2PM/mot, les mots s\'impriment fortement sur la volonté des auditeurs) (L)',
        'Don des langues (-2PM, comprend toutes les langues, au moins partiellement)',
        'Reconstruction Occulte (-3PM, régénère le corps via des symboles tracés, +1D6 PV, effets sur le Pouvoir)',
        'Sceau de Sang (-3PM, scelle une surface ou un corps pendant D6 tours, nécessite du sang de la cible)',
        'Sceau Démoniaque (-4PM, scelle un démon en réduisant ses PM de D20, le scelle si 0 PM, nécessite son Nom)',
        'Malédiction (-4PM, Mod -20% pendant D10 tours)',
        'Convocation (-5PM, force une entité à se révéler sous sa forme véritable, nécessite son Nom)',
        'Révélation du Nom (-6PM, force une entité à révéler son Nom)',
        'Poésie Majestueuse (-6PM, donne un ordre en un Alexandrin, +1PM par Alexandrin supplémentaire) (L)',
      ],
    ),

    // ---- Inquisiteur --------------------------------------------------------
    ClassSheetPage(
      id: 'classe_inquisiteur',
      sectionId: 'classes_speciales',
      title: 'Inquisiteur',
      className: 'Inquisiteur',
      classCategory: 'Classes Humaines',
      quote:
          'Les créatures des abysses brûleront toutes en enfer, et j\'espère pouvoir tenir l\'allumette.',
      classBonuses: ['/6 Foi', '/6 Inquisition', '/6 Théologie'],
      equipment: [
        EquipmentSlot(label: 'Arme Blanche', detail: 'Coupe:DX (Effet) Estoc:DX'),
        EquipmentSlot(
          label: 'Arme à Feu',
          detail: 'D6 max (Effet) Calibre Rechargement:x Bar[-/-/-/-/-/-] S.A',
        ),
        EquipmentSlot(label: 'Munitions', detail: '1 emplacement'),
      ],
      affinities: ['Armes blanche à une main', 'Armes à feu'],
      munitionSlots: 1,
      skillFormula:
          'Physique/20 compétences — PM = Mental/10 (doit être croyant)',
      freeSkills: [
        'Protection Divine (-3PM, retarde les dégâts d\'une attaque subie de D6 tours)',
      ],
      accessibleSkills: [
        'Prière (rend 1PM par tour passé en position de prière en combat)',
        'Provocation (-1PM, focalise l\'attention de la cible sur soi)',
        'Confession (-2PM, obtient une confession par la peur, Mod15% au jet de social)',
        'Marque de Jugement (-2PM, chauffe l\'arme au rouge, +1 dégât/attaque réussie de l\'Inquisiteur sur la cible marquée)',
        'Bénédiction de l\'épée (-2PM, Effet Sacré sur une arme blanche pendant D6 tours)',
        'Zèle d\'Inquisiteur (-3PM, double les dégâts pour une attaque en récitant une prière)',
        'Purification (-3PM, brise l\'emprise mentale d\'une entité sur la cible)',
        'Bénédiction des Flammes (-4PM, Effet Incendiaire + Effet Sacré sur une arme blanche pendant D4 tours)',
        'Présentation (-4PM, brandit un symbole sacré — les attaques de lames alentours ont l\'Effet Sacré) (L)',
        'Volonté Divine (-4PM, Mod15% à toute action en accord avec la foi du personnage)',
      ],
    ),

    // ---- Homme de Foi -------------------------------------------------------
    ClassSheetPage(
      id: 'classe_homme_de_foi',
      sectionId: 'classes_speciales',
      title: 'Homme de Foi',
      className: 'Homme de Foi',
      classCategory: 'Classes Humaines',
      quote: 'Le Seigneur dans son infinie bonté a fait les vampires faciles à brûler.',
      classBonuses: ['/6 Foi', '/6 Compassion', '/6 Théologie'],
      equipment: [
        EquipmentSlot(label: 'Arme Blanche', detail: 'Coupe:DX (Effet) Estoc:DX'),
      ],
      affinities: ['Armes blanche à une main'],
      munitionSlots: 0,
      skillFormula:
          'Relationnel/20 compétences — PM = Mental/10 (doit être croyant)',
      freeSkills: [
        'Lumière sacrée (-1PM, génère de la lumière à Effet Sacré depuis sa paume levée)',
      ],
      accessibleSkills: [
        'Sermon (-1PM, enveloppe le discours de passion, Mod30% au jet de social)',
        'Concentration (-1PM/tour, Mod10% par tour passé sans être interrompu)',
        'Inspiration (-1PM, confère Mod10% à tous les alliés pour la prochaine action)',
        'Prière (rend 2PM par tour de combat passé à prier, 1×/heure hors combat)',
        'Don de Soi (-2PM, permet à la cible de consommer les PM du lanceur à sa place)',
        'Confession (-2PM, obtient une confession par la confiance, Mod15% au jet de social)',
        'Consécration (-2PM, consacre le sol autour de lui) (L)',
        'Bénédiction de l\'esprit (-2PM, donne 2PM à la cible)',
        'Bénédiction des Armes (-2PM, Effet Béni sur une arme ou un projectile pendant D6 tours)',
        'Sceau de l\'Esprit (-3PM, cible insensible aux intrusions mentales pendant 2D4 tours)',
        'Miséricorde (-3PM, rend D8 PM à la cible s\'il lui reste moins de 3PV)',
        'Exorcisme Religieux (-4PM, au contact, retire 2D6 PM en récitant un verset d\'un livre saint)',
        'Miracle (-4PM, rend D6 PV et D6 PM à la cible)',
        'Commandement Sacré (-5PM, si la cible est sensible à l\'Effet Sacré, la fait obéir à un ordre simple)',
        'Bannissement (-6PM, au contact, bannit l\'esprit si la cible n\'a plus de PM — D6 PM/tour, D12 si sensible à l\'Effet Béni) (L)',
      ],
    ),

    // =========================================================================
    // CLASSES SEMI-ANGÉLIQUES
    // =========================================================================

    // ---- Néphilim -----------------------------------------------------------
    ClassSheetPage(
      id: 'classe_nephilim',
      sectionId: 'classes_speciales',
      title: 'Néphilim',
      className: 'Néphilim',
      classCategory: 'Classes Semi-Angéliques',
      quote: 'Tout ce que je vois je peux l\'abattre. Et j\'ai de très bons yeux.',
      classBonuses: [
        '/6 Temporalité Différée',
        '/6 Tir',
        '/6 Perception Globale',
      ],
      equipment: [
        EquipmentSlot(
          label: 'Arme à Feu ×3',
          detail: 'DX (Effet) Calibre Rechargement:x Bar[-/-/-/-/-/-] S.A',
        ),
        EquipmentSlot(
          label: 'Arme à Feu ×1',
          detail: 'DX (Effet) Calibre Rechargement:x Bar[-/-/-/-/-/-] S.A',
        ),
        EquipmentSlot(label: 'Munitions', detail: '4 emplacements'),
      ],
      affinities: ['Armes à Feu', 'Armes d\'Archerie'],
      munitionSlots: 4,
      skillFormula: 'Physique/20 compétences — PM = Mental/10',
      freeSkills: [
        'Perception accélérée (-1PM, ralentit la perception du temps — Mod15% perception, Mod5% visée et esquive)',
      ],
      accessibleSkills: [
        'Double Tir (-1PM, si l\'armement le permet, tire avec deux armes dans la même action)',
        'Vision Angélique (-1PM/tour, voir quelles que soient les conditions ou l\'état des yeux)',
        'Acuité Visuelle (-1PM, remarquer des détails même à grande distance)',
        'Vision Future (-2PM, connaît la prochaine action de la cible) (L)',
        'Vision des Auras (-2PM, détecte intentions et humeur, peut révéler l\'identité)',
        'Éclat de Lumière (-2PM, crée un flash lumineux aveuglant)',
        'Verrouillage (-2PM, la cible ne peut échapper au regard même si le contact visuel est brisé)',
        'Évaluation (-3PM, jauge la puissance d\'une entité par rapport à soi ou à d\'autres)',
        'Détection des Hostiles (-3PM, ressent la présence des entités hostiles alentour)',
        'Œil de Néphilim (-3PM, pause la perception du temps durant son action)',
        'Rayon de Lumière (-3PM, rayon lumineux depuis la main, D6 dégâts) (L)',
        'Marque de Chasse (-4PM, ressent la présence de la cible marquée, Mod10% à toutes les prochaines attaques sur elle)',
        'Vision Prédictive (-4PM, voit la cible quelques instants dans le futur — empêche l\'esquive) (L)',
        'Divine Vélocité (-5PM, arrête le temps pour le lanceur durant 2 actions, -2PM/action supplémentaire)',
      ],
    ),

    // ---- Séraphin -----------------------------------------------------------
    ClassSheetPage(
      id: 'classe_seraphin',
      sectionId: 'classes_speciales',
      title: 'Séraphin',
      className: 'Séraphin',
      classCategory: 'Classes Semi-Angéliques',
      quote:
          'Démon, vampire, lycanthropes, goules… Tant de noms pour un seul adjectif : coupable.',
      classBonuses: [
        '/6 Escrime',
        '/6 Jugement',
        '/6 Présence',
      ],
      equipment: [
        EquipmentSlot(label: 'Arme blanche', detail: 'Coupe:DX (Effet) Estoc:DX'),
      ],
      affinities: ['Arme blanche à deux mains'],
      munitionSlots: 0,
      skillFormula: 'Physique/20 compétences — PM = Mental/10',
      freeSkills: [
        'Sentence (-1PM, accuse la cible en l\'attaquant — 2e dé de dégâts si coupable, -3PM supplémentaire si innocente) (L)',
      ],
      accessibleSkills: [
        'Injonction (-1PM, pose une question à la cible, elle perd D4 PM si elle ment)',
        'Purification (-1PV, -1PM, donne du sang pour purifier un liquide et lui conférer l\'Effet Sacré)',
        'Aura Angélique (-1PM/tour, émet une lumière autour de lui)',
        'Pardon (-2PM, contact requis, brûle l\'esprit de la cible pour D6 dégâts aux PM)',
        'Jugement (-2PM, perçoit les péchés d\'un individu, contact visuel requis — conséquences importantes)',
        'Volonté de Fer (-2PM, réduit de D4 les dégâts d\'une attaque subie)',
        'Flambeau (-2PM, enflamme son arme — lumière + Effet Incendiaire)',
        'Abnégation (-3PM, divise tout dégât subi par 2 pendant D8 tours, arrondi à l\'inférieur) (L)',
        'Auréole (-3PM, irradie de lumière à Effet Sacré)',
        'Second Souffle (-3PM, permet de garder 1PV en cas de dégât mortel)',
        'Condamnation (-4PM, déclenche une combustion spontanée — la cible subit Effet Enflammé Aggravé)',
        'Représailles (-4PM, riposte en ajoutant la moitié des dégâts subis au dernier jet de dégâts)',
        'Bûcher Sacré (-5PM, enflamme une zone — Effets Incendiaire Aggravé + Sacré pendant D6+2 tours) (L)',
        'Sanctification (-6PM, rend une zone consacrée où l\'utilisation de PM est impossible sauf pour le lanceur) (L)',
      ],
    ),

    // ---- Chérubin -----------------------------------------------------------
    ClassSheetPage(
      id: 'classe_cherubin',
      sectionId: 'classes_speciales',
      title: 'Chérubin',
      className: 'Chérubin',
      classCategory: 'Classes Semi-Angéliques',
      quote: 'Le monde ne serait pas si dangereux si le bien et le mal étaient clairement définis.',
      classBonuses: [
        '/6 Soin',
        '/6 Empathie',
        '/6 Intuition Médicale',
      ],
      equipment: [
        EquipmentSlot(
          label: 'Arme',
          detail: 'Arme Blanche Coupe:D6 max Estoc:D6 max OU Arme à Feu D6 max Calibre Rechargement:x Bar[-/-/-/-/-/-] S.A',
        ),
        EquipmentSlot(label: 'Kit', detail: 'Kit de Chirurgie'),
        EquipmentSlot(label: 'Munitions', detail: '1 emplacement'),
      ],
      affinities: ['Armes blanche à une main'],
      munitionSlots: 1,
      skillFormula: 'Mental/20 compétences — PM = Mental/10',
      freeSkills: [
        'Imposition des mains (X PM, rend X PV à la cible au contact)',
      ],
      accessibleSkills: [
        'Don des langues (communique oralement dans n\'importe quel langage)',
        'Soin Rapide (-1PM, rend immédiatement 2PV à une cible visible) (L)',
        'Anesthésie (-1PM, inhibe la douleur et retire les malus de blessures)',
        'Compassion (-2PM, ressent les émotions et le vécu d\'une créature, consciente ou non)',
        'Bénédiction du Seuil (-2PM, sur un seuil, empêche les créatures sensibles à l\'Effet Sacré de passer)',
        'Lumière Intérieure (-2PM, renforce la volonté de la cible, lui rend D4 PM)',
        'Accélération métabolique (-3PM, la cible se soigne d\'1PV en dépensant 1PE/tour pendant D6 tours)',
        'Cercle de Soin (-3PM, tous les êtres alentours se soignent de 1D4 PV)',
        'Ataraxie (-3PM, cible ignore les dégâts subis pendant D4 tours, pris en compte au dernier tour)',
        'Guérison (-4PM, guérit entièrement une blessure subie il y a moins de 3 tours) (L)',
        'Nexus Mental (-5PM, crée une connexion entre les PJ mettant en commun les PM) (L)',
        'Miroir Défensif (-6PM, ignore les dégâts d\'une attaque subie et les renvoie à son lanceur) (L)',
        'Lazare (-6PM, ramène un mort récent à la vie avec 2PV et 2PM, -1PM par PV ou PM additionnel)',
      ],
    ),
  ],
);
