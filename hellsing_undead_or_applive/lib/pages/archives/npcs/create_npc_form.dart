import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class CreateNpcPage extends StatefulWidget {
  const CreateNpcPage({super.key});

  @override
  State<CreateNpcPage> createState() => _CreateNpcPageState();
}

class _CreateNpcPageState extends State<CreateNpcPage> {
  // ─── Contrôleurs ────────────────────────────────────────────────────────────
  final _nameCtrl        = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // ─── Champs enum ─────────────────────────────────────────────────────────────
  Entitype     _type     = Entitype.human;
  Relationship _relation = Relationship.neutral;

  // ─── Statut ───────────────────────────────────────────────────────────────────
  bool _alive = true;

  // ─── Illustration ─────────────────────────────────────────────────────────────
  File? _picture;

  // ─── État ────────────────────────────────────────────────────────────────────
  String? _error;
  bool    _loading = false;

  final PNJRepository _repository = PNJRepository();

  // ─── Validation ──────────────────────────────────────────────────────────────
  bool get _canCreate {
    if (_loading) return false;
    if (_nameCtrl.text.trim().isEmpty)        return false;
    if (_descriptionCtrl.text.trim().isEmpty) return false;
    return true;
  }

  // ─── Image ───────────────────────────────────────────────────────────────────
  Future<void> _pickPicture() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _picture = File(picked.path));
    }
  }

  void _removePicture() => setState(() => _picture = null);

  Future<String> _uploadPicture(File image) async {
    const cloudName    = 'hellsingundeadapp';
    const uploadPreset = 'NPC_illustrations-unsigned';
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

  String _relationLabel(Relationship r) => switch (r) {
        Relationship.neutral => 'Neutre',
        Relationship.ally    => 'Allié',
        Relationship.enemy   => 'Ennemi',
        Relationship.trader  => 'Marchand',
      };

  // ─── Création ────────────────────────────────────────────────────────────────
  Future<void> _createNpc() async {
    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      String? pictureUrl;
      if (_picture != null) {
        pictureUrl = await _uploadPicture(_picture!);
      }

      await _repository.createPNJ(
        name:        _nameCtrl.text.trim(),
        type:        _type,
        picturePath: pictureUrl,
        description: _descriptionCtrl.text.trim(),
        relation:    _relation,
        alive:       _alive,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.npcs);
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
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: const Text('Nouveau PNJ'),
      ),
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

          // ── Relation ─────────────────────────────────────────────────────────
          DropdownButtonFormField<Relationship>(
            initialValue: _relation,
            decoration: const InputDecoration(labelText: 'Relation'),
            items: Relationship.values
                .map((r) => DropdownMenuItem(
                      value: r,
                      child: Text(_relationLabel(r)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _relation = v);
            },
          ),
          const SizedBox(height: 16),

          // ── Statut vivant/mort ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Vivant', style: Theme.of(context).textTheme.titleMedium),
              Switch(
                value: _alive,
                onChanged: (v) => setState(() => _alive = v),
              ),
            ],
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

          // ── Description ───────────────────────────────────────────────────────
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          TextField(
            controller: _descriptionCtrl,
            decoration: const InputDecoration(
              labelText: 'Description *',
              helperText: 'Présentation générale du personnage.',
            ),
            minLines: 3,
            maxLines: 12,
            onChanged: (_) => setState(() {}),
          ),
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
              onPressed: _canCreate ? _createNpc : null,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Créer le PNJ'),
            ),
          ),

        ],
      ),
    );
  }
}
