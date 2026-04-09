import '../annex_sheet.dart';
import '../book_index.dart';
import 'section_cover_intro.dart';
import 'section_creation.dart';
import 'section_races.dart';
import 'section_classes_communes.dart';
import 'section_classes_speciales.dart';
import 'section_regles.dart';
import 'section_effets.dart';

/// Sections du livre dans leur ordre de pagination définitif.
const _sections = [
  sectionCover,
  sectionIntro,
  sectionCreation,
  sectionRaces,
  sectionClassesCommunes,
  sectionClassesSpeciales,
  sectionRegles,
  sectionEffets,
];

/// Fiches annexes accessibles via des liens internes (aucune pour l'instant).
const _annexes = <AnnexSheet>[];

/// Construit l'index complet du livre de règles.
BookIndex buildBookIndex() {
  return BookIndex.build(
    rawSections: _sections,
    rawAnnexes: _annexes,
  );
}
