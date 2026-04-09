import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_page.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/rich_content.dart';
import '../widgets/page_frame.dart';
import '../widgets/rich_content_renderer.dart';

/// Gabarit pour une page de texte courant (règles, explications).
///
/// Titre (Cinzel Decorative) + trait + corps défilant.
class FlowTextTemplate extends StatelessWidget {
  final FlowTextPage page;
  final int? pageNumber;
  final void Function(String targetId, LinkStyle style, Offset globalPosition)?
      onLinkTap;

  const FlowTextTemplate({
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3B2410),
              ),
            ),
            const SizedBox(height: 6),
            const Divider(color: Color(0xFF5C3A1E), thickness: 0.8),
            const SizedBox(height: 14),
          ],
          Expanded(
            child: SingleChildScrollView(
              child: RichContentRenderer(
                content: page.body,
                onLinkTap: onLinkTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
