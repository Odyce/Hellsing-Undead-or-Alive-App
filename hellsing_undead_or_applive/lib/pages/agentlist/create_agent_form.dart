import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:http/http.dart';
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
  final _physiqueCtrl = TextEditingController();
  final _mentalCtrl = TextEditingController();
  final _relationnelCtrl = TextEditingController();

  int _pv = 0;
  int _pe = 0;
  int _pm = 0;
  int _pc = 0;
  int _remainingPoints = 180;

  final RaceList _raceList = RaceList();
  int _selectedRaceIndex = 0; // 0 = Humain par défaut
  final _powerScoreCtrl = TextEditingController();

  Race get _selectedRace => _raceList.allRaces[_selectedRaceIndex];

  AgentClass? _selectedClass;
  List<int> _classBonuses = [0, 0, 0];
  final List<TextEditingController> _classBonusControllers = List.generate(3, (_) => TextEditingController());

  List<AgentClass> get _availableClasses => _selectedRace.availableClasses;

  List<Skill?> _selectedSkills = [];

  final _moneyCtrl = TextEditingController();

  final List<_ContactFormData> _contacts = [];

  int get _usedPc => _contacts.fold(0, (sum, c) => sum + c.cost);

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
  bool _loading = false;
  String? _error;

  final AgentRepository _repository = AgentRepository();

  ///////////////////////////
  // Création du chasseur  //
  ///////////////////////////
  Future<void> _createAgent() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await _uploadToCloudinary(_selectedImage!);
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

      await _repository.createAgent(
        name: _nameController.text,
        background: _backgroundController.text,
        state: _stateController.text,
        note: _noteController.text,
        profilPicturePath: imageUrl ?? '',
        attributes: [
          _parseInt(_physiqueCtrl),
          _parseInt(_mentalCtrl),
          _parseInt(_relationnelCtrl),
        ],
        pools: [_pv, _pe, _pm],
        maxPools: [_pv, _pe, _pm],
        race: _selectedRace,
        powerScore: _selectedRace.name == 'Humain' ? 0 : int.tryParse(_powerScoreCtrl.text) ?? 0,
        agentClass: _selectedClass!,
        classBonuses: _classBonuses,
        skills: _selectedSkills.map((s) => s!).toList() + _selectedClass!.freeSkill.map((s) => s).toList(),
        bagSlots: _initBagSlots(),
        bankSlots: _initBankSlots(),
        muniSlots: _initMuniSlots(),
        weaponSlots: _initWeaponSlots(),
        money: _parseInt(_moneyCtrl),
        missions: _initMissions(),
        level: 1,
        pc: _pc,
        contacts: contactsToSend,
      );

      if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/agentlist'); // retour après création
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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

  Future<String> _uploadToCloudinary(File image) async {
    const cloudName = 'hellsingundeadapp';
    const uploadPreset = 'Agent_profiles-unsigned';

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        await MultipartFile.fromPath('file', image.path),
      );

    final response = await request.send();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur upload image Cloudinary: ${response.statusCode}',
      );
    }

    final body = await response.stream.bytesToString();
    final data = jsonDecode(body);

    return data['secure_url'];
  }

  ///////////////////////
  // Gestion des stats //
  ///////////////////////
  int _parseInt(TextEditingController c) {
    return int.tryParse(c.text) ?? 0;
  }

  int _ceilDiv10(int value) => (value / 10).ceil();

  void _recomputePools() {
    final physique = _parseInt(_physiqueCtrl);
    final mental = _parseInt(_mentalCtrl);
    final relationnel = _parseInt(_relationnelCtrl);

    final maxAttr = [
      physique,
      mental,
      relationnel,
    ].reduce((a, b) => a > b ? a : b);

    setState(() {
      _pv = _ceilDiv10(maxAttr) + 2;
      _pe = _ceilDiv10(physique);
      _pm = _ceilDiv10(mental);
      _pc = _ceilDiv10(relationnel);

      if (_selectedClass?.skillNumberCases == SkillNumberCases.fifth) {
        _pm *= 2;
      }
    });

    _validateAttributes();
    _updateSkillSlots();
  }

  void _validateAttributes() {
    final physique = _parseInt(_physiqueCtrl);
    final mental = _parseInt(_mentalCtrl);
    final relationnel = _parseInt(_relationnelCtrl);

    final values = [physique, mental, relationnel];
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
    for (final c in _classBonusControllers) {
      c.text = '0';
    }
  }

  void _validateClassBonuses() {
    final total = _classBonuses.reduce((a, b) => a + b);

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

    final physique = _parseInt(_physiqueCtrl);
    final mental = _parseInt(_mentalCtrl);
    final relationnel = _parseInt(_relationnelCtrl);

    int base;

    switch (_selectedClass!.skillNumberCases) {
      case SkillNumberCases.first:
      case SkillNumberCases.third:
        base = physique;
        break;

      case SkillNumberCases.second:
      case SkillNumberCases.fourth:
      case SkillNumberCases.fifth:
        base = mental;
        break;

      case SkillNumberCases.sixth:
        base = relationnel;
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

  ////////////////////////////////////////
  // Gestion temporaire de l'inventaire //
  // A REFAIRE AU PROPRE PLUS TARD !!!! //
  ////////////////////////////////////////
  List<BagSlot> _initBagSlots() {
    return List.generate(
      10,
      (index) => BagSlot(
        id: index,
        empty: true,
      ),
    );
  }

  List<BankSlot> _initBankSlots() {
    return List.generate(
      50,
      (index) => BankSlot(
        id: index,
        empty: true,
      ),
    );
  }

  List<MuniSlot> _initMuniSlots() {
    if (_selectedClass == null) return [];

    return List.generate(
      _selectedClass!.muniSlotNumber,
      (index) => MuniSlot(
        id: index,
        empty: true,
        numberLeft: 0,
      ),
    );
  }

  List<WeaponSlot> _initWeaponSlots() {
    return [
      WeaponSlot.empty(0),
    ];
  }

  /////////////////////////////
  // Gestion des compétences //
  /////////////////////////////
  List<MissionRecord> _initMissions() {
    return [
      MissionRecord(
        id: -66, 
        title: "Foundation Training", 
        description: "Fausse mission d'entraînement pour que la liste ne soit pas vide, ne doit pas être visible.", 
        completedAt: null,
      ),
    ];
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

  late final bool canCreate = _canCreate && _powerScoreValid && _classBonusValid && _skillsValid && _moneyValid && _remainingPc >= 0;

  @override
  void dispose() {
    _nameController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final classes = _availableClasses;
    _selectedClass = classes.isNotEmpty ? classes.first : null;

    _resetClassBonuses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un Agent'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nom',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _backgroundController,
            decoration: const InputDecoration(
              labelText: 'Background',
            ),
            minLines: 3,
            maxLines: 10,
          ),
          TextField(
            controller: _stateController,
            decoration: const InputDecoration(
              labelText: 'État',
              helperText:
                  'Si tu est un robot, empoisonné sur le long termes, ou autre vicissitudes du genre, merci de le mettre ici.',
            ),
            minLines: 1,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              helperText: 'Les détails sur ton perso pour le fluff.',
            ),
            minLines: 1,
            maxLines: 6,
          ),
          const SizedBox(height: 24),
          Text(
            'Photo de profil (optionnel)',
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
                    fit: BoxFit.cover,
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

          TextField(
            controller: _physiqueCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Physique'),
            onChanged: (_) => _recomputePools(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _mentalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Mental'),
            onChanged: (_) => _recomputePools(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _relationnelCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Relationnel'),
            onChanged: (_) => _recomputePools(),
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
          Slider(
            value: _selectedRaceIndex.toDouble(),
            min: 0,
            max: (_raceList.allRaces.length - 1).toDouble(),
            divisions: _raceList.allRaces.length - 1,
            label: _selectedRace.name,
            onChanged: (value) {
              setState(() {
                _selectedRaceIndex = value.round();

                final classes = _availableClasses;
                _selectedClass = classes.isNotEmpty ? classes.first : null;

                _resetClassBonuses();
                if (_selectedRace.name == 'Humain') {
                  _powerScoreCtrl.clear();
                }
              });

              _validatePowerScore();
              _validateClassBonuses();
            },
          ),
          Center(
            child: Text(
              _selectedRace.name,
              style: Theme.of(context).textTheme.titleLarge,
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

          if (_selectedRace.bonuses != null || _selectedRace.maluses != null)
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
            decoration: const InputDecoration(
              labelText: 'Classe',
            ),
          ),
          const SizedBox(height: 12),
          Text('Bonus de classe :'),
          ..._selectedClass!.classBonus.map((b) => Text('• $b')),
          const SizedBox(height: 8),
          Text('Affinités :'),
          ..._selectedClass!.affinities.map((a) => Text('• $a')),
          const SizedBox(height: 8),
          Text('Emplacements de munitions : ${_selectedClass!.muniSlotNumber}'),
          const SizedBox(height: 16),
          Text(
            'Répartition des bonus de classe (total 9, max 6 par bonus)',
            style: Theme.of(context).textTheme.labelLarge,
          ),

          for (int i = 0; i < 3; i++)
            Row(
              children: [
                Expanded(child: Text(_selectedClass!.classBonus[i])),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _classBonusControllers[i],
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _classBonuses[i] = int.tryParse(value) ?? 0;
                      _validateClassBonuses();
                    },
                  ),
                ),
              ],
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
                    (index) => SizedBox(
                      width: itemWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<Skill>(
                            initialValue: (_selectedSkills[index] != null && _selectedClass!.allSkills.contains(_selectedSkills[index])) ? _selectedSkills[index] : null,
                            items: _selectedClass!.allSkills
                                .map(
                                  (skill) => DropdownMenuItem<Skill>(
                                    value: skill,
                                    child: Text(skill.name),
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
                    ),
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
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (canCreate || _loading) ? null : _createAgent,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Créer'),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/agentlist'),
              child: const Text("Retour"),
            ),
          ),
        ],
      ),
    );
  }
}
