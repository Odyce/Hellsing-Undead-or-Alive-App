import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';

class ResDevSheetPage extends StatelessWidget {
  const ResDevSheetPage({super.key});

  // ─── Labels ───────────────────────────────────────────────────────────────────
  static String _stockageLabel(Stockage s) => switch (s) {
        Stockage.weapon => 'Arme',
        Stockage.bag    => 'Sac',
        Stockage.muni   => 'Munitions',
      };

  static String _affinityLabel(Affinities a) => switch (a) {
        Affinities.firearm            => 'Arme à feu',
        Affinities.explosive          => 'Explosif',
        Affinities.oneHandBlade       => 'Lame 1 main',
        Affinities.twoHandBlade       => 'Lame 2 mains',
        Affinities.bow                => 'Arc',
        Affinities.throwable          => 'Lancer',
        Affinities.none               => 'Aucun',
        Affinities.choiceNonExplosive => 'Choix (non explosif)',
      };

  static String _subAffinityLabel(SubAffinities s) => switch (s) {
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

  static String _effectLabel(Effect e) => switch (e) {
        Effect.none           => 'Aucun',
        Effect.blessed        => 'Bénie',
        Effect.blessedAggr    => 'Bénie (aggravé)',
        Effect.holy           => 'Sainte',
        Effect.silver         => 'Argent',
        Effect.silverAggr     => 'Argent (aggravé)',
        Effect.mercury        => 'Mercure',
        Effect.mercuryAggr    => 'Mercure (aggravé)',
        Effect.piercing       => 'Perforant',
        Effect.piercingAggr   => 'Perforant (aggravé)',
        Effect.incendiary     => 'Incendiaire',
        Effect.incendiaryAggr => 'Incendiaire (aggravé)',
        Effect.burning        => 'Brûlant',
        Effect.burningAggr    => 'Brûlant (aggravé)',
        Effect.bleed          => 'Saignement',
        Effect.bleedAggr      => 'Saignement (aggravé)',
      };

  static String _firingLabel(Firing f) => switch (f) {
        Firing.none           => 'Aucun',
        Firing.sA             => 'Simple action',
        Firing.dA             => 'Double action',
        Firing.multiple       => 'Multiple',
        Firing.semA           => 'Semi-automatique',
        Firing.separedTrigger => 'Gâchettes séparées',
        Firing.mLev           => 'Levier',
        Firing.mVer           => 'Verrou',
      };

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)!.settings.arguments as Object;

    // ── Champs communs ─────────────────────────────────────────────────────────
    final String  name;
    final String  description;
    final String? picturePath;

    switch (item) {
      case ResDev r:
        name        = r.name;
        description = r.description;
        picturePath = r.picturePath;
      case ResDevWeapon w:
        name        = w.name;
        description = w.description;
        picturePath = w.picturePath;
      default:
        return const Scaffold(body: Center(child: Text('Élément inconnu')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Illustration ──────────────────────────────────────────────────
            if (picturePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  picturePath,
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
              const SizedBox(height: 24),
            ],

            // ── Nom ───────────────────────────────────────────────────────────
            Text(
              name,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ── Description ───────────────────────────────────────────────────
            _SectionTitle('Description'),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 24),

            // ══ Section ResDev (non-arme) ═════════════════════════════════════
            if (item is ResDev) ...[
              _SectionTitle('Caractéristiques'),
              const SizedBox(height: 8),
              _InfoRow('Stockage', _stockageLabel(item.stockage)),
              _InfoRow('Taille',   item.size.toString()),
              if (item.number != null)
                _InfoRow('Quantité', item.number.toString()),
              const SizedBox(height: 24),
            ],

            // ══ Section ResDevWeapon ══════════════════════════════════════════
            if (item is ResDevWeapon) ...[
              _SectionTitle('Arme de R&D', icon: Icons.shield_outlined),
              const SizedBox(height: 8),
              _InfoRow('Type',      _affinityLabel(item.type)),
              _InfoRow('Sous-type', _subAffinityLabel(item.subType)),
              const SizedBox(height: 16),

              _SectionTitle('Dégâts'),
              const SizedBox(height: 8),
              Text(item.damage),
              const SizedBox(height: 16),

              _SectionTitle('Particularité'),
              const SizedBox(height: 8),
              Text(item.feature),
              const SizedBox(height: 16),

              _SectionTitle('Effets'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: item.effect
                    .map((e) => Chip(label: Text(_effectLabel(e))))
                    .toList(),
              ),
              const SizedBox(height: 16),

              _InfoRow('Taille', item.size.toString()),

              if (item.fire) ...[
                const SizedBox(height: 16),
                _SectionTitle('Arme à feu',
                    icon: Icons.local_fire_department),
                const SizedBox(height: 8),
                if (item.calibre != null)
                  _InfoRow('Calibre', item.calibre!.name),
                if (item.reload != null)
                  _InfoRow('Rechargement', '${item.reload} tour(s)'),
                if (item.magazineSize != null)
                  _InfoRow('Chargeur', '${item.magazineSize} cartouches'),
                if (item.secondMagazine == true &&
                    item.secondMagazineSize != null)
                  _InfoRow(
                      '2e chargeur', '${item.secondMagazineSize} cartouches'),
                if (item.firing != null)
                  _InfoRow('Mode de tir', _firingLabel(item.firing!)),
              ],
              const SizedBox(height: 24),
            ],

            // ── Retour ────────────────────────────────────────────────────────
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
      ),
    );
  }
}

// ─── Widgets utilitaires ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _SectionTitle(this.text, {this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
