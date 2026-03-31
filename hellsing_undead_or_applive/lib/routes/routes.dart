/// Constantes centralisées pour tous les noms de routes.
///
/// Utilisation : Routes.missionBoard au lieu de '/missionboard'
/// → plus d'erreurs de frappe, autocomplétion IDE, renommage en un seul endroit.
class Routes {
  Routes._(); // non instanciable

  // ── Auth & accueil ──────────────────────────────────────────────────────────
  static const login  = '/login';
  static const home   = '/home';

  // ── Agents ──────────────────────────────────────────────────────────────────
  static const agentList           = '/agentlist';
  static const agentCreate         = '/agentcreate';
  static const agentValidationList = '/agentvalidationlist';

  // ── Archives (menu) ─────────────────────────────────────────────────────────
  static const archives = '/archives';

  // ── Missions ─────────────────────────────────────────────────────────────────
  static const missions       = '/missions';
  static const missionBoard   = '/missionboard';
  static const missionChrono  = '/chrono';
  static const missionSheet   = '/missionsheet';
  static const missionCreate  = '/missioncreate';
  static const missionEdit    = '/edit-mission';

  // ── Bestiaire ────────────────────────────────────────────────────────────────
  static const bestiary       = '/bestiary';
  static const bestiarySheet  = '/bestiarySheet';
  static const bestiaryCreate = '/bestiaryCreate';
  static const bestiaryEdit   = '/bestiaryEdit';

  // ── PNJs ────────────────────────────────────────────────────────────────────
  static const npcs      = '/npcs';
  static const npcSheet  = '/npcSheet';
  static const npcCreate = '/npcCreate';

  // ── Artefacts ───────────────────────────────────────────────────────────────
  static const artefacts       = '/artefacts';
  static const artefactSheet   = '/artefactSheet';
  static const artefactCreate  = '/artefactCreate';

  // ── Recherche & Développement ────────────────────────────────────────────────
  static const resDev              = '/resDev';
  static const resDevList          = '/resDevList';
  static const resDevSheet         = '/resDevSheet';
  static const resDevCreate        = '/resDevCreate';
  static const resDevProjectSheet  = '/resDevProjectSheet';
  static const resDevProjectCreate = '/resDevProjectCreate';

  // ── Divers ───────────────────────────────────────────────────────────────────
  static const rulebook       = '/rulebook';
  static const calendar       = '/calendar';
  static const notifications  = '/notifications';
}
