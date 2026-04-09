import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_page.dart';

/// Gabarit pour la page de couverture.
///
/// Si [page.assetPath] est fourni, affiche l'image en plein cadre.
/// Sinon, affiche le titre centré sur fond parchemin.
class CoverTemplate extends StatelessWidget {
  final CoverPage page;

  const CoverTemplate({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    if (page.assetPath != null) {
      return SizedBox.expand(
        child: Image(
          image: AssetImage(page.assetPath!),
          fit: BoxFit.cover,
        ),
      );
    }

    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF3E6C8),
          image: DecorationImage(
            image: AssetImage("assets/images/parchment.jpg"),
            fit: BoxFit.fill,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              page.title ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Cinzel Decorative',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B2410),
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
