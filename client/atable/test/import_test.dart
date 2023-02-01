import 'package:atable/logic/import.dart';
import 'package:atable/logic/models.dart';
import 'package:flutter_test/flutter_test.dart';

class TestD {
  final String text;
  final List<MenuItem> expected;
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
        MenuItem("Petits pqts chips", 21, Unite.piece),
        MenuItem("Thon", 1.2, Unite.kg),
        MenuItem("Pots mayo", 4, Unite.piece),
        MenuItem("Oeufs", 21, Unite.piece),
        MenuItem("Champis", 1, Unite.kg),
        MenuItem("Salade", 1, Unite.piece),
        MenuItem("Nectarines", 21, Unite.piece),
      ]),
      TestD("""
4kg lentilles en boîte
2kg patates
8 avocats
2kg tomates
2concombres
4 pqts lardons
1/2 pasteque""", [
        MenuItem("Lentilles en boîte", 4, Unite.kg),
        MenuItem("Patates", 2, Unite.kg),
        MenuItem("Avocats", 8, Unite.piece),
        MenuItem("Tomates", 2, Unite.kg),
        MenuItem("Concombres", 2, Unite.piece),
        MenuItem("Pqts lardons", 4, Unite.piece),
        MenuItem("Pasteque", 0.5, Unite.piece),
      ]),
      TestD("""
21 tranches jambon
500 g beurre
1,2kg tomates
1 Salade
21 petits pqts chips
42 abricots""", [
        MenuItem("Tranches jambon", 21, Unite.piece),
        MenuItem("Beurre", 0.5, Unite.kg),
        MenuItem("Tomates", 1.2, Unite.kg),
        MenuItem("Salade", 1, Unite.piece),
        MenuItem("Petits pqts chips", 21, Unite.piece),
        MenuItem("Abricots", 42, Unite.piece),
      ]),
      TestD("""
2kg de pâtes
1,2kg dés de jambon
0.8 kg tomates
800g maïs
pot/sac d'olives

1kg raisin""", [
        MenuItem("De pâtes", 2, Unite.kg),
        MenuItem("Dés de jambon", 1.2, Unite.kg),
        MenuItem("Tomates", 0.8, Unite.kg),
        MenuItem("Maïs", 0.8, Unite.kg),
        MenuItem("Pot/sac d'olives", 1, Unite.piece),
        MenuItem("Raisin", 1, Unite.kg),
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
        MenuItem("Melons", 4, Unite.piece),
        MenuItem("Riz", 1.2, Unite.kg),
        MenuItem("Tomate", 0.8, Unite.kg),
        MenuItem("Oeufs", 10, Unite.piece),
        MenuItem("Boites de lardons", 4, Unite.piece),
        MenuItem("Compté", 0.2, Unite.kg),
        MenuItem("Concombres", 2, Unite.piece),
      ])
    ];

    for (var te in texts) {
      final got = parseIngredients(te.text);
      expect(got, equals(te.expected));
    }
  });
}
