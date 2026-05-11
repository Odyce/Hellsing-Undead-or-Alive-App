import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hellsing_undead_or_applive/domain/archives/archives_repository.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class CreateJournalEntryPage extends StatefulWidget {
  const CreateJournalEntryPage({super.key});

  @override
  State<CreateJournalEntryPage> createState() =>
      _CreateJournalEntryPageState();
}

class _CreateJournalEntryPageState extends State<CreateJournalEntryPage> {
  final _pageNumberCtrl = TextEditingController(text: '1');

  DateTime _date = DateTime.now();
  File? _image;

  String? _pageNumberError;
  String? _error;
  bool _loading = false;

  final JournalRepository _repository = JournalRepository();

  bool get _canCreate =>
      _image != null &&
      int.tryParse(_pageNumberCtrl.text) != null &&
      int.parse(_pageNumberCtrl.text) > 0 &&
      _pageNumberError == null &&
      !_loading;

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1800),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) setState(() => _image = File(picked.path));
  }

  void _validatePageNumber() {
    final n = int.tryParse(_pageNumberCtrl.text);
    setState(() {
      _pageNumberError = n == null
          ? 'Le numéro de page doit être un entier.'
          : n <= 0
              ? 'Le numéro de page doit être strictement positif.'
              : null;
    });
  }

  Future<String> _uploadImage(File image) async {
    const cloudName = 'hellsingundeadapp';
    const uploadPreset = 'Journal_pages-unsigned';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Erreur upload page de journal Cloudinary: ${response.statusCode}',
      );
    }
    final body = await response.stream.bytesToString();
    return jsonDecode(body)['secure_url'] as String;
  }

  Future<void> _createEntry() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final url = await _uploadImage(_image!);
      await _repository.createEntry(
        imageUrl: url,
        date: _date,
        pageNumber: int.parse(_pageNumberCtrl.text),
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pageNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: const Text('Ajouter une page au Journal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Date ─────────────────────────────────────────────────────────
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date *'),
            subtitle: Text(_formatDate(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),

          // ── Numéro de page ───────────────────────────────────────────────
          TextField(
            controller: _pageNumberCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Numéro de page *',
              helperText:
                  'Sert à ordonner plusieurs pages publiées le même jour.',
              errorText: _pageNumberError,
            ),
            onChanged: (_) => _validatePageNumber(),
          ),
          const SizedBox(height: 24),

          // ── Image ────────────────────────────────────────────────────────
          Text('Page (image) *',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _image!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _image = null),
              icon: const Icon(Icons.delete),
              label: const Text('Supprimer'),
            ),
            const SizedBox(height: 4),
          ],
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: Text(_image == null
                ? "Choisir l'image"
                : "Changer l'image"),
          ),
          const SizedBox(height: 32),

          // ── Erreur & bouton création ─────────────────────────────────────
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canCreate ? _createEntry : null,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Publier la page'),
            ),
          ),
        ],
      ),
    );
  }
}
