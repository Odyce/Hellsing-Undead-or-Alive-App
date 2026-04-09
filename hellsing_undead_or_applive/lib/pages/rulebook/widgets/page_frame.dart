import 'package:flutter/material.dart';

/// Cadre de base partagé par tous les gabarits de page du livre.
///
/// Fournit : fond parchemin, marges internes, numéro de page optionnel.
class PageFrame extends StatelessWidget {
  final Widget child;

  /// Numéro de page affiché en bas de page. Null = pas de numéro (couverture,
  /// page blanche, illustration plein cadre).
  final int? pageNumber;

  const PageFrame({super.key, required this.child, this.pageNumber});

  static const _textColor = Color(0xFF5C3A1E);

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF3E6C8),
          image: DecorationImage(
            image: AssetImage("assets/images/parchment.jpg"),
            fit: BoxFit.fill,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(40, 48, 40, 52),
                child: child,
              ),
            ),
            if (pageNumber != null)
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Text(
                  '— $pageNumber —',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'EBGaramond',
                    fontSize: 13,
                    color: _textColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
