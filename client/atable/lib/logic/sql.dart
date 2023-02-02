import 'dart:io';

import 'package:atable/logic/models.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// à garder synchronisé avec models.dart
const _createSQLStatements = [
  """ 
  CREATE TABLE ingredients(
    id INTEGER PRIMARY KEY,
    nom TEXT NOT NULL,
    categorie INTEGER NOT NULL,
    UNIQUE(nom, categorie)
  );
 """,
  """
  CREATE TABLE menus(
    id INTEGER PRIMARY KEY, 
    date TEXT NOT NULL,
    nbPersonnes INTEGER NOT NULL
  );
 """,
  """
  CREATE TABLE menu_ingredients(
    idMenu INTEGER NOT NULL,
    idIngredient INTEGER NOT NULL,
    quantite REAL NOT NULL,
    unite INTEGER NOT NULL,
    categorie INTEGER NOT NULL,
    FOREIGN KEY(idMenu) REFERENCES menus(id) ON DELETE CASCADE,
    FOREIGN KEY(idIngredient) REFERENCES ingredients(id),
    UNIQUE(idMenu, idIngredient, categorie)
  );
  """
];

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

    // open/create the database
    final database =
        await openDatabase(dbPath, version: 1, onCreate: (db, version) async {
      // Run the CREATE TABLE statements on the database.
      final ba = db.batch();
      for (var table in _createSQLStatements) {
        ba.execute(table);
      }
      ba.commit();
    }, singleInstance: false);

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
    return Ingredient(id: id, nom: ing.nom, categorie: ing.categorie);
  }

  Future<void> deleteIngredient(int id) async {
    // TODO: décider comment gérer les ingrédients utilisés dans un menu
    // Pour l'instant, une exception sera levée à cause la contrainte SQL
    await db.delete("ingredients", where: "id = ?", whereArgs: [id]);
  }

  Future<MenuExt> getMenu(int id) async {
    // load the menu
    final menu = Menu.fromSQLMap(
        (await db.query("menus", where: "id = ?", whereArgs: [id])).first);
    // load the link objects
    final menuIngredients = (await db
            .query("menu_ingredients", where: "idMenu = ?", whereArgs: [id]))
        .map(MenuIngredient.fromSQLMap);

    // load the ingredients
    final ingredients = Map.fromEntries((await db.query("ingredients"))
        .map(Ingredient.fromSQLMap)
        .map((ing) => MapEntry(ing.id, ing)));
    return MenuExt(
        menu,
        menuIngredients
            .map((link) =>
                MenuIngredientExt(ingredients[link.idIngredient]!, link))
            .toList());
  }

  /// [getMenus] renvoie la liste de tous les menus,
  /// avec leurs ingrédients.
  /// La liste est triée par date.
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
          ingredients[menuIngredient.idIngredient]!, menuIngredient));
    }
    // final build the complete menu
    final out =
        menus.map((m) => MenuExt(m, ingredientsByMenu[m.id] ?? [])).toList();
    out.sort((a, b) => a.menu.date.compareTo(b.menu.date));
    return out;
  }

  /// [insertMenu] crée un nouveau menu et renvoie l'objet avec le champ `id`
  /// mis à jour
  Future<Menu> insertMenu(Menu menu) async {
    final id = await db.insert("menus", menu.toSQLMap(true));
    return Menu(id: id, date: menu.date, nbPersonnes: menu.nbPersonnes);
  }

  /// [updateMenu] modifie le menu donné.
  Future<void> updateMenu(Menu menu) async {
    // Les liens MenuIngredients sont supprimés par cascade
    await db.update("menus", menu.toSQLMap(true),
        where: "id = ?", whereArgs: [menu.id]);
  }

  /// [deleteMenu] supprime le menu donné.
  /// Les ingrédients sont conservés.
  Future<void> deleteMenu(int id) async {
    // Les liens MenuIngredients sont supprimés par cascade
    await db.delete("menus", where: "id = ?", whereArgs: [id]);
  }

  /// [insertMenuIngredient] ajoute l'ingrédient donné au menu donné.
  /// Une exception est levée si l'ingrédient est déjà présent dans le menu (contrainte SQL).
  Future<void> insertMenuIngredient(MenuIngredient ingredient) async {
    await db.insert("menu_ingredients", ingredient.toSQLMap());
  }

  /// [deleteMenuIngredient] retire l'ingrédient donné du menu donné.
  Future<void> deleteMenuIngredient(int idMenu, int idIngredient) async {
    await db.delete("menu_ingredients",
        where: "idMenu = ? AND idIngredient = ?",
        whereArgs: [idMenu, idIngredient]);
  }

  /// [updateMenuIngredient] modifie le lien donné
  Future<void> updateMenuIngredient(MenuIngredient ing) async {
    await db.update("menu_ingredients", ing.toSQLMap(),
        where: "idMenu = ? AND idIngredient = ?",
        whereArgs: [ing.idMenu, ing.idIngredient]);
  }

  /// [updateMenuIngredients] est une optimisation pour appliquer [updateMenuIngredient]
  /// pour de nombreux ingrédients
  Future<void> updateMenuIngredients(List<MenuIngredient> ings) async {
    final b = db.batch();
    for (var ing in ings) {
      b.update("menu_ingredients", ing.toSQLMap(),
          where: "idMenu = ? AND idIngredient = ?",
          whereArgs: [ing.idMenu, ing.idIngredient]);
    }
    await b.commit();
  }
}
