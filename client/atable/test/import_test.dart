import 'package:atable/logic/import.dart';
import 'package:atable/logic/models.dart';
import 'package:flutter_test/flutter_test.dart';

class TestD {
  final String text;
  final List<MenuImport> expected;
  const TestD(this.text, this.expected);
}

main() {
  test('Import ingredient', () {
    const texts = [
      TestD("""
21 petits pqts chips
1,2 kg thon
4 pots mayo
21 oeufs
1 kg champis
1 salade
21 nectarines
""", [
        MenuImport("Petits pqts chips", 21, Unite.piece),
        MenuImport("Thon", 1.2, Unite.kg),
        MenuImport("Pots mayo", 4, Unite.piece),
        MenuImport("Oeufs", 21, Unite.piece),
        MenuImport("Champis", 1, Unite.kg),
        MenuImport("Salade", 1, Unite.piece),
        MenuImport("Nectarines", 21, Unite.piece),
      ]),
      TestD("""
4kg lentilles en boîte
2kg patates
8 avocats
2kg tomates
2concombres
4 pqts lardons
1/2 pasteque""", [
        MenuImport("Lentilles en boîte", 4, Unite.kg),
        MenuImport("Patates", 2, Unite.kg),
        MenuImport("Avocats", 8, Unite.piece),
        MenuImport("Tomates", 2, Unite.kg),
        MenuImport("Concombres", 2, Unite.piece),
        MenuImport("Pqts lardons", 4, Unite.piece),
        MenuImport("Pasteque", 0.5, Unite.piece),
      ]),
      TestD("""
21 tranches jambon
500 g beurre
1,2kg tomates
1 Salade
21 petits pqts chips
42 abricots""", [
        MenuImport("Tranches jambon", 21, Unite.piece),
        MenuImport("Beurre", 0.5, Unite.kg),
        MenuImport("Tomates", 1.2, Unite.kg),
        MenuImport("Salade", 1, Unite.piece),
        MenuImport("Petits pqts chips", 21, Unite.piece),
        MenuImport("Abricots", 42, Unite.piece),
      ]),
      TestD("""
2kg de pâtes
1,2kg dés de jambon
0.8 kg tomates
800g maïs
pot/sac d'olives

1kg raisin""", [
        MenuImport("De pâtes", 2, Unite.kg),
        MenuImport("Dés de jambon", 1.2, Unite.kg),
        MenuImport("Tomates", 0.8, Unite.kg),
        MenuImport("Maïs", 0.8, Unite.kg),
        MenuImport("Pot/sac d'olives", 1, Unite.piece),
        MenuImport("Raisin", 1, Unite.kg),
      ]),
      TestD("""
4 melons
1,2 kg riz
0,8 kg tomate
 10 oeufs
4 boites de lardons
200g compté
2 concombres
""", [
        MenuImport("Melons", 4, Unite.piece),
        MenuImport("Riz", 1.2, Unite.kg),
        MenuImport("Tomate", 0.8, Unite.kg),
        MenuImport("Oeufs", 10, Unite.piece),
        MenuImport("Boites de lardons", 4, Unite.piece),
        MenuImport("Compté", 0.2, Unite.kg),
        MenuImport("Concombres", 2, Unite.piece),
      ])
    ];

    for (var te in texts) {
      final got = parseIngredients(te.text);
      expect(got, equals(te.expected));
    }
  });
}
