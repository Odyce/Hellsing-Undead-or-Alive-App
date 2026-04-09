import 'rich_content.dart';

/// Données d'un emplacement d'équipement pour les fiches de classe.
class EquipmentSlot {
  final String label;
  final String detail;

  const EquipmentSlot({required this.label, required this.detail});
}

/// Entrée d'arme pour les tableaux d'armes.
class WeaponEntry {
  final String name;
  final String flavorText;
  final String damage;
  final String? effect;
  final String? characteristics;
  final int price;

  const WeaponEntry({
    required this.name,
    this.flavorText = '',
    required this.damage,
    this.effect,
    this.characteristics,
    required this.price,
  });
}

/// Entrée d'effet pour la liste des effets.
class EffectEntry {
  final String name;
  final String description;
  final String? aggravatedDescription;

  const EffectEntry({
    required this.name,
    required this.description,
    this.aggravatedDescription,
  });
}

// ---------------------------------------------------------------------------
// BookPage — sealed class racine
// ---------------------------------------------------------------------------

/// Classe racine pour toutes les pages du livre de règles.
///
/// Sealed : le compilateur force l'exhaustivité dans les switch expressions,
/// garantissant que tout nouveau type de page est pris en charge partout.
sealed class BookPage {
  /// Identifiant stable, utilisé pour les liens internes. Jamais un numéro.
  final String id;

  /// Section à laquelle appartient cette page.
  final String sectionId;

  /// Titre optionnel (historique, popup de lien, recherche).
  final String? title;

  const BookPage({
    required this.id,
    required this.sectionId,
    this.title,
  });
}

// ---------------------------------------------------------------------------
// Sous-types
// ---------------------------------------------------------------------------

/// Page de couverture du livre.
class CoverPage extends BookPage {
  final String? assetPath;

  const CoverPage({
    required super.id,
    required super.sectionId,
    super.title,
    this.assetPath,
  });
}

/// Page d'introduction d'un chapitre.
class ChapterIntroPage extends BookPage {
  final RichContent body;
  final String? assetPath;

  const ChapterIntroPage({
    required super.id,
    required super.sectionId,
    super.title,
    required this.body,
    this.assetPath,
  });
}

/// Page de texte long (règles narratives, explications).
class FlowTextPage extends BookPage {
  final RichContent body;

  const FlowTextPage({
    required super.id,
    required super.sectionId,
    super.title,
    required this.body,
  });
}

/// Fiche de race (Vampire, Demi-Vampire, Humain, Semi-Ange).
class RaceSheetPage extends BookPage {
  final String raceName;
  final RichContent description;
  final List<String> bonuses;
  final List<String> maluses;
  final List<String> accessibleClasses;
  final String? illustrationAsset;

  const RaceSheetPage({
    required super.id,
    required super.sectionId,
    super.title,
    required this.raceName,
    required this.description,
    required this.bonuses,
    required this.maluses,
    required this.accessibleClasses,
    this.illustrationAsset,
  });
}

/// Fiche de classe (Fusiller, Bretteur, Nosferatu, etc.).
class ClassSheetPage extends BookPage {
  final String className;
  final String classCategory;
  final String quote;
  final List<String> classBonuses;
  final List<EquipmentSlot> equipment;
  final List<String> affinities;
  final int munitionSlots;
  final String skillFormula;
  final List<String> freeSkills;
  final List<String> accessibleSkills;
  final String? note;

  const ClassSheetPage({
    required super.id,
    required super.sectionId,
    super.title,
    required this.className,
    required this.classCategory,
    required this.quote,
    required this.classBonuses,
    required this.equipment,
    required this.affinities,
    required this.munitionSlots,
    required this.skillFormula,
    required this.freeSkills,
    required this.accessibleSkills,
    this.note,
  });
}

/// Tableau d'armes (armes blanches à une main, armes à feu, etc.).
class WeaponTablePage extends BookPage {
  final String category;
  final List<WeaponEntry> weapons;

  const WeaponTablePage({
    required super.id,
    required super.sectionId,
    super.title,
    required this.category,
    required this.weapons,
  });
}

/// Liste des effets (Béni, Sacré, Argent, etc.).
class EffectListPage extends BookPage {
  final List<EffectEntry> effects;

  const EffectListPage({
    required super.id,
    required super.sectionId,
    super.title,
    required this.effects,
  });
}

/// Page blanche numérotée (pour aligner les chapitres en double page).
class BlankPage extends BookPage {
  const BlankPage({
    required super.id,
    required super.sectionId,
  });
}

/// Illustration plein cadre sans texte.
class FullIllustrationPage extends BookPage {
  final String assetPath;

  const FullIllustrationPage({
    required super.id,
    required super.sectionId,
    super.title,
    required this.assetPath,
  });
}
