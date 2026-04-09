# Module Book Viewer — Architecture & Spécifications

> **À lire en premier (pour Claude ou tout nouveau contributeur)** : ce document est la source de vérité pour la refonte du module d'affichage du livre de règles. Il contient le contexte projet, les décisions de design, l'architecture en couches, et le plan d'implémentation. Lis-le entièrement avant de toucher au code. Le PDF du livre de règles (`Règle_Hellsing_V5_3_format_livre.pdf`) est le contenu source à porter dans le nouveau module.

---

## 1. Contexte projet

### 1.1 L'application

Application **Flutter** dédiée au JDR maison **"Undead or Alive — Hellsing Foundation"** (V5.3 actuellement). Univers victorien occulte (Londres, 1873) inspiré de Hellsing : la Fondation Hellsing chasse les Midians (vampires, loups-garous, démons, etc.). L'app sert de compagnon aux joueurs et au MJ.

### 1.2 Plateformes cibles

- **Immédiat** : Android (tactile, écrans variés, portrait probable) et Windows (souris/clavier, grand écran, paysage).
- **Plus tard, à voir** : Web, Linux, iOS. À ne pas anticiper dans le code dès maintenant, mais ne pas faire de choix qui les bloqueraient irrémédiablement.

### 1.3 Le module concerné

Module **"livre de règles interactif"**. Doit afficher l'intégralité du contenu du PDF des règles sous forme d'un vrai livre numérique navigable, avec animations de tournage de pages, liens internes, fiches annexes, et recherche.

### 1.4 État actuel (à remplacer entièrement)

Prototype minimal avec trois fichiers :

- `book_viewer_page.dart` : tout le contenu hardcodé dans le widget, utilise `PageFlipWidget` du package `page_flip`.
- `book_page_template.dart` : un seul template monolithique (titre + texte scrollable sur fond parchemin).
- `book_page_model.dart` : un modèle simpliste (`type`, `title`, `content: String`, `imageUrl`).

**Limitations bloquantes du prototype** :
- Aucune structure pour des pages spécialisées (fiches de classe, tableaux d'armes, listes d'effets).
- Pas de système de navigation, de liens internes, ni d'historique.
- Pas de pagination contrôlée — tout est listé en dur dans le `build`.
- Pas de fiches annexes.
- Aucune adaptation responsive entre Android et Windows.

---

## 2. Objectifs et exigences fonctionnelles

### 2.1 Pagination et structure

- **Hybride** : sections avec templates fixes par catégorie de contenu, mais scroll vertical interne autorisé si une page déborde de l'écran.
- **Numérotation stable et continue** comme un vrai livre. Le numéro d'une page donnée ne doit pas changer entre deux lancements ni entre deux appareils.
- **Sections nettes** : un point clé du livre = une page dédiée. Pas de chevauchement.
- **Présentation "double page" sur desktop** : sur Windows, on affiche deux pages côte à côte façon livre ouvert. Sur Android, une seule page visible à la fois.
- **Pages spéciales acceptées dans la pagination** :
  - `BlankPage` (page blanche, juste numérotée) — utile pour faire commencer un chapitre sur une page de droite.
  - `FullIllustrationPage` (illustration plein cadre, pas de texte).

### 2.2 Navigation

- **Lecture séquentielle principale** : on tourne les pages comme dans un vrai livre, avec animations.
- **Liens internes à deux styles** :
  - **Lien direct** : coloré, visible dans le texte. Tap → saut immédiat à la page cible.
  - **Lien discret** : couleur peu visible. Tap → petite popup positionnée sous le mot, contenant le titre de la page cible en couleur visible. Tap sur la popup → saut. Tap en dehors → fermeture.
- **Historique de navigation** avec bouton "retour" qui dépile. L'historique ne s'alimente **que** sur les sauts explicites (clics sur liens, ouvertures d'annexes), pas sur le feuilletage normal. Logique calquée sur un navigateur web.
- **Recherche textuelle** via un petit bouton loupe dans un coin, qui ouvre un widget de recherche par mot-clef sur tout le contenu du livre. Les résultats sont des liens vers les pages concernées et alimentent l'historique normalement.

### 2.3 Fiches annexes

- Contenu **hors pagination principale**, accessible **uniquement** via des liens depuis le livre.
- Pas navigables entre elles (pas de "page suivante" entre fiches annexes).
- Affichées en **page temporaire** qui remplace le livre, avec une **animation différente** du tournage de pages (probablement glissement vertical ou fondu — à finaliser à l'implémentation) pour bien marquer la rupture.
- Bouton retour de l'annexe → on retombe exactement sur la page du livre où on était.

### 2.4 Animations et présentation

- **Animation d'ouverture** du livre au lancement du module (le livre s'ouvre).
- **Tournage de pages** animé (déjà fonctionnel via `page_flip` dans le prototype, à conserver ou remplacer selon les besoins responsive).
- **Animation distincte** pour l'apparition/disparition des fiches annexes.
- Petites animations sur les popups de liens discrets et sur l'overlay de recherche.

### 2.5 Contenu

- **Figé dans l'app**, pas de fetch serveur. Les règles n'évoluent pas souvent et un téléchargement serait du gâchis de ressources.
- **Doit rester facile à éditer et étendre** par le développeur (le projet est solo). Ajouter une nouvelle classe ou une nouvelle race ne doit pas demander de toucher à l'infrastructure, juste à un fichier de contenu.

---

## 3. Décisions d'architecture

### 3.1 Approche retenue : "Sections fixes + micro-flow" (template-first)

Trois approches ont été envisagées :

| Approche | Description | Verdict |
|---|---|---|
| **A. Template-first pur** | Pages 100% prédéfinies via templates remplis avec des données. | Trop rigide pour les pages narratives longues. |
| **B. Flow-based** | Le contenu coule automatiquement dans les pages selon la taille d'écran (style ePub). | Numérotation instable entre appareils → casse les liens "page X". Trop complexe à implémenter proprement. |
| **C. Hybride sections + templates** | Sections avec templates fixes, scroll interne autorisé pour le débordement, numérotation stable parce que tout est défini statiquement. | **Retenue.** Meilleur compromis entre contrôle, stabilité et souplesse. |

**Raison principale du choix C** : le contenu du livre est très tabulaire et répétitif (10+ classes avec exactement le même layout, fiches de races, tableaux d'armes, listes d'effets). Ce contenu se prête idéalement à des templates, et la stabilité de pagination est non négociable pour les liens internes.

### 3.2 Découplage en couches

L'architecture est organisée en **5 couches**, chacune avec une responsabilité claire et indépendante :

```
┌─────────────────────────────────────────────────┐
│  COUCHE 5 : BookViewerPage (UI racine)          │
│  - Layout double/simple page selon plateforme   │
│  - Animations d'ouverture                       │
│  - Overlays (popups, annexes, recherche)        │
├─────────────────────────────────────────────────┤
│  COUCHE 4 : BookNavigator (service état)        │
│  - currentPageIndex, history stack              │
│  - goToPageById(), back(), openAnnex()          │
├─────────────────────────────────────────────────┤
│  COUCHE 3 : BookIndex (table des matières)     │
│  - Liste ordonnée de toutes les pages           │
│  - Map<id, pageIndex> pour résoudre les liens   │
│  - Map<id, AnnexSheet> pour les annexes         │
│  - Validation des liens au build                │
├─────────────────────────────────────────────────┤
│  COUCHE 2 : Templates (widgets Flutter)         │
│  - Un template par sous-type de BookPage        │
│  - PageFrame commun (fond, marges, numéro)      │
│  - Responsive via LayoutBuilder                 │
├─────────────────────────────────────────────────┤
│  COUCHE 1 : Modèles de données (sealed)         │
│  - BookPage (sealed) + sous-types               │
│  - RichContent avec liens inline                │
│  - AnnexSheet                                   │
└─────────────────────────────────────────────────┘
```

### 3.3 Format de stockage du contenu

**Dart `const` dans des fichiers séparés par section** (`content/section_races.dart`, `content/section_classes.dart`, etc.).

Pourquoi pas JSON/YAML :
- Pas de gain tant que le contenu est figé et que le seul éditeur est le développeur.
- Le typage Dart à la compilation détecte les erreurs structurelles tôt.
- Aucun parsing au runtime → démarrage instantané.

À reconsidérer si un jour un non-dev doit éditer le contenu, ou si le contenu devient téléchargeable.

### 3.4 Gestion de la double page (desktop)

- `BookViewerPage` détecte la largeur de la fenêtre et choisit entre `SinglePageLayout` (mobile) et `DoublePageLayout` (desktop).
- En double page : les pages paires s'affichent à gauche, les impaires à droite (ou inverse selon convention de reliure choisie à l'implémentation — convention occidentale habituelle = page 1 à droite).
- **Insertion automatique de pages blanches** : un normalizer dans `BookIndex` insère des `BlankPage` à la fin d'une section qui se termine sur une page de gauche, pour qu'un nouveau chapitre commence toujours sur une page de droite. Le contenu lui-même est écrit naturellement, sans se soucier de ça.
- Sur mobile, les pages blanches restent visibles et se feuillettent comme les autres — exactement comme dans un vrai livre.

### 3.5 Résolution des liens

- Les liens utilisent des **`id` sémantiques** (`"nosferatu"`, `"effet_argent"`, `"creation_personnage"`), **jamais** des numéros de page.
- `BookIndex` maintient une `Map<String, int>` qui résout `id → pageIndex`.
- Conséquence : insérer une nouvelle page au milieu d'une section ne casse aucun lien. Seuls les numéros affichés changent.
- **Validation au build** : à la construction de `BookIndex`, on vérifie que tous les `LinkNode.targetId` pointent vers un id existant. Assertion en mode debug → impossible de publier avec un lien cassé.

### 3.6 Conventions pour l'historique

- L'historique est une **pile**, pas une liste.
- On y push **uniquement** sur :
  - Tap sur un lien direct.
  - Tap sur un lien discret confirmé via popup.
  - Sélection d'un résultat de recherche.
  - Ouverture d'une fiche annexe.
- On ne push **jamais** sur le feuilletage manuel (swipe ou bouton page suivante).
- `back()` dépile et restaure la position précédente. Si pile vide, le bouton retour est désactivé.

---

## 4. Modèles de données (Couche 1)

### 4.1 Hiérarchie BookPage (sealed class)

```dart
sealed class BookPage {
  final String id;           // identifiant stable, utilisé pour les liens
  final String sectionId;    // appartenance à une section
  final String? title;       // pour l'historique, la popup, la recherche
  const BookPage({required this.id, required this.sectionId, this.title});
}

class CoverPage extends BookPage { ... }
class ChapterIntroPage extends BookPage {
  final RichContent body;
  ...
}
class FlowTextPage extends BookPage {
  final RichContent body;  // pour les pages de règles en texte long
  ...
}
class RaceSheetPage extends BookPage {
  final String raceName;
  final RichContent description;
  final List<RichContent> bonuses;
  final List<RichContent> maluses;
  final List<String> accessibleClasses;
  final String? illustrationAsset;
  ...
}
class ClassSheetPage extends BookPage {
  final String className;
  final String quote;
  final List<String> classBonuses;
  final List<EquipmentSlot> equipment;
  final List<String> affinities;
  final int munitionSlots;
  final List<Skill> freeSkills;
  final List<Skill> accessibleSkills;
  final String? note;        // les "N.B" du PDF
  ...
}
class WeaponTablePage extends BookPage {
  final String category;     // "Armes blanches à une main", etc.
  final List<WeaponEntry> weapons;
  ...
}
class EffectListPage extends BookPage { ... }
class BlankPage extends BookPage { ... }
class FullIllustrationPage extends BookPage {
  final String assetPath;
  ...
}
```

**Le switch sur la sealed class est exhaustif** : si on ajoute un nouveau type de page, le compilateur force à mettre à jour tous les endroits qui font un switch dessus. Excellent garde-fou.

### 4.2 Texte riche avec liens

```dart
class RichContent {
  final List<InlineNode> nodes;
}

sealed class InlineNode {}
class TextNode extends InlineNode {
  final String text;
  final TextStyleHint? hint;  // gras, italique, petit, etc.
}
class LinkNode extends InlineNode {
  final String text;
  final String targetId;      // page ou annexe
  final LinkStyle style;      // direct ou discreet
}
class LineBreakNode extends InlineNode {}
class ParagraphBreakNode extends InlineNode {}
```

`targetId` peut résoudre vers une `BookPage.id` ou une `AnnexSheet.id` — le navigator route en fonction de ce qu'il trouve dans l'index.

### 4.3 Fiches annexes

```dart
class AnnexSheet {
  final String id;
  final String title;
  final RichContent body;
  final String? illustrationAsset;
  // pas de sectionId, pas de pageNumber : hors pagination
}
```

---

## 5. Templates (Couche 2)

### 5.1 PageFrame commun

```dart
class PageFrame extends StatelessWidget {
  final Widget child;
  final int pageNumber;
  final String? runningHeader;  // ex: "Classes communes"
  // gère : fond parchemin, marges, numéro de page, ornements, polices
}
```

Toutes les pages passent par ce frame pour garantir la cohérence visuelle.

### 5.2 Liste des templates à créer

Un par sous-type de `BookPage` :

- `CoverTemplate`
- `ChapterIntroTemplate`
- `FlowTextTemplate`
- `RaceSheetTemplate`
- `ClassSheetTemplate`
- `WeaponTableTemplate`
- `EffectListTemplate`
- `BlankTemplate`
- `FullIllustrationTemplate`
- `AnnexTemplate` (pour les fiches annexes, légèrement différent du PageFrame)

### 5.3 Stratégie responsive

**`LayoutBuilder` + seuils** pour la majorité des templates :

```dart
LayoutBuilder(builder: (context, constraints) {
  if (constraints.maxWidth > 800) {
    return _wideLayout();  // deux colonnes, comme le PDF
  } else {
    return _narrowLayout(); // empilé verticalement
  }
});
```

`FittedBox` en fallback pour les pages très visuelles (couverture, illustrations) où le layout doit rester strict.

### 5.4 Scroll interne

- Chaque template enveloppe son contenu dans un `SingleChildScrollView` avec une `PageStorageKey` (pour mémoriser la position de scroll si on revient sur la page).
- **Piège connu à anticiper** : conflit de gestures entre le scroll vertical interne et le swipe horizontal du `PageFlipWidget`. À tester tôt. Solution probable : un `GestureDetector` custom qui distingue clairement les directions, ou utiliser un `NotificationListener` sur le scroll.

---

## 6. Index du livre (Couche 3)

```dart
class BookIndex {
  final List<BookPage> orderedPages;        // toutes les pages, dans l'ordre
  final Map<String, int> pageIdToIndex;     // id → index dans orderedPages
  final Map<String, AnnexSheet> annexes;    // fiches hors pagination
  final List<SectionInfo> sections;         // {id, title, startPage, pageCount}

  int? indexOfPage(String id);
  BookPage pageAt(int index);
  SectionInfo sectionAt(int index);
  AnnexSheet? annex(String id);

  // construction avec normalisation (insertion de pages blanches)
  factory BookIndex.build(List<Section> sections, List<AnnexSheet> annexes);
}
```

**Construit une seule fois au démarrage** de l'app (ou de l'écran, à voir selon les performances). Source de vérité pour toute la pagination.

**Validation au build** : assertion qui vérifie que chaque `LinkNode.targetId` du contenu pointe vers un id existant. Erreur de compilation logique → on ne livre pas.

---

## 7. Navigator (Couche 4)

```dart
class BookNavigator extends ChangeNotifier {
  final BookIndex index;
  int _currentPageIndex;
  final List<NavigationEntry> _history;
  AnnexSheet? _openAnnex;

  int get currentPageIndex;
  AnnexSheet? get openAnnex;
  bool get canGoBack;

  // sauts qui alimentent l'historique
  void goToPageById(String id);
  void openAnnexById(String id);

  // sauts directs qui n'alimentent pas l'historique (feuilletage normal)
  void nextPage();
  void previousPage();
  void goToPageIndex(int index, {bool pushHistory = false});

  // gestion historique
  void back();
  void closeAnnex();
}
```

**Choix de gestion d'état** : à confirmer avec le développeur selon ce qui est déjà utilisé dans l'app (`provider`, `riverpod`, `bloc`, `ChangeNotifier` simple...). Par défaut : `ChangeNotifier` + `provider`, le plus standard.

---

## 8. UI racine (Couche 5)

```
BookViewerPage (Scaffold)
└── Stack
    ├── BookBackground (fond bois sombre)
    ├── AnimatedSwitcher (mode book / mode annex)
    │   ├── BookMode
    │   │   ├── BookOpeningAnimation (au premier affichage)
    │   │   └── DoublePageLayout (desktop) ou SinglePageLayout (mobile)
    │   │       └── PageTurner
    │   │           └── switch sur sealed class → template correspondant
    │   └── AnnexMode
    │       └── AnnexTemplate (animation verticale ou fondu)
    ├── LinkPopupOverlay (popup des liens discrets)
    ├── SearchOverlay (loupe + résultats)
    └── TopBar (bouton retour app, bouton historique back, bouton recherche)
```

Switch exhaustif pour rendre une page :

```dart
Widget _buildPageWidget(BookPage page) => switch (page) {
  CoverPage p => CoverTemplate(data: p),
  ChapterIntroPage p => ChapterIntroTemplate(data: p),
  FlowTextPage p => FlowTextTemplate(data: p),
  RaceSheetPage p => RaceSheetTemplate(data: p),
  ClassSheetPage p => ClassSheetTemplate(data: p),
  WeaponTablePage p => WeaponTableTemplate(data: p),
  EffectListPage p => EffectListTemplate(data: p),
  BlankPage p => BlankTemplate(data: p),
  FullIllustrationPage p => FullIllustrationTemplate(data: p),
};
```

---

## 9. Plan d'implémentation (étapes incrémentales)

Chaque étape est livrable et testable indépendamment. Jamais de "tout ou rien".

1. **Fondations sans UI** : sealed classes (`BookPage` et sous-types, `RichContent`, `InlineNode`, `AnnexSheet`), création manuelle de 2-3 pages de contenu pour test, écriture du `BookIndex`, validation des liens en console.
2. **Premier template + écran minimal** : implémenter `ClassSheetTemplate` (le plus représentatif), brancher sur le `PageFlipWidget` actuel, vérifier le rendu sur Android et Windows.
3. **Navigator + liens directs** : `BookNavigator` avec `goToPageById`, intégration dans le rendu du `RichContent`, tests avec quelques liens en dur.
4. **Historique + bouton retour** : pile, `back()`, bouton dans la TopBar.
5. **Liens discrets + popup** : overlay positionné via `OverlayPortal`, animation d'apparition.
6. **Fiches annexes** : `AnnexSheet`, `AnnexTemplate`, basculement de mode dans `BookViewerPage` avec animation distincte.
7. **Layout double page (desktop)** : détection de largeur, `DoublePageLayout`, normalisation des pages blanches dans le `BookIndex`.
8. **Recherche textuelle** : bouton loupe, `SearchOverlay`, parcours des `RichContent`, ranking simple.
9. **Polish** : animation d'ouverture du livre, sons éventuels, transitions entre modes.
10. **Migration du contenu** : porter tout le PDF dans la nouvelle structure. Mécanique mais long. À faire en dernier, quand l'infrastructure est stable.

**Philosophie** : construire l'infrastructure sur un échantillon minuscule, prouver qu'elle marche, puis remplir. Pas l'inverse.

---

## 10. Points techniques à surveiller

- **Conflit de gestures** entre scroll interne et swipe horizontal de tournage de page. À tester dès l'étape 2.
- **Performance du `PageFlipWidget`** sur Windows avec des templates complexes. Si problème, envisager une alternative custom basée sur `AnimatedBuilder` + `Transform`.
- **Polices** : le PDF utilise des polices spécifiques (gothique pour les titres principaux, Cinzel et EB Garamond dans le prototype). S'assurer qu'elles sont bien dans `pubspec.yaml` et qu'elles rendent correctement sur les deux plateformes.
- **Assets** : le fond parchemin, les ornements, les illustrations. À organiser dans une structure claire (`assets/book/parchment.jpg`, `assets/book/illustrations/`, etc.).
- **Tests** : prévoir des tests unitaires sur `BookIndex` (résolution des liens, normalisation des pages blanches) et `BookNavigator` (pile d'historique, transitions de mode).

---

## 11. Décisions ouvertes (à trancher pendant l'implémentation)

- Convention de reliure pour la double page : page 1 à droite (occidental classique) ou à gauche.
- Gestionnaire d'état exact (`provider` vs `riverpod` vs autre) — dépend de ce qui existe déjà dans l'app.
- Animation précise pour l'apparition des fiches annexes (glissement vertical vs fondu vs autre).
- Conserver `page_flip` ou écrire un `PageTurner` custom pour mieux gérer le double page et les conflits de gestures.
- Seuil exact de largeur pour basculer mobile/desktop (probablement 800-900px logiques).

---

## 12. Comment reprendre cette conversation

Si tu es Claude et que tu lis ce document pour la première fois dans une nouvelle session :

1. **Lis ce document en entier** avant de proposer quoi que ce soit.
2. **Lis le PDF source** (`Règle_Hellsing_V5_3_format_livre.pdf`) au moins en survol pour comprendre la nature du contenu à porter.
3. **Lis le code existant** s'il est présent dans le dépôt — le prototype ou ce qui a déjà été implémenté de la nouvelle architecture.
4. **Demande à l'utilisateur où il en est** dans le plan d'implémentation (section 9) avant de proposer du code. Ne suppose pas que tout est à faire ou que rien n'est fait.
5. **Respecte les décisions déjà prises** dans ce document. Si tu penses qu'une décision est mauvaise, dis-le explicitement avant de la contourner — ne change pas l'architecture en silence.
6. **Pose des questions** sur les points ouverts (section 11) si on arrive à un moment où il faut les trancher.

Le contexte de la conversation initiale qui a produit ce document : le développeur est solo, l'app est en Flutter, il a un prototype fonctionnel mais limité, et on a passé du temps à comparer trois approches d'architecture avant de retenir la C (template-first hybride). Les questions cruciales (plateformes, double page, style des liens, fiches annexes, recherche) ont toutes été tranchées ensemble.

---

*Document généré à l'issue de la phase de design. À mettre à jour au fur et à mesure des décisions d'implémentation.*
