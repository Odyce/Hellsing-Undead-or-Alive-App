import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class CreateMissionPage extends StatefulWidget {
  const CreateMissionPage({super.key});

  @override
  State<CreateMissionPage> createState() => _CreateMissionPageState();
}

class _CreateMissionPageState extends State<CreateMissionPage> {
  // ─── Contrôleurs ────────────────────────────────────────────────────────────
  final _titleCtrl            = TextEditingController();
  final _notesForDMCtrl       = TextEditingController();
  final _descriptionIntroCtrl = TextEditingController();
  final _descriptionOutroCtrl = TextEditingController();
  final _bountyMinCtrl         = TextEditingController();
  final _bountyMaxCtrl         = TextEditingController();

  // ─── Champs enum & toggle ────────────────────────────────────────────────────
  Difficulty _difficulty = Difficulty.inconnu;
  CladeName   _clade       = CladeName.osiris;
  bool       _urgent     = false;

  // ─── Dates ───────────────────────────────────────────────────────────────────
  DateTime  _postedAt   = DateTime.now();
  DateTime? _playedAt;
  DateTime? _completedAt;

  // ─── Fichiers ────────────────────────────────────────────────────────────────
  File?            _illustration;
  final List<File> _reports = [];

  // ─── État ────────────────────────────────────────────────────────────────────
  String? _bountyMinError;
  String? _bountyMaxError;
  String? _reportsError;
  String? _error;
  bool    _loading = false;

  final MissionRepository _repository = MissionRepository();

  static const int _maxReportBytes = 1 * 1024 * 1024; // 1 Mo

  // ─── Validation ──────────────────────────────────────────────────────────────
  bool get _canCreate =>
      _titleCtrl.text.trim().isNotEmpty &&
      _descriptionIntroCtrl.text.trim().isNotEmpty &&
      _bountyMinError == null &&
      _bountyMaxError == null &&
      int.tryParse(_bountyMinCtrl.text) != null &&
      int.tryParse(_bountyMaxCtrl.text) != null &&
      !_loading;

  void _validateBounty() {
    final min = int.tryParse(_bountyMinCtrl.text);
    final max = int.tryParse(_bountyMaxCtrl.text);
    setState(() {
      _bountyMinError = min == null
          ? 'La prime min doit être un nombre entier.'
          : min < 0
              ? 'La prime min ne peut pas être négative.'
              : null;
      _bountyMaxError = max == null
          ? 'La prime max doit être un nombre entier.'
          : max < 0
              ? 'La prime max ne peut pas être négative.'
              : (min != null && max < min)
                  ? 'La prime max doit être ≥ prime min.'
                  : null;
    });
  }

  // ─── Formatage date ───────────────────────────────────────────────────────────
  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  // ─── Sélecteur de date ────────────────────────────────────────────────────────
  Future<void> _pickDate({
    required DateTime initial,
    required void Function(DateTime) onPicked,
    DateTime? firstDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  // ─── Illustration ─────────────────────────────────────────────────────────────
  Future<void> _pickIllustration() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _illustration = File(picked.path));
  }

  Future<String> _uploadIllustration(File image) async {
    const cloudName    = 'hellsingundeadapp';
    const uploadPreset = 'Mission_illustrations-unsigned';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur upload illustration Cloudinary: ${response.statusCode}',
      );
    }
    final body = await response.stream.bytesToString();
    return jsonDecode(body)['secure_url'] as String;
  }

  // ─── Comptes-rendus PDF ───────────────────────────────────────────────────────
  Future<void> _pickReports() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result == null) return;

    String? warning;
    final valid = <File>[];

    for (final pf in result.files) {
      if (pf.path == null) continue;
      final file = File(pf.path!);
      final size = await file.length();
      if (size > _maxReportBytes) {
        warning = 'Certains PDFs dépassent 1 Mo et ont été ignorés.';
        continue;
      }
      valid.add(file);
    }

    setState(() {
      _reports.addAll(valid);
      _reportsError = warning;
    });
  }

  void _removeReport(int index) => setState(() => _reports.removeAt(index));

  Future<String> _uploadReport(File pdf) async {
    const cloudName    = 'hellsingundeadapp';
    const uploadPreset = 'Mission_reports-unsigned';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload',
    );

    final request = MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await MultipartFile.fromPath('file', pdf.path));

    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur upload PDF Cloudinary: ${response.statusCode}',
      );
    }
    final body = await response.stream.bytesToString();
    return jsonDecode(body)['secure_url'] as String;
  }

  // ─── Création ────────────────────────────────────────────────────────────────
  Future<void> _createMission() async {
    setState(() {
      _loading = true;
      _error   = null;
    });

    try {
      String? illustrationUrl;
      if (_illustration != null) {
        illustrationUrl = await _uploadIllustration(_illustration!);
      }

      List<String>? reportUrls;
      if (_reports.isNotEmpty) {
        reportUrls = [];
        for (final pdf in _reports) {
          reportUrls.add(await _uploadReport(pdf));
        }
      }

      await _repository.createMission(
        title:            _titleCtrl.text.trim(),
        notesForDM:       _notesForDMCtrl.text.trim().isEmpty
                              ? null
                              : _notesForDMCtrl.text.trim(),
        descriptionIntro: _descriptionIntroCtrl.text.trim(),
        descriptionOutro: _descriptionOutroCtrl.text.trim().isEmpty
                              ? null
                              : _descriptionOutroCtrl.text.trim(),
        illustrationPath: illustrationUrl,
        difficulty:       _difficulty,
        clade:             _clade,
        postedAt:         _postedAt,
        playedAt:         _playedAt,
        completedAt:      _completedAt,
        bountyMin:        int.parse(_bountyMinCtrl.text),
        bountyMax:        int.parse(_bountyMaxCtrl.text),
        reportPaths:      reportUrls,
        urgent:           _urgent,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.missions);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Labels ───────────────────────────────────────────────────────────────────
  String _difficultyLabel(Difficulty d) => switch (d) {
    Difficulty.basse   => 'Basse',
    Difficulty.moyenne => 'Moyenne',
    Difficulty.haute   => 'Haute',
    Difficulty.inconnu => 'Inconnue',
    Difficulty.tresHaute => 'Maïca',
  };

  String _cladeLabel(CladeName c) => switch (c) {
    CladeName.osiris            => 'Osiris',
    CladeName.blackOrchid       => 'Black Orchid',
    CladeName.pennyDreadful     => 'Penny Dreadful',
    CladeName.beginning         => 'The Beginning',
    CladeName.origins           => 'Origins',
    CladeName.unNeufTroisZero   => '1930',
    CladeName.western           => 'Western',
    CladeName.arthur            => 'The Legend of King Arthur',
  };

  // ─── Dispose ──────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesForDMCtrl.dispose();
    _descriptionIntroCtrl.dispose();
    _descriptionOutroCtrl.dispose();
    _bountyMinCtrl.dispose();
    _bountyMaxCtrl.dispose();
    super.dispose();
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer une mission')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Titre ────────────────────────────────────────────────────────────
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Titre *'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // ── Difficulté ───────────────────────────────────────────────────────
          DropdownButtonFormField<Difficulty>(
            initialValue: _difficulty,
            decoration: const InputDecoration(labelText: 'Difficulté'),
            items: Difficulty.values
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(_difficultyLabel(d)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _difficulty = v);
            },
          ),
          const SizedBox(height: 16),

          // ── Clan ─────────────────────────────────────────────────────────────
          DropdownButtonFormField<CladeName>(
            initialValue: _clade,
            decoration: const InputDecoration(labelText: 'Clade'),
            items: CladeName.values
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(_cladeLabel(c)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _clade = v);
            },
          ),
          const SizedBox(height: 8),

          // ── Urgente ──────────────────────────────────────────────────────────
          SwitchListTile(
            title: const Text('Urgente'),
            value: _urgent,
            onChanged: (v) => setState(() => _urgent = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),

          // ── Fourchette de prime ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bountyMinCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Prime min (£) *',
                    errorText: _bountyMinError,
                  ),
                  onChanged: (_) => _validateBounty(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _bountyMaxCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Prime max (£) *',
                    errorText: _bountyMaxError,
                  ),
                  onChanged: (_) => _validateBounty(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Dates ────────────────────────────────────────────────────────────
          Text('Dates', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date de publication *'),
            subtitle: Text(_formatDate(_postedAt)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(
              initial: _postedAt,
              onPicked: (d) => _postedAt = d,
            ),
          ),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date de jeu'),
            subtitle: Text(
              _playedAt != null ? _formatDate(_playedAt!) : 'Non renseignée',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_playedAt != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Effacer',
                    onPressed: () => setState(() => _playedAt = null),
                  ),
                const Icon(Icons.calendar_today),
              ],
            ),
            onTap: () => _pickDate(
              initial: _playedAt ?? DateTime.now(),
              onPicked: (d) => _playedAt = d,
            ),
          ),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date de complétion'),
            subtitle: Text(
              _completedAt != null
                  ? _formatDate(_completedAt!)
                  : 'Non renseignée',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_completedAt != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Effacer',
                    onPressed: () => setState(() => _completedAt = null),
                  ),
                const Icon(Icons.calendar_today),
              ],
            ),
            onTap: () => _pickDate(
              initial: _completedAt ?? DateTime(1877, 6, 1),
              onPicked: (d) => _completedAt = d,
              firstDate: DateTime(1800),
            ),
          ),
          const SizedBox(height: 24),

          // ── Descriptions ─────────────────────────────────────────────────────
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          TextField(
            controller: _descriptionIntroCtrl,
            decoration: const InputDecoration(
              labelText: 'Introduction *',
              helperText: 'Description principale de la mission.',
            ),
            minLines: 3,
            maxLines: 12,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _descriptionOutroCtrl,
            decoration: const InputDecoration(
              labelText: 'Outro (optionnel)',
              helperText: 'Résumé ou conclusion après la mission.',
            ),
            minLines: 2,
            maxLines: 8,
          ),
          const SizedBox(height: 24),

          // ── Notes MJ ─────────────────────────────────────────────────────────
          Text('Notes MJ', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          TextField(
            controller: _notesForDMCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
              helperText: 'Informations réservées au MJ.',
            ),
            minLines: 2,
            maxLines: 8,
          ),
          const SizedBox(height: 24),

          // ── Illustration ─────────────────────────────────────────────────────
          Text('Illustration', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),

          if (_illustration != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _illustration!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _illustration = null),
              icon: const Icon(Icons.delete),
              label: const Text('Supprimer'),
            ),
            const SizedBox(height: 4),
          ],

          ElevatedButton.icon(
            onPressed: _pickIllustration,
            icon: const Icon(Icons.image),
            label: Text(
              _illustration == null
                  ? 'Choisir une illustration'
                  : "Changer l'illustration",
            ),
          ),
          const SizedBox(height: 24),

          // ── Comptes-rendus ───────────────────────────────────────────────────
          Text(
            'Rapport',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Text(
            'PDF uniquement · 1 Mo max par fichier',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),

          if (_reports.isNotEmpty)
            ...List.generate(_reports.length, (i) {
              final name =
                  _reports[i].path.split(Platform.pathSeparator).last;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.picture_as_pdf),
                title: Text(name, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeReport(i),
                ),
              );
            }),

          if (_reportsError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _reportsError!,
                style: const TextStyle(color: Colors.orange),
              ),
            ),

          ElevatedButton.icon(
            onPressed: _pickReports,
            icon: const Icon(Icons.upload_file),
            label: const Text('Ajouter des PDFs'),
          ),
          const SizedBox(height: 32),

          // ── Erreur & bouton création ─────────────────────────────────────────
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
              onPressed: _canCreate ? _createMission : null,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Créer la mission'),
            ),
          ),

          Align(
            alignment: Alignment.bottomLeft,
            child: TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, Routes.missions),
              child: const Text('Retour'),
            ),
          ),
        ],
      ),
    );
  }
}
