import 'package:atable/logic/import.dart';
import 'package:atable/logic/models.dart';
import 'package:flutter_test/flutter_test.dart';

class TestD {
  final String text;
  final List<RecetteImport> expected;
  const TestD(this.text, this.expected);
}

main() {
  test("Import CSV", () {
    const input = """
      Tiramisu, , 8
      Oeufs, 6, P 
      Mascarpone, 500, g
      Sucre, 0.1, kg 
      Boudoirs, 60, P 
      Rhum, 10, cl
      Lardons, 300, g

      Salade de riz, , 12
      Riz, 2, kg
      Tomates, 1, kg
      Lardon, 0.5, kg
    """;
    final got = RecettesImporter.fromCSV(input).recettes;
    expect(got.length, 2);

    expect(got[0].ingredients.length, 6);
    expect(got[0].ingredients[0].quantite, 6);
    expect(got[0].ingredients[0].unite, Unite.piece);
    expect(got[0].ingredients[4].quantite, 0.1);

    expect(got[1].ingredients.length, 3);
    expect(got[1].ingredients[2].nom, "Lardons"); // pluriel
  });

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
        RecetteImport("Petits pqts chips", 21, Unite.piece),
        RecetteImport("Thon", 1.2, Unite.kg),
        RecetteImport("Pots mayo", 4, Unite.piece),
        RecetteImport("Oeufs", 21, Unite.piece),
        RecetteImport("Champis", 1, Unite.kg),
        RecetteImport("Salade", 1, Unite.piece),
        RecetteImport("Nectarines", 21, Unite.piece),
      ]),
      TestD("""
4kg lentilles en boîte
2kg patates
8 avocats
2kg tomates
2concombres
4 pqts lardons
1/2 pasteque""", [
        RecetteImport("Lentilles en boîte", 4, Unite.kg),
        RecetteImport("Patates", 2, Unite.kg),
        RecetteImport("Avocats", 8, Unite.piece),
        RecetteImport("Tomates", 2, Unite.kg),
        RecetteImport("Concombres", 2, Unite.piece),
        RecetteImport("Pqts lardons", 4, Unite.piece),
        RecetteImport("Pasteque", 0.5, Unite.piece),
      ]),
      TestD("""
21 tranches jambon
500 g beurre
1,2kg tomates
1 Salade
21 petits pqts chips
42 abricots""", [
        RecetteImport("Tranches jambon", 21, Unite.piece),
        RecetteImport("Beurre", 0.5, Unite.kg),
        RecetteImport("Tomates", 1.2, Unite.kg),
        RecetteImport("Salade", 1, Unite.piece),
        RecetteImport("Petits pqts chips", 21, Unite.piece),
        RecetteImport("Abricots", 42, Unite.piece),
      ]),
      TestD("""
2kg de pâtes
1,2kg dés de jambon
0.8 kg tomates
800g maïs
pot/sac d'olives

1kg raisin""", [
        RecetteImport("De pâtes", 2, Unite.kg),
        RecetteImport("Dés de jambon", 1.2, Unite.kg),
        RecetteImport("Tomates", 0.8, Unite.kg),
        RecetteImport("Maïs", 0.8, Unite.kg),
        RecetteImport("Pot/sac d'olives", 1, Unite.piece),
        RecetteImport("Raisin", 1, Unite.kg),
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
        RecetteImport("Melons", 4, Unite.piece),
        RecetteImport("Riz", 1.2, Unite.kg),
        RecetteImport("Tomate", 0.8, Unite.kg),
        RecetteImport("Oeufs", 10, Unite.piece),
        RecetteImport("Boites de lardons", 4, Unite.piece),
        RecetteImport("Compté", 0.2, Unite.kg),
        RecetteImport("Concombres", 2, Unite.piece),
      ])
    ];

    for (var te in texts) {
      final got = parseIngredients(te.text);
      expect(got, equals(te.expected));
    }
  });
}
