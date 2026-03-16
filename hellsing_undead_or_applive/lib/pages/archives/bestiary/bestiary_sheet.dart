import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/pages/archives/widgets/field_notes_section.dart';
import 'package:hellsing_undead_or_applive/routes/routes.dart';

class BestiarySheetPage extends StatefulWidget {
  const BestiarySheetPage({super.key});

  @override
  State<BestiarySheetPage> createState() => _BestiarySheetPageState();
}

class _BestiarySheetPageState extends State<BestiarySheetPage> {
  int _currentImageIndex = 0;

  static String _typeLabel(Entitype t) => switch (t) {
        Entitype.demon   => 'Démon',
        Entitype.angel   => 'Ange',
        Entitype.midian  => 'Midian',
        Entitype.beast   => 'Bête',
        Entitype.human   => 'Humain',
      };

  @override
  Widget build(BuildContext context) {
    final monster = ModalRoute.of(context)!.settings.arguments as Monster;
    final images   = monster.illustrationPaths ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(monster.name)),
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

              // Miniatures de navigation si plusieurs images
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
              monster.name,
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
                Chip(label: Text(_typeLabel(monster.type))),
                Chip(label: Text(monster.race)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Description ───────────────────────────────────────────────────
            _SectionTitle('Description'),
            const SizedBox(height: 8),
            Text(monster.description),
            const SizedBox(height: 24),

            // ── Compétences ───────────────────────────────────────────────────
            _SectionTitle('Compétences'),
            const SizedBox(height: 8),
            Text(monster.skills),
            const SizedBox(height: 24),

            // ── Faiblesse ─────────────────────────────────────────────────────
            _SectionTitle('Faiblesse'),
            const SizedBox(height: 8),
            Text(monster.weakness),
            const SizedBox(height: 24),

            // ── Lieu d'apparition ─────────────────────────────────────────────
            _SectionTitle("Lieu d'apparition"),
            const SizedBox(height: 8),
            Text(monster.location),
            const SizedBox(height: 24),

            // ── Estimation des PV ─────────────────────────────────────────────
            _SectionTitle('Estimation des PV'),
            const SizedBox(height: 8),
            Row(
              children: [
                _StatBox(
                  label: 'Minimum',
                  value: monster.hpScale.isNotEmpty
                      ? monster.hpScale[0].toString()
                      : '—',
                ),
                const SizedBox(width: 16),
                _StatBox(
                  label: 'Maximum',
                  value: monster.hpScale.length > 1
                      ? monster.hpScale[1].toString()
                      : '—',
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Notes des agents ──────────────────────────────────────────────
            FieldNotesSection(targetType: 'monster', targetId: monster.id),
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
