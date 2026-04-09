import 'package:cloud_firestore/cloud_firestore.dart';

/// ─── Repository centralisé pour toutes les statistiques ─────────────────────
class StatsRepository {
  final _fs = FirebaseFirestore.instance;

  /// Cache des agents : un seul Future partagé pour éviter les requêtes en
  /// double lorsque plusieurs méthodes sont appelées simultanément via Future.wait.
  Future<List<Map<String, dynamic>>>? _agentsFuture;

  /// Vide le cache (appelé en début de recalcul complet).
  void clearCache() => _agentsFuture = null;

  // ═══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> _allAgents() =>
      _agentsFuture ??= _fetchAllAgents();

  Future<List<Map<String, dynamic>>> _fetchAllAgents() async {
    final usersSnap = await _fs.collection('users').get();
    final agents = <Map<String, dynamic>>[];
    for (final userDoc in usersSnap.docs) {
      final agentsSnap = await userDoc.reference.collection('agents').get();
      for (final doc in agentsSnap.docs) {
        if (doc.id == '_meta_') continue;
        agents.add(doc.data());
      }
    }
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

  Future<double> averageSkillsPerAgent() async {
    final agents = await _allAgents();
    if (agents.isEmpty) return 0;
    final total = agents.fold<int>(0, (acc, a) => acc + _extractSkills(a).length);
    return total / agents.length;
  }

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

  Future<List<MapEntry<String, int>>> topSupportItems({int limit = 5}) async {
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
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

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

  Future<double> averageEquipmentCost() async {
    final agents = await _allAgents();
    if (agents.isEmpty) return 0;
    var totalCost = 0;
    for (final a in agents) {
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
      final bags = a['bagSlots'];
      if (bags is List) {
        for (final slot in bags) {
          if (slot is! Map || slot['empty'] == true) continue;
          final supp = slot['support'];
          if (supp is Map) totalCost += (supp['price'] as int?) ?? 0;
        }
      }
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

  // ═══════════════════════════════════════════════════════════════════════════
  //  STATS SUMMARY — document pré-calculé /common/stats
  // ═══════════════════════════════════════════════════════════════════════════

  static const _summaryCollection = 'common';
  static const _summaryDocId = 'stats';

  /// Recalcule toutes les statistiques et les persiste dans /common/stats.
  Future<void> rebuildSummary() async {
    clearCache();

    final agentFutures = Future.wait([
      totalAgents(),           // 0
      agentsByRace(),          // 1
      agentsByClass(),         // 2
      averageLevel(),          // 3
      richestAgent(),          // 4
      agentsBySecondClass(),   // 5
      classComboFrequency(),   // 6
      agentsByClassType(),     // 7
    ]);
    final skillFutures = Future.wait([
      totalDistinctSkills(),    // 0
      averageSkillsPerAgent(),  // 1
      topSkills(),              // 2
      leastPopularSkills(),     // 3
      skillsByCostType(),       // 4
      agentWithMostSkills(),    // 5
      skillsPerClass(),         // 6
      skillsAccessiblePerRace(),// 7
    ]);
    final missionFutures = Future.wait([
      totalMissions(),          // 0
      missionsByDifficulty(),   // 1
      missionsByClade(),        // 2
      totalAgentsDeceased(),    // 3
    ]);
    final otherFutures = Future.wait([
      totalMonsters(),          // 0
      pnjsByRelation(),         // 1
      totalArtefacts(),         // 2
      resDevProgress(),         // 3
      weaponsByType(),          // 4
      averageBagItems(),        // 5
      topWeapons(),             // 6
      leastPopularWeapons(),    // 7
      muniByCalibr(),           // 8
      topSupportItems(),        // 9
      leastPopularSupportItems(), // 10
      averageEquipmentCost(),   // 11
    ]);

    final results = await Future.wait([
      agentFutures,
      skillFutures,
      missionFutures,
      otherFutures,
    ]);

    final a = results[0] as List;
    final s = results[1] as List;
    final m = results[2] as List;
    final o = results[3] as List;

    final (richName, richMoney) = a[4] as (String, int);
    final (bestSkillAgent, bestSkillCount) = s[5] as (String, int);
    final (rdCompleted, rdInProgress) = o[3] as (int, int);

    final summary = <String, dynamic>{
      // Agents
      'totalAgents': a[0] as int,
      'agentsByRace': a[1] as Map<String, int>,
      'agentsByClass': a[2] as Map<String, int>,
      'averageLevel': a[3] as double,
      'richestAgent': {'name': richName, 'count': richMoney},
      'agentsBySecondClass': a[5] as Map<String, int>,
      'classComboFrequency': a[6] as Map<String, int>,
      'agentsByClassType': a[7] as Map<String, int>,
      // Compétences
      'totalDistinctSkills': s[0] as int,
      'averageSkillsPerAgent': s[1] as double,
      'topSkills': _encodeEntries(s[2] as List<MapEntry<String, int>>),
      'leastPopularSkills': _encodeEntries(s[3] as List<MapEntry<String, int>>),
      'skillsByCostType': s[4] as Map<String, int>,
      'agentWithMostSkills': {'name': bestSkillAgent, 'count': bestSkillCount},
      'skillsPerClass': s[6] as Map<String, int>,
      'skillsAccessiblePerRace': s[7] as Map<String, int>,
      // Missions
      'totalMissions': m[0] as int,
      'missionsByDifficulty': m[1] as Map<String, int>,
      'missionsByClade': m[2] as Map<String, int>,
      'totalDeceased': m[3] as int,
      // Bestiaire & PNJ
      'totalMonsters': o[0] as int,
      'pnjsByRelation': o[1] as Map<String, int>,
      // Inventaire, Artefacts & R&D
      'totalArtefacts': o[2] as int,
      'resDevProgress': {'completed': rdCompleted, 'inProgress': rdInProgress},
      'weaponsByType': o[4] as Map<String, int>,
      'averageBagItems': o[5] as double,
      'topWeapons': _encodeEntries(o[6] as List<MapEntry<String, int>>),
      'leastPopularWeapons': _encodeEntries(o[7] as List<MapEntry<String, int>>),
      'muniByCalibre': o[8] as Map<String, int>,
      'topSupportItems': _encodeEntries(o[9] as List<MapEntry<String, int>>),
      'leastPopularSupportItems': _encodeEntries(o[10] as List<MapEntry<String, int>>),
      'averageEquipmentCost': o[11] as double,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    await _fs
        .collection(_summaryCollection)
        .doc(_summaryDocId)
        .set(summary);
  }

  /// Charge les statistiques depuis le document pré-calculé.
  /// Retourne null si le document n'existe pas encore (premier lancement).
  Future<Map<String, dynamic>?> loadSummary() async {
    final doc = await _fs
        .collection(_summaryCollection)
        .doc(_summaryDocId)
        .get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Fire-and-forget : déclenche un recalcul en arrière-plan sans bloquer l'UI.
  /// À appeler après toute mutation de données impactant les statistiques.
  static void scheduleRebuild() {
    StatsRepository().rebuildSummary().catchError((_) {});
  }

  // ─── Helpers de sérialisation ────────────────────────────────────────────

  static List<Map<String, dynamic>> _encodeEntries(
          List<MapEntry<String, int>> entries) =>
      entries.map((e) => {'key': e.key, 'value': e.value}).toList();
}
