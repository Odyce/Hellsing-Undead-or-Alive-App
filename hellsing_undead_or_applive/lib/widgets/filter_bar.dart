import 'package:flutter/material.dart';

/// Un groupe de filtres (ex : "Type", "Relation", "Statut").
///
/// Chaque groupe contient une liste d'options. Lorsqu'une option est
/// sélectionnée, seuls les éléments correspondant à ce critère restent
/// visibles. Cliquer à nouveau désactive le filtre.
class FilterGroup<T> {
  final String label;
  final List<FilterOption<T>> options;

  const FilterGroup({required this.label, required this.options});
}

class FilterOption<T> {
  final String label;
  final T value;

  const FilterOption({required this.label, required this.value});
}

/// Barre de filtres affichée en haut d'une liste.
///
/// [groups] définit les groupes de filtres disponibles.
/// [activeFilters] est un Map'<'String, Set'<'T'>>' indexé par le label du groupe.
/// [onChanged] est appelé à chaque clic sur un chip avec la nouvelle map.
class FilterBar extends StatelessWidget {
  final List<FilterGroup> groups;
  final Map<String, Set<dynamic>> activeFilters;
  final ValueChanged<Map<String, Set<dynamic>>> onChanged;

  const FilterBar({
    super.key,
    required this.groups,
    required this.activeFilters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final group in groups)
            for (final option in group.options)
              _buildChip(context, group.label, option),
        ],
      ),
    );
  }

  Widget _buildChip(
      BuildContext context, String groupLabel, FilterOption option) {
    final active = activeFilters[groupLabel]?.contains(option.value) ?? false;

    return FilterChip(
      label: Text(
        option.label,
        style: TextStyle(
          fontSize: 12,
          color: active ? Colors.white : null,
        ),
      ),
      selected: active,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Colors.white,
      onSelected: (_) {
        final newFilters =
            Map<String, Set<dynamic>>.from(activeFilters.map(
          (k, v) => MapEntry(k, Set<dynamic>.from(v)),
        ));

        final set = newFilters.putIfAbsent(groupLabel, () => <dynamic>{});
        if (active) {
          set.remove(option.value);
          if (set.isEmpty) newFilters.remove(groupLabel);
        } else {
          set.add(option.value);
        }
        onChanged(newFilters);
      },
    );
  }
}
