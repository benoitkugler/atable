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
        id: 0, nom: "INg1", categorie: CategorieIngredient.epicerie));

    final got1 = (await db.getIngredients()).map((e) => e.toString());
    expect(got1, [ing1.toString()]); // Check content

    final ing2 = await db.insertIngredient(const Ingredient(
        id: 0, nom: "INg1", categorie: CategorieIngredient.laitages));
    final got2 = (await db.getIngredients()).map((e) => e.toString());
    expect(got2, [ing1.toString(), ing2.toString()]); // Check content

    // nouveau menu
    final menu1 =
        await db.createMenu(const Menu(id: -1, nbPersonnes: 8, label: ""));
    final repas1 = await db.createRepas(
        Repas(id: 0, idMenu: menu1.id, date: DateTime.now(), nbPersonnes: 7));

    await db.insertMenuIngredient(MenuIngredient(
        idMenu: repas1.idMenu,
        idIngredient: ing1.id,
        quantite: 0.1245,
        unite: Unite.L,
        categorie: CategoriePlat.dessert));

    await db.insertMenuIngredient(MenuIngredient(
        idMenu: repas1.idMenu,
        idIngredient: ing2.id,
        quantite: 0.1245,
        unite: Unite.kg,
        categorie: CategoriePlat.divers));

    final got3 = await db.getIngredients();
    expect(got3.length, 2);

    await db.deleteMenuIngredient(MenuIngredient(
        idMenu: repas1.idMenu,
        idIngredient: ing2.id,
        quantite: 0,
        unite: Unite.piece,
        categorie: CategoriePlat.divers));

    await db.deleteRepas(repas1);

    final allRepas = await db.getRepas();
    expect(allRepas.length, 0);

    final menu2 = await db
        .createMenu(const Menu(id: 0, nbPersonnes: 10, label: "Super !"));
    final repas2 = await db.createRepas(
        Repas(id: 0, idMenu: menu2.id, date: DateTime.now(), nbPersonnes: 50));
    expect(repas2.idMenu, menu2.id);
    await db
        .createMenu(const Menu(id: 0, nbPersonnes: 10, label: "")); // anonyme

    final favoris = await db.getMenusFavoris();
    expect(favoris.length, 1);

    await db.db.close();
  });

  test('SQL API - Recettes', () async {
    final db = await DBApi.open(dbPath: inMemoryDatabasePath);
    final ing1 = await db.insertIngredient(const Ingredient(
        id: 0, nom: "INg1", categorie: CategorieIngredient.epicerie));
    final ing2 = await db.insertIngredient(const Ingredient(
        id: 0, nom: "INg1", categorie: CategorieIngredient.laitages));

    final recette1 = await db.createRecette(const Recette(
        id: -1,
        nbPersonnes: 8,
        label: "",
        categorie: CategoriePlat.entree,
        description: "Cuisson : 20min"));

    final recettes1 = await db.getRecettes();
    expect(recettes1.length, 1);

    await db.insertRecetteIngredient(RecetteIngredient(
      idRecette: recette1.id,
      idIngredient: ing1.id,
      quantite: 0.1245,
      unite: Unite.L,
    ));

    await db.insertRecetteIngredient(RecetteIngredient(
      idRecette: recette1.id,
      idIngredient: ing2.id,
      quantite: 0.1245,
      unite: Unite.kg,
    ));

    await db.insertRecetteIngredient(RecetteIngredient(
      idRecette: recette1.id,
      idIngredient: ing2.id,
      quantite: 0.1245,
      unite: Unite.kg,
    ));

    await db.deleteRecetteIngredient(RecetteIngredient(
      idRecette: recette1.id,
      idIngredient: ing2.id,
      quantite: 0,
      unite: Unite.piece,
    ));

    await db.deleteRecette(recette1.id);

    final recettes2 = await db.getRecettes();
    expect(recettes2.length, 0);

    await db.db.close();
  });
}
