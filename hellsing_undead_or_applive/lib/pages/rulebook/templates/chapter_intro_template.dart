import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_page.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/rich_content.dart';
import '../widgets/page_frame.dart';
import '../widgets/rich_content_renderer.dart';

/// Gabarit pour une page d'introduction de chapitre.
///
/// Affiche : titre principal (Cinzel Decorative, grand), trait décoratif,
/// corps de texte riche avec défilement si nécessaire.
class ChapterIntroTemplate extends StatelessWidget {
  final ChapterIntroPage page;
  final int? pageNumber;
  final void Function(String targetId, LinkStyle style, Offset globalPosition)?
      onLinkTap;

  const ChapterIntroTemplate({
    super.key,
    required this.page,
    this.pageNumber,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      pageNumber: pageNumber,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (page.title != null) ...[
            Text(
              page.title!,
              style: const TextStyle(
                fontFamily: 'Cinzel Decorative',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B2410),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF8B0000), thickness: 1.5),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: SingleChildScrollView(
              child: RichContentRenderer(
                content: page.body,
                onLinkTap: onLinkTap,
                baseStyle: const TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
