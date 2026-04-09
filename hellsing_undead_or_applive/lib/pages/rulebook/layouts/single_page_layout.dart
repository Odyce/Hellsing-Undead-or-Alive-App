import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';

/// Layout mobile : une page visible à la fois, animée par [PageFlipWidget].
///
/// Reçoit les pages déjà construites et un controller externe pour permettre
/// au parent de déclencher des sauts programmatiques (`goToPage`).
class SinglePageLayout extends StatelessWidget {
  final List<Widget> pages;
  final GlobalKey<PageFlipWidgetState> controller;

  const SinglePageLayout({
    super.key,
    required this.pages,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 600,
        height: 800,
        child: PageFlipWidget(
          key: controller,
          backgroundColor: Colors.transparent,
          children: pages,
        ),
      ),
    );
  }
}
