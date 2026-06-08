import 'package:flutter/widgets.dart';

/// Remplace la page courante (typiquement un formulaire de création) par une
/// instance *fraîche* de [routeName].
///
/// À utiliser à la place de `Navigator.pushReplacementNamed(...)` quand on
/// revient vers une liste ou un menu après avoir validé un formulaire. Résout
/// deux problèmes d'un coup :
///
/// * **Doublons de page** : si [routeName] est déjà ouverte plus bas dans la
///   pile (ex. la liste depuis laquelle on a ouvert le formulaire), un simple
///   `pushReplacementNamed` empilerait une 2e instance par-dessus l'ancienne ;
///   la flèche de retour repasserait alors sur une page identique avant de
///   réellement revenir en arrière. Ici l'ancienne instance est retirée.
/// * **Données périmées** : la nouvelle instance est reconstruite, donc son
///   `initState` recharge les données et la liste affiche bien la création.
///
/// La pile sous la cible est préservée : on s'arrête au premier écran qui n'est
/// ni le formulaire courant ni une instance de [routeName]. Le formulaire peut
/// donc indifféremment avoir été ouvert depuis un menu ou depuis la liste.
void replaceWithFreshRoute(BuildContext context, String routeName) {
  final currentName = ModalRoute.of(context)?.settings.name;
  Navigator.of(context).pushNamedAndRemoveUntil(
    routeName,
    (route) =>
        route.settings.name != routeName && route.settings.name != currentName,
  );
}
