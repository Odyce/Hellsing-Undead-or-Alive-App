import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/rich_content.dart';

/// Convertit un [RichContent] en widgets Flutter.
///
/// Les [ParagraphBreakNode] créent une séparation verticale entre les blocs
/// de texte. Les [LineBreakNode] restent dans le même bloc (simple \n).
/// Les [LinkNode] reçoivent un style coloré et appellent [onLinkTap].
///
/// La signature de [onLinkTap] inclut la position globale du tap pour
/// permettre à l'appelant de positionner une popup de lien discret.
class RichContentRenderer extends StatelessWidget {
  final RichContent content;

  /// Appelé quand l'utilisateur tape sur un lien.
  /// [globalPosition] = position du tap en coordonnées écran.
  final void Function(
    String targetId,
    LinkStyle style,
    Offset globalPosition,
  )? onLinkTap;

  /// Style de base pour le texte. Fusionné par-dessus le style par défaut.
  final TextStyle? baseStyle;

  /// Espacement vertical entre deux paragraphes (points Flutter).
  final double paragraphSpacing;

  const RichContentRenderer({
    super.key,
    required this.content,
    this.onLinkTap,
    this.baseStyle,
    this.paragraphSpacing = 12,
  });

  static const _defaultStyle = TextStyle(
    fontFamily: 'EBGaramond',
    fontSize: 16,
    height: 1.5,
    color: Color(0xFF3B2410),
  );

  static const _directLinkColor = Color(0xFF8B0000);
  static const _discreetLinkColor = Color(0xFF5C3A1E);

  @override
  Widget build(BuildContext context) {
    final effective = _defaultStyle.merge(baseStyle);
    final paragraphs = _splitToParagraphs(content.nodes);

    if (paragraphs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) SizedBox(height: paragraphSpacing),
          Text.rich(
            TextSpan(
              style: effective,
              children: paragraphs[i]
                  .map((node) => _buildSpan(node, effective))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------

  List<List<InlineNode>> _splitToParagraphs(List<InlineNode> nodes) {
    final paragraphs = <List<InlineNode>>[];
    var current = <InlineNode>[];
    for (final node in nodes) {
      if (node is ParagraphBreakNode) {
        if (current.isNotEmpty) {
          paragraphs.add(current);
          current = [];
        }
      } else {
        current.add(node);
      }
    }
    if (current.isNotEmpty) paragraphs.add(current);
    return paragraphs;
  }

  InlineSpan _buildSpan(InlineNode node, TextStyle base) {
    return switch (node) {
      TextNode n => TextSpan(
          text: n.text,
          style: _styleForHint(n.style, base),
        ),
      LinkNode n => _buildLinkSpan(n, base),
      LineBreakNode() => const TextSpan(text: '\n'),
      ParagraphBreakNode() => const TextSpan(text: ''),
    };
  }

  /// Construit un span de lien avec capture de position du tap.
  ///
  /// Chaque appel crée sa propre variable [tapPos] capturée par les closures,
  /// ce qui permet d'avoir la position exacte du tap sur ce lien précis.
  TextSpan _buildLinkSpan(LinkNode n, TextStyle base) {
    Offset tapPos = Offset.zero;

    final color = n.linkStyle == LinkStyle.direct
        ? _directLinkColor
        : _discreetLinkColor;

    return TextSpan(
      text: n.text,
      style: base.copyWith(
        color: color,
        decoration: TextDecoration.underline,
        decorationColor: color,
        // Les liens discrets ont une décoration moins visible.
        decorationStyle: n.linkStyle == LinkStyle.discreet
            ? TextDecorationStyle.dotted
            : TextDecorationStyle.solid,
      ),
      recognizer: onLinkTap != null
          ? (TapGestureRecognizer()
            ..onTapDown = (d) {
              tapPos = d.globalPosition;
            }
            ..onTap = () => onLinkTap!(n.targetId, n.linkStyle, tapPos))
          : null,
    );
  }

  TextStyle _styleForHint(TextStyleHint hint, TextStyle base) {
    return switch (hint) {
      TextStyleHint.normal => base,
      TextStyleHint.bold => base.copyWith(fontWeight: FontWeight.bold),
      TextStyleHint.italic => base.copyWith(fontStyle: FontStyle.italic),
      TextStyleHint.boldItalic => base.copyWith(
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
        ),
      TextStyleHint.small =>
        base.copyWith(fontSize: (base.fontSize ?? 16) * 0.82),
      TextStyleHint.heading => base.copyWith(
          fontSize: (base.fontSize ?? 16) * 1.25,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cinzel Decorative',
        ),
    };
  }
}
