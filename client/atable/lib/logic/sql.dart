import 'dart:io';

import 'package:atable/logic/models.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// à garder synchronisé avec models.dart
const _createSQLStatement = """ 
  CREATE TABLE ingredients(
    id INTEGER PRIMARY KEY,
    nom TEXT NOT NULL,
    unite INTEGER NOT NULL,
    categorie INTEGER NOT NULL,
    UNIQUE(nom, categorie)
  );
 
  CREATE TABLE menus(
    id INTEGER PRIMARY KEY, 
    date TEXT NOT NULL,
    nbPersonnes INTEGER NOT NULL
  );
 
  CREATE TABLE menu_ingredients(
    idMenu INTEGER NOT NULL,
    idIngredient INTEGER NOT NULL,
    quantite REAL NOT NULL,
    categorie INTEGER NOT NULL,
    FOREIGN KEY(idMenu) REFERENCES menus(id) ON DELETE CASCADE,
    FOREIGN KEY(idIngredient) REFERENCES ingredients(id),
    UNIQUE(idMenu, idIngredient, categorie)
  );
  """;

/// DBApi stocke une connection à la base de données
/// et fournit les méthodes requises pour y lire et écrire.
class DBApi {
  final Database db;
  const DBApi._(this.db);

  /// [open] se connecte à la base de données ou en créée une
  /// si besoin.
  static Future<DBApi> open({String? dbPath}) async {
    WidgetsFlutterBinding.ensureInitialized(); // required by sqflite

    if (dbPath == null) {
      const dbName = "atable_database.db";
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      dbPath = join(await getDatabasesPath(), dbName);
    }

    final fi = File(dbPath);
    if (await fi.exists()) {
      await fi.delete();
    }

    // open/create the database
    final database = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // Run the CREATE TABLE statements on the database.
        await db.execute(_createSQLStatement);
      },
    );

    return DBApi._(database);
  }

  /// [getIngredients] renvoie la liste de tous les ingrédients connus.
  Future<List<Ingredient>> getIngredients() async {
    return (await db.query("ingredients")).map(Ingredient.fromSQLMap).toList();
  }

  /// [insertIngredient] crée un nouvel ingrédient et renvoie l'objet avec le champ `id`
  /// mis à jour
  Future<Ingredient> insertIngredient(Ingredient ing) async {
    final id = await db.insert("ingredients", ing.toSQLMap(true));
    return Ingredient(
        id: id, nom: ing.nom, unite: ing.unite, categorie: ing.categorie);
  }

  Future<void> deleteIngredient(int id) async {
    // TODO: décider comment gérer les ingrédients utilisés dans un menu
    // Pour l'instant, une exception sera levée à cause la contrainte SQL
    await db.delete("ingredients", where: "id = ?", whereArgs: [id]);
  }

  /// [getMenus] renvoie la liste de tous les menus,
  /// avec leurs ingrédients.
  Future<List<MenuExt>> getMenus() async {
    // load the ingredients
    final ingredients = Map.fromEntries((await db.query("ingredients"))
        .map(Ingredient.fromSQLMap)
        .map((ing) => MapEntry(ing.id, ing)));
    // load the menus
    final menus = (await db.query("menus")).map(Menu.fromSQLMap);
    // load the link objects
    final menuIngredients =
        (await db.query("menu_ingredients")).map(MenuIngredient.fromSQLMap);
    final ingredientsByMenu = <int, List<MenuIngredientExt>>{};
    for (var menuIngredient in menuIngredients) {
      final l = ingredientsByMenu.putIfAbsent(menuIngredient.idMenu, () => []);
      l.add(MenuIngredientExt(
        ingredients[menuIngredient.idIngredient]!,
        menuIngredient.quantite,
        menuIngredient.categorie,
      ));
    }
    // final build the complete menu
    return menus.map((m) => MenuExt(m, ingredientsByMenu[m.id] ?? [])).toList();
  }

  /// [insertMenu] crée un nouveau menu et renvoie l'objet avec le champ `id`
  /// mis à jour
  Future<Menu> insertMenu(Menu menu) async {
    final id = await db.insert("menus", menu.toSQLMap(true));
    return Menu(id: id, date: menu.date, nbPersonnes: menu.nbPersonnes);
  }

  // TODO: vérifier si cette méthode est réellement utile
  Future<void> insertMenuIngredients(List<MenuIngredient> ingredients) async {
    final batch = db.batch();
    for (var ingredient in ingredients) {
      batch.insert("menu_ingredients", ingredient.toSQLMap());
    }
    await batch.commit();
  }

  /// [deleteMenu] supprime le menu donné.
  /// Les ingrédients sont conservés.
  Future<void> deleteMenu(int id) async {
    // TODO: à implémenter
  }

  /// [insertMenuIngredient] ajoute l'ingrédient donné au menu donné.
  /// Une exception est levée si l'ingrédient est déjà présent dans le menu (contrainte SQL).
  Future<void> insertMenuIngredient(MenuIngredient ingredient) async {
    // TODO: à implémenter
  }

  /// [deleteMenuIngredient] retire l'ingrédient donné du menu donné.
  Future<void> deleteMenuIngredient(MenuIngredient ingredient) async {
    // TODO: à implémenter
  }
}
