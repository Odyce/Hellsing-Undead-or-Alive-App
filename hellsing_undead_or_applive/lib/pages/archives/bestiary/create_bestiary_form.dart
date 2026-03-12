import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

class CreateBestiaryPage extends StatefulWidget {
  const CreateBestiaryPage({super.key});

  @override
  State<CreateBestiaryPage> createState() => _CreateBestiaryPageState();
}

class _CreateBestiaryPageState extends State<CreateBestiaryPage> {
  // ─── Contrôleurs ────────────────────────────────────────────────────────────
  final _nameCtrl        = TextEditingController();
  final _raceCtrl        = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _skillsCtrl      = TextEditingController();
  final _weaknessCtrl    = TextEditingController();
  final _locationCtrl    = TextEditingController();
  final _hpMinCtrl       = TextEditingController();
  final _hpMaxCtrl       = TextEditingController();

  // ─── Champ enum ─────────────────────────────────────────────────────────────
  Entitype _type = Entitype.demon;

  // ─── Illustrations ───────────────────────────────────────────────────────────
  final List<File> _illustrations = [];

  // ─── État ────────────────────────────────────────────────────────────────────
  String? _hpError;
  String? _error;
  bool    _loading = false;

  final MonsterRepository _repository = MonsterRepository();

  // ─── Validation ──────────────────────────────────────────────────────────────
  bool get _canCreate {
    if (_loading) return false;
    if (_nameCtrl.text.trim().isEmpty)        return false;
    if (_raceCtrl.text.trim().isEmpty)        return false;
    if (_descriptionCtrl.text.trim().isEmpty) return false;
    if (_skillsCtrl.text.trim().isEmpty)      return false;
    if (_weaknessCtrl.text.trim().isEmpty)    return false;
    if (_locationCtrl.text.trim().isEmpty)    return false;
    if (_hpError != null)                     return false;
    final min = int.tryParse(_hpMinCtrl.text);
    final max = int.tryParse(_hpMaxCtrl.text);
    if (min == null || max == null)           return false;
    return true;
  }

  void _validateHp() {
    final min = int.tryParse(_hpMinCtrl.text);
    final max = int.tryParse(_hpMaxCtrl.text);
    setState(() {
      if (min == null || max == null) {
        _hpError = 'Les deux valeurs doivent être des entiers.';
      } else if (min < 0 || max < 0) {
        _hpError = 'Les PV ne peuvent pas être négatifs.';
      } else if (min > max) {
        _hpError = 'Le minimum ne peut pas dépasser le maximum.';
      } else {
        _hpError = null;
      }
    });
  }

  // ─── Illustrations ────────────────────────────────────────────────────────────
  Future<void> _addIllustration() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _illustrations.add(File(picked.path)));
    }
  }

  void _removeIllustration(int index) =>
      setState(() => _illustrations.removeAt(index));

  Future<String> _uploadIllustration(File image) async {
    const cloudName    = 'hellsingundeadapp';
    const uploadPreset = 'Monster_illustrations-unsigned';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur upload illustration Cloudinary : ${response.statusCode}',
      );
    }
    final body = await response.stream.bytesToString();
    return jsonDecode(body)['secure_url'] as String;
  }

  // ─── Labels ───────────────────────────────────────────────────────────────────
  String _typeLabel(Entitype t) => switch (t) {
        Entitype.demon   => 'Démon',
        Entitype.angel   => 'Ange',
        Entitype.midian  => 'Midian',
        Entitype.beast   => 'Bête',
        Entitype.human   => 'Humain',
      };

  // ─── Création ────────────────────────────────────────────────────────────────
  Future<void> _createMonster() async {
    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      List<String>? illustrationUrls;
      if (_illustrations.isNotEmpty) {
        illustrationUrls = [];
        for (final img in _illustrations) {
          illustrationUrls.add(await _uploadIllustration(img));
        }
      }

      await _repository.createMonster(
        name:              _nameCtrl.text.trim(),
        type:              _type,
        race:              _raceCtrl.text.trim(),
        illustrationPaths: illustrationUrls,
        description:       _descriptionCtrl.text.trim(),
        skills:            _skillsCtrl.text.trim(),
        weakness:          _weaknessCtrl.text.trim(),
        location:          _locationCtrl.text.trim(),
        hpScale:           [
          int.parse(_hpMinCtrl.text),
          int.parse(_hpMaxCtrl.text),
        ],
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/bestiary');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Dispose ──────────────────────────────────────────────────────────────────
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

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle entrée bestiaire')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Nom ──────────────────────────────────────────────────────────────
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom *'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // ── Type ─────────────────────────────────────────────────────────────
          DropdownButtonFormField<Entitype>(
            initialValue: _type,
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

          // ── Race ─────────────────────────────────────────────────────────────
          TextField(
            controller: _raceCtrl,
            decoration: const InputDecoration(labelText: 'Race *'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // ── Illustrations (multi-upload) ──────────────────────────────────────
          Text('Illustrations', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          if (_illustrations.isNotEmpty) ...[
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _illustrations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _illustrations[i],
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: GestureDetector(
                        onTap: () => _removeIllustration(i),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          ElevatedButton.icon(
            onPressed: _addIllustration,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Ajouter une illustration'),
          ),
          const SizedBox(height: 24),

          // ── Description ───────────────────────────────────────────────────────
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          TextField(
            controller: _descriptionCtrl,
            decoration: const InputDecoration(
              labelText: 'Description *',
              helperText: 'Présentation générale de la créature.',
            ),
            minLines: 3,
            maxLines: 12,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // ── Compétences ───────────────────────────────────────────────────────
          Text('Compétences', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          TextField(
            controller: _skillsCtrl,
            decoration: const InputDecoration(
              labelText: 'Compétences *',
              helperText: 'Capacités et pouvoirs spéciaux.',
            ),
            minLines: 2,
            maxLines: 8,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // ── Faiblesse ─────────────────────────────────────────────────────────
          Text('Faiblesse', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          TextField(
            controller: _weaknessCtrl,
            decoration: const InputDecoration(
              labelText: 'Faiblesse *',
              helperText: 'Ce qui peut blesser ou tuer la créature.',
            ),
            minLines: 1,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // ── Lieu d'apparition ─────────────────────────────────────────────────
          Text("Lieu d'apparition",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              labelText: 'Lieu *',
              helperText:
                  "Où cette créature est-elle susceptible d'apparaître ?",
            ),
            minLines: 1,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // ── Estimation des PV ─────────────────────────────────────────────────
          Text('Estimation des PV',
              style: Theme.of(context).textTheme.titleMedium),
          const Text(
            'Fourchette de points de vie estimée pour cette créature.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _hpMinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minimum *'),
                  onChanged: (_) => _validateHp(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _hpMaxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Maximum *'),
                  onChanged: (_) => _validateHp(),
                ),
              ),
            ],
          ),

          if (_hpError != null) ...[
            const SizedBox(height: 4),
            Text(
              _hpError!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
          const SizedBox(height: 32),

          // ── Erreur & bouton création ──────────────────────────────────────────
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canCreate ? _createMonster : null,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("Créer l'entrée"),
            ),
          ),

          Align(
            alignment: Alignment.bottomLeft,
            child: TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/bestiary'),
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }
}
