import 'package:atable/logic/sql.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_sejours.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future main() async {
  // Setup sqflite_common_ffi for flutter test
  setUpAll(() {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  });
  test('SQL API', () async {
    final db = await DBApi.open(dbPath: inMemoryDatabasePath);
    final ing1 = await db
        .insertIngredient(const Ingredient(0, "INg1", IngredientKind.epicerie));

    final got1 = (await db.getIngredients()).map((e) => e.toString());
    expect(got1, [ing1.toString()]); // Check content

    final ing2 = await db
        .insertIngredient(const Ingredient(0, "INg1", IngredientKind.laitages));
    final got2 = (await db.getIngredients()).map((e) => e.toString());
    expect(got2, [ing1.toString(), ing2.toString()]); // Check content

    // nouveau menu
    final menu1 =
        await db.db.insert("menus", const Menu(-1, 0, false).toSQLMap(true));
    final meal1 = await db.db
        .insert("meals", MealM(0, menu1, "", DateTime.now(), 7).toSQLMap(true));

    await db.insertMenuIngredient(MenuIngredient(
        menu1, ing1.id, const QuantityR(0.1245, Unite.l, 8), PlatKind.dessert));

    await db.insertMenuIngredient(MenuIngredient(menu1, ing2.id,
        const QuantityR(0.1245, Unite.kg, 8), PlatKind.platPrincipal));

    final got3 = await db.getIngredients();
    expect(got3.length, 2);

    await db.deleteMenuIngredient(MenuIngredient(
        menu1, ing2.id, const QuantityR(0, Unite.cL, 0), PlatKind.empty));

    await db.deleteMeal(meal1);

    final allMeals = await db.getMeals();
    expect(allMeals.length, 0);

    final menu2 =
        await db.db.insert("menus", const Menu(0, 0, false).toSQLMap(true));
    await db.db.insert(
        "meals", MealM(0, menu2, "", DateTime.now(), 50).toSQLMap(true));

    await db.close();
  });

  test('SQL API - Receipes', () async {
    final db = await DBApi.open(dbPath: inMemoryDatabasePath);
    final ing1 = await db
        .insertIngredient(const Ingredient(0, "INg1", IngredientKind.epicerie));
    final ing2 = await db
        .insertIngredient(const Ingredient(0, "INg1", IngredientKind.laitages));

    final receipe1 = await db.db.insert(
        "receipes",
        const Receipe(-1, 0, PlatKind.entree, "", "Cuisson : 20min")
            .toSQLMap(true));

    await db.insertReceipeIngredient(ReceipeIngredient(
        receipe1, ing1.id, const QuantityR(0.1245, Unite.l, 10)));
    await db.insertReceipeIngredient(ReceipeIngredient(
        receipe1, ing2.id, const QuantityR(0.1245, Unite.kg, 10)));
    await db.insertReceipeIngredient(ReceipeIngredient(
        receipe1, ing2.id, const QuantityR(0.1245, Unite.kg, 10)));

    await db.deleteReceipeIngredient(ReceipeIngredient(
      receipe1,
      ing2.id,
      const QuantityR(0, Unite.piece, 0),
    ));

    await db.close();
  });
}
