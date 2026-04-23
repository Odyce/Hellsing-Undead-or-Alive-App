import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/pages/archives/widgets/field_notes_section.dart';
import 'package:hellsing_undead_or_applive/pages/archives/widgets/mission_history_section.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class BestiarySheetPage extends StatefulWidget {
  const BestiarySheetPage({super.key});

  @override
  State<BestiarySheetPage> createState() => _BestiarySheetPageState();
}

class _BestiarySheetPageState extends State<BestiarySheetPage> {
  late Monster _monster;
  bool _initialized = false;
  bool _uploading = false;
  int _currentImageIndex = 0;

  final MonsterRepository _repository = MonsterRepository();

  static String _typeLabel(Entitype t) => switch (t) {
        Entitype.demon  => 'Démon',
        Entitype.angel  => 'Ange',
        Entitype.midian => 'Midian',
        Entitype.beast  => 'B\u00eate',
        Entitype.human  => 'Humain',
      };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _monster = ModalRoute.of(context)!.settings.arguments as Monster;
      _initialized = true;
    }
  }

  Future<void> _refreshMonster() async {
    final snap = await FirebaseFirestore.instance
        .collection('common')
        .doc('archives')
        .collection('bestiary')
        .where('id', isEqualTo: _monster.id)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty && mounted) {
      setState(() {
        _monster = Monster.fromMap(snap.docs.first.data());
        final images = _monster.illustrationPaths ?? [];
        if (_currentImageIndex >= images.length) {
          _currentImageIndex = images.isEmpty ? 0 : images.length - 1;
        }
      });
    }
  }

  // ─── Ajout illustration ────────────────────────────────────────────────────
  Future<void> _addIllustration() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      const cloudName = 'hellsingundeadapp';
      const uploadPreset = 'Monster_illustrations-unsigned';
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await MultipartFile.fromPath('file', File(picked.path).path));

      final response = await request.send();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Erreur upload : ${response.statusCode}');
      }
      final body = await response.stream.bytesToString();
      final url = jsonDecode(body)['secure_url'] as String;

      await _repository.appendIllustration(_monster.id, url);
      await _refreshMonster();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Illustration ajoutée.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openEditForm() async {
    final updated = await Navigator.pushNamed(
      context,
      Routes.bestiaryEdit,
      arguments: _monster,
    );
    if (updated == true) {
      await _refreshMonster();
    }
  }

  @override
  Widget build(BuildContext context) {
    final images = _monster.illustrationPaths ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(_monster.name),
        actions: [
          IconButton(
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate),
            tooltip: 'Ajouter une illustration',
            onPressed: _uploading ? null : _addIllustration,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: _openEditForm,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Illustrations ─────────────────────────────────────────────────
            if (images.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  images[_currentImageIndex],
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 220,
                    child: Center(
                      child: Icon(Icons.broken_image,
                          size: 80, color: Colors.grey),
                    ),
                  ),
                ),
              ),

              if (images.length > 1) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 60,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) => GestureDetector(
                      onTap: () => setState(() => _currentImageIndex = i),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: i == _currentImageIndex
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              images[i],
                              width: 60,
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],

            // ── Nom & type ────────────────────────────────────────────────────
            Text(
              _monster.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text(_typeLabel(_monster.type))),
                Chip(label: Text(_monster.race)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Description ───────────────────────────────────────────────────
            _SectionTitle('Description'),
            const SizedBox(height: 8),
            Text(_monster.description),
            const SizedBox(height: 24),

            // ── Compétences ───────────────────────────────────────────────────
            _SectionTitle('Compétences'),
            const SizedBox(height: 8),
            Text(_monster.skills),
            const SizedBox(height: 24),

            // ── Faiblesse ─────────────────────────────────────────────────────
            _SectionTitle('Faiblesse'),
            const SizedBox(height: 8),
            Text(_monster.weakness),
            const SizedBox(height: 24),

            // ── Lieu d'apparition ─────────────────────────────────────────────
            _SectionTitle("Lieu d'apparition"),
            const SizedBox(height: 8),
            Text(_monster.location),
            const SizedBox(height: 24),

            // ── Estimation des PV ─────────────────────────────────────────────
            _SectionTitle('Estimation des PV'),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatBox(
                  label: 'Minimum',
                  value: _monster.hpScale.isNotEmpty
                      ? _monster.hpScale[0].toString()
                      : '\u2014',
                ),
                const SizedBox(width: 16),
                _StatBox(
                  label: 'Maximum',
                  value: _monster.hpScale.length > 1
                      ? _monster.hpScale[1].toString()
                      : '\u2014',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Missions ──────────────────────────────────────────────────────
            MissionHistorySection(missions: _monster.missions),
            if (_monster.missions.isNotEmpty) const SizedBox(height: 32),

            // ── Notes des agents ──────────────────────────────────────────────
            FieldNotesSection(targetType: 'monster', targetId: _monster.id),
            const SizedBox(height: 32),

            // ── Retour ────────────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, Routes.bestiary),
                child: const Text('Retour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets utilitaires ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
