import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

class NpcSheetPage extends StatelessWidget {
  const NpcSheetPage({super.key});

  static String _typeLabel(Entitype t) => switch (t) {
        Entitype.demon   => 'Démon',
        Entitype.angel   => 'Ange',
        Entitype.midian  => 'Midian',
        Entitype.beast   => 'Bête',
        Entitype.human   => 'Humain',
      };

  static String _relationLabel(Relationship r) => switch (r) {
        Relationship.neutral => 'Neutre',
        Relationship.ally    => 'Allié',
        Relationship.enemy   => 'Ennemi',
        Relationship.trader  => 'Marchand',
      };

  @override
  Widget build(BuildContext context) {
    final pnj = ModalRoute.of(context)!.settings.arguments as PNJ;

    return Scaffold(
      appBar: AppBar(title: Text(pnj.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Illustration ──────────────────────────────────────────────────
            if (pnj.picturePath != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    pnj.picturePath!,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),

            if (pnj.picturePath != null) const SizedBox(height: 24),

            // ── Nom & statut ──────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    pnj.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Icon(
                  pnj.alive ? Icons.favorite : Icons.close,
                  color: pnj.alive ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  pnj.alive ? 'Vivant' : 'Décédé',
                  style: TextStyle(
                    color: pnj.alive ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Badges type + relation ────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text(_typeLabel(pnj.type))),
                Chip(label: Text(_relationLabel(pnj.relation))),
              ],
            ),
            const SizedBox(height: 24),

            // ── Description ───────────────────────────────────────────────────
            Text(
              'Description',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(pnj.description),
            const SizedBox(height: 32),

            // ── Retour ────────────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/npcs'),
                child: const Text('Retour'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}