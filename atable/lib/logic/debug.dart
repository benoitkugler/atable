import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_sejours.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';

final now = DateTime.now();
const qu = QuantityR(1, Unite.kg, 10);
final data = TablesM({
  1: Ingredient(1, "Ing 1", IngredientKind.epicerie),
  2: Ingredient(2, "Ing 2", IngredientKind.viandes),
  3: Ingredient(3, "Ing 3", IngredientKind.legumes),
  4: Ingredient(4, "Pain", IngredientKind.boulangerie),
}, {
  1: Receipe(1, 0, PlatKind.entree, "Salade", ""),
  2: Receipe(2, 0, PlatKind.platPrincipal, "Moussaka", ""),
  3: Receipe(3, 0, PlatKind.dessert, "Tiramisu", ""),
  4: Receipe(4, 0, PlatKind.empty, "Salade inconnue", ""),
}, [
  ReceipeIngredient(1, 1, qu),
  ReceipeIngredient(1, 2, qu),
  ReceipeIngredient(1, 3, qu),
  //
  ReceipeIngredient(2, 1, qu),
  ReceipeIngredient(2, 2, qu),
  //
  ReceipeIngredient(3, 2, qu),
], {
  1: Menu(1, 0, false),
  2: Menu(2, 0, false),
}, [
  MenuReceipe(1, 1),
  MenuReceipe(1, 2),
  MenuReceipe(2, 3),
], [
  MenuIngredient(1, 3, qu, PlatKind.dessert),
  MenuIngredient(1, 4, qu, PlatKind.dessert),
], [
  MealM(1, 1, "C2 (Grands)", DateTime(now.year, now.month, now.day, 8), 25),
  MealM(2, 1, "C2 (Grands)", DateTime(now.year, now.month, now.day, 12), 25),
  MealM(
      3,
      2,
      "C2 (Grands)",
      DateTime(now.year, now.month, now.day, 8).add(const Duration(days: 1)),
      25),
  MealM(
      4,
      1,
      "C2 (Grands)",
      DateTime(now.year, now.month, now.day, 8)
          .subtract(const Duration(days: 2)),
      25),
  MealM(
      5,
      1,
      "C2 (Grands)",
      DateTime(now.year, now.month, now.day, 8)
          .subtract(const Duration(days: 3)),
      25),
  MealM(
      6,
      1,
      "C2 (Grands)",
      DateTime(now.year, now.month, now.day, 8)
          .subtract(const Duration(days: 4)),
      25),
]);
