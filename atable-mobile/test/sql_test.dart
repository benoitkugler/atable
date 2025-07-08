import 'package:atable/logic/env.dart';
import 'package:atable/logic/shop.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/stock.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_sejours.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_shop-session.dart';
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
    final db = await DBApi.open(BuildMode.prod, dbPath: inMemoryDatabasePath);
    final ing1 = await db.insertIngredient(
        const Ingredient(0, "INg1", IngredientKind.epicerie, 1));

    final got1 = (await db.getIngredients()).map((e) => e.toString());
    expect(got1, [ing1.toString()]); // Check content

    final ing2 = await db.insertIngredient(
        const Ingredient(0, "INg1", IngredientKind.laitages, 1));
    final got2 = (await db.getIngredients()).map((e) => e.toString());
    expect(got2, [ing1.toString(), ing2.toString()]); // Check content

    // nouveau menu
    final menu1 = await db.db.insert(
        "menus", Menu(-1, 0, false, false, DateTime.now()).toSQLMap(true));
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

    final menu2 = await db.db.insert(
        "menus", Menu(0, 0, false, false, DateTime.now()).toSQLMap(true));
    await db.db.insert(
        "meals", MealM(0, menu2, "", DateTime.now(), 50).toSQLMap(true));

    await db.close();
  });

  test('SQL API - Receipes', () async {
    final db = await DBApi.open(BuildMode.dev, dbPath: inMemoryDatabasePath);
    final ing1 = await db.insertIngredient(
        const Ingredient(0, "INg1", IngredientKind.epicerie, 1));
    final ing2 = await db.insertIngredient(
        const Ingredient(0, "INg1", IngredientKind.laitages, 1));

    final receipe1 = await db.db.insert(
        "receipes",
        Receipe(-1, 0, PlatKind.entree, "", "Cuisson : 20min", false,
                DateTime.now())
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

  test("SQL API - Stock", () async {
    final db = await DBApi.open(BuildMode.dev, dbPath: inMemoryDatabasePath);
    final ing1 = await db.insertIngredient(
        const Ingredient(0, "INg1", IngredientKind.epicerie, 1));
    final ing2 = await db.insertIngredient(
        const Ingredient(0, "INg1", IngredientKind.laitages, 1));

    expect((await db.getStock()).length, 0);

    await db.insertStock(
        StockEntry(ing1.id, const QuantitiesNorm(l: 23.3, pieces: 4)));
    await db.updateStock(StockEntry(ing1.id, const QuantitiesNorm()));

    expect((await db.getStock()).length, 1);

    await db.deleteStock(ing1.id);

    expect((await db.getStock()).length, 0);

    await db.insertStock(StockEntry(ing1.id, const QuantitiesNorm()));

    await db.addStockFromShop([
      IngredientUses(
          ing1,
          [
            Quantite(2, Unite.kg, Origin(DateTime.now(), "", "")),
            Quantite(2.3, Unite.l, Origin(DateTime.now(), "", "")),
          ],
          false),
      IngredientUses(ing2, [], false),
    ]);

    expect((await db.getStock()).length, 2);

    await db.addStockFromShop([
      IngredientUses(
          ing1,
          [
            Quantite(2, Unite.kg, Origin(DateTime.now(), "", "")),
            Quantite(2.3, Unite.l, Origin(DateTime.now(), "", "")),
          ],
          false),
      IngredientUses(ing2, [], false),
    ]);

    expect((await db.getStock()).length, 2);

    await db.close();
  });
}
