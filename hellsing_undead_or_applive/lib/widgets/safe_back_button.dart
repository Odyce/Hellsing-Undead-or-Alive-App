import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

/// Flèche de retour unifiée : remonte la pile de navigation si possible,
/// sinon retombe sur [Routes.home] pour éviter un écran vide quand la page
/// est la seule route (ouverture via lien profond, état restauré, etc.).
///
/// Forme et couleur identiques au [BackButton] standard, donc visuellement
/// indiscernable de la flèche implicite d'une [AppBar].
class SafeBackButton extends StatelessWidget {
  final Color? color;

  const SafeBackButton({super.key, this.color});

  static void pop(BuildContext context) {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackButton(
      color: color,
      onPressed: () => pop(context),
    );
  }
}

/// Variante pour les pages sans [AppBar] : positionne un [SafeBackButton]
/// en haut à gauche, au-dessus du contenu, dans la zone sûre de l'écran.
///
/// Usage :
/// ```dart
/// Scaffold(
///   body: Stack(children: [contenu, const SafeBackButtonOverlay()]),
/// )
/// ```
class SafeBackButtonOverlay extends StatelessWidget {
  final Color? color;

  const SafeBackButtonOverlay({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SafeBackButton(color: color),
        ),
      ),
    );
  }
}
