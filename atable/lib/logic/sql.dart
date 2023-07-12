import 'dart:io';

import 'package:atable/logic/models.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  CREATE TABLE recettes(
    id INTEGER PRIMARY KEY, 
    nbPersonnes INTEGER NOT NULL,
    label TEXT NOT NULL,
    categorie INTEGER NOT NULL,
    description TEXT NOT NULL
  );
  """,
  """
  CREATE TABLE recette_ingredients(
    idRecette INTEGER NOT NULL,
    idIngredient INTEGER NOT NULL,
    quantite REAL NOT NULL,
    unite INTEGER NOT NULL,
    FOREIGN KEY(idRecette) REFERENCES recettes(id) ON DELETE CASCADE,
    FOREIGN KEY(idIngredient) REFERENCES ingredients(id),
    UNIQUE(idRecette, idIngredient)
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
  """,
  """
  CREATE TABLE menu_recettes(
    idMenu INTEGER NOT NULL,
    idRecette INTEGER NOT NULL,
    FOREIGN KEY(idMenu) REFERENCES menus(id) ON DELETE CASCADE,
    FOREIGN KEY(idRecette) REFERENCES recettes(id),
    UNIQUE(idMenu, idRecette)
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
];

class UtilisationsIngredient {
  final int recettes;
  final int menus;
  const UtilisationsIngredient(this.recettes, this.menus);
}

class MenuOrRepas {
  final Repas? repas;
  final Menu menu;
  MenuOrRepas(this.repas, this.menu);
}

/// DBApi stocke une connection à la base de données
/// et fournit les méthodes requises pour y lire et écrire.
class DBApi {
  final Database _db;
  const DBApi._(this._db);

  static const _apiVersion = 1;

  static Future<String> _defaultPath() async {
    const dbName = "atable_database.db";
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    return join(await getDatabasesPath(), dbName);
  }

  /// [open] se connecte à la base de données ou en créée une
  /// si besoin.
  /// [dbPath] peut être fourni pour choisir le fichier de stockage.
  static Future<DBApi> open({String? dbPath}) async {
    WidgetsFlutterBinding.ensureInitialized(); // required by sqflite

    dbPath ??= await _defaultPath();

    // // DEV MODE only : reset DB at start
    // final fi = File(dbPath);
    // if (await fi.exists()) {
    //   await fi.delete();
    //   print("DB deleted");
    // }

    // open/create the database
    final database = await openDatabase(dbPath, version: _apiVersion,
        onCreate: (db, version) async {
      // Run the CREATE TABLE statements on the database.
      final ba = db.batch();
      for (var table in _createSQLStatements) {
        ba.execute(table);
      }
      ba.commit();
    }, singleInstance: false);

    return DBApi._(database);
  }

  /// [checkValidDB] lance une exception si le fichier ne suit pas le modèle attendu.
  static Future<void> checkValidDB(File inDBFile) async {
    final Database tmpDB;
    final int v;
    try {
      tmpDB = await openDatabase(inDBFile.path, readOnly: true);
      v = await tmpDB.getVersion();
    } catch (e) {
      throw "Le fichier n'est pas une base de données A table.";
    }

    if (v != _apiVersion) {
      tmpDB.close();
      throw "La version de la base de données est incompatible ($v != $_apiVersion).";
    }

    final tables =
        (await tmpDB.query("sqlite_master", columns: ['type', 'name']))
            .where((element) => element["type"] == "table")
            .map((d) => d["name"])
            .toSet();
    if (!tables.containsAll([
      "ingredients",
      "recettes",
      "recette_ingredients",
      "menus",
      "menu_ingredients",
      "menu_recettes",
      "repas",
    ])) {
      tmpDB.close();
      throw "Le schéma de la base de données est invalide.";
    }
  }

  /// [importDB] copie le fichier donné en remplacement de la base actuelle,
  /// puis ouvre une nouvelle connection.
  /// La base actuelle devrait être fermée au préalable.
  static Future<DBApi> importDB(File inDBFile, {String? dbPath}) async {
    dbPath ??= await _defaultPath();
    final newDBFile = await inDBFile.copy(dbPath);
    return await open(dbPath: newDBFile.path);
  }

  /// [exportDB] copie le fichier de la base dans le dossier
  /// de téléchargements et renvoie le chemin du fichier créé.
  static Future<String> exportDB({String? dbPath}) async {
    final dir = await downloadDir();

    final perm = await Permission.storage.request();
    if (!perm.isGranted) {
      throw "L'accès au dossier est refusé.";
    }

    final now = DateTime.now();
    final targetPath = join(dir.absolute.path,
        "atable_${now.day.toString().padLeft(2, '0')}_${now.month.toString().padLeft(2, '0')}.db.tar");

    dbPath ??= await _defaultPath();
    await File(dbPath).copy(targetPath);
    return targetPath;
  }

  Future<void> close() async {
    await _db.close();
  }

  /// [getIngredients] renvoie la liste de tous les ingrédients connus.
  Future<List<Ingredient>> getIngredients() async {
    return (await _db.query("ingredients")).map(Ingredient.fromSQLMap).toList();
  }

  /// [insertIngredient] crée un nouvel ingrédient et renvoie l'objet avec le champ `id`
  /// mis à jour
  Future<Ingredient> insertIngredient(Ingredient ing) async {
    final id = await _db.insert("ingredients", ing.toSQLMap(true));
    return Ingredient(id: id, nom: ing.nom, categorie: ing.categorie);
  }

  /// [insertIngredients] crée plusieurs ingrédients et renvoie les objets avec le champ `id`
  /// mis à jour
  Future<List<Ingredient>> insertIngredients(List<Ingredient> ings) async {
    final batch = _db.batch();
    for (var ing in ings) {
      batch.insert("ingredients", ing.toSQLMap(true));
    }
    final ids = await batch.commit();
    return List.generate(
        ings.length, (index) => ings[index].copyWith(id: ids[index] as int));
  }

  Future<void> updateIngredient(Ingredient ing) async {
    await _db.update("ingredients", ing.toSQLMap(true),
        where: "id = ?", whereArgs: [ing.id]);
  }

  Future<UtilisationsIngredient> getIngredientUses(int id) async {
    final recettes = (await _db.query("recette_ingredients",
            where: "idIngredient = ?", whereArgs: [id]))
        .map(RecetteIngredient.fromSQLMap)
        .map((e) => e.idRecette)
        .toSet()
        .length;
    final menus = (await _db.query("menu_ingredients",
            where: "idIngredient = ?", whereArgs: [id]))
        .map(MenuIngredient.fromSQLMap)
        .map((e) => e.idMenu)
        .toSet()
        .length;
    return UtilisationsIngredient(recettes, menus);
  }

  Future<RecetteExt> getRecette(int id) async {
    // load the recette
    final recette = Recette.fromSQLMap(
        (await _db.query("recettes", where: "id = ?", whereArgs: [id])).first);

    // load the link objects
    final recetteIngredients = await _loadRecetteIngredients(id);

    return RecetteExt(recette, recetteIngredients);
  }

  /// [getRecettesMetas] renvoie la liste des recettes (sans les ingrédients)
  Future<List<Recette>> getRecettesMetas() async {
    // load the required recettes
    final recettes = (await _db.query("recettes")).map(Recette.fromSQLMap);

    return recettes.toList();
  }

  /// [getRecettes] renvoie la liste des recettes.
  Future<List<RecetteExt>> getRecettes() async {
    // load the required recettes
    final recettes = (await _db.query("recettes")).map(Recette.fromSQLMap);

    return await _loadRecettesIngs(recettes);
  }

  Future<List<RecetteExt>> _loadRecettesIngs(Iterable<Recette> recettes) async {
    // load the links
    final links = (await _db.query("recette_ingredients"))
        .map(RecetteIngredient.fromSQLMap);

    final ingredients =
        await _loadIngredients(links.map((e) => e.idIngredient));

    final ingredientsByRecette = <int, List<RecetteIngredientExt>>{};
    for (var recetteIngredient in links) {
      final l = ingredientsByRecette.putIfAbsent(
          recetteIngredient.idRecette, () => []);
      l.add(RecetteIngredientExt(
          ingredients[recetteIngredient.idIngredient]!, recetteIngredient));
    }

    return recettes
        .map((rec) => RecetteExt(rec, ingredientsByRecette[rec.id] ?? []))
        .toList();
  }

  /// [createRecette] ajoute [recette] et met à jour le champ `id`
  Future<Recette> createRecette(Recette recette) async {
    final id = await _db.insert("recettes", recette.toSQLMap(true));
    return recette.copyWith(id: id);
  }

  /// [updateRecette] modifie la recette donnée.
  Future<void> updateRecette(Recette recette) async {
    await _db.update("recettes", recette.toSQLMap(true),
        where: "id = ?", whereArgs: [recette.id]);
  }

  /// [deleteRecette] supprime la recette donnée.
  /// Les ingrédients sont conservés.
  Future<void> deleteRecette(int id) async {
    await _db
        .delete("recette_ingredients", where: "idRecette = ?", whereArgs: [id]);
    await _db.delete("recettes", where: "id = ?", whereArgs: [id]);
  }

  /// [insertRecetteIngredient] ajoute l'ingrédient donné à la recette donnée.
  /// Si l'ingrédient est déjà présent, les quantités sont fusionnées
  /// Renvoie les ingrédients mis à jour
  Future<List<RecetteIngredientExt>> insertRecetteIngredient(
      RecetteIngredient ingredient) async {
    final recetteIngredients = (await _db.query("recette_ingredients",
            where: "idRecette = ?", whereArgs: [ingredient.idRecette]))
        .map(RecetteIngredient.fromSQLMap)
        .toList();

    final alreadyPresent = recetteIngredients.indexWhere(
        (element) => element.idIngredient == ingredient.idIngredient);
    if (alreadyPresent != -1) {
      final link = recetteIngredients[alreadyPresent];
      final newLink =
          link.copyWith(quantite: link.quantite + ingredient.quantite);
      await updateRecetteIngredient(newLink);
    } else {
      await _db.insert("recette_ingredients", ingredient.toSQLMap());
    }

    return await _loadRecetteIngredients(ingredient.idRecette);
  }

  /// [insertRecettes] crée plusieurs recettes et renvoie les objets avec le champ `id`
  /// mis à jour.
  /// Les liens vers les ingrédients sont aussi ajoutés.
  Future<void> insertRecettes(List<RecetteExt> recettes) async {
    var batch = _db.batch();
    for (var recette in recettes) {
      batch.insert("recettes", recette.recette.toSQLMap(true));
    }
    final idRecettes = await batch.commit();

    batch = _db.batch();
    for (var i = 0; i < recettes.length; i++) {
      final recette = recettes[i];
      final id = idRecettes[i] as int;

      for (var link in recette.ingredients) {
        final withId = link.link.copyWith(idRecette: id);
        batch.insert("recette_ingredients", withId.toSQLMap());
      }
    }
    await batch.commit();
  }

  /// [insertRecetteIngredients] ajoute les liens donnés
  /// Renvoie les ingrédients mis à jour
  Future<List<RecetteIngredientExt>> insertRecetteIngredients(
      RecetteIngredient ingredient) async {
    final recetteIngredients = (await _db.query("recette_ingredients",
            where: "idRecette = ?", whereArgs: [ingredient.idRecette]))
        .map(RecetteIngredient.fromSQLMap)
        .toList();

    final alreadyPresent = recetteIngredients.indexWhere(
        (element) => element.idIngredient == ingredient.idIngredient);
    if (alreadyPresent != -1) {
      final link = recetteIngredients[alreadyPresent];
      final newLink =
          link.copyWith(quantite: link.quantite + ingredient.quantite);
      await updateRecetteIngredient(newLink);
    } else {
      await _db.insert("recette_ingredients", ingredient.toSQLMap());
    }

    return await _loadRecetteIngredients(ingredient.idRecette);
  }

  Future<List<RecetteIngredientExt>> _loadRecetteIngredients(
      int idRecette) async {
    // load the link objects
    final recetteIngredients = (await _db.query("recette_ingredients",
            where: "idRecette = ?", whereArgs: [idRecette]))
        .map(RecetteIngredient.fromSQLMap);

    // load the ingredients
    final ingredients =
        await _loadIngredients(recetteIngredients.map((e) => e.idIngredient));

    final out = recetteIngredients
        .map((link) =>
            RecetteIngredientExt(ingredients[link.idIngredient]!, link))
        .toList();
    out.sort((a, b) => a.ingredient.nom.compareTo(b.ingredient.nom));
    return out;
  }

  /// [deleteRecetteIngredient] retire l'ingrédient donné du menu donné.
  /// S'il n'est plus utilisé, l'ingrédient sous-jacent est supprimé
  Future<void> deleteRecetteIngredient(RecetteIngredient link) async {
    await _db.delete("recette_ingredients",
        where: "idRecette = ? AND idIngredient = ?",
        whereArgs: [link.idRecette, link.idIngredient]);
    // la contrainte SQL empêche la suppression si l'ingrédient est encore utilisé
    try {
      _db.delete("ingredients",
          where: "id = ?", whereArgs: [link.idIngredient]);
    } catch (e) {
      // rien à faire
    }
  }

  /// [updateRecetteIngredient] modifie le lien donné
  Future<void> updateRecetteIngredient(RecetteIngredient ing) async {
    await _db.update("recette_ingredients", ing.toSQLMap(),
        where: "idRecette = ? AND idIngredient = ?",
        whereArgs: [ing.idRecette, ing.idIngredient]);
  }

  Future<MenuExt> getMenu(int id) async {
    // load the menu
    final menu = Menu.fromSQLMap(
        (await _db.query("menus", where: "id = ?", whereArgs: [id])).first);

    // load the link objects
    final menuIngredients = await _loadMenuIngredients(id);

    final menuRecettes = await _loadMenuRecettes(id);

    return MenuExt(menu, menuIngredients, menuRecettes);
  }

  /// [getMenusFavoris] renvoie la liste des menus ajoutés en favori.
  Future<List<MenuExt>> getMenusFavoris() async {
    // load the required menus
    final menus = (await _db.query(
      "menus",
      where: "label != ''",
      orderBy: "label",
    ))
        .map(Menu.fromSQLMap);

    return _loadMenusContent(menus);
  }

  /// [getMenusFromRecette] renvoie la liste des menus dans lesquels [recette]
  /// est utilisée (éventuellement vide).
  Future<List<MenuOrRepas>> getMenusFromRecette(Recette recette) async {
    final links = (await _db.query("menu_recettes",
            where: "idRecette = ?", whereArgs: [recette.id]))
        .map(MenuRecette.fromSQLMap);

    final idsMenu = links.map((e) => e.idMenu).toList();
    final menus = (await _db.query("menus",
            where: "id IN ${_arrayPlaceholders(idsMenu)}", whereArgs: idsMenu))
        .map(Menu.fromSQLMap);

    // si le menu est présent dans un repas, renvoie le repas
    final repas = (await _db.query("repas",
            where: "idMenu IN ${_arrayPlaceholders(idsMenu)}",
            whereArgs: idsMenu))
        .map(Repas.fromSQLMap);
    final menuToRepas = Map.fromEntries(repas
        .map((e) => MapEntry(e.idMenu, e))); // conserve uniquement un repas

    return menus.map((e) => MenuOrRepas(menuToRepas[e.id], e)).toList();
  }

  // load the ingredients
  Future<Map<int, Ingredient>> _loadIngredients(Iterable<int> ids) async {
    return Map.fromEntries((await _db.query("ingredients",
            where: "id IN ${_arrayPlaceholders(ids)}", whereArgs: ids.toList()))
        .map(Ingredient.fromSQLMap)
        .map((ing) => MapEntry(ing.id, ing)));
  }

  Future<List<MenuExt>> _loadMenusContent(Iterable<Menu> menus) async {
    // load the link objects
    final menuIngredients = (await _db.query("menu_ingredients",
            where: "idMenu IN ${_arrayPlaceholders(menus)}",
            whereArgs: menus.map((e) => e.id).toList()))
        .map(MenuIngredient.fromSQLMap);

    // load the ingredients
    final ingredients =
        await _loadIngredients(menuIngredients.map((e) => e.idIngredient));

    final ingredientsByMenu = <int, List<MenuIngredientExt>>{};
    for (var menuIngredient in menuIngredients) {
      final l = ingredientsByMenu.putIfAbsent(menuIngredient.idMenu, () => []);
      l.add(MenuIngredientExt(
          ingredients[menuIngredient.idIngredient]!, menuIngredient));
    }

    // load the link objects
    final menuRecettes = (await _db.query("menu_recettes",
            where: "idMenu IN ${_arrayPlaceholders(menus)}",
            whereArgs: menus.map((e) => e.id).toList()))
        .map(MenuRecette.fromSQLMap);

    // load the recettes
    final recettesTmp = (await _db.query("recettes",
            where: "id IN ${_arrayPlaceholders(menuRecettes)}",
            whereArgs: menuRecettes.map((e) => e.idRecette).toList()))
        .map(Recette.fromSQLMap);

    final recettes = await _loadRecettesIngs(recettesTmp);
    final recettesDict =
        Map.fromEntries(recettes.map((e) => MapEntry(e.recette.id, e)));
    final recettesByMenu = <int, List<RecetteExt>>{};
    for (var menuRecette in menuRecettes) {
      final l = recettesByMenu.putIfAbsent(menuRecette.idMenu, () => []);
      l.add(recettesDict[menuRecette.idRecette]!);
    }

    // final build the complete menu
    final out = menus
        .map((m) => MenuExt(
              m,
              ingredientsByMenu[m.id] ?? [],
              recettesByMenu[m.id] ?? [],
            ))
        .toList();
    return out;
  }

  Future<List<MenuIngredientExt>> _loadMenuIngredients(int idMenu) async {
    // load the link objects
    final menuIngredients = (await _db.query("menu_ingredients",
            where: "idMenu = ?", whereArgs: [idMenu]))
        .map(MenuIngredient.fromSQLMap);

    // load the ingredients
    final ingredients =
        await _loadIngredients(menuIngredients.map((e) => e.idIngredient));

    return menuIngredients
        .map((link) => MenuIngredientExt(ingredients[link.idIngredient]!, link))
        .toList();
  }

  Future<List<RecetteExt>> _loadMenuRecettes(int idMenu) async {
    // load the link objects
    final menuRecettes = (await _db
            .query("menu_recettes", where: "idMenu = ?", whereArgs: [idMenu]))
        .map(MenuRecette.fromSQLMap);

    // load the recettes
    final recettes = (await _db.query("recettes",
            where: "id IN ${_arrayPlaceholders(menuRecettes)}",
            whereArgs: menuRecettes.map((e) => e.idRecette).toList()))
        .map(Recette.fromSQLMap);

    return await _loadRecettesIngs(recettes);
  }

  /// [getRepasFromMenu] renvoie la liste des repas dans lesquels [menu]
  /// est utilisé (éventuellement vide).
  Future<List<Repas>> getRepasFromMenu(Menu menu) async {
    final repas =
        (await _db.query("repas", where: "idMenu = ?", whereArgs: [menu.id]))
            .map(Repas.fromSQLMap)
            .toList();
    repas.sort((a, b) => a.date.compareTo(b.date));
    return repas;
  }

  /// [createMenu] ajoute [menu] et met à jour le champ `id`
  Future<Menu> createMenu(Menu menu) async {
    final id = await _db.insert("menus", menu.toSQLMap(true));
    return menu.copyWith(id: id);
  }

  /// [updateMenu] modifie le menu donné.
  Future<void> updateMenu(Menu menu) async {
    await _db.update("menus", menu.toSQLMap(true),
        where: "id = ?", whereArgs: [menu.id]);
  }

  /// [deleteMenu] supprime le menu donné.
  /// Les ingrédients sont conservés.
  Future<void> deleteMenu(int id) async {
    // Les liens MenuIngredients sont supprimés par cascade
    await _db.delete("menus", where: "id = ?", whereArgs: [id]);
  }

  /// [getRepas] renvoie la liste de tous les repas,
  /// avec leur menu.
  /// La liste est triée par date.
  Future<List<RepasExt>> getRepas() async {
    // load all the repas
    final repas = (await _db.query("repas")).map(Repas.fromSQLMap);
    final idMenus = repas.map((e) => e.idMenu);

    // load the required menus
    final menus = (await _db.query("menus",
            where: "id IN ${_arrayPlaceholders(idMenus)}",
            whereArgs: idMenus.toList()))
        .map(Menu.fromSQLMap);

    final menusExt = await _loadMenusContent(menus);
    final menusDict =
        Map.fromEntries(menusExt.map((e) => MapEntry(e.menu.id, e)));

    // finally build the complete repas
    final out = repas.map((r) => RepasExt(r, menusDict[r.idMenu]!)).toList();
    out.sort((a, b) => a.repas.date.compareTo(b.repas.date));
    return out;
  }

  /// Utilise la date courante si aucun repas n'existe encore
  /// Sinon utilise le dernier repas et passe au prochain créneau horaire
  Future<Repas> guessRepasProperties() async {
    final repass = (await _db.query("repas")).map(Repas.fromSQLMap).toList();
    repass.sort((a, b) => a.date.compareTo(b.date));
    final date = repass.isEmpty
        ? DateTime.now()
        : MomentRepasE.nextRepas(repass.last.date);
    final nbPersonnes = repass.isEmpty ? 8 : repass.last.nbPersonnes;
    return Repas(id: 0, idMenu: 0, date: date, nbPersonnes: nbPersonnes);
  }

  /// [createRepas] crée un nouveau repas et renvoie l'objet avec le champ `id` mis à jour
  Future<Repas> createRepas(Repas repas) async {
    final idRepas = await _db.insert("repas", repas.toSQLMap(true));
    return repas.copyWith(id: idRepas);
  }

  /// [updateRepas] modifie le repas donné.
  Future<void> updateRepas(Repas repas) async {
    await _db.update("repas", repas.toSQLMap(true),
        where: "id = ?", whereArgs: [repas.id]);
  }

  /// [deleteRepas] supprime le repas donné.
  /// Si le menu associé est anonyme, il est aussi supprimé (via [deleteMenu])
  Future<void> deleteRepas(Repas repas) async {
    final menu = Menu.fromSQLMap(
        (await _db.query("menus", where: "id = ?", whereArgs: [repas.idMenu]))
            .first);

    // Les liens MenuIngredients sont supprimés par cascade
    await _db.delete("repas", where: "id = ?", whereArgs: [repas.id]);

    if (menu.label.isEmpty) {
      await deleteMenu(menu.id);
    }
  }

  /// [insertMenuIngredient] ajoute l'ingrédient donné au menu donné.
  /// Si l'ingrédient est déjà présent (dans le même plat), les quantités sont fusionnées
  /// Renvoie les ingrédients mis à jour
  Future<List<MenuIngredientExt>> insertMenuIngredient(
      MenuIngredient ingredient) async {
    final menuIngredients = (await _db.query("menu_ingredients",
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
      await _db.insert("menu_ingredients", ingredient.toSQLMap());
    }

    return await _loadMenuIngredients(ingredient.idMenu);
  }

  /// [deleteMenuIngredient] retire l'ingrédient donné du menu donné.
  Future<void> deleteMenuIngredient(MenuIngredient link) async {
    await _db.delete("menu_ingredients",
        where: "idMenu = ? AND idIngredient = ? AND categorie = ?",
        whereArgs: [link.idMenu, link.idIngredient, link.categorie.index]);
  }

  /// [updateMenuIngredient] modifie le lien donné
  Future<void> updateMenuIngredient(MenuIngredient ing) async {
    await _db.update("menu_ingredients", ing.toSQLMap(),
        where: "idMenu = ? AND idIngredient = ?",
        whereArgs: [ing.idMenu, ing.idIngredient]);
  }

  Future<RecetteExt> insertMenuRecette(int idMenu, int idRecette) async {
    final link = MenuRecette(idMenu: idMenu, idRecette: idRecette);
    await _db.insert("menu_recettes", link.toSQLMap());

    return await getRecette(idRecette);
  }

  /// [deleteMenuRecette] retire la recette donnée du menu donné.
  Future<void> deleteMenuRecette(MenuRecette link) async {
    await _db.delete("menu_recettes",
        where: "idMenu = ? AND idRecette = ?",
        whereArgs: [link.idMenu, link.idRecette]);
  }
}

String _arrayPlaceholders(Iterable array) {
  final values = List.filled(array.length, "?").join(",");
  return "($values)";
}

Future<Directory> downloadDir() async {
  if (Platform.isAndroid) {
    return Directory('/storage/emulated/0/Download/');
  } else {
    final opt = await getDownloadsDirectory();
    if (opt == null) {
      throw "Impossible de trouver le dossier de téléchargements.";
    }
    return opt;
  }
}
