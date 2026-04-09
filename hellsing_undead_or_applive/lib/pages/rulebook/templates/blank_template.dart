import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/rulebook/book_page.dart';
import '../widgets/page_frame.dart';

/// Gabarit pour une page blanche (alignement double-page).
/// Affiche le fond parchemin sans contenu.
class BlankTemplate extends StatelessWidget {
  final BlankPage page;
  final int? pageNumber;

  const BlankTemplate({super.key, required this.page, this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      pageNumber: pageNumber,
      child: const SizedBox.shrink(),
    );
  }
}
