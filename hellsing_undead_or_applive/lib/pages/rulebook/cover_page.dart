import 'dart:ui';
import 'package:flutter/material.dart';

class VictorianCoverPage extends StatelessWidget {
  final String title;
  final ImageProvider image;
  final bool isBackCover;
  final void Function(int pageIndex) onGoToPage;

  /// Optionnel: un petit texte en bas (ex: "Tome I", "Édition 1876", etc.)
  final String? footer;

  const VictorianCoverPage({
    super.key,
    required this.title,
    required this.image,
    this.isBackCover = false,
    this.footer,
    required this.onGoToPage
  });

  @override
  Widget build(BuildContext context) {
    // Même si cover = peu de contenu, on met un ScrollView pour respecter ton besoin “si ça dépasse”.
    return LayoutBuilder(
      builder: (context, constraints) {
        final pagePadding = EdgeInsets.symmetric(
          horizontal: constraints.maxWidth * 0.08,
          vertical: constraints.maxHeight * 0.08,
        );

        return Container(
          // “Cuir victorien” : texture + léger vignettage
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/textures/leather.jpg'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: 1,
                offset: Offset(0, 10),
                color: Colors.black26,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Grain par-dessus (optionnel)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.18,
                  child: Image.asset(
                    'assets/textures/grain.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Vignettage léger
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.35),
                      ],
                    ),
                  ),
                ),
              ),

              // Cadre doré + contenu
              Padding(
                padding: pagePadding,
                child: _GoldFrame(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 0.6, sigmaY: 0.6),
                      child: Container(
                        color: Colors.black.withOpacity(0.10),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight - pagePadding.vertical,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 12),

                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        height: 1.1,
                                        color: const Color(0xFFF2E6C9), // ivoire
                                        shadows: const [
                                          Shadow(
                                            blurRadius: 10,
                                            offset: Offset(0, 2),
                                            color: Colors.black45,
                                          )
                                        ],
                                      ),
                                ),

                                const SizedBox(height: 22),

                                // Image sous le texte (centrée)
                                AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFFD6B25E),
                                          width: 2,
                                        ),
                                      ),
                                      child: Image(
                                        image: image,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),

                                if (footer != null) ...[
                                  const SizedBox(height: 22),
                                  Text(
                                    footer!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: const Color(0xFFE9D8B0),
                                          letterSpacing: 0.8,
                                        ),
                                  ),
                                ],

                                // Petit repère discret si tu veux distinguer 4e de couverture
                                if (isBackCover) ...[
                                  const SizedBox(height: 18),
                                  Opacity(
                                    opacity: 0.7,
                                    child: Text(
                                      "— Fin —",
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: const Color(0xFFE9D8B0),
                                            letterSpacing: 1.0,
                                          ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GoldFrame extends StatelessWidget {
  final Widget child;
  const _GoldFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE2C170),
            Color(0xFFB58A2A),
            Color(0xFFF1D58A),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF3B2A12), width: 2),
          color: Colors.transparent,
        ),
        child: child,
      ),
    );
  }
}
