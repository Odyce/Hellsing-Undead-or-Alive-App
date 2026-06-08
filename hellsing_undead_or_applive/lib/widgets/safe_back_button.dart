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

    // Seule route de la pile : pas de page précédente, on retombe sur l'accueil
    // pour éviter un écran vide (lien profond, état restauré, etc.).
    if (!nav.canPop()) {
      nav.pushReplacementNamed(Routes.home);
      return;
    }

    final currentName = ModalRoute.of(context)?.settings.name;

    // Si on ne connaît pas le nom de la route courante, on se contente d'un
    // pop simple pour ne pas risquer de sauter des pages par erreur.
    if (currentName == null) {
      nav.pop();
      return;
    }

    // Pop la page courante, puis saute toute page identique empilée juste en
    // dessous (ex. un menu réaffiché via pushReplacement après un formulaire),
    // jusqu'à atteindre une page réellement différente. `route.isFirst` garantit
    // qu'on ne pop jamais la route racine.
    nav.popUntil(
      (route) => route.isFirst || route.settings.name != currentName,
    );
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
