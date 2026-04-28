import 'package:flutter/material.dart';
import 'package:hellsing_undead_or_applive/domain/models.dart';
import 'package:hellsing_undead_or_applive/widgets/safe_back_button.dart';

class ArtefactSheetPage extends StatelessWidget {
  const ArtefactSheetPage({super.key});

  // ─── Labels ───────────────────────────────────────────────────────────────────
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

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)!.settings.arguments as Object;

    // Extraire les champs communs
    final String     name;
    final String     description;
    final String?    picturePath;
    final bool       limitedUses;
    final int?       usesLeft;
    final Mission?   missionRetrievedAt;
    final DateTime?  dateRetrievedAt;
    switch (item) {
      case Artefacts a:
        name               = a.name;
        description        = a.description;
        picturePath        = a.picturePath;
        limitedUses        = a.limitedUses;
        usesLeft           = a.usesLeft;
        missionRetrievedAt = a.missionRetrievedAt;
        dateRetrievedAt    = a.dateRetrievedAt;
      case ArtefactWeapon w:
        name               = w.name;
        description        = w.description;
        picturePath        = w.picturePath;
        limitedUses        = w.limitedUses;
        usesLeft           = w.usesLeft;
        missionRetrievedAt = w.missionRetrievedAt;
        dateRetrievedAt    = w.dateRetrievedAt;
      default:
        // Ne devrait jamais arriver
        return const Scaffold(body: Center(child: Text('Artefact inconnu')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(),
        title: Text(name),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Illustration ──────────────────────────────────────────────────
            if (picturePath != null) ...[
              Center(
                child: ClipRRect(
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

            // ── Usages ────────────────────────────────────────────────────────
            if (limitedUses) ...[
              _SectionTitle('Usages'),
              const SizedBox(height: 8),
              Text(usesLeft != null ? '$usesLeft usage(s) restant(s)' : '—'),
              const SizedBox(height: 24),
            ],

            // ── Récupération ──────────────────────────────────────────────────
            if (missionRetrievedAt != null || dateRetrievedAt != null) ...[
              _SectionTitle('Récupération'),
              const SizedBox(height: 8),
              if (missionRetrievedAt != null)
                _InfoRow('Mission', missionRetrievedAt.title),
              if (dateRetrievedAt != null)
                _InfoRow('Date', _formatDate(dateRetrievedAt)),
              const SizedBox(height: 24),
            ],

            // ══ Section arme ══════════════════════════════════════════════════
            if (item is Artefacts) ...[
              _SectionTitle('Effet'),
              const SizedBox(height: 8),
              Text(item.effect),
              const SizedBox(height: 24),
            ],

            if (item is ArtefactWeapon) ...[
              _SectionTitle('Type d\'arme', icon: Icons.shield),
              const SizedBox(height: 8),
              _buildWeaponSection(context, item),
            ],

          ],
        ),
      ),
    );
  }

  // ─── Section arme ─────────────────────────────────────────────────────────────
  Widget _buildWeaponSection(BuildContext context, ArtefactWeapon w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow('Type',      _affinityLabel(w.type)),
        _InfoRow('Sous-type', _subAffinityLabel(w.subType)),
        const SizedBox(height: 16),

        _SectionTitle('Dégâts'),
        const SizedBox(height: 8),
        Text(w.damage),
        const SizedBox(height: 16),

        _SectionTitle('Caractéristiques'),
        const SizedBox(height: 8),
        Text(w.feature),
        const SizedBox(height: 16),

        _SectionTitle('Effets'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: w.effect
              .map((e) => Chip(label: Text(_effectLabel(e))))
              .toList(),
        ),
        const SizedBox(height: 16),

        _InfoRow('Taille', w.size.toString()),

        if (w.fire) ...[
          const SizedBox(height: 16),
          _SectionTitle('Arme à feu', icon: Icons.local_fire_department),
          const SizedBox(height: 8),
          if (w.calibre != null)    _InfoRow('Calibre',    w.calibre!.name),
          if (w.reload != null)     _InfoRow('Rechargement', '${w.reload}'),
          if (w.magazineSize != null)
            _InfoRow('Chargeur', '${w.magazineSize} cartouches'),
          if (w.secondMagazine == true && w.secondMagazineSize != null)
            _InfoRow('2e chargeur', '${w.secondMagazineSize} cartouches'),
          if (w.firing != null)
            _InfoRow('Mode de tir', _firingLabel(w.firing!)),
        ],

        const SizedBox(height: 24),
      ],
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
