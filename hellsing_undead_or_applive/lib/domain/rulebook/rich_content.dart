/// Modèle de texte riche avec liens inline pour le livre de règles.
///
/// Utilisé dans les pages du livre pour afficher du texte formaté
/// contenant des liens internes (vers d'autres pages ou des fiches annexes).

/// Indice de style pour un fragment de texte.
enum TextStyleHint {
  normal,
  bold,
  italic,
  boldItalic,
  small,
  heading,
}

/// Style de lien dans le texte.
enum LinkStyle {
  /// Lien coloré, visible, tap = saut immédiat.
  direct,

  /// Lien discret, tap = popup avec titre, puis confirmation pour sauter.
  discreet,
}

/// Un noeud inline dans un contenu riche (sealed pour exhaustivité au switch).
sealed class InlineNode {
  const InlineNode();
}

/// Fragment de texte brut avec style optionnel.
class TextNode extends InlineNode {
  final String text;
  final TextStyleHint style;

  const TextNode(this.text, {this.style = TextStyleHint.normal});
}

/// Lien vers une page du livre ou une fiche annexe.
class LinkNode extends InlineNode {
  final String text;
  final String targetId;
  final LinkStyle linkStyle;

  const LinkNode({
    required this.text,
    required this.targetId,
    this.linkStyle = LinkStyle.direct,
  });
}

/// Saut de ligne simple (<br>).
class LineBreakNode extends InlineNode {
  const LineBreakNode();
}

/// Saut de paragraphe (espacement plus grand).
class ParagraphBreakNode extends InlineNode {
  const ParagraphBreakNode();
}

/// Contenu riche : une liste ordonnée de noeuds inline.
class RichContent {
  final List<InlineNode> nodes;

  const RichContent(this.nodes);

  /// Contenu vide.
  static const empty = RichContent([]);

  /// Raccourci pour du texte simple sans formatage.
  factory RichContent.plain(String text) =>
      RichContent([TextNode(text)]);

  /// Extrait tout le texte brut (pour la recherche).
  String toPlainText() {
    final buffer = StringBuffer();
    for (final node in nodes) {
      switch (node) {
        case TextNode n:
          buffer.write(n.text);
        case LinkNode n:
          buffer.write(n.text);
        case LineBreakNode():
          buffer.write('\n');
        case ParagraphBreakNode():
          buffer.write('\n\n');
      }
    }
    return buffer.toString();
  }

  /// Collecte tous les targetId des liens pour validation.
  Iterable<String> get allLinkTargetIds sync* {
    for (final node in nodes) {
      if (node is LinkNode) {
        yield node.targetId;
      }
    }
  }
}
