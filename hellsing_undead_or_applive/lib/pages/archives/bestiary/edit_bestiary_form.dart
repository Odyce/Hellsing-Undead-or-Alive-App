import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

class EditBestiaryPage extends StatefulWidget {
  const EditBestiaryPage({super.key});

  @override
  State<EditBestiaryPage> createState() => _EditBestiaryPageState();
}

class _EditBestiaryPageState extends State<EditBestiaryPage> {
  final _nameCtrl = TextEditingController();
  final _raceCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _weaknessCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _hpMinCtrl = TextEditingController();
  final _hpMaxCtrl = TextEditingController();

  Entitype _type = Entitype.demon;

  late Monster _original;
  bool _initialized = false;
  String? _hpError;
  String? _error;
  bool _loading = false;

  final MonsterRepository _repository = MonsterRepository();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _original = ModalRoute.of(context)!.settings.arguments as Monster;
      _nameCtrl.text = _original.name;
      _raceCtrl.text = _original.race;
      _descriptionCtrl.text = _original.description;
      _skillsCtrl.text = _original.skills;
      _weaknessCtrl.text = _original.weakness;
      _locationCtrl.text = _original.location;
      _hpMinCtrl.text =
          _original.hpScale.isNotEmpty ? _original.hpScale[0].toString() : '';
      _hpMaxCtrl.text =
          _original.hpScale.length > 1 ? _original.hpScale[1].toString() : '';
      _type = _original.type;
      _initialized = true;
    }
  }

  bool get _canSave {
    if (_loading) return false;
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (_raceCtrl.text.trim().isEmpty) return false;
    if (_descriptionCtrl.text.trim().isEmpty) return false;
    if (_skillsCtrl.text.trim().isEmpty) return false;
    if (_weaknessCtrl.text.trim().isEmpty) return false;
    if (_locationCtrl.text.trim().isEmpty) return false;
    if (_hpError != null) return false;
    final hpMin = int.tryParse(_hpMinCtrl.text);
    final hpMax = int.tryParse(_hpMaxCtrl.text);
    if (hpMin == null || hpMax == null) return false;
    return true;
  }

  void _validateHp() {
    final min = int.tryParse(_hpMinCtrl.text);
    final max = int.tryParse(_hpMaxCtrl.text);
    setState(() {
      if (min == null || max == null) {
        _hpError = 'Les deux valeurs doivent \u00eatre des entiers.';
      } else if (min < 0 || max < 0) {
        _hpError = 'Les PV ne peuvent pas \u00eatre n\u00e9gatifs.';
      } else if (max < min) {
        _hpError = 'Le max doit \u00eatre \u2265 au min.';
      } else {
        _hpError = null;
      }
    });
  }

  static String _typeLabel(Entitype t) => switch (t) {
        Entitype.demon  => 'D\u00e9mon',
        Entitype.angel  => 'Ange',
        Entitype.midian => 'Midian',
        Entitype.beast  => 'B\u00eate',
        Entitype.human  => 'Humain',
      };

  Future<void> _save() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fields = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'race': _raceCtrl.text.trim(),
        'type': _type.name,
        'description': _descriptionCtrl.text.trim(),
        'skills': _skillsCtrl.text.trim(),
        'weakness': _weaknessCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'hpScale': [
          int.parse(_hpMinCtrl.text),
          int.parse(_hpMaxCtrl.text),
        ],
      };

      await _repository.updateMonster(_original.id, fields);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _raceCtrl.dispose();
    _descriptionCtrl.dispose();
    _skillsCtrl.dispose();
    _weaknessCtrl.dispose();
    _locationCtrl.dispose();
    _hpMinCtrl.dispose();
    _hpMaxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier la cr\u00e9ature')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom *'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _raceCtrl,
            decoration: const InputDecoration(labelText: 'Race *'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<Entitype>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Type'),
            items: Entitype.values
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(_typeLabel(t)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _type = v);
            },
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _descriptionCtrl,
            decoration: const InputDecoration(labelText: 'Description *'),
            minLines: 3,
            maxLines: 12,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _skillsCtrl,
            decoration: const InputDecoration(labelText: 'Comp\u00e9tences *'),
            minLines: 2,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _weaknessCtrl,
            decoration: const InputDecoration(labelText: 'Faiblesse *'),
            minLines: 2,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(labelText: "Lieu d'apparition *"),
            minLines: 1,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          Text('Estimation des PV',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _hpMinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'PV min *'),
                  onChanged: (_) => _validateHp(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _hpMaxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'PV max *'),
                  onChanged: (_) => _validateHp(),
                ),
              ),
            ],
          ),

          if (_hpError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_hpError!, style: const TextStyle(color: Colors.red)),
            ),

          const SizedBox(height: 32),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSave ? _save : null,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Enregistrer les modifications'),
            ),
          ),

          Align(
            alignment: Alignment.bottomLeft,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ),
        ],
      ),
    );
  }
}
