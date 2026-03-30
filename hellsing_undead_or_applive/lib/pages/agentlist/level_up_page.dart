import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

// ---------------------------------------------------------------------------
// Missions cumulées requises pour chaque niveau
// ---------------------------------------------------------------------------
/// Nombre de missions dans chaque palier (index 0 = niveau 1, etc.)
const List<int> _missionsPerLevel = [
  3, // Niveau 1
  3, // Niveau 2
  4, // Niveau 3
  5, // Niveau 4
  6, // Niveau 5
  7, // Niveau 6
  8, // Niveau 7
  9, // Niveau 8
  10, // Niveau 9
  11, // Niveau 10
];
const int _legendaryMissionsPerLevel = 7;

/// Missions cumulées requises pour passer au niveau [targetLevel].
/// Ex : pour passer au niveau 2, il faut 3 missions (palier du niveau 1).
int cumulativeMissionsRequired(int targetLevel) {
  int total = 0;
  for (int i = 0; i < targetLevel - 1; i++) {
    if (i < _missionsPerLevel.length) {
      total += _missionsPerLevel[i];
    } else {
      total += _legendaryMissionsPerLevel;
    }
  }
  return total;
}

/// Retourne la liste des niveaux auxquels l'agent peut monter.
List<int> availableLevelUps(Agent agent) {
  final result = <int>[];
  final missionCount = agent.missions.where((m) => m.id != -66).length;
  for (int nextLvl = agent.level + 1; nextLvl <= agent.level + 20; nextLvl++) {
    if (missionCount >= cumulativeMissionsRequired(nextLvl)) {
      result.add(nextLvl);
    } else {
      break;
    }
  }
  return result;
}

// ---------------------------------------------------------------------------
// Classes communes (disponibles à toutes les races) = IDs 0-6
// ---------------------------------------------------------------------------
const List<int> _commonClassIds = [0, 1, 2, 3, 4, 5, 6];

List<AgentClass> getCommonClasses() {
  return ClassList()
      .allClasses
      .where((c) => _commonClassIds.contains(c.id))
      .toList();
}

// ---------------------------------------------------------------------------
// Caps
// ---------------------------------------------------------------------------
const int _maxPV = 15;
const int _maxPEPM = 30;
const int _maxClassBonus = 6;

// ---------------------------------------------------------------------------
// LevelUpPage
// ---------------------------------------------------------------------------
class LevelUpPage extends StatefulWidget {
  final Agent agent;
  final String agentDocId;
  final String ownerUid;
  final int targetLevel;

  const LevelUpPage({
    super.key,
    required this.agent,
    required this.agentDocId,
    required this.ownerUid,
    required this.targetLevel,
  });

  @override
  State<LevelUpPage> createState() => _LevelUpPageState();
}

class _LevelUpPageState extends State<LevelUpPage> {
  // Déterminé par le niveau et la race
  late final bool _isLevelFive;
  late final bool _isLegendary;
  late final String _raceName;

  // ── Résultats du formulaire ──
  // Classe secondaire (niveau 5)
  AgentClass? _selectedSecondClass;

  // Choix radio pour chaque option de la race
  final Map<String, String> _choices = {};

  // Bonus de classe : clé = "primary_0", "secondary_1", etc.
  final Map<String, int> _classBonusAllocations = {};

  // Skill sélectionnée (quand le choix inclut "1 nouvelle compétence")
  Skill? _selectedSkill;

  // Attribut sélectionné (quand le choix inclut "+5 dans une Caractéristique")
  int? _selectedAttributeIndex; // 0=Physique, 1=Mental, 2=Relationnel

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _isLevelFive = widget.targetLevel == 5;
    _isLegendary = widget.targetLevel >= 11;
    _raceName = widget.agent.race.name.toLowerCase();
  }

  // ── Options de level-up par race ──────────────────────────────────────────

  List<_LevelUpChoice> _buildChoices() {
    final agent = widget.agent;
    final pv = agent.maxPools[0];
    final pe = agent.maxPools[1];
    final pm = agent.maxPools[2];

    if (_isLegendary) {
      return [_buildLegendaryChoice(agent)];
    }

    switch (_raceName) {
      case 'vampire':
        return _buildVampireChoices(pe, pm);
      case 'demi-vampire':
        return _buildDemiVampireChoices(pv, pe, pm);
      case 'semi-ange':
        return _buildSemiAngeChoices(pv, pe, pm);
      case 'humain':
      case 'autre':
      default:
        return _buildHumainChoices(pv, pe, pm);
    }
  }

  // ── Vampire ──
  List<_LevelUpChoice> _buildVampireChoices(int pe, int pm) {
    return [
      _LevelUpChoice(
        id: 'vampire_1',
        label: 'Choix 1',
        options: [
          if (pm < _maxPEPM) _Option('pm1', '+1 PM'),
          if (pe < _maxPEPM) _Option('pe2', '+2 PE'),
        ],
      ),
      _LevelUpChoice(
        id: 'vampire_2',
        label: 'Choix 2',
        options: [
          _Option('power20_pc1', '+20 au Pouvoir et +1 PC'),
          _Option('skill', '1 nouvelle compétence'),
        ],
      ),
      _LevelUpChoice(
        id: 'vampire_auto',
        label: 'Bonus automatique',
        options: [_Option('pc1_auto', '+1 PC')],
        isAutomatic: true,
      ),
    ];
  }

  // ── Demi-Vampire ──
  List<_LevelUpChoice> _buildDemiVampireChoices(int pv, int pe, int pm) {
    return [
      _LevelUpChoice(
        id: 'dv_1',
        label: 'Choix 1',
        options: [
          if (pm < _maxPEPM) _Option('pm1', '+1 PM'),
          if (pe < _maxPEPM) _Option('pe1', '+1 PE'),
        ],
      ),
      _LevelUpChoice(
        id: 'dv_2',
        label: 'Choix 2',
        options: [
          if (pv < _maxPV) _Option('pv1', '+1 PV'),
          _Option('pc1', '+1 PC'),
        ],
      ),
      _LevelUpChoice(
        id: 'dv_3',
        label: 'Choix 3',
        options: [
          _Option('classbonus1_pc1', '+1 bonus de classe et +1 PC'),
          _Option('attribute5', '+5 dans une Caractéristique'),
        ],
      ),
      _LevelUpChoice(
        id: 'dv_4',
        label: 'Choix 4',
        options: [
          _Option('skill', '1 nouvelle compétence'),
          _Option('power_minus10', '-10 au Pouvoir'),
        ],
      ),
    ];
  }

  // ── Semi-Ange ──
  List<_LevelUpChoice> _buildSemiAngeChoices(int pv, int pe, int pm) {
    return [
      _LevelUpChoice(
        id: 'sa_1',
        label: 'Choix 1',
        options: [
          if (pe < _maxPEPM) _Option('pe1', '+1 PE'),
          if (pm < _maxPEPM) _Option('pm1', '+1 PM'),
        ],
      ),
      _LevelUpChoice(
        id: 'sa_2',
        label: 'Choix 2',
        options: [
          if (pv < _maxPV) _Option('pv1', '+1 PV'),
          _Option('pc1', '+1 PC'),
        ],
      ),
      _LevelUpChoice(
        id: 'sa_3',
        label: 'Choix 3',
        options: [
          _Option('skill', '1 nouvelle compétence'),
          _Option('attribute5', '+5 dans une Caractéristique'),
        ],
      ),
      _LevelUpChoice(
        id: 'sa_auto',
        label: 'Bonus automatique',
        options: [_Option('classbonus1_pc1_auto', '+1 bonus de classe et +1 PC')],
        isAutomatic: true,
      ),
    ];
  }

  // ── Humain / Autre ──
  List<_LevelUpChoice> _buildHumainChoices(int pv, int pe, int pm) {
    return [
      _LevelUpChoice(
        id: 'h_1',
        label: 'Choix 1',
        options: [
          if (pe < _maxPEPM) _Option('pe2', '+2 PE'),
          if (pm < _maxPEPM) _Option('pm2', '+2 PM'),
          if (pe < _maxPEPM && pm < _maxPEPM) _Option('pe1pm1', '+1 PE et +1 PM'),
        ],
      ),
      _LevelUpChoice(
        id: 'h_2',
        label: 'Choix 2',
        options: [
          if (pv < _maxPV) _Option('pv1', '+1 PV'),
          _Option('pc1', '+1 PC'),
        ],
      ),
      _LevelUpChoice(
        id: 'h_3',
        label: 'Choix 3',
        options: [
          _Option('classbonus2', '+2 bonus de classe'),
          _Option('attribute5', '+5 dans une Caractéristique'),
        ],
      ),
      _LevelUpChoice(
        id: 'h_auto',
        label: 'Bonus automatique',
        options: [_Option('skill_pc1_auto', '+1 compétence et +1 PC')],
        isAutomatic: true,
      ),
    ];
  }

  // ── Légendaire (toutes races) ──
  _LevelUpChoice _buildLegendaryChoice(Agent agent) {
    return _LevelUpChoice(
      id: 'legendary',
      label: 'Choix légendaire',
      options: [
        _Option('classbonus2_pc1', '+2 bonus de classe et +1 PC'),
        _Option('skill_pc1', '+1 compétence et +1 PC'),
      ],
    );
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool _isFormValid() {
    final choices = _buildChoices();

    // Vérifier que tous les choix non-automatiques sont faits
    for (final choice in choices) {
      if (choice.isAutomatic) continue;
      if (choice.options.isEmpty) continue;
      if (choice.options.length == 1) continue; // un seul choix = auto
      if (!_choices.containsKey(choice.id)) return false;
    }

    // Vérifier la classe secondaire au niveau 5
    if (_isLevelFive && widget.agent.secondClass == null && _selectedSecondClass == null) {
      return false;
    }

    // Vérifier les sous-choix
    if (_needsSkillSelection() && _selectedSkill == null) return false;
    if (_needsAttributeSelection() && _selectedAttributeIndex == null) return false;
    if (_needsClassBonusAllocation() && !_isClassBonusAllocationValid()) return false;

    return true;
  }

  bool _needsSkillSelection() {
    for (final choice in _buildChoices()) {
      final selected = choice.isAutomatic || choice.options.length <= 1
          ? choice.options.firstOrNull?.id
          : _choices[choice.id];
      if (selected == null) continue;
      if (selected == 'skill' || selected == 'skill_pc1' || selected == 'skill_pc1_auto') {
        return true;
      }
    }
    return false;
  }

  bool _needsAttributeSelection() {
    for (final choice in _buildChoices()) {
      final selected = choice.isAutomatic || choice.options.length <= 1
          ? choice.options.firstOrNull?.id
          : _choices[choice.id];
      if (selected == null) continue;
      if (selected == 'attribute5') return true;
    }
    return false;
  }

  bool _needsClassBonusAllocation() {
    for (final choice in _buildChoices()) {
      final selected = choice.isAutomatic || choice.options.length <= 1
          ? choice.options.firstOrNull?.id
          : _choices[choice.id];
      if (selected == null) continue;
      if (selected.contains('classbonus')) return true;
    }
    return false;
  }

  int _totalClassBonusPointsToAllocate() {
    int total = 0;
    for (final choice in _buildChoices()) {
      final selected = choice.isAutomatic || choice.options.length <= 1
          ? choice.options.firstOrNull?.id
          : _choices[choice.id];
      if (selected == null) continue;
      if (selected == 'classbonus2' || selected == 'classbonus2_pc1') {
        total += 2;
      } else if (selected == 'classbonus1_pc1' || selected == 'classbonus1_pc1_auto') {
        total += 1;
      }
    }
    return total;
  }

  bool _isClassBonusAllocationValid() {
    final needed = _totalClassBonusPointsToAllocate();
    if (needed == 0) return true;
    int allocated = 0;
    for (final v in _classBonusAllocations.values) {
      allocated += v;
    }
    return allocated == needed;
  }

  // ── Application des choix ─────────────────────────────────────────────────

  Future<void> _applyLevelUp() async {
    setState(() => _saving = true);

    try {
      final agent = widget.agent;
      final newMaxPools = List<int>.from(agent.maxPools);
      final newPools = List<int>.from(agent.pools);
      final newAttributes = List<int>.from(agent.attributes);
      final newSkills = List<Skill>.from(agent.skills);
      final newClassBonuses = List<int>.from(agent.classBonuses);
      final newSecondClassBonuses = List<int>.from(agent.secondClassBonuses);
      int newPc = agent.pc;
      int? newPowerScore = agent.powerScore;
      AgentClass? newSecondClass = _selectedSecondClass ?? agent.secondClass;

      // Niveau 5 : ajouter les bonus de la classe secondaire
      if (_isLevelFive && _selectedSecondClass != null) {
        // Initialiser les bonus de classe secondaire à [0, 0, 0]
        if (newSecondClassBonuses.isEmpty) {
          newSecondClassBonuses.addAll([0, 0, 0]);
        }
        // Ajouter les freeSkills de la classe secondaire
        for (final skill in _selectedSecondClass!.freeSkill) {
          if (!newSkills.any((s) => s.id == skill.id)) {
            newSkills.add(skill);
          }
        }
      }

      // Appliquer chaque choix
      for (final choice in _buildChoices()) {
        final selected = choice.isAutomatic || choice.options.length <= 1
            ? choice.options.firstOrNull?.id
            : _choices[choice.id];
        if (selected == null) continue;

        switch (selected) {
          case 'pm1':
            newMaxPools[2] += 1;
            newPools[2] += 1;
          case 'pm2':
            newMaxPools[2] += 2;
            newPools[2] += 2;
          case 'pe1':
            newMaxPools[1] += 1;
            newPools[1] += 1;
          case 'pe2':
            newMaxPools[1] += 2;
            newPools[1] += 2;
          case 'pe1pm1':
            newMaxPools[1] += 1;
            newPools[1] += 1;
            newMaxPools[2] += 1;
            newPools[2] += 1;
          case 'pv1':
            newMaxPools[0] += 1;
            newPools[0] += 1;
          case 'pc1':
          case 'pc1_auto':
            newPc += 1;
          case 'power20_pc1':
            newPowerScore = (newPowerScore ?? 0) + 20;
            newPc += 1;
          case 'power_minus10':
            newPowerScore = (newPowerScore ?? 0) - 10;
          case 'skill':
            if (_selectedSkill != null) {
              newSkills.add(_selectedSkill!);
            }
          case 'skill_pc1':
          case 'skill_pc1_auto':
            if (_selectedSkill != null) {
              newSkills.add(_selectedSkill!);
            }
            newPc += 1;
          case 'classbonus1_pc1':
          case 'classbonus1_pc1_auto':
            newPc += 1;
            // Les allocations sont appliquées ci-dessous
          case 'classbonus2':
            // Les allocations sont appliquées ci-dessous
            break;
          case 'classbonus2_pc1':
            newPc += 1;
            // Les allocations sont appliquées ci-dessous
          case 'attribute5':
            if (_selectedAttributeIndex != null) {
              newAttributes[_selectedAttributeIndex!] += 5;
            }
        }
      }

      // Appliquer les bonus de classe alloués
      for (final entry in _classBonusAllocations.entries) {
        final parts = entry.key.split('_');
        final source = parts[0]; // "primary" ou "secondary"
        final index = int.parse(parts[1]);
        final amount = entry.value;
        if (source == 'primary') {
          newClassBonuses[index] += amount;
        } else {
          newSecondClassBonuses[index] += amount;
        }
      }

      // Caps
      newMaxPools[0] = newMaxPools[0].clamp(0, _maxPV);
      newPools[0] = newPools[0].clamp(0, newMaxPools[0]);
      newMaxPools[1] = newMaxPools[1].clamp(0, _maxPEPM);
      newPools[1] = newPools[1].clamp(0, newMaxPools[1]);
      newMaxPools[2] = newMaxPools[2].clamp(0, _maxPEPM);
      newPools[2] = newPools[2].clamp(0, newMaxPools[2]);

      // Écriture Firestore
      final uid = widget.ownerUid;
      final agentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('agents')
          .doc(widget.agentDocId);

      final updateData = <String, dynamic>{
        'level': widget.targetLevel,
        'maxPools': newMaxPools,
        'pools': newPools,
        'attributes': newAttributes,
        'skills': newSkills.map((s) => s.toMap()).toList(),
        'classBonuses': newClassBonuses,
        'pc': newPc,
        'powerScore': newPowerScore,
      };

      if (newSecondClass != null) {
        updateData['secondClass'] = newSecondClass.toMap();
        updateData['secondClassBonuses'] = newSecondClassBonuses;
      }

      await agentRef.update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${agent.name} est passé au niveau ${widget.targetLevel} !',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final choices = _buildChoices();

    return Scaffold(
      appBar: AppBar(
        title: Text('Niveau ${widget.targetLevel}'),
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Passage au niveau ${widget.targetLevel} pour ${agent.name}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Race : ${agent.race.name} — Classe : ${agent.agentClass.name}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // ── Classe secondaire (niveau 5 uniquement) ──
                if (_isLevelFive && agent.secondClass == null) ...[
                  const Text(
                    'Choisir une classe secondaire',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSecondClassSelector(agent),
                  const Divider(height: 32),
                ],

                // ── Choix de level-up ──
                ...choices.map((choice) => _buildChoiceSection(choice)),

                // ── Sélection de compétence ──
                if (_needsSkillSelection()) ...[
                  const Divider(height: 32),
                  _buildSkillSelector(agent),
                ],

                // ── Sélection d'attribut ──
                if (_needsAttributeSelection()) ...[
                  const Divider(height: 32),
                  _buildAttributeSelector(agent),
                ],

                // ── Allocation de bonus de classe ──
                if (_needsClassBonusAllocation()) ...[
                  const Divider(height: 32),
                  _buildClassBonusAllocator(agent),
                ],

                const SizedBox(height: 32),

                // ── Bouton confirmer ──
                ElevatedButton(
                  onPressed: _isFormValid() ? _applyLevelUp : null,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Confirmer la montée de niveau',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Widget : Sélecteur de classe secondaire ───────────────────────────────

  Widget _buildSecondClassSelector(Agent agent) {
    final commonClasses = getCommonClasses()
        .where((c) => c.id != agent.agentClass.id)
        .toList();

    return Column(
      children: commonClasses.map((cls) {
        final isSelected = _selectedSecondClass?.id == cls.id;
        return Card(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            title: Text(
              cls.name,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonus : ${cls.classBonus.join(", ")}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Affinités : ${cls.affinities.map((a) => a.label).join(", ")}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Compétence gratuite : ${cls.freeSkill.map((s) => s.name).join(", ")}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _selectedSecondClass = cls;
                // Reset class bonus allocations quand on change de classe
                _classBonusAllocations.clear();
              });
            },
          ),
        );
      }).toList(),
    );
  }

  // ── Widget : Section de choix (radio buttons) ─────────────────────────────

  Widget _buildChoiceSection(_LevelUpChoice choice) {
    if (choice.options.isEmpty) {
      return const SizedBox.shrink();
    }

    // Automatique ou une seule option
    if (choice.isAutomatic || choice.options.length == 1) {
      final opt = choice.options.first;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Card(
          color: Colors.green.withValues(alpha: 0.1),
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(choice.label),
            subtitle: Text(opt.label),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                choice.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              ...choice.options.map((opt) {
                return RadioListTile<String>(
                  title: Text(opt.label),
                  value: opt.id,
                  groupValue: _choices[choice.id],
                  onChanged: (value) {
                    setState(() {
                      _choices[choice.id] = value!;
                      // Reset les sous-choix quand on change d'option
                      _selectedSkill = null;
                      _selectedAttributeIndex = null;
                      _classBonusAllocations.clear();
                    });
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widget : Sélecteur de compétence ──────────────────────────────────────

  Widget _buildSkillSelector(Agent agent) {
    // Compétences disponibles = allSkills de la classe primaire + secondaire
    // moins les compétences déjà possédées
    final existingIds = agent.skills.map((s) => s.id).toSet();
    final available = <Skill>[];

    for (final skill in agent.agentClass.allSkills) {
      if (!existingIds.contains(skill.id) && !available.any((s) => s.id == skill.id)) {
        available.add(skill);
      }
    }

    final secondClass = _selectedSecondClass ?? agent.secondClass;
    if (secondClass != null) {
      for (final skill in secondClass.allSkills) {
        if (!existingIds.contains(skill.id) && !available.any((s) => s.id == skill.id)) {
          available.add(skill);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisir une compétence',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (available.isEmpty)
          const Text(
            'Aucune compétence disponible.',
            style: TextStyle(color: Colors.grey),
          )
        else
          ...available.map((skill) {
            return RadioListTile<int>(
              title: Text(skill.name),
              subtitle: Text(skill.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              value: skill.id,
              groupValue: _selectedSkill?.id,
              onChanged: (value) {
                setState(() {
                  _selectedSkill = skill;
                });
              },
            );
          }),
      ],
    );
  }

  // ── Widget : Sélecteur d'attribut ─────────────────────────────────────────

  Widget _buildAttributeSelector(Agent agent) {
    const labels = ['Physique', 'Mental', 'Relationnel'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisir une Caractéristique (+5)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(3, (i) {
          return RadioListTile<int>(
            title: Text('${labels[i]} (${agent.attributes[i]})'),
            value: i,
            groupValue: _selectedAttributeIndex,
            onChanged: (value) {
              setState(() => _selectedAttributeIndex = value);
            },
          );
        }),
      ],
    );
  }

  // ── Widget : Allocation de bonus de classe ────────────────────────────────

  Widget _buildClassBonusAllocator(Agent agent) {
    final total = _totalClassBonusPointsToAllocate();
    int allocated = 0;
    for (final v in _classBonusAllocations.values) {
      allocated += v;
    }
    final remaining = total - allocated;

    final secondClass = _selectedSecondClass ?? agent.secondClass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Répartir $total point${total > 1 ? 's' : ''} de bonus de classe',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          'Restant : $remaining',
          style: TextStyle(
            fontSize: 13,
            color: remaining == 0 ? Colors.green : Colors.orange,
          ),
        ),
        const SizedBox(height: 8),

        // Bonus primaires
        const Text('Classe principale :', style: TextStyle(fontWeight: FontWeight.w600)),
        ...List.generate(agent.agentClass.classBonus.length, (i) {
          final key = 'primary_$i';
          final current = agent.classBonuses[i];
          final added = _classBonusAllocations[key] ?? 0;
          final canAdd = remaining > 0 && (current + added) < _maxClassBonus;
          final canRemove = added > 0;

          return ListTile(
            title: Text('${agent.agentClass.classBonus[i]} ($current + $added)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: canRemove
                      ? () => setState(() => _classBonusAllocations[key] = added - 1)
                      : null,
                ),
                Text('$added'),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: canAdd
                      ? () => setState(() => _classBonusAllocations[key] = added + 1)
                      : null,
                ),
              ],
            ),
          );
        }),

        // Bonus secondaires
        if (secondClass != null) ...[
          const SizedBox(height: 8),
          const Text('Classe secondaire :', style: TextStyle(fontWeight: FontWeight.w600)),
          ...List.generate(secondClass.classBonus.length, (i) {
            final key = 'secondary_$i';
            final current = i < agent.secondClassBonuses.length
                ? agent.secondClassBonuses[i]
                : 0;
            final added = _classBonusAllocations[key] ?? 0;
            final canAdd = remaining > 0 && (current + added) < _maxClassBonus;
            final canRemove = added > 0;

            return ListTile(
              title: Text('${secondClass.classBonus[i]} ($current + $added)'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: canRemove
                        ? () => setState(() => _classBonusAllocations[key] = added - 1)
                        : null,
                  ),
                  Text('$added'),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: canAdd
                        ? () => setState(() => _classBonusAllocations[key] = added + 1)
                        : null,
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Modèles internes
// ---------------------------------------------------------------------------

class _LevelUpChoice {
  final String id;
  final String label;
  final List<_Option> options;
  final bool isAutomatic;

  const _LevelUpChoice({
    required this.id,
    required this.label,
    required this.options,
    this.isAutomatic = false,
  });
}

class _Option {
  final String id;
  final String label;

  const _Option(this.id, this.label);
}
