import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

class CreateResDevPage extends StatefulWidget {
  const CreateResDevPage({super.key});

  @override
  State<CreateResDevPage> createState() => _CreateResDevPageState();
}

class _CreateResDevPageState extends State<CreateResDevPage> {
  // ─── Contrôleurs communs ─────────────────────────────────────────────────────
  final _nameCtrl        = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // ─── Contrôleurs ResDev ──────────────────────────────────────────────────────
  final _sizeCtrl   = TextEditingController();
  final _numberCtrl = TextEditingController();

  // ─── Contrôleurs arme ────────────────────────────────────────────────────────
  final _damageCtrl    = TextEditingController();
  final _featureCtrl   = TextEditingController();
  final _sizeCtrW      = TextEditingController();
  final _reloadCtrl    = TextEditingController();
  final _magazineCtrl  = TextEditingController();
  final _magazine2Ctrl = TextEditingController();

  // ─── Champs communs ──────────────────────────────────────────────────────────
  bool               _isWeapon  = false;
  File?              _picture;
  ResDevProject?     _selectedProject;
  String?            _selectedDocId;

  // ─── Champs ResDev ────────────────────────────────────────────────────────────
  Stockage _stockage = Stockage.bag;

  // ─── Champs arme ─────────────────────────────────────────────────────────────
  Affinities       _type       = Affinities.none;
  SubAffinities    _subType    = SubAffinities.smallOneHandBlade;
  final List<Effect> _effects  = [];
  bool             _fire       = false;
  Calibre?         _calibre;
  bool             _secondMag  = false;
  Firing?          _firing;

  // ─── Projets disponibles ─────────────────────────────────────────────────────
  // Couple (docId, projet) pour les projets dont prerequisiteCompletes == true
  // et completed == false
  List<({String docId, ResDevProject project})> _availableProjects = [];

  // ─── État ────────────────────────────────────────────────────────────────────
  String? _error;
  bool    _loading = false;

  final ResDevRepository        _resDevRepo    = ResDevRepository();
  final ResDevProjectRepository _projectRepo   = ResDevProjectRepository();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('common')
          .doc('archives')
          .collection('resdevproject')
          .where('prerequisiteCompletes', isEqualTo: true)
          .where('completed', isEqualTo: false)
          .get();

      final list = snapshot.docs
          .map((d) => (docId: d.id, project: ResDevProject.fromMap(d.data())))
          .toList();

      setState(() => _availableProjects = list);
    } catch (_) {}
  }

  // ─── Image Cloudinary ────────────────────────────────────────────────────────
  Future<String?> _uploadToCloudinary(File file) async {
    const cloudName    = 'dkbpqplya';
    const uploadPreset = 'ResDev_illustrations-unsigned';
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      return jsonDecode(body)['secure_url'] as String?;
    }
    return null;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _picture = File(picked.path));
  }

  // ─── Validation ──────────────────────────────────────────────────────────────
  bool get _canCreate {
    if (_loading) return false;
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (_descriptionCtrl.text.trim().isEmpty) return false;
    if (_selectedProject == null) return false;

    if (!_isWeapon) {
      if (_sizeCtrl.text.trim().isEmpty) return false;
      if (double.tryParse(_sizeCtrl.text.trim()) == null) return false;
    } else {
      if (_damageCtrl.text.trim().isEmpty) return false;
      if (_featureCtrl.text.trim().isEmpty) return false;
      if (_effects.isEmpty) return false;
      if (_sizeCtrW.text.trim().isEmpty) return false;
      if (double.tryParse(_sizeCtrW.text.trim()) == null) return false;
    }
    return true;
  }

  // ─── Soumission ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_canCreate) return;
    setState(() { _loading = true; _error = null; });

    try {
      String? pictureUrl;
      if (_picture != null) pictureUrl = await _uploadToCloudinary(_picture!);

      final projectId = _selectedProject!.id;

      if (!_isWeapon) {
        await _resDevRepo.createResDev(
          name:        _nameCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          picturePath: pictureUrl,
          stockage:    _stockage,
          size:        double.parse(_sizeCtrl.text.trim()),
          number:      _numberCtrl.text.trim().isNotEmpty
              ? double.tryParse(_numberCtrl.text.trim())
              : null,
          projectId: projectId,
        );
      } else {
        await _resDevRepo.createResDevWeapon(
          name:        _nameCtrl.text.trim(),
          description: _descriptionCtrl.text.trim(),
          picturePath: pictureUrl,
          damage:      _damageCtrl.text.trim(),
          feature:     _featureCtrl.text.trim(),
          type:        _type,
          subType:     _subType,
          effect:      List.from(_effects),
          size:        double.parse(_sizeCtrW.text.trim()),
          fire:        _fire,
          calibre:     _calibre,
          reload: _fire && _reloadCtrl.text.trim().isNotEmpty
              ? double.tryParse(_reloadCtrl.text.trim())
              : null,
          magazineSize: _fire && _magazineCtrl.text.trim().isNotEmpty
              ? int.tryParse(_magazineCtrl.text.trim())
              : null,
          secondMagazine:     _fire ? _secondMag : null,
          secondMagazineSize: _fire && _secondMag && _magazine2Ctrl.text.trim().isNotEmpty
              ? int.tryParse(_magazine2Ctrl.text.trim())
              : null,
          firing:    _fire ? _firing : null,
          projectId: projectId,
        );
      }

      // Marquer le projet comme complété
      await _projectRepo.setCompleted(_selectedDocId!);

      if (mounted) Navigator.of(context).pushReplacementNamed('/resDev');
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _sizeCtrl.dispose();
    _numberCtrl.dispose();
    _damageCtrl.dispose();
    _featureCtrl.dispose();
    _sizeCtrW.dispose();
    _reloadCtrl.dispose();
    _magazineCtrl.dispose();
    _magazine2Ctrl.dispose();
    super.dispose();
  }

  // ─── Helpers labels ──────────────────────────────────────────────────────────
  String _stockageLabel(Stockage s) {
    switch (s) {
      case Stockage.weapon: return 'Arme';
      case Stockage.bag:    return 'Sac';
      case Stockage.muni:   return 'Munitions';
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau R&D')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Projet associé ────────────────────────────────────────────────────
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Projet associé *'),
            initialValue: _selectedDocId,
            items: _availableProjects
                .map((e) => DropdownMenuItem(
                      value: e.docId,
                      child: Text(e.project.name),
                    ))
                .toList(),
            onChanged: (docId) {
              if (docId == null) return;
              final entry = _availableProjects
                  .firstWhere((e) => e.docId == docId);
              setState(() {
                _selectedDocId   = docId;
                _selectedProject = entry.project;
              });
            },
            hint: _availableProjects.isEmpty
                ? const Text('Aucun projet prêt')
                : const Text('Choisir un projet'),
          ),
          const SizedBox(height: 16),

          // ── Nom ──────────────────────────────────────────────────────────────
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom *'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // ── Description ───────────────────────────────────────────────────────
          TextFormField(
            controller: _descriptionCtrl,
            decoration: const InputDecoration(labelText: 'Description *'),
            maxLines: 4,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // ── Image ─────────────────────────────────────────────────────────────
          Row(
            children: [
              Text('Illustration',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Choisir'),
              ),
            ],
          ),
          if (_picture != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(_picture!, height: 160, fit: BoxFit.cover),
            ),
          ],
          const SizedBox(height: 20),

          // ── Case à cocher arme ────────────────────────────────────────────────
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: CheckboxListTile(
              title: const Text('Est-ce qu\'il s\'agit d\'une arme ?'),
              value: _isWeapon,
              onChanged: (v) => setState(() => _isWeapon = v ?? false),
            ),
          ),
          const SizedBox(height: 16),

          // ── Champs ResDev (non-arme) ──────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: !_isWeapon
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stockage
                      DropdownButtonFormField<Stockage>(
                        decoration:
                            const InputDecoration(labelText: 'Stockage *'),
                        initialValue: _stockage,
                        items: Stockage.values
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(_stockageLabel(s)),
                                ))
                            .toList(),
                        onChanged: (s) =>
                            setState(() => _stockage = s ?? _stockage),
                      ),
                      const SizedBox(height: 16),

                      // Taille
                      TextFormField(
                        controller: _sizeCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Taille *'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      TextFormField(
                        controller: _numberCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Quantité',
                          hintText: 'Laisser vide si 1',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: 16),
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // ── Champs arme ───────────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isWeapon
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dégâts
                      TextFormField(
                        controller: _damageCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Dégâts *'),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Particularité
                      TextFormField(
                        controller: _featureCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Particularité *'),
                        maxLines: 2,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Affinité
                      DropdownButtonFormField<Affinities>(
                        decoration:
                            const InputDecoration(labelText: 'Affinité *'),
                        initialValue: _type,
                        items: Affinities.values
                            .map((a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(a.name),
                                ))
                            .toList(),
                        onChanged: (a) =>
                            setState(() => _type = a ?? _type),
                      ),
                      const SizedBox(height: 16),

                      // Sous-affinité
                      DropdownButtonFormField<SubAffinities>(
                        decoration: const InputDecoration(
                            labelText: 'Sous-affinité *'),
                        initialValue: _subType,
                        items: SubAffinities.values
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name),
                                ))
                            .toList(),
                        onChanged: (s) =>
                            setState(() => _subType = s ?? _subType),
                      ),
                      const SizedBox(height: 16),

                      // Effets (multi-select)
                      Text('Effets *',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: Effect.values.map((e) {
                          return FilterChip(
                            label: Text(e.name),
                            selected: _effects.contains(e),
                            onSelected: (sel) => setState(() {
                              if (sel) {
                                _effects.add(e);
                              } else {
                                _effects.remove(e);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Taille
                      TextFormField(
                        controller: _sizeCtrW,
                        decoration:
                            const InputDecoration(labelText: 'Taille *'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),

                      // Arme à feu
                      SwitchListTile(
                        title: const Text('Arme à feu'),
                        value: _fire,
                        onChanged: (v) =>
                            setState(() { _fire = v; if (!v) _secondMag = false; }),
                        contentPadding: EdgeInsets.zero,
                      ),

                      if (_fire) ...[
                        // Calibre
                        DropdownButtonFormField<Calibre>(
                          decoration:
                              const InputDecoration(labelText: 'Calibre'),
                          initialValue: _calibre,
                          items: Calibre.values
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.name),
                                  ))
                              .toList(),
                          onChanged: (c) => setState(() => _calibre = c),
                        ),
                        const SizedBox(height: 16),

                        // Rechargement
                        TextFormField(
                          controller: _reloadCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Rechargement (tours)'),
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                        ),
                        const SizedBox(height: 16),

                        // Taille du chargeur
                        TextFormField(
                          controller: _magazineCtrl,
                          decoration: const InputDecoration(
                              labelText: 'Taille chargeur'),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),

                        // Second chargeur
                        SwitchListTile(
                          title: const Text('Second chargeur'),
                          value: _secondMag,
                          onChanged: (v) => setState(() => _secondMag = v),
                          contentPadding: EdgeInsets.zero,
                        ),

                        if (_secondMag) ...[
                          TextFormField(
                            controller: _magazine2Ctrl,
                            decoration: const InputDecoration(
                                labelText: 'Taille second chargeur'),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Mode de tir
                        DropdownButtonFormField<Firing>(
                          decoration: const InputDecoration(
                              labelText: 'Mode de tir'),
                          initialValue: _firing,
                          items: Firing.values
                              .map((f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f.name),
                                  ))
                              .toList(),
                          onChanged: (f) => setState(() => _firing = f),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  )
                : const SizedBox.shrink(),
          ),

          // ── Erreur ────────────────────────────────────────────────────────────
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
          ],

          // ── Bouton ────────────────────────────────────────────────────────────
          FilledButton(
            onPressed: _canCreate ? _submit : null,
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Créer'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
