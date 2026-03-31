# Todo-list Hellsing App

| # | Tâche | Difficulté | Statut |
|---|-------|------------|--------|
| 1 | Changer l'affichage des "affinities" par des phrases descriptives | ⭐ Très simple — remplacer des labels par du texte descriptif | Fait |
| 2 | Remplacer les points noirs du mot de passe par des pentagrammes | ⭐ Très simple — custom obscuringCharacter sur le TextField | Fait |
| 3 | Changer la "Prime" des missions par une fourchette invisible aux non-admins + "Prime finale" visible une fois remplie | ⭐⭐ Simple — modifier le modèle Mission (bounty → bountyMin/bountyMax) + conditionner l'affichage au rôle | Fait |
| 4 | Mise à jour de la page d'accueil (boutons Tableau d'affichage, Notifications, Statistiques) | ⭐⭐ Simple  — ajouter 3 boutons de navigation sur HomePage | Fait |
| 5 | Changer le slider de race par un carousel d'icônes avec légende Cinzel Decorative | ⭐⭐ Moyen-simple — remplacer un widget par un carousel custom | Fait |
| 6 | Changer la navigation dans la date du calendrier (sélecteur mois/année cliquable) | ⭐⭐ Moyen-simple — améliorer la navigation dans MoonCalendarPage (saut par mois/année) | Fait |
| 7 | Revoir les permissions ResDev | ⭐⭐ Moyen — investiguer et corriger la logique de permissions existante | Fait |
| 8 | Créer une nouvelle race "Autre" (toutes classes, bonus/malus éditables, sauvegarde privateResources) | ⭐⭐⭐ Moyen — nouvelle race + champs remplissables uniquement par admin à la validation | Fait |
| 9 | Fond d'écran manoir de la fondation sur le menu login | ⭐ Simple — ajouter une image de fond sur LoginPage | Fait |
| 10 | Fond d'écran hall du manoir dans le menu principal | ⭐ Simple  — ajouter une image de fond sur HomePage | Fait |
| 11 | Terminer la validation des agents (fonctionnelle) — inclure modif admin des bonus/malus race "Autre" | ⭐⭐⭐ Moyen — compléter AgentValidationListPage et le flux de validation | Fait |
| 12 | Rajout de filtres de tri sur toutes les pages de listes | ⭐⭐⭐ Moyen — répétitif mais touche beaucoup de pages (agents, missions, monstres, PNJ, artefacts, R&D) | Fait |
| 13 | Vue Admin du module agents (liste tous agents + tri par utilisateur) | ⭐⭐⭐ Moyen  — nouvelle vue admin avec requête cross-users sur Firestore | Fait |
| 14 | Page de niveau supérieur pour les agents | ⭐⭐⭐ Moyen  — nouveau flux avec logique de level-up | Fait |
| 15 | Animation d'ouverture des portes du manoir lors de la connexion | ⭐⭐⭐ Moyen-complexe — animation Flutter custom (clip paths ou sprites) | Fait |
| 16 | Page de modification des missions, monstres et PNJs | ⭐⭐⭐⭐ Complexe 3 pages d'édition (pré-remplir les formulaires existants + logique d'update) | Fait |
| 17 | Revoir l'entièreté du tableau d'affichage | ⭐⭐⭐⭐ Complexe  — refonte complète d'un module existant | Fait |
| 18 | Page et module de notification — nouveau système complet (modèle, stockage, UI, état lu/non-lu) | ⭐⭐⭐⭐ Complexe | Fait |
| 19 | Notification hebdomadaire Admin (fiches à valider + level ups) | ⭐⭐⭐⭐ Complexe — dépend du module notification + logique backend schedulée (Cloud Function ou équivalent) | A faire |
| 20 | Notification immédiate joueurs (publication mission) | ⭐⭐⭐⭐ Complexe — dépend du module notification + push notifications (FCM) | A faire |
| 21 | Suppression mensuelle automatique des images Cloudinary non-utilisées | ⭐⭐⭐⭐ Complexe — Cloud Function + API Cloudinary + scan de toutes les refs Firestore | A faire |
| 22 | Module statistique (10+ stats, constamment mis à jour) | ⭐⭐⭐⭐⭐ Très complexe — gros module avec agrégation de données cross-collections, UI riche, mises à jour en temps réel | A faire |
