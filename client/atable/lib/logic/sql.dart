import 'dart:io';

import 'package:atable/logic/models.dart';
import 'package:atable/logic/utils.dart';
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
    nbPersonnes INTEGER NOT NULL,
    label TEXT NOT NULL
  );
 """,
  """
  CREATE TABLE repas(
    id INTEGER PRIMARY KEY, 
    idMenu INTEGER NOT NULL,
    date TEXT NOT NULL,
    nbPersonnes INTEGER NOT NULL,
    FOREIGN KEY(idMenu) REFERENCES menus(id)
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

    // DEV MODE only : reset DB at start
    final fi = File(dbPath);
    if (await fi.exists()) {
      await fi.delete();
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

  Future<List<MenuIngredientExt>> _loadMenuIngredients(int idMenu) async {
    // load the link objects
    final menuIngredients = (await db.query("menu_ingredients",
            where: "idMenu = ?", whereArgs: [idMenu]))
        .map(MenuIngredient.fromSQLMap);

    // load the ingredients
    final ingredients = Map.fromEntries((await db.query("ingredients",
            where: "id IN ${_arrayPlaceholders(menuIngredients)}",
            whereArgs: menuIngredients.map((e) => e.idIngredient).toList()))
        .map(Ingredient.fromSQLMap)
        .map((ing) => MapEntry(ing.id, ing)));

    return menuIngredients
        .map((link) => MenuIngredientExt(ingredients[link.idIngredient]!, link))
        .toList();
  }

  Future<MenuExt> getMenu(int id) async {
    // load the menu
    final menu = Menu.fromSQLMap(
        (await db.query("menus", where: "id = ?", whereArgs: [id])).first);

    // load the link objects
    final menuIngredients = await _loadMenuIngredients(id);

    return MenuExt(menu, menuIngredients);
  }

  /// [getMenusFavoris] renvoie la liste des menus ajoutés en favori.
  Future<List<MenuExt>> getMenusFavoris() async {
    // load the required menus
    final menus = (await db.query(
      "menus",
      where: "label != ''",
      orderBy: "label",
    ))
        .map(Menu.fromSQLMap);

    return _loadIngredients(menus);
  }

  /// [getRepas] renvoie la liste de tous les repas,
  /// avec leur menu.
  /// La liste est triée par date.
  Future<List<RepasExt>> getRepas() async {
    // load all the repas
    final repas = (await db.query("repas")).map(Repas.fromSQLMap);
    final idMenus = repas.map((e) => e.idMenu);

    // load the required menus
    final menus = (await db.query("menus",
            where: "id IN ${_arrayPlaceholders(idMenus)}",
            whereArgs: idMenus.toList()))
        .map(Menu.fromSQLMap);

    final menusExt = await _loadIngredients(menus);
    final menusDict =
        Map.fromEntries(menusExt.map((e) => MapEntry(e.menu.id, e)));

    // finally build the complete repas
    final out = repas.map((r) => RepasExt(r, menusDict[r.idMenu]!)).toList();
    out.sort((a, b) => a.repas.date.compareTo(b.repas.date));
    return out;
  }

  Future<List<MenuExt>> _loadIngredients(Iterable<Menu> menus) async {
    // load the link objects
    final menuIngredients = (await db.query("menu_ingredients",
            where: "idMenu IN ${_arrayPlaceholders(menus)}",
            whereArgs: menus.map((e) => e.id).toList()))
        .map(MenuIngredient.fromSQLMap);

    // load the ingredients
    final ingredients = Map.fromEntries((await db.query("ingredients",
            where: "id IN ${_arrayPlaceholders(menuIngredients)}",
            whereArgs: menuIngredients.map((e) => e.idIngredient).toList()))
        .map(Ingredient.fromSQLMap)
        .map((ing) => MapEntry(ing.id, ing)));

    final ingredientsByMenu = <int, List<MenuIngredientExt>>{};
    for (var menuIngredient in menuIngredients) {
      final l = ingredientsByMenu.putIfAbsent(menuIngredient.idMenu, () => []);
      l.add(MenuIngredientExt(
          ingredients[menuIngredient.idIngredient]!, menuIngredient));
    }
    // final build the complete menu
    final out =
        menus.map((m) => MenuExt(m, ingredientsByMenu[m.id] ?? [])).toList();
    return out;
  }

  /// [getRepasFromMenu] renvoie la liste des repas dans lesquels [menu]
  /// est utilisé (éventuellement vide).
  Future<List<Repas>> getRepasFromMenu(Menu menu) async {
    final repas =
        (await db.query("repas", where: "idMenu = ?", whereArgs: [menu.id]))
            .map(Repas.fromSQLMap)
            .toList();
    repas.sort((a, b) => a.date.compareTo(b.date));
    return repas;
  }

  /// Utilise la date courante si aucun repas n'existe encore
  /// Sinon utilise le dernier repas et passe au prochain créneau horaire
  Future<Repas> guessRepasProperties() async {
    final repass = (await db.query("repas")).map(Repas.fromSQLMap);
    final date = repass.isEmpty
        ? DateTime.now()
        : MomentRepasE.nextRepas(repass.last.date);
    final nbPersonnes = repass.isEmpty ? 8 : repass.last.nbPersonnes;
    return Repas(id: 0, idMenu: 0, date: date, nbPersonnes: nbPersonnes);
  }

  /// [createRepas] crée un nouveau repas et renvoie l'objet avec le champ `id` mis à jour
  Future<Repas> createRepas(Repas repas) async {
    final idRepas = await db.insert("repas", repas.toSQLMap(true));
    return repas.copyWith(id: idRepas);
  }

  /// [updateRepas] modifie le repas donné.
  Future<void> updateRepas(Repas repas) async {
    await db.update("repas", repas.toSQLMap(true),
        where: "id = ?", whereArgs: [repas.id]);
  }

  /// [createMenu] ajoute [menu] et met à jour le champ `id`
  Future<Menu> createMenu(Menu menu) async {
    final id = await db.insert("menus", menu.toSQLMap(true));
    return menu.copyWith(id: id);
  }

  /// [updateMenu] modifie le menu donné.
  Future<void> updateMenu(Menu menu) async {
    await db.update("menus", menu.toSQLMap(true),
        where: "id = ?", whereArgs: [menu.id]);
  }

  /// [deleteMenu] supprime le menu donné.
  /// Les ingrédients sont conservés.
  Future<void> deleteMenu(int id) async {
    // Les liens MenuIngredients sont supprimés par cascade
    await db.delete("menus", where: "id = ?", whereArgs: [id]);
  }

  /// [deleteRepas] supprime le repas donné.
  /// Si le menu associé est anonyme, il est aussi supprimé (via [deleteMenu])
  Future<void> deleteRepas(Repas repas) async {
    final menu = Menu.fromSQLMap(
        (await db.query("menus", where: "id = ?", whereArgs: [repas.idMenu]))
            .first);

    // Les liens MenuIngredients sont supprimés par cascade
    await db.delete("repas", where: "id = ?", whereArgs: [repas.id]);

    if (menu.label.isEmpty) {
      await deleteMenu(menu.id);
    }
  }

  /// [insertMenuIngredient] ajoute l'ingrédient donné au menu donné.
  /// Si l'ingrédient est déjà présent (dans le même plat), les quantités sont fusionnées
  /// Renvoie les ingrédients mis à jour
  Future<List<MenuIngredientExt>> insertMenuIngredient(
      MenuIngredient ingredient) async {
    final menuIngredients = (await db.query("menu_ingredients",
            where: "idMenu = ?", whereArgs: [ingredient.idMenu]))
        .map(MenuIngredient.fromSQLMap)
        .toList();

    final alreadyPresent = menuIngredients.indexWhere((element) =>
        element.categorie == ingredient.categorie &&
        element.idIngredient == ingredient.idIngredient);
    if (alreadyPresent != -1) {
      final link = menuIngredients[alreadyPresent];
      final newLink =
          link.copyWith(quantite: link.quantite + ingredient.quantite);
      await updateMenuIngredient(newLink);
    } else {
      await db.insert("menu_ingredients", ingredient.toSQLMap());
    }

    return await _loadMenuIngredients(ingredient.idMenu);
  }

  /// [deleteMenuIngredient] retire l'ingrédient donné du menu donné.
  Future<void> deleteMenuIngredient(MenuIngredient link) async {
    await db.delete("menu_ingredients",
        where: "idMenu = ? AND idIngredient = ? AND categorie = ?",
        whereArgs: [link.idMenu, link.idIngredient, link.categorie.index]);
  }

  /// [updateMenuIngredient] modifie le lien donné
  Future<void> updateMenuIngredient(MenuIngredient ing) async {
    await db.update("menu_ingredients", ing.toSQLMap(),
        where: "idMenu = ? AND idIngredient = ?",
        whereArgs: [ing.idMenu, ing.idIngredient]);
  }
}

String _arrayPlaceholders(Iterable array) {
  final values = List.filled(array.length, "?").join(",");
  return "($values)";
}
