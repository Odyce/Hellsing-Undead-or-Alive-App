import 'package:cloud_firestore/cloud_firestore.dart';

/// ─── Repository centralisé pour toutes les statistiques ─────────────────────
class StatsRepository {
  final _fs = FirebaseFirestore.instance;

  /// Cache des agents pour éviter de refetch N fois dans le même chargement.
  List<Map<String, dynamic>>? _agentsCache;

  /// Vide le cache (à appeler en début de chargement complet).
  void clearCache() => _agentsCache = null;

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> _allAgents() async {
    if (_agentsCache != null) return _agentsCache!;
    final usersSnap = await _fs.collection('users').get();
    final agents = <Map<String, dynamic>>[];
    for (final userDoc in usersSnap.docs) {
      final agentsSnap = await userDoc.reference.collection('agents').get();
      for (final doc in agentsSnap.docs) {
        agents.add(doc.data());
      }
    }
    _agentsCache = agents;
    return agents;
  }

  Future<List<Map<String, dynamic>>> _allMissions() async {
    final snap = await _fs.collection('common/archives/missions').get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  AGENTS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<int> totalAgents() async => (await _allAgents()).length;

  Future<Map<String, int>> agentsByRace() async {
    final agents = await _allAgents();
    final map = <String, int>{};
    for (final a in agents) {
      final race = a['race'];
      final name = (race is Map ? race['name'] as String? : null) ?? 'Inconnue';
      map[name] = (map[name] ?? 0) + 1;
    }
    return map;
  }

  Future<Map<String, int>> agentsByClass() async {
    final agents = await _allAgents();
    final map = <String, int>{};
    for (final a in agents) {
      final cls = a['agentClass'];
      final name =
          (cls is Map ? cls['name'] as String? : null) ?? 'Sans classe';
      map[name] = (map[name] ?? 0) + 1;
    }
    return map;
  }

  Future<double> averageLevel() async {
    final agents = await _allAgents();
    if (agents.isEmpty) return 0;
    final total =
        agents.fold<int>(0, (acc, a) => acc + ((a['level'] as int?) ?? 1));
    return total / agents.length;
  }

  Future<(String, int)> richestAgent() async {
    final agents = await _allAgents();
    if (agents.isEmpty) return ('Aucun', 0);
    agents.sort(
        (a, b) => ((b['money'] as int?) ?? 0).compareTo((a['money'] as int?) ?? 0));
    final top = agents.first;
    return (
      (top['name'] as String?) ?? 'Inconnu',
      (top['money'] as int?) ?? 0,
    );
  }

  /// Répartition par classe secondaire
  Future<Map<String, int>> agentsBySecondClass() async {
    final agents = await _allAgents();
    final map = <String, int>{};
    for (final a in agents) {
      final cls = a['secondClass'];
      if (cls == null) continue;
      final name =
          (cls is Map ? cls['name'] as String? : null) ?? 'Inconnue';
      map[name] = (map[name] ?? 0) + 1;
    }
    return map;
  }

  /// Combinaisons classe principale + secondaire
  Future<Map<String, int>> classComboFrequency() async {
    final agents = await _allAgents();
    final map = <String, int>{};
    for (final a in agents) {
      final main = a['agentClass'];
      final sec = a['secondClass'];
      if (main == null || sec == null) continue;
      final mainName =
          (main is Map ? main['name'] as String? : null) ?? '?';
      final secName =
          (sec is Map ? sec['name'] as String? : null) ?? '?';
      final combo = '$mainName + $secName';
      map[combo] = (map[combo] ?? 0) + 1;
    }
    return map;
  }

  /// Répartition par type de classe (classType: pe/pm)
  Future<Map<String, int>> agentsByClassType() async {
    final agents = await _allAgents();
    final labels = {'pe': 'Physique (PE)', 'pm': 'Mentale (PM)'};
    final map = <String, int>{};
    for (final a in agents) {
      final cls = a['agentClass'];
      if (cls is! Map) continue;
      final raw = (cls['classType'] as String?) ?? 'pe';
      final label = labels[raw] ?? raw;
      map[label] = (map[label] ?? 0) + 1;
    }
    return map;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  COMPÉTENCES
  // ═══════════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _extractSkills(Map<String, dynamic> agent) {
    final skills = agent['skills'];
    if (skills is! List) return [];
    return skills.whereType<Map<String, dynamic>>().toList();
  }

  /// Nombre total de skills distincts (union par nom)
  Future<int> totalDistinctSkills() async {
    final agents = await _allAgents();
    final names = <String>{};
    for (final a in agents) {
      for (final s in _extractSkills(a)) {
        final name = s['name'] as String?;
        if (name != null) names.add(name);
      }
    }
    return names.length;
  }

  /// Nombre moyen de skills par agent
  Future<double> averageSkillsPerAgent() async {
    final agents = await _allAgents();
    if (agents.isEmpty) return 0;
    final total = agents.fold<int>(0, (acc, a) => acc + _extractSkills(a).length);
    return total / agents.length;
  }

  /// Top 5 skills les plus populaires { name: count }
  Future<List<MapEntry<String, int>>> topSkills({int limit = 5}) async {
    final agents = await _allAgents();
    final map = <String, int>{};
    for (final a in agents) {
      for (final s in _extractSkills(a)) {
        final name = (s['name'] as String?) ?? '?';
        map[name] = (map[name] ?? 0) + 1;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Top 5 skills les moins populaires
  Future<List<MapEntry<String, int>>> leastPopularSkills({int limit = 5}) async {
    final agents = await _allAgents();
    final map = <String, int>{};
    for (final a in agents) {
      for (final s in _extractSkills(a)) {
        final name = (s['name'] as String?) ?? '?';
        map[name] = (map[name] ?? 0) + 1;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.take(limit).toList();
  }

  /// Répartition des skills par type de coût (PE/PM/PV)
  Future<Map<String, int>> skillsByCostType() async {
    final agents = await _allAgents();
    final labels = {'pe': 'PE', 'pm': 'PM', 'pv': 'PV'};
    final map = <String, int>{};
    for (final a in agents) {
      for (final s in _extractSkills(a)) {
        final raw = (s['costType'] as String?) ?? 'pe';
        final label = labels[raw] ?? raw;
        map[label] = (map[label] ?? 0) + 1;
      }
    }
    return map;
  }

  /// Agent avec le plus de compétences (name, count)
  Future<(String, int)> agentWithMostSkills() async {
    final agents = await _allAgents();
    if (agents.isEmpty) return ('Aucun', 0);
    String bestName = 'Aucun';
    int bestCount = 0;
    for (final a in agents) {
      final count = _extractSkills(a).length;
      if (count > bestCount) {
        bestCount = count;
        bestName = (a['name'] as String?) ?? 'Inconnu';
      }
    }
    return (bestName, bestCount);
  }

  /// Nombre de skills par classe (via allSkills de agentClass)
  Future<Map<String, int>> skillsPerClass() async {
    final agents = await _allAgents();
    final map = <String, int>{};
    final seen = <String>{};
    for (final a in agents) {
      final cls = a['agentClass'];
      if (cls is! Map) continue;
      final name = (cls['name'] as String?) ?? '?';
      if (seen.contains(name)) continue;
      seen.add(name);
      final allSkills = cls['allSkills'];
      final count = (allSkills is List) ? allSkills.length : 0;
      map[name] = count;
    }
    return map;
  }

  /// Nombre de skills accessibles par race (union des allSkills de toutes les
  /// classes disponibles de la race)
  Future<Map<String, int>> skillsAccessiblePerRace() async {
    final agents = await _allAgents();
    final map = <String, int>{};
    final seen = <String>{};
    for (final a in agents) {
      final race = a['race'];
      if (race is! Map) continue;
      final raceName = (race['name'] as String?) ?? '?';
      if (seen.contains(raceName)) continue;
      seen.add(raceName);
      final available = race['availableClasses'];
      if (available is! List) {
        map[raceName] = 0;
        continue;
      }
      final skillNames = <String>{};
      for (final cls in available) {
        if (cls is! Map) continue;
        final allSkills = cls['allSkills'];
        if (allSkills is! List) continue;
        for (final s in allSkills) {
          if (s is Map) {
            final n = s['name'] as String?;
            if (n != null) skillNames.add(n);
          }
        }
      }
      map[raceName] = skillNames.length;
    }
    return map;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  MISSIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<int> totalMissions() async => (await _allMissions()).length;

  Future<Map<String, int>> missionsByDifficulty() async {
    final missions = await _allMissions();
    final labels = {
      'basse': 'Basse',
      'moyenne': 'Moyenne',
      'haute': 'Haute',
      'tresHaute': 'Très haute',
      'inconnu': 'Inconnue',
    };
    final map = <String, int>{};
    for (final m in missions) {
      final raw = (m['difficulty'] as String?) ?? 'inconnu';
      final label = labels[raw] ?? raw;
      map[label] = (map[label] ?? 0) + 1;
    }
    return map;
  }

  Future<Map<String, int>> missionsByClade() async {
    final missions = await _allMissions();
    final labels = {
      'origins': 'Origins',
      'western': 'Western',
      'beginning': 'Beginning',
      'unNeufTroisZero': '1930',
      'arthur': 'Arthur',
      'osiris': 'Osiris',
      'blackOrchid': 'Black Orchid',
      'pennyDreadful': 'Penny Dreadful',
    };
    final map = <String, int>{};
    for (final m in missions) {
      final raw = (m['clade'] as String?) ?? 'inconnu';
      final label = labels[raw] ?? raw;
      map[label] = (map[label] ?? 0) + 1;
    }
    return map;
  }

  Future<int> totalAgentsDeceased() async {
    final missions = await _allMissions();
    var total = 0;
    for (final m in missions) {
      final deceased = m['agentDeceased'];
      if (deceased is List) total += deceased.length;
    }
    return total;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BESTIAIRE & PNJ
  // ═══════════════════════════════════════════════════════════════════════════

  Future<int> totalMonsters() async {
    final snap = await _fs.collection('common/archives/bestiary').get();
    return snap.docs.length;
  }

  Future<Map<String, int>> pnjsByRelation() async {
    final snap = await _fs.collection('common/archives/npcs').get();
    final labels = {
      'neutral': 'Neutre',
      'ally': 'Allié',
      'enemy': 'Ennemi',
      'trader': 'Marchand',
    };
    final map = <String, int>{};
    for (final doc in snap.docs) {
      final raw = (doc.data()['relation'] as String?) ?? 'neutral';
      final label = labels[raw] ?? raw;
      map[label] = (map[label] ?? 0) + 1;
    }
    return map;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  INVENTAIRE, ARTEFACTS & R&D
  // ═══════════════════════════════════════════════════════════════════════════

  Future<int> totalArtefacts() async {
    final snap = await _fs.collection('common/archives/artefacts').get();
    return snap.docs.length;
  }

  Future<(int, int)> resDevProgress() async {
    final snap = await _fs.collection('common/archives/resdevproject').get();
    var completed = 0;
    var inProgress = 0;
    for (final doc in snap.docs) {
      if (doc.data()['completed'] == true) {
        completed++;
      } else {
        inProgress++;
      }
    }
    return (completed, inProgress);
  }

  /// Répartition des armes par type (affinité)
  Future<Map<String, int>> weaponsByType() async {
    final agents = await _allAgents();
    final labels = {
      'firearm': 'Arme à feu',
      'explosive': 'Explosif',
      'oneHandBlade': 'Lame 1 main',
      'twoHandBlade': 'Lame 2 mains',
      'bow': 'Arc',
      'throwable': 'Lancer',
      'none': 'Aucun',
      'choiceNonExplosive': 'Au choix',
    };
    final map = <String, int>{};
    for (final a in agents) {
      final slots = a['weaponSlots'];
      if (slots is! List) continue;
      for (final slot in slots) {
        if (slot is! Map) continue;
        if (slot['empty'] == true) continue;
        final weapon = slot['weapon'];
        if (weapon is! Map) continue;
        final raw = (weapon['type'] as String?) ?? 'none';
        final label = labels[raw] ?? raw;
        map[label] = (map[label] ?? 0) + 1;
      }
    }
    return map;
  }

  /// Nombre moyen d'objets en sac (bagSlots non vides)
  Future<double> averageBagItems() async {
    final agents = await _allAgents();
    if (agents.isEmpty) return 0;
    var total = 0;
    for (final a in agents) {
      final slots = a['bagSlots'];
      if (slots is! List) continue;
      for (final slot in slots) {
        if (slot is! Map) continue;
        if (slot['empty'] != true) total++;
      }
    }
    return total / agents.length;
  }

  /// Top N armes les plus populaires { name: count }
  Future<List<MapEntry<String, int>>> topWeapons({int limit = 5}) async {
    final agents = await _allAgents();
    final map = <String, int>{};
    for (final a in agents) {
      final slots = a['weaponSlots'];
      if (slots is! List) continue;
      for (final slot in slots) {
        if (slot is! Map || slot['empty'] == true) continue;
        final weapon = slot['weapon'];
        if (weapon is! Map) continue;
        final name = (weapon['name'] as String?) ?? '?';
        map[name] = (map[name] ?? 0) + 1;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Top N armes les moins populaires
  Future<List<MapEntry<String, int>>> leastPopularWeapons({int limit = 5}) async {
    final agents = await _allAgents();
    final map = <String, int>{};
    for (final a in agents) {
      final slots = a['weaponSlots'];
      if (slots is! List) continue;
      for (final slot in slots) {
        if (slot is! Map || slot['empty'] == true) continue;
        final weapon = slot['weapon'];
        if (weapon is! Map) continue;
        final name = (weapon['name'] as String?) ?? '?';
        map[name] = (map[name] ?? 0) + 1;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.take(limit).toList();
  }

  /// Répartition des munitions par calibre
  Future<Map<String, int>> muniByCalibr() async {
    final agents = await _allAgents();
    final map = <String, int>{};
    for (final a in agents) {
      final slots = a['muniSlots'];
      if (slots is! List) continue;
      for (final slot in slots) {
        if (slot is! Map || slot['empty'] == true) continue;
        final muni = slot['muni'];
        if (muni is! Map) continue;
        final name = (muni['name'] as String?) ?? '?';
        final qty = (slot['numberLeft'] as int?) ?? 0;
        map[name] = (map[name] ?? 0) + qty;
      }
    }
    return map;
  }

  /// Top 5 équipements de support les plus populaires
  Future<List<MapEntry<String, int>>> topSupportItems({int limit = 5}) async {
    final agents = await _allAgents();
    final map = <String, int>{};
    for (final a in agents) {
      // Support dans les bagSlots
      final bags = a['bagSlots'];
      if (bags is List) {
        for (final slot in bags) {
          if (slot is! Map || slot['empty'] == true) continue;
          final supp = slot['support'];
          if (supp is! Map) continue;
          final name = (supp['name'] as String?) ?? '?';
          map[name] = (map[name] ?? 0) + 1;
        }
      }
      // Support dans les muniSlots (champ supp)
      final munis = a['muniSlots'];
      if (munis is List) {
        for (final slot in munis) {
          if (slot is! Map) continue;
          final supp = slot['supp'];
          if (supp is! Map) continue;
          final name = (supp['name'] as String?) ?? '?';
          map[name] = (map[name] ?? 0) + 1;
        }
      }
      // Kit dans les weaponSlots
      final weapons = a['weaponSlots'];
      if (weapons is List) {
        for (final slot in weapons) {
          if (slot is! Map) continue;
          final kit = slot['kit'];
          if (kit is! Map) continue;
          final name = (kit['name'] as String?) ?? '?';
          map[name] = (map[name] ?? 0) + 1;
        }
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Top 5 équipements de support les moins populaires
  Future<List<MapEntry<String, int>>> leastPopularSupportItems({int limit = 5}) async {
    final agents = await _allAgents();
    final map = <String, int>{};
    for (final a in agents) {
      final bags = a['bagSlots'];
      if (bags is List) {
        for (final slot in bags) {
          if (slot is! Map || slot['empty'] == true) continue;
          final supp = slot['support'];
          if (supp is! Map) continue;
          final name = (supp['name'] as String?) ?? '?';
          map[name] = (map[name] ?? 0) + 1;
        }
      }
      final munis = a['muniSlots'];
      if (munis is List) {
        for (final slot in munis) {
          if (slot is! Map) continue;
          final supp = slot['supp'];
          if (supp is! Map) continue;
          final name = (supp['name'] as String?) ?? '?';
          map[name] = (map[name] ?? 0) + 1;
        }
      }
      final weapons = a['weaponSlots'];
      if (weapons is List) {
        for (final slot in weapons) {
          if (slot is! Map) continue;
          final kit = slot['kit'];
          if (kit is! Map) continue;
          final name = (kit['name'] as String?) ?? '?';
          map[name] = (map[name] ?? 0) + 1;
        }
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.take(limit).toList();
  }

  /// Coût moyen du total des équipements par agent
  Future<double> averageEquipmentCost() async {
    final agents = await _allAgents();
    if (agents.isEmpty) return 0;
    var totalCost = 0;
    for (final a in agents) {
      // Armes
      final weapons = a['weaponSlots'];
      if (weapons is List) {
        for (final slot in weapons) {
          if (slot is! Map || slot['empty'] == true) continue;
          final weapon = slot['weapon'];
          if (weapon is Map) totalCost += (weapon['price'] as int?) ?? 0;
          final kit = slot['kit'];
          if (kit is Map) totalCost += (kit['price'] as int?) ?? 0;
        }
      }
      // Sac
      final bags = a['bagSlots'];
      if (bags is List) {
        for (final slot in bags) {
          if (slot is! Map || slot['empty'] == true) continue;
          final supp = slot['support'];
          if (supp is Map) totalCost += (supp['price'] as int?) ?? 0;
        }
      }
      // Munitions
      final munis = a['muniSlots'];
      if (munis is List) {
        for (final slot in munis) {
          if (slot is! Map || slot['empty'] == true) continue;
          final muni = slot['muni'];
          if (muni is Map) {
            final qty = (slot['numberLeft'] as int?) ?? 0;
            final price = (muni['price'] as int?) ?? 0;
            totalCost += price * qty;
          }
          final supp = slot['supp'];
          if (supp is Map) totalCost += (supp['price'] as int?) ?? 0;
        }
      }
    }
    return totalCost / agents.length;
  }
}
