import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/pages/agentlist/create_agent_inventory_form.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';
import 'package:image_picker/image_picker.dart';

/////////////////////////////////
// Widget pour gérer les stats //
/////////////////////////////////
class _StatBox extends StatelessWidget {
  final String label;
  final int value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value.toString(),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    );
  }
}

/////////////////////////////////
// Compteur générique avec +/- //
/////////////////////////////////
class _CounterRow extends StatelessWidget {
  final Widget labelChild;
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  const _CounterRow({
    required this.labelChild,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: labelChild),
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

/////////////////////////////////////////////////
// Libellé d'une compétence avec badge "Limité" //
/////////////////////////////////////////////////
class _SkillItemLabel extends StatelessWidget {
  final Skill skill;

  const _SkillItemLabel({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            skill.name,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (skill.limited) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Limité',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

////////////////////////////////////
// Classe pour gérer les contacts //
////////////////////////////////////
class _ContactFormData {
  int cost;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;

  _ContactFormData({
    required this.cost,
  })  : nameCtrl = TextEditingController(),
        descCtrl = TextEditingController();
}

class CreateAgentPage extends StatefulWidget {
  const CreateAgentPage({super.key});

  @override
  State<CreateAgentPage> createState() => _CreateAgentPageState();
}


//////////////////////////////////
// Classe principale du fichier //
//////////////////////////////////
class _CreateAgentPageState extends State<CreateAgentPage> {
  final _nameController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _stateController = TextEditingController();
  final _noteController = TextEditingController();
  
  File? _selectedImage;
  int _physique = 50;
  int _mental = 50;
  int _relationnel = 50;

  int _pv = 0;
  int _pe = 0;
  int _pm = 0;
  int _pc = 0;
  int _remainingPoints = 30;

  final RaceList _raceList = RaceList();
  int _selectedRaceIndex = 0; // 0 = Humain par défaut
  final _powerScoreCtrl = TextEditingController();

  Race get _selectedRace => _raceList.allRaces[_selectedRaceIndex];

  // Bonus/Malus custom pour la race "Autre"
  final List<TextEditingController> _customBonusCtrls = [];
  final List<TextEditingController> _customMalusCtrls = [];

  AgentClass? _selectedClass;
  List<int> _classBonuses = [0, 0, 0];

  List<AgentClass> get _availableClasses => _selectedRace.availableClasses;

  List<Skill?> _selectedSkills = [];

  final _moneyCtrl = TextEditingController();

  final List<_ContactFormData> _contacts = [];

  int get _usedPc => _contacts.fold(0, (sums, c) => sums + c.cost);

  int get _remainingPc => _pc - _usedPc;
  
  String? _attributesError;
  String? _powerScoreError;
  bool _powerScoreValid = true;
  String? _classBonusError;
  bool _classBonusValid = false;
  String? _skillsError;
  bool _skillsValid = false;
  String? _moneyError;
  bool _moneyValid = true;
  bool _canCreate = false;

  ///////////////////////////////////////////////
  // Navigation vers le formulaire inventaire //
  ///////////////////////////////////////////////
  void _goToInventoryForm() {
    // Déclenche toutes les validations pour s'assurer que les messages sont à jour
    _recomputePools();
    _validatePowerScore();
    _validateClassBonuses();
    _validateSkills();
    _validateMoney();

    final bool allValid = _canCreate &&
        _powerScoreValid &&
        _classBonusValid &&
        _skillsValid &&
        _moneyValid &&
        _remainingPc >= 0;

    if (!allValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le formulaire contient des erreurs. Vérifie les champs en rouge.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    List<Contact> contactsToSend;

    if (_contacts.isEmpty) {
      contactsToSend = [
        Contact(
          id: "-66",
          name: "Loki",
          description: "Tu ne vois pas ses yeux",
          contactPointsValue: 66,
        ),
      ];
    } else {
      contactsToSend = List.generate(
        _contacts.length,
        (index) {
          final c = _contacts[index];
          return Contact(
            id: index.toString(),
            name: c.nameCtrl.text,
            description: c.descCtrl.text,
            contactPointsValue: c.cost,
          );
        },
      );
    }

    // Si race "Autre", on crée une copie avec les bonus/malus custom
    // et on sauvegarde dans Firestore
    Race raceToSend = _selectedRace;
    if (_selectedRace.name == 'Autre') {
      final bonuses = _customBonusCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final maluses = _customMalusCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      raceToSend = _selectedRace.copyWith(
        bonuses: bonuses.isEmpty ? null : bonuses,
        maluses: maluses.isEmpty ? null : maluses,
      );

      // Sauvegarde dans /users/{uid}/privateResources/
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('privateResources')
            .add({
          'type': 'customRace',
          'agentName': _nameController.text,
          'bonuses': bonuses,
          'maluses': maluses,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateAgentInventoryPage(
          name: _nameController.text,
          background: _backgroundController.text,
          state: _stateController.text,
          note: _noteController.text,
          selectedImage: _selectedImage,
          attributes: [
            _physique,
            _mental,
            _relationnel,
          ],
          pools: [_pv, _pe, _pm],
          maxPools: [_pv, _pe, _pm],
          race: raceToSend,
          powerScore: _selectedRace.name == 'Humain'
              ? 0
              : int.tryParse(_powerScoreCtrl.text) ?? 0,
          agentClass: _selectedClass!,
          classBonuses: _classBonuses,
          skills: _selectedSkills.map((s) => s!).toList() +
              _selectedClass!.freeSkill.map((s) => s).toList(),
          money: _parseInt(_moneyCtrl),
          pc: _pc,
          contacts: contactsToSend,
        ),
      ),
    );
  }

  //////////////////////
  // Image de profil  //
  //////////////////////
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // compression côté client
    );

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  ///////////////////////
  // Gestion des stats //
  ///////////////////////
  int _parseInt(TextEditingController c) {
    return int.tryParse(c.text) ?? 0;
  }

  int _ceilDiv10(int value) => (value / 10).ceil();

  int get _attributesTotal => _physique + _mental + _relationnel;

  bool _canIncrementAttribute(int currentValue) =>
      currentValue < 80 && _attributesTotal < 180;

  bool _canDecrementAttribute(int currentValue) => currentValue > 20;

  void _incrementAttribute(int index) {
    if (index == 0 && _canIncrementAttribute(_physique)) {
      _physique += 5;
    } else if (index == 1 && _canIncrementAttribute(_mental)) {
      _mental += 5;
    } else if (index == 2 && _canIncrementAttribute(_relationnel)) {
      _relationnel += 5;
    } else {
      return;
    }
    _recomputePools();
  }

  void _decrementAttribute(int index) {
    if (index == 0 && _canDecrementAttribute(_physique)) {
      _physique -= 5;
    } else if (index == 1 && _canDecrementAttribute(_mental)) {
      _mental -= 5;
    } else if (index == 2 && _canDecrementAttribute(_relationnel)) {
      _relationnel -= 5;
    } else {
      return;
    }
    _recomputePools();
  }

  void _recomputePools() {
    final maxAttr = [
      _physique,
      _mental,
      _relationnel,
    ].reduce((a, b) => a > b ? a : b);

    final isVampire = _selectedRace.name.toLowerCase() == 'vampire';

    setState(() {
      _pv = isVampire ? 13 : _ceilDiv10(maxAttr) + 2;
      _pe = _ceilDiv10(_physique);
      _pm = _ceilDiv10(_mental);
      _pc = _ceilDiv10(_relationnel);

      if (_selectedClass?.skillNumberCases == SkillNumberCases.fifth) {
        _pm *= 2;
      }
    });

    _validateAttributes();
    _updateSkillSlots();
  }

  void _validateAttributes() {
    final values = [_physique, _mental, _relationnel];
    final total = values.fold(0, (a, b) => a + b);

    String? error;

    // règles de base
    if (values.any((v) => v < 0)) {
      error = 'Les valeurs doivent être positives.';
    } else if (values.any((v) => v % 5 != 0)) {
      error = 'Les valeurs doivent être des multiples de 5.';
    } else if (values.any((v) => v > 80)) {
      error = 'Aucune valeur ne peut dépasser 80.';
    } else if (total != 180) {
      error = 'Le total doit être exactement de 180.';
    }

    setState(() {
      _attributesError = error;
      _canCreate = error == null;
      _remainingPoints = 180 - total;
    });
  }

  //////////////////////////////////////////
  // Gestion du powerScore et de l'argent //
  //////////////////////////////////////////
  void _validatePowerScore() {
    if (_selectedRace.name == 'Humain') {
      setState(() {
        _powerScoreError = null;
        _powerScoreValid = true;
      });
      return;
    }

    final value = int.tryParse(_powerScoreCtrl.text);

    if (value == null) {
      _powerScoreError = 'Le pouvoir doit être un nombre.';
      _powerScoreValid = false;
    } else if (value < 0 || value > 70) {
      _powerScoreError = 'Le pouvoir doit être compris entre 0 et 70.';
      _powerScoreValid = false;
    } else {
      _powerScoreError = null;
      _powerScoreValid = true;
    }

    setState(() {});
  }

  void _validateMoney() {
    final value = int.tryParse(_moneyCtrl.text);

    if (value == null) {
      _moneyError = "L'argent doit être un nombre.";
      _moneyValid = false;
    } else if (value < 0 || value > 999) {
      _moneyError = "L'argent doit être compris entre 0 et 999.";
      _moneyValid = false;
    } else {
      _moneyError = null;
      _moneyValid = true;
    }

    setState(() {});
  }

  /////////////////////////
  // Gestion des classes //
  /////////////////////////
  void _resetClassBonuses() {
    _classBonuses = [0, 0, 0];
  }

  int get _classBonusTotal => _classBonuses.fold(0, (a, b) => a + b);

  bool _canIncrementClassBonus(int index) =>
      _classBonuses[index] < 6 && _classBonusTotal < 9;

  bool _canDecrementClassBonus(int index) => _classBonuses[index] > 0;

  void _incrementClassBonus(int index) {
    if (!_canIncrementClassBonus(index)) return;
    setState(() => _classBonuses[index]++);
    _validateClassBonuses();
  }

  void _decrementClassBonus(int index) {
    if (!_canDecrementClassBonus(index)) return;
    setState(() => _classBonuses[index]--);
    _validateClassBonuses();
  }

  void _validateClassBonuses() {
    final total = _classBonusTotal;

    String? error;

    if (_classBonuses.any((v) => v < 0)) {
      error = 'Les bonus doivent être positifs.';
    } else if (_classBonuses.any((v) => v > 6)) {
      error = 'Aucun bonus ne peut dépasser 6.';
    } else if (total != 9) {
      error = 'Le total des bonus de classe doit être 9.';
    }

    setState(() {
      _classBonusError = error;
      _classBonusValid = error == null;
    });
  }

  /////////////////////////////
  // Gestion des compétences //
  /////////////////////////////
  int _computeSkillCount() {
    if (_selectedClass == null) return 0;

    int base;

    switch (_selectedClass!.skillNumberCases) {
      case SkillNumberCases.first:
      case SkillNumberCases.third:
        base = _physique;
        break;

      case SkillNumberCases.second:
      case SkillNumberCases.fourth:
      case SkillNumberCases.fifth:
        base = _mental;
        break;

      case SkillNumberCases.sixth:
        base = _relationnel;
        break;
    }

    return (base / 20).ceil();
  }

  void _updateSkillSlots() {
    final count = _computeSkillCount();

    setState(() {
      if (_selectedSkills.length != count) {
        _selectedSkills = List.generate(count, (_) => null);
      }
    });

    _validateSkills();
  }

  void _validateSkills() {
    final selected = _selectedSkills.whereType<Skill>().toList();

    if (selected.length != _selectedSkills.length) {
      _skillsError = 'Tous les skills doivent être sélectionnés.';
      _skillsValid = false;
    } else if (selected.toSet().length != selected.length) {
      _skillsError = 'Les skills doivent être différents.';
      _skillsValid = false;
    } else {
      _skillsError = null;
      _skillsValid = true;
    }

    setState(() {});
  }

  //////////////////////////
  // Gestion des contacts //
  //////////////////////////
  void _addContact() {
    if (_remainingPc <= 0) return;

    setState(() {
      _contacts.add(_ContactFormData(cost: 1));
    });
  }

  void _removeContact(int index) {
    setState(() {
      _contacts.removeAt(index);
    });
  }

  List<int> _availableCosts(int currentCost) {
    final bool isVampire =
        _selectedRace.name.toLowerCase() == 'vampire';

    final int max = isVampire ? 5 : 4;

    return List.generate(max, (i) => i + 1)
        .where((value) {
          final simulatedUsed =
              _usedPc - currentCost + value;
          return simulatedUsed <= _pc;
        })
        .toList();
  }

  // ── Builder pour bonus/malus custom (race "Autre") ─────────────────────
  Widget _buildCustomBonusMalus() {
    Widget buildEditableList({
      required String title,
      required Color color,
      required List<TextEditingController> controllers,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color,)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => setState(() => controllers.add(TextEditingController())),
              ),
            ],
          ),
          for (int i = 0; i < controllers.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controllers[i],
                      decoration: InputDecoration(
                        hintText: '$title ${i + 1}',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  if (controllers.length > 1)
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline, size: 20, color: color),
                      onPressed: () => setState(() {
                        controllers[i].dispose();
                        controllers.removeAt(i);
                      }),
                    ),
                ],
              ),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildEditableList(
          title: 'Bonus',
          color: Colors.green,
          controllers: _customBonusCtrls,
        ),
        const SizedBox(height: 8),
        buildEditableList(
          title: 'Malus',
          color: Colors.red,
          controllers: _customMalusCtrls,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _backgroundController.dispose();
    for (final c in _customBonusCtrls) { c.dispose(); }
    for (final c in _customMalusCtrls) { c.dispose(); }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final classes = _availableClasses;
    _selectedClass = classes.isNotEmpty ? classes.first : null;

    _resetClassBonuses();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recomputePools();
      _validateClassBonuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: const Text('Créer un Agent'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nom',
              labelStyle: GoogleFonts.cinzelDecorative(fontSize: 15),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _backgroundController,
            decoration: InputDecoration(
              labelText: 'Background',
              labelStyle: GoogleFonts.cinzelDecorative(fontSize: 15),
            ),
            minLines: 3,
            maxLines: 10,
          ),
          TextField(
            controller: _stateController,
            decoration: InputDecoration(
              labelText: 'État',
              labelStyle: GoogleFonts.cinzelDecorative(fontSize: 15),
              helperText:
                  'Si tu est un robot, empoisonné sur le long termes, ou autre vicissitudes du genre, merci de le mettre ici.',
            ),
            minLines: 1,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: InputDecoration(
              labelText: 'Notes',
              labelStyle: GoogleFonts.cinzelDecorative(fontSize: 15),
              helperText: 'Les détails sur ton perso pour le fluff.',
            ),
            minLines: 1,
            maxLines: 6,
          ),
          const SizedBox(height: 24),
          Text(
            'Photo de profil (optionnel)   (10,20Mo MAX)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),

          if (_selectedImage != null)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _selectedImage!,
                    height: 150,
                    width: 150,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),

          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: const Text('Choisir une image'),
          ),

          _CounterRow(
            labelChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Physique',
                    style: GoogleFonts.cinzelDecorative(fontSize: 15)),
                Text(
                  'Pas de 5, entre 20 et 80',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            value: _physique,
            onDecrement: _canDecrementAttribute(_physique)
                ? () => _decrementAttribute(0)
                : null,
            onIncrement: _canIncrementAttribute(_physique)
                ? () => _incrementAttribute(0)
                : null,
          ),
          _CounterRow(
            labelChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mental',
                    style: GoogleFonts.cinzelDecorative(fontSize: 15)),
                Text(
                  'Pas de 5, entre 20 et 80',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            value: _mental,
            onDecrement: _canDecrementAttribute(_mental)
                ? () => _decrementAttribute(1)
                : null,
            onIncrement: _canIncrementAttribute(_mental)
                ? () => _incrementAttribute(1)
                : null,
          ),
          _CounterRow(
            labelChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Relationnel',
                    style: GoogleFonts.cinzelDecorative(fontSize: 15)),
                Text(
                  'Pas de 5, entre 20 et 80',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            value: _relationnel,
            onDecrement: _canDecrementAttribute(_relationnel)
                ? () => _decrementAttribute(2)
                : null,
            onIncrement: _canIncrementAttribute(_relationnel)
                ? () => _incrementAttribute(2)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            'Points restants à distribuer : $_remainingPoints',
            style: TextStyle(
              color: _remainingPoints == 0 ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_attributesError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _attributesError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatBox(label: 'PV', value: _pv),
              _StatBox(label: 'PE', value: _pe),
              _StatBox(label: 'PM', value: _pm),
              _StatBox(label: 'PC', value: _pc),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Race',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_raceList.allRaces.length, (index) {
                final race = _raceList.allRaces[index];
                final isSelected = index == _selectedRaceIndex;
                const raceIcons = [
                  'assets/icons/race_humain.png',
                  'assets/icons/race_semi_ange.png',
                  'assets/icons/race_vampire.png',
                  'assets/icons/race_demi_vampire.png',
                  'assets/icons/race_other.png',
                ];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRaceIndex = index;

                      final classes = _availableClasses;
                      _selectedClass = classes.isNotEmpty ? classes.first : null;

                      _resetClassBonuses();
                      if (_selectedRace.name == 'Humain') {
                        _powerScoreCtrl.clear();
                      }

                      // Reset custom bonus/malus
                      for (final c in _customBonusCtrls) { c.dispose(); }
                      for (final c in _customMalusCtrls) { c.dispose(); }
                      _customBonusCtrls.clear();
                      _customMalusCtrls.clear();
                      if (_selectedRace.name == 'Autre') {
                        _customBonusCtrls.add(TextEditingController());
                        _customMalusCtrls.add(TextEditingController());
                      }
                    });

                    _recomputePools();
                    _validatePowerScore();
                    _validateClassBonuses();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withAlpha(25)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          raceIcons[index],
                          width: 52,
                          height: 52,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          race.name,
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _selectedRace.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),

          // ── Bonus / Malus ──────────────────────────────────────
          if (_selectedRace.name == 'Autre')
            _buildCustomBonusMalus()
          else if (_selectedRace.bonuses != null || _selectedRace.maluses != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedRace.bonuses != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bonus',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      ..._selectedRace.bonuses!.map(
                        (b) => Text('• $b'),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                if (_selectedRace.maluses != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Malus',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      ..._selectedRace.maluses!.map(
                        (m) => Text('• $m'),
                      ),
                    ],
                  ),
              ],
            ),

          if (_selectedRace.name != 'Humain') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _powerScoreCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Pouvoir',
                labelStyle: GoogleFonts.cinzelDecorative(fontSize: 15),
                helperText:
                    'Fait un jet de dès auprès d\'un MJ pour remplir.',
                errorText: _powerScoreError,
              ),
              onChanged: (_) => _validatePowerScore(),
            ),
          ],

          const SizedBox(height: 24),
          Text(
            'Classe',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          DropdownButtonFormField<AgentClass>(
            initialValue: _selectedClass,
            items: _availableClasses
                .map(
                  (agentClass) => DropdownMenuItem<AgentClass>(
                    value: agentClass,
                    child: Text(agentClass.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedClass = value;
                _selectedSkills = [];
                _resetClassBonuses();
              });
              _recomputePools();
              _updateSkillSlots();
              _validateClassBonuses();
            },
            decoration: InputDecoration(
              labelText: 'Classe',
            ),
          ),
          const SizedBox(height: 12),
          Text('Bonus de classe :'),
          ..._selectedClass!.classBonus.map((b) => Text('• $b')),
          const SizedBox(height: 8),
          Text('Affinités :'),
          ..._selectedClass!.affinities.map((a) => Text('• ${a.label}')),
          const SizedBox(height: 8),
          Text('Emplacements de munitions : ${_selectedClass!.muniSlotNumber}'),
          const SizedBox(height: 16),
          Text(
            'Répartition des bonus de classe (total 9, max 6 par bonus)',
            style: Theme.of(context).textTheme.labelLarge,
          ),

          for (int i = 0; i < 3; i++)
            _CounterRow(
              labelChild: Text(_selectedClass!.classBonus[i]),
              value: _classBonuses[i],
              onDecrement: _canDecrementClassBonus(i)
                  ? () => _decrementClassBonus(i)
                  : null,
              onIncrement: _canIncrementClassBonus(i)
                  ? () => _incrementClassBonus(i)
                  : null,
            ),

          if (_classBonusError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _classBonusError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          
          if (_selectedClass != null) ...[
            const SizedBox(height: 24),
            Text(
              _selectedClass!.skillNumberReminder,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 16),

          if (_selectedSkills.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                final double itemWidth =
                    (constraints.maxWidth - 12) / 2; // 2 colonnes

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    _selectedSkills.length,
                    (index) {
                      final selectedElsewhere = <Skill>{
                        for (int j = 0; j < _selectedSkills.length; j++)
                          if (j != index && _selectedSkills[j] != null)
                            _selectedSkills[j]!,
                      };
                      final availableSkills = _selectedClass!.allSkills
                          .where((s) => !selectedElsewhere.contains(s))
                          .toList();

                      return SizedBox(
                        width: itemWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<Skill>(
                              isExpanded: true,
                              initialValue: (_selectedSkills[index] != null && availableSkills.contains(_selectedSkills[index])) ? _selectedSkills[index] : null,
                              items: availableSkills
                                  .map(
                                    (skill) => DropdownMenuItem<Skill>(
                                      value: skill,
                                      child: _SkillItemLabel(skill: skill),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSkills[index] = value;
                                });
                                _validateSkills();
                              },
                              decoration: InputDecoration(
                                labelText: 'Skill ${index + 1}',
                              ),
                            ),
                            if (_selectedSkills[index] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _selectedSkills[index]!.description,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

          if (_skillsError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _skillsError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          
          const SizedBox(height: 16),
            TextField(
              controller: _moneyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Argent',
                labelStyle: GoogleFonts.cinzelDecorative(fontSize: 15),
                helperText:
                    'Fait un jet de dès auprès d\'un MJ pour remplir.',
                errorText: _moneyError,
              ),
              onChanged: (_) => _validateMoney(),
            ),
          
          const SizedBox(height: 32),
          Text(
            "Contact :",
            style: Theme.of(context).textTheme.titleMedium,
          ),

          Row(
            children: [
              if (_remainingPc > 0)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addContact,
                ),
              if (_contacts.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _removeContact(_contacts.length - 1),
                ),
            ],
          ),

          for (int i = 0; i < _contacts.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final double costWidth = 90;
                  final nameWidth = (width - costWidth - 24) * 0.35;
                  final descWidth = (width - costWidth - 24) * 0.65;

                  final contact = _contacts[i];

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: costWidth,
                        child: DropdownButtonFormField<int>(
                          initialValue: contact.cost,
                          items: _availableCosts(contact.cost)
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              contact.cost = value;
                            });
                          },
                          decoration:
                              const InputDecoration(labelText: "Coût"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: nameWidth,
                        child: TextField(
                          controller: contact.nameCtrl,
                          decoration:
                              const InputDecoration(labelText: "Nom"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: descWidth,
                        child: TextField(
                          controller: contact.descCtrl,
                          decoration: const InputDecoration(
                              labelText: "Description"),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          
          Text(
            "Points de contacts restants : $_remainingPc",
            style: TextStyle(
              color: _remainingPc >= 0
                  ? Colors.green
                  : Colors.red,
            ),
          ),



          //
          //Fin du formulaire
          // late final bool canCreate = _canCreate && _powerScoreValid && _classBonusValid && _skillsValid && _moneyValid && _remainingPc >= 0;
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToInventoryForm,
              child: const Text('Suivant'),
            ),
          ),
        ],
      ),
    );
  }
}
