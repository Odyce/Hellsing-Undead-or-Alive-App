enum CostType { pe, pm, pv}

class Skill {
  final int id;
  final String name;
  final int cost;
  final CostType costType;
  final int? secondCost;
  final CostType? secondCostType;
  final bool multiCost;
  final List<int>? costs;
  final List<String>? descriptions;
  final bool limited;
  final String description;
  
  const Skill(
    {
      required this.id,
      required this.name,
      required this.cost,
      required this.costType,
      this.secondCost,
      this.secondCostType,
      required this.multiCost,
      this.costs,
      this.descriptions,
      required this.limited,
      required this.description
    }
  );
}

enum Affinities { firearm, explosive, oneHandSharp, twoHandShard, bow, throwable, none, choiceNonExplosive}

class Class {
  final int id;
  final String name;
  final String quote;
  final List<String> classBonus;
  final List<Affinities> affinities;
  final List<Skill> freeSkill;
  final String skillNumberReminder;
  final CostType classType;
  final List<Skill> allSkills;

  const Class(
    {
      required this.id,
      required this.name,
      required this.quote,
      required this.classBonus,
      required this.affinities,
      required this.freeSkill,
      required this.skillNumberReminder,
      required this.classType,
      required this.allSkills
    }
  );
}

class Race {
  final int id;
  final String name;
  final String description;
  final List<String>? bonuses;
  final List<String>? maluses;
  final List<Class> availableClasses;

  const Race (
    {
      required this.id,
      required this.name,
      required this.description,
      this.bonuses,
      this.maluses,
      required this.availableClasses
    }
  );
}
