import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class CreateArtefactPage extends StatefulWidget {
  const CreateArtefactPage({super.key});

  @override
  State<CreateArtefactPage> createState() => _CreateArtefactPageState();
}

class _CreateArtefactPageState extends State<CreateArtefactPage> {
  // ─── Contrôleurs communs ─────────────────────────────────────────────────────
  final _nameCtrl        = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _effectCtrl      = TextEditingController(); // Artefacts uniquement
  final _usesLeftCtrl    = TextEditingController();

  // ─── Contrôleurs arme ────────────────────────────────────────────────────────
  final _damageCtrl      = TextEditingController();
  final _featureCtrl     = TextEditingController();
  final _sizeCtrl        = TextEditingController();
  final _reloadCtrl      = TextEditingController();
  final _magazineCtrl    = TextEditingController();
  final _magazine2Ctrl   = TextEditingController();

  // ─── Champs communs ──────────────────────────────────────────────────────────
  bool     _isWeapon    = false;
  bool     _limitedUses = false;
  File?    _picture;
  Mission? _missionRetrievedAt;
  DateTime? _dateRetrievedAt;

  // ─── Missions disponibles (pour le dropdown) ─────────────────────────────────
  List<Mission> _missions = [];

  // ─── Champs arme ─────────────────────────────────────────────────────────────
  Affinities       _type        = Affinities.none;
  SubAffinities    _subType     = SubAffinities.smallOneHandBlade;
  final List<Effect> _effects   = [];
  bool             _fire        = false;
  Calibre?         _calibre;
  bool             _secondMag   = false;
  Firing?          _firing;

  // ─── État ────────────────────────────────────────────────────────────────────
  String? _error;
  bool    _loading = false;

  final ArtefactRepository _repository = ArtefactRepository();

  // ─── Init ────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('common')
          .doc('archives')
          .collection('missions')
          .get();
      final missions = snapshot.docs
          .map((d) => Mission.fromMap(d.data()))
          .toList();
      setState(() => _missions = missions);
    } catch (_) {}
  }

  // ─── Validation ──────────────────────────────────────────────────────────────
  bool get _canCreate {
    if (_loading) return false;
    if (_nameCtrl.text.trim().isEmpty)        return false;
    if (_descriptionCtrl.text.trim().isEmpty) return false;
    if (!_isWeapon && _effectCtrl.text.trim().isEmpty) return false;
    if (_limitedUses) {
      final v = int.tryParse(_usesLeftCtrl.text);
      if (v == null || v < 0) return false;
    }
    if (_isWeapon) {
      if (_damageCtrl.text.trim().isEmpty)  return false;
      if (_featureCtrl.text.trim().isEmpty) return false;
      if (_effects.isEmpty)                 return false;
      final size = double.tryParse(_sizeCtrl.text.replaceAll(',', '.'));
      if (size == null || size < 0)         return false;
    }
    return true;
  }

  // ─── Image ───────────────────────────────────────────────────────────────────
  Future<void> _pickPicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _picture = File(picked.path));
  }

  void _removePicture() => setState(() => _picture = null);

  Future<String> _uploadPicture(File image) async {
    const cloudName    = 'hellsingundeadapp';
    const uploadPreset = 'Artefact_illustrations-unsigned';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur upload Cloudinary : ${response.statusCode}',
      );
    }
    final body = await response.stream.bytesToString();
    return jsonDecode(body)['secure_url'] as String;
  }

  // ─── Sélection date ──────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateRetrievedAt ?? DateTime.now(),
      firstDate: DateTime(1800),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dateRetrievedAt = picked);
  }

  // ─── Création ────────────────────────────────────────────────────────────────
  Future<void> _create() async {
    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      String? pictureUrl;
      if (_picture != null) pictureUrl = await _uploadPicture(_picture!);

      final usesLeft = _limitedUses
          ? int.tryParse(_usesLeftCtrl.text)
          : null;

      if (_isWeapon) {
        final size = double.parse(_sizeCtrl.text.replaceAll(',', '.'));
        await _repository.createArtefactWeapon(
          name:               _nameCtrl.text.trim(),
          description:        _descriptionCtrl.text.trim(),
          picturePath:        pictureUrl,
          damage:             _damageCtrl.text.trim(),
          feature:            _featureCtrl.text.trim(),
          type:               _type,
          subType:            _subType,
          effect:             _effects,
          size:               size,
          fire:               _fire,
          calibre:            _fire ? _calibre : null,
          reload:             _fire
              ? double.tryParse(_reloadCtrl.text.replaceAll(',', '.'))
              : null,
          magazineSize:       _fire
              ? int.tryParse(_magazineCtrl.text)
              : null,
          secondMagazine:     _fire ? _secondMag : null,
          secondMagazineSize: (_fire && _secondMag)
              ? int.tryParse(_magazine2Ctrl.text)
              : null,
          firing:             _fire ? _firing : null,
          limitedUses:        _limitedUses,
          usesLeft:           usesLeft,
          missionRetrievedAt: _missionRetrievedAt,
          dateRetrievedAt:    _dateRetrievedAt,
        );
      } else {
        await _repository.createArtefact(
          name:               _nameCtrl.text.trim(),
          description:        _descriptionCtrl.text.trim(),
          picturePath:        pictureUrl,
          effect:             _effectCtrl.text.trim(),
          limitedUses:        _limitedUses,
          usesLeft:           usesLeft,
          missionRetrievedAt: _missionRetrievedAt,
          dateRetrievedAt:    _dateRetrievedAt,
        );
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.artefacts);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Labels ───────────────────────────────────────────────────────────────────
  String _affinityLabel(Affinities a) => switch (a) {
        Affinities.firearm          => 'Arme à feu',
        Affinities.explosive        => 'Explosif',
        Affinities.oneHandBlade     => 'Lame 1 main',
        Affinities.twoHandBlade     => 'Lame 2 mains',
        Affinities.bow              => 'Arc',
        Affinities.throwable        => 'Lancer',
        Affinities.none             => 'Aucun',
        Affinities.choiceNonExplosive => 'Choix (non explosif)',
      };

  String _subAffinityLabel(SubAffinities s) => switch (s) {
        SubAffinities.smallOneHandBlade => 'Petite lame 1 main',
        SubAffinities.bigOneHandBlade   => 'Grande lame 1 main',
        SubAffinities.smallTwoHandBlade => 'Petite lame 2 mains',
        SubAffinities.bigTwoHandBlade   => 'Grande lame 2 mains',
        SubAffinities.bow               => 'Arc',
        SubAffinities.throwable         => 'Lancer',
        SubAffinities.smallHandgun      => 'Petit pistolet',
        SubAffinities.bigHandgun        => 'Grand pistolet',
        SubAffinities.dispersion        => 'Dispersion',
        SubAffinities.smallRifle        => 'Petit fusil',
        SubAffinities.bigRifle          => 'Grand fusil',
      };

  String _effectLabel(Effect e) => switch (e) {
        Effect.none            => 'Aucun',
        Effect.blessed         => 'Bénie',
        Effect.blessedAggr     => 'Bénie (aggravé)',
        Effect.holy            => 'Sainte',
        Effect.silver          => 'Argent',
        Effect.silverAggr      => 'Argent (aggravé)',
        Effect.mercury         => 'Mercure',
        Effect.mercuryAggr     => 'Mercure (aggravé)',
        Effect.piercing        => 'Perforant',
        Effect.piercingAggr    => 'Perforant (aggravé)',
        Effect.incendiary      => 'Incendiaire',
        Effect.incendiaryAggr  => 'Incendiaire (aggravé)',
        Effect.burning         => 'Brûlant',
        Effect.burningAggr     => 'Brûlant (aggravé)',
        Effect.bleed           => 'Saignement',
        Effect.bleedAggr       => 'Saignement (aggravé)',
      };

  String _firingLabel(Firing f) => switch (f) {
        Firing.none            => 'Aucun',
        Firing.sA              => 'Simple action',
        Firing.dA              => 'Double action',
        Firing.multiple        => 'Multiple',
        Firing.semA            => 'Semi-automatique',
        Firing.separedTrigger  => 'Gâchettes séparées',
        Firing.mLev            => 'Levier',
        Firing.mVer            => 'Verrou',
      };

  // ─── Dispose ──────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _effectCtrl.dispose();
    _usesLeftCtrl.dispose();
    _damageCtrl.dispose();
    _featureCtrl.dispose();
    _sizeCtrl.dispose();
    _reloadCtrl.dispose();
    _magazineCtrl.dispose();
    _magazine2Ctrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel artefact')),
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

          // ── Description ───────────────────────────────────────────────────────
          TextField(
            controller: _descriptionCtrl,
            decoration: const InputDecoration(
              labelText: 'Description *',
              helperText: 'Présentation générale de l\'artefact.',
            ),
            minLines: 3,
            maxLines: 12,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),

          // ── Illustration ──────────────────────────────────────────────────────
          Text('Illustration', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          if (_picture != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _picture!,
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: _removePicture,
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
            const SizedBox(height: 8),
          ],

          ElevatedButton.icon(
            onPressed: _pickPicture,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Ajouter une illustration'),
          ),
          const SizedBox(height: 24),

          // ── Usages limités ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Usages limités',
                  style: Theme.of(context).textTheme.titleMedium),
              Switch(
                value: _limitedUses,
                onChanged: (v) => setState(() {
                  _limitedUses = v;
                  if (!v) _usesLeftCtrl.clear();
                }),
              ),
            ],
          ),

          if (_limitedUses) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _usesLeftCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Usages restants *'),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 24),

          // ── Mission liée ──────────────────────────────────────────────────────
          Text('Mission liée', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          DropdownButtonFormField<Mission?>(
            initialValue: _missionRetrievedAt,
            decoration: const InputDecoration(labelText: 'Mission (optionnel)'),
            items: [
              const DropdownMenuItem(value: null, child: Text('— Aucune —')),
              ..._missions.map(
                (m) => DropdownMenuItem(value: m, child: Text(m.title)),
              ),
            ],
            onChanged: (v) => setState(() => _missionRetrievedAt = v),
          ),
          const SizedBox(height: 16),

          // ── Date de récupération ──────────────────────────────────────────────
          Text("Date de récupération",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: Text(
                  _dateRetrievedAt != null
                      ? '${_dateRetrievedAt!.day.toString().padLeft(2, '0')}/'
                        '${_dateRetrievedAt!.month.toString().padLeft(2, '0')}/'
                        '${_dateRetrievedAt!.year}'
                      : 'Non renseignée',
                  style: TextStyle(
                    color: _dateRetrievedAt != null
                        ? null
                        : Colors.grey,
                  ),
                ),
              ),
              TextButton(
                onPressed: _pickDate,
                child: const Text('Choisir'),
              ),
              if (_dateRetrievedAt != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () =>
                      setState(() => _dateRetrievedAt = null),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Case à cocher : est-ce une arme ? ────────────────────────────────
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: CheckboxListTile(
              title: const Text(
                "Est-ce qu'il s'agit d'une arme ?",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              value: _isWeapon,
              onChanged: (v) => setState(() => _isWeapon = v ?? false),
            ),
          ),
          const SizedBox(height: 16),

          // ══ Section commune artefact simple ═══════════════════════════════════
          if (!_isWeapon) ...[
            Text('Effet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _effectCtrl,
              decoration: const InputDecoration(
                labelText: 'Effet *',
                helperText: 'Description de l\'effet de l\'artefact.',
              ),
              minLines: 2,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 32),
          ],

          // ══ Section arme (visible si _isWeapon) ═══════════════════════════════
          if (_isWeapon) ...[

            // ── Dégâts ────────────────────────────────────────────────────────
            Text('Dégâts', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _damageCtrl,
              decoration: const InputDecoration(labelText: 'Dégâts *'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // ── Caractéristiques ──────────────────────────────────────────────
            Text('Caractéristiques',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _featureCtrl,
              decoration: const InputDecoration(
                labelText: 'Caractéristiques *',
                helperText: 'Propriétés spéciales de l\'arme.',
              ),
              minLines: 2,
              maxLines: 6,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),

            // ── Type (Affinities) ─────────────────────────────────────────────
            DropdownButtonFormField<Affinities>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type *'),
              items: Affinities.values
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(_affinityLabel(a)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
            const SizedBox(height: 16),

            // ── Sous-type (SubAffinities) ─────────────────────────────────────
            DropdownButtonFormField<SubAffinities>(
              initialValue: _subType,
              decoration: const InputDecoration(labelText: 'Sous-type *'),
              items: SubAffinities.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(_subAffinityLabel(s)),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _subType = v);
              },
            ),
            const SizedBox(height: 24),

            // ── Effets (multi-sélection) ──────────────────────────────────────
            Text('Effets *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_effects.isEmpty)
              const Text(
                'Sélectionnez au moins un effet.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: Effect.values.map((e) {
                final selected = _effects.contains(e);
                return FilterChip(
                  label: Text(
                    _effectLabel(e),
                    style: TextStyle(fontSize: 12),
                  ),
                  selected: selected,
                  onSelected: (on) => setState(() {
                    if (on) {
                      _effects.add(e);
                    } else {
                      _effects.remove(e);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Taille ────────────────────────────────────────────────────────
            TextField(
              controller: _sizeCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Taille *',
                helperText: 'Encombrement (valeur décimale).',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // ── Arme à feu ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Arme à feu',
                    style: Theme.of(context).textTheme.titleMedium),
                Switch(
                  value: _fire,
                  onChanged: (v) => setState(() => _fire = v),
                ),
              ],
            ),

            // ── Champs spécifiques arme à feu ─────────────────────────────────
            if (_fire) ...[
              const SizedBox(height: 16),

              DropdownButtonFormField<Calibre?>(
                initialValue: _calibre,
                decoration:
                    const InputDecoration(labelText: 'Calibre (optionnel)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                  ...Calibre.values.map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _calibre = v),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _reloadCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Rechargement (optionnel)',
                  helperText: 'Nombre d\'actions pour recharger.',
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _magazineCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Taille du chargeur (optionnel)',
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Second chargeur'),
                  Switch(
                    value: _secondMag,
                    onChanged: (v) => setState(() => _secondMag = v),
                  ),
                ],
              ),

              if (_secondMag) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _magazine2Ctrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Taille du 2e chargeur (optionnel)',
                  ),
                ),
              ],
              const SizedBox(height: 16),

              DropdownButtonFormField<Firing?>(
                initialValue: _firing,
                decoration: const InputDecoration(
                    labelText: 'Mode de tir (optionnel)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Aucun —')),
                  ...Firing.values.map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(_firingLabel(f)),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _firing = v),
              ),
            ],
            const SizedBox(height: 32),
          ],

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
              onPressed: _canCreate ? _create : null,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text("Créer l'artefact"),
            ),
          ),

          Align(
            alignment: Alignment.bottomLeft,
            child: TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, Routes.artefacts),
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }
}
