import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
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
    final ing1 = await db.insertIngredient(const Ingredient(
        id: 0,
        nom: "INg1",
        unite: Unite.L,
        categorie: CategorieIngredient.epicerie));

    final got1 = (await db.getIngredients()).map((e) => e.toString());
    expect(got1, [ing1.toString()]); // Check content

    final ing2 = await db.insertIngredient(const Ingredient(
        id: 0,
        nom: "INg1",
        unite: Unite.L,
        categorie: CategorieIngredient.laitages));
    final got2 = (await db.getIngredients()).map((e) => e.toString());
    expect(got2, [ing1.toString(), ing2.toString()]); // Check content

    final menu =
        await db.insertMenu(Menu(id: 0, date: DateTime.now(), nbPersonnes: 7));

    await db.insertMenuIngredients([
      MenuIngredient(
          idMenu: menu.id,
          idIngredient: ing1.id,
          quantite: 0.1245,
          categorie: CategoriePlat.dessert),
      MenuIngredient(
          idMenu: menu.id,
          idIngredient: ing2.id,
          quantite: 0.1245,
          categorie: CategoriePlat.divers),
    ]);

    final got3 = await db.getIngredients();
    expect(got3.length, 2);

    await db.db.close();
  });
}
