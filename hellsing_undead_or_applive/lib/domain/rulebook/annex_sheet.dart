import 'rich_content.dart';

/// Fiche annexe : contenu hors pagination principale.
///
/// Accessible uniquement via des liens depuis le livre.
/// Pas de numéro de page, pas de navigation séquentielle entre annexes.
class AnnexSheet {
  /// Identifiant stable, résolu par BookIndex.
  final String id;

  /// Titre affiché dans la popup de lien et en haut de l'annexe.
  final String title;

  /// Contenu riche de la fiche.
  final RichContent body;

  /// Illustration optionnelle.
  final String? illustrationAsset;

  const AnnexSheet({
    required this.id,
    required this.title,
    required this.body,
    this.illustrationAsset,
  });

  /// Collecte tous les targetId des liens pour validation.
  Iterable<String> get allLinkTargetIds => body.allLinkTargetIds;
}
