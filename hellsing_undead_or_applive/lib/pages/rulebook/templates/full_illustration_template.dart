import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_page.dart';

/// Gabarit pour une illustration plein cadre sans texte.
/// Pas de fond parchemin — l'image occupe tout l'espace.
class FullIllustrationTemplate extends StatelessWidget {
  final FullIllustrationPage page;

  const FullIllustrationTemplate({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Image(
        image: AssetImage(page.assetPath),
        fit: BoxFit.cover,
      ),
    );
  }
}
