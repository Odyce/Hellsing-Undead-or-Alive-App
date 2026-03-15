import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

class ResDevProjectFormPage extends StatefulWidget {
  const ResDevProjectFormPage({super.key});

  @override
  State<ResDevProjectFormPage> createState() => _ResDevProjectFormPageState();
}

class _ResDevProjectFormPageState extends State<ResDevProjectFormPage> {
  // ─── Contrôleurs ─────────────────────────────────────────────────────────────
  final _nameCtrl        = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _costCtrl        = TextEditingController();

  // ─── État ────────────────────────────────────────────────────────────────────
  File?   _picture;
  Agent?  _selectedBenefactor;
  bool    _loading = false;
  String? _error;

  // ─── Prérequis (liste dynamique) ─────────────────────────────────────────────
  final List<TextEditingController> _prereqControllers = [
    TextEditingController(),
  ];

  // ─── Agents de l'utilisateur ─────────────────────────────────────────────────
  List<Agent> _userAgents = [];

  final ResDevProjectRepository _repository = ResDevProjectRepository();

  @override
  void initState() {
    super.initState();
    _loadUserAgents();
  }

  Future<void> _loadUserAgents() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('agents')
          .get();
      final agents = snapshot.docs
          .where((d) => d.id != '_meta_')
          .map((d) => Agent.fromMap(d.data()))
          .toList();
      setState(() => _userAgents = agents);
    } catch (_) {}
  }

  // ─── Image Cloudinary ────────────────────────────────────────────────────────
  Future<String?> _uploadToCloudinary(File file) async {
    const cloudName   = 'dkbpqplya';
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

  // ─── Gestion des prérequis ────────────────────────────────────────────────────
  void _addPrereq() {
    setState(() => _prereqControllers.add(TextEditingController()));
  }

  void _removePrereq(int index) {
    if (_prereqControllers.length <= 1) return;
    setState(() {
      _prereqControllers[index].dispose();
      _prereqControllers.removeAt(index);
    });
  }

  // ─── Validation ──────────────────────────────────────────────────────────────
  bool get _canCreate {
    if (_loading) return false;
    if (_nameCtrl.text.trim().isEmpty) return false;
    if (_descriptionCtrl.text.trim().isEmpty) return false;
    if (_costCtrl.text.trim().isEmpty) return false;
    if (int.tryParse(_costCtrl.text.trim()) == null) return false;
    if (_selectedBenefactor == null) return false;
    if (_prereqControllers.every((c) => c.text.trim().isEmpty)) return false;
    return true;
  }

  // ─── Soumission ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_canCreate) return;
    setState(() { _loading = true; _error = null; });

    try {
      String? pictureUrl;
      if (_picture != null) pictureUrl = await _uploadToCloudinary(_picture!);

      final prereqs = _prereqControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await _repository.createProject(
        name:        _nameCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        picturePath: pictureUrl,
        benefactor:  [_selectedBenefactor!],
        prerequisite: prereqs,
        cost:        int.parse(_costCtrl.text.trim()),
      );

      if (mounted) Navigator.of(context).pushReplacementNamed('/resDev');
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _costCtrl.dispose();
    for (final c in _prereqControllers) { c.dispose(); }
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau projet R&D')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Nom ──────────────────────────────────────────────────────────────
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Nom du projet *'),
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

          // ── Coût ─────────────────────────────────────────────────────────────
          TextFormField(
            controller: _costCtrl,
            decoration: const InputDecoration(labelText: 'Coût *'),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // ── Bénéficiaire ──────────────────────────────────────────────────────
          DropdownButtonFormField<Agent>(
            decoration: const InputDecoration(labelText: 'Bénéficiaire *'),
            initialValue: _selectedBenefactor,
            items: _userAgents
                .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                .toList(),
            onChanged: (a) => setState(() => _selectedBenefactor = a),
            hint: _userAgents.isEmpty
                ? const Text('Aucun agent disponible')
                : const Text('Choisir un agent'),
          ),
          const SizedBox(height: 24),

          // ── Prérequis ─────────────────────────────────────────────────────────
          Row(
            children: [
              Text('Prérequis *',
                  style: Theme.of(context).textTheme.titleSmall),
              const Spacer(),
              TextButton.icon(
                onPressed: _addPrereq,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._prereqControllers.asMap().entries.map((entry) {
            final i   = entry.key;
            final ctrl = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: ctrl,
                      decoration: InputDecoration(
                        labelText: 'Prérequis ${i + 1}',
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  if (_prereqControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: () => _removePrereq(i),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 24),

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
              child: Image.file(_picture!, height: 160, fit: BoxFit.contain),
            ),
          ],
          const SizedBox(height: 24),

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
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: Colors.white),
                  )
                : const Text('Créer le projet'),
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/resDev'),
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }
}
