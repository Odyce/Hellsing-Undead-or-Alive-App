import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/annex_sheet.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/rich_content.dart';
import '../widgets/rich_content_renderer.dart';

/// Gabarit pour une fiche annexe.
///
/// Contrairement aux pages du livre principal, une annexe possède sa propre
/// barre de titre fixe (hors [PageFrame]) avec un bouton "Fermer" intégré,
/// pour signaler visuellement que l'on est sorti de la pagination normale.
/// L'animation d'entrée/sortie (slide vertical) est gérée par [BookViewerPage].
class AnnexTemplate extends StatelessWidget {
  final AnnexSheet annex;
  final VoidCallback onClose;
  final void Function(String targetId, LinkStyle style, Offset globalPosition)?
      onLinkTap;

  const AnnexTemplate({
    super.key,
    required this.annex,
    required this.onClose,
    this.onLinkTap,
  });

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
        child: Column(
          children: [
            // ---- Barre de titre fixe ----------------------------------------
            _AnnexHeader(title: annex.title, onClose: onClose),

            // ---- Contenu défilant -------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
                child: RichContentRenderer(
                  content: annex.body,
                  onLinkTap: onLinkTap,
                  baseStyle: const TextStyle(fontSize: 16),
                  paragraphSpacing: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Barre de titre interne
// ---------------------------------------------------------------------------

class _AnnexHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _AnnexHeader({required this.title, required this.onClose});

  static const _blood = Color(0xFF8B0000);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _blood,
        // Légère ombre vers le bas pour séparer header et contenu.
        boxShadow: [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icône "document"
          const Icon(Icons.menu_book, color: Colors.white70, size: 18),
          const SizedBox(width: 8),

          // Label "ANNEXE" + titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'FICHE ANNEXE',
                  style: TextStyle(
                    fontFamily: 'Cinzel Decorative',
                    fontSize: 9,
                    letterSpacing: 2,
                    color: Colors.white54,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Cinzel Decorative',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Bouton fermer
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white38),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.keyboard_return, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Retour au livre',
                    style: TextStyle(
                      fontFamily: 'EBGaramond',
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
