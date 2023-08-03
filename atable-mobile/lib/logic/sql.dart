import 'dart:convert';

import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_sejours.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_shop-session.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_sejours.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// à garder synchronisé avec types/xxx.dart
const _createSQLStatements = [
  """ 
  CREATE TABLE ingredients(
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    kind INTEGER NOT NULL
  );
  """,
  """
  CREATE TABLE receipes(
    id INTEGER PRIMARY KEY, 
    plat INTEGER NOT NULL,
    name TEXT NOT NULL,
    description TEXT NOT NULL
  );
  """,
  """
  CREATE TABLE receipe_ingredients(
    idReceipe INTEGER NOT NULL,
    idIngredient INTEGER NOT NULL,
    quantity TEXT NOT NULL,
    FOREIGN KEY(idReceipe) REFERENCES receipes(id) ON DELETE CASCADE,
    FOREIGN KEY(idIngredient) REFERENCES ingredients(id) ON DELETE CASCADE
  );
  """,
  """
  CREATE TABLE menus(
    id INTEGER PRIMARY KEY,
    owner INTEGER NOT NULL
  );
  """,
  """
  CREATE TABLE menu_ingredients(
    idMenu INTEGER NOT NULL,
    idIngredient INTEGER NOT NULL,
    quantity TEXT NOT NULL,
    plat INTEGER NOT NULL,
    FOREIGN KEY(idMenu) REFERENCES menus(id) ON DELETE CASCADE,
    FOREIGN KEY(idIngredient) REFERENCES ingredients(id) ON DELETE CASCADE,
    UNIQUE(idMenu, idIngredient)
  );
  """,
  """
  CREATE TABLE menu_receipes(
    idMenu INTEGER NOT NULL,
    idReceipe INTEGER NOT NULL,
    FOREIGN KEY(idMenu) REFERENCES menus(id) ON DELETE CASCADE,
    FOREIGN KEY(idReceipe) REFERENCES receipes(id) ON DELETE CASCADE,
    UNIQUE(idMenu, idReceipe)
  );
  """,
  """
  CREATE TABLE meals(
    id INTEGER PRIMARY KEY, 
    idMenu INTEGER NOT NULL,
    name TEXT NOT NULL,
    date TEXT NOT NULL,
    for_ INTEGER NOT NULL,
    FOREIGN KEY(idMenu) REFERENCES menus(id)
  );
 """,
];

extension I on Ingredient {
  static Ingredient fromSQLMap(Map<String, dynamic> map) {
    return Ingredient(
      map["id"],
      map["name"],
      IngredientKind.values[map["kind"]],
    );
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "name": name,
      "kind": kind.index,
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }

  Ingredient copyWith({
    int? id,
    String? name,
    IngredientKind? kind,
  }) {
    return Ingredient(id ?? this.id, name ?? this.name, kind ?? this.kind);
  }
}

extension R on Receipe {
  static Receipe fromSQLMap(Map<String, dynamic> map) {
    return Receipe(
      map["id"],
      0,
      PlatKind.values[map["plat"]],
      map["name"],
      map["description"],
      false,
    );
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "plat": plat.index,
      "name": name,
      "description": description,
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }

  Receipe copyWith({
    int? id,
    int? owner,
    PlatKind? plat,
    String? name,
    String? description,
    bool? isPublished,
  }) {
    return Receipe(
        id ?? this.id,
        owner ?? this.owner,
        plat ?? this.plat,
        name ?? this.name,
        description ?? this.description,
        isPublished ?? this.isPublished);
  }
}

extension RI on ReceipeIngredient {
  static ReceipeIngredient fromSQLMap(Map<String, dynamic> map) {
    return ReceipeIngredient(
      map["idReceipe"],
      map["idIngredient"],
      quantityRFromJson(jsonDecode(map["quantity"])),
    );
  }

  Map<String, dynamic> toSQLMap() {
    final out = {
      "idReceipe": idReceipe,
      "idIngredient": idIngredient,
      "quantity": jsonEncode(quantityRToJson(quantity)),
    };
    return out;
  }

  ReceipeIngredient copyWith({
    int? idReceipe,
    int? idIngredient,
    QuantityR? quantity,
  }) {
    return ReceipeIngredient(
      idReceipe ?? this.idReceipe,
      idIngredient ?? this.idIngredient,
      quantity ?? this.quantity,
    );
  }
}

extension M on Menu {
  static Menu fromSQLMap(Map<String, dynamic> map) {
    return Menu(map["id"], map["owner"], false, false);
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = <String, dynamic>{
      "owner": owner,
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }
}

extension MI on MenuIngredient {
  static MenuIngredient fromSQLMap(Map<String, dynamic> map) {
    return MenuIngredient(
      map["idMenu"],
      map["idIngredient"],
      quantityRFromJson(jsonDecode(map["quantity"])),
      PlatKind.values[map["plat"]],
    );
  }

  Map<String, dynamic> toSQLMap() {
    return {
      "idMenu": idMenu,
      "idIngredient": idIngredient,
      "quantity": jsonEncode(quantityRToJson(quantity)),
      "plat": plat.index,
    };
  }

  MenuIngredient copyWith({
    int? idMenu,
    int? idIngredient,
    QuantityR? quantity,
    Unite? unite,
    PlatKind? plat,
  }) {
    return MenuIngredient(
        idMenu ?? this.idMenu,
        idIngredient ?? this.idIngredient,
        quantity ?? this.quantity,
        plat ?? this.plat);
  }
}

extension MR on MenuReceipe {
  static MenuReceipe fromSQLMap(Map<String, dynamic> map) {
    return MenuReceipe(
      map["idMenu"],
      map["idReceipe"],
    );
  }

  Map<String, dynamic> toSQLMap() {
    return {
      "idMenu": idMenu,
      "idReceipe": idReceipe,
    };
  }

  MenuReceipe copyWith({
    int? idMenu,
    int? idReceipe,
  }) {
    return MenuReceipe(
      idMenu ?? this.idMenu,
      idReceipe ?? this.idReceipe,
    );
  }
}

extension Mea on MealM {
  static MealM fromSQLMap(Map<String, dynamic> map) {
    return MealM(
      map["id"],
      map["idMenu"],
      map["name"],
      DateTime.parse(map["date"]),
      map["for_"],
    );
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "idMenu": idMenu,
      "name": name,
      "date": date.toIso8601String(),
      "for_": for_,
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }

  MealM copyWith({
    int? id,
    int? idMenu,
    String? name,
    DateTime? date,
    int? for_,
  }) {
    return MealM(id ?? this.id, idMenu ?? this.idMenu, name ?? this.name,
        date ?? this.date, for_ ?? this.for_);
  }
}

/// [ReceipeExt] is a [Receipe] with its [Ingredient]s
class ReceipeExt {
  final Receipe receipe;
  final List<ReceipeIngredientExt> ingredients;
  const ReceipeExt(this.receipe, this.ingredients);

  ReceipeExt copyWith({
    Receipe? receipe,
    List<ReceipeIngredientExt>? ingredients,
  }) {
    return ReceipeExt(
      receipe ?? this.receipe,
      ingredients ?? this.ingredients,
    );
  }
}

class RelativeQuantityIngredient {
  final Ingredient ingredient;
  final QuantityR quantity;
  const RelativeQuantityIngredient(this.ingredient, this.quantity);
}

abstract class QuantifiedIngI {
  RelativeQuantityIngredient iq();
}

class ReceipeIngredientExt implements QuantifiedIngI {
  final Ingredient ingredient;
  final ReceipeIngredient link;

  const ReceipeIngredientExt(this.ingredient, this.link);

  ReceipeIngredientExt copyWith(
      {Ingredient? ingredient, ReceipeIngredient? link}) {
    return ReceipeIngredientExt(
        ingredient ?? this.ingredient, link ?? this.link);
  }

  @override
  RelativeQuantityIngredient iq() =>
      RelativeQuantityIngredient(ingredient, link.quantity);
}

class MenuIngredientExt implements QuantifiedIngI {
  final Ingredient ingredient;
  final MenuIngredient link;

  const MenuIngredientExt(this.ingredient, this.link);

  MenuIngredientExt copyWith({
    Ingredient? ingredient,
    MenuIngredient? link,
  }) {
    return MenuIngredientExt(ingredient ?? this.ingredient, link ?? this.link);
  }

  @override
  RelativeQuantityIngredient iq() =>
      RelativeQuantityIngredient(ingredient, link.quantity);
}

/// [MenuExt] is a [Menu] with its [Receipe]s and [Ingredient]s.
class MenuExt {
  final Menu menu;
  final List<MenuIngredientExt> ingredients;
  final List<ReceipeExt> receipes;

  const MenuExt(this.menu, this.ingredients, this.receipes);

  MenuExt copyWith({
    Menu? menu,
    List<MenuIngredientExt>? ingredients,
    List<ReceipeExt>? receipes,
  }) {
    return MenuExt(
      menu ?? this.menu,
      ingredients ?? this.ingredients,
      receipes ?? this.receipes,
    );
  }
}

class ResolvedQuantityIngredient {
  final Ingredient ingredient;
  final Quantite quantity;

  const ResolvedQuantityIngredient(this.ingredient, this.quantity);
}

class MealExt {
  final MealM meal;
  final MenuExt menu;

  const MealExt(this.meal, this.menu);

  MealExt copyWith({MealM? meal, MenuExt? menu}) {
    return MealExt(meal ?? this.meal, menu ?? this.menu);
  }

  /// [requiredQuantities] resolve the quantities for the
  /// required number of people.
  Map<PlatKind, List<ResolvedQuantityIngredient>> requiredQuantities() {
    final out = <PlatKind, List<ResolvedQuantityIngredient>>{};
    // resolve free ingredients
    for (var ing in menu.ingredients) {
      final quantite = ing.link.quantity.resolveFor(meal.for_);
      final origin = Origin(meal.date, meal.name, "");
      final ingQuant = ResolvedQuantityIngredient(
          ing.ingredient, Quantite(quantite, ing.link.quantity.unite, origin));
      final l = out.putIfAbsent(ing.link.plat, () => []);
      l.add(ingQuant);
    }
    // resolve receipes
    for (var receipe in menu.receipes) {
      for (var ing in receipe.ingredients) {
        final quantite = ing.link.quantity.resolveFor(meal.for_);
        final origin = Origin(meal.date, meal.name, receipe.receipe.name);
        final ingQuant = ResolvedQuantityIngredient(ing.ingredient,
            Quantite(quantite, ing.link.quantity.unite, origin));
        final l = out.putIfAbsent(receipe.receipe.plat, () => []);
        l.add(ingQuant);
      }
    }
    return out;
  }
}

extension on QuantityR {
  QuantityR add(double valToAdd) => QuantityR(val + valToAdd, unite, for_);

  double resolveFor(int target) {
    return val * target.toDouble() / for_.toDouble();
  }
}

/// DBApi provides a convenient API
/// over a SQL database
class DBApi {
  @visibleForTesting
  final Database db;

  const DBApi._(this.db);

  static const _apiVersion = 1;

  static Future<String> _defaultPath() async {
    const dbName = "atable_database.db";
    // Set the path to the database. Note: Using the `join` function from the
    // `path` package is best practice to ensure the path is correctly
    // constructed for each platform.
    return join(await getDatabasesPath(), dbName);
  }

  /// [open] open a connection, creating the DB if needed
  /// [dbPath] may be adjusted in tests
  static Future<DBApi> open({String? dbPath}) async {
    WidgetsFlutterBinding.ensureInitialized(); // required by sqflite

    dbPath ??= await _defaultPath();

    // DEV MODE only : reset DB at start
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

  Future<void> close() async {
    await db.close();
  }

  /// importSejour clears all the current tables,
  /// and insert the given data
  Future<void> importSejour(TablesM tables) async {
    // cleanup...
    await db.delete("meals");
    await db.delete("menu_ingredients");
    await db.delete("menu_receipes");
    await db.delete("menus");
    await db.delete("receipe_ingredients");
    await db.delete("receipes");
    await db.delete("ingredients");

    // ... and insert new data
    final batch = db.batch();
    for (var ingredient in tables.ingredients) {
      batch.insert("ingredients", ingredient.toSQLMap(false));
    }
    for (var receipe in tables.receipes) {
      batch.insert("receipes", receipe.toSQLMap(false));
    }
    for (var link in tables.receipeIngredients) {
      batch.insert("receipe_ingredients", link.toSQLMap());
    }
    for (var menu in tables.menus) {
      batch.insert("menus", menu.toSQLMap(false));
    }
    for (var link in tables.menuIngredients) {
      batch.insert("menu_ingredients", link.toSQLMap());
    }
    for (var link in tables.menuReceipes) {
      batch.insert("menu_receipes", link.toSQLMap());
    }
    for (var meal in tables.meals) {
      batch.insert("meals", meal.toSQLMap(false));
    }

    await batch.commit();
  }

  Future<Iterable<Ingredient>> getIngredients() async {
    return (await db.query("ingredients")).map(I.fromSQLMap);
  }

  /// [insertIngredient] creates a new [Ingredient]
  Future<Ingredient> insertIngredient(Ingredient ing) async {
    final id = await db.insert("ingredients", ing.toSQLMap(true));
    return ing.copyWith(id: id);
  }

  Future<void> updateIngredient(Ingredient ing) async {
    await db.update("ingredients", ing.toSQLMap(true),
        where: "id = ?", whereArgs: [ing.id]);
  }

  Future<UtilisationsIngredient> getIngredientUses(int id) async {
    final receipes = (await db.query("receipe_ingredients",
            where: "idIngredient = ?", whereArgs: [id]))
        .map(RI.fromSQLMap)
        .map((e) => e.idReceipe)
        .toSet()
        .length;
    final menus = (await db.query("menu_ingredients",
            where: "idIngredient = ?", whereArgs: [id]))
        .map(MI.fromSQLMap)
        .map((e) => e.idMenu)
        .toSet()
        .length;
    return UtilisationsIngredient(receipes, menus);
  }

  Future<List<ReceipeExt>> _loadReceipesIngs(Iterable<Receipe> receipes) async {
    // load the links
    final links = (await db.query("receipe_ingredients")).map(RI.fromSQLMap);

    final ingredients =
        await _loadIngredients(links.map((e) => e.idIngredient));

    final ingredientsByReceipe = <int, List<ReceipeIngredientExt>>{};
    for (var receipeIngredient in links) {
      final l = ingredientsByReceipe.putIfAbsent(
          receipeIngredient.idReceipe, () => []);
      l.add(ReceipeIngredientExt(
          ingredients[receipeIngredient.idIngredient]!, receipeIngredient));
    }

    return receipes
        .map((rec) => ReceipeExt(rec, ingredientsByReceipe[rec.id] ?? []))
        .toList();
  }

  /// [updateReceipe] modifie la receipe donnée.
  Future<void> updateReceipe(Receipe receipe) async {
    await db.update("receipes", receipe.toSQLMap(true),
        where: "id = ?", whereArgs: [receipe.id]);
  }

  /// [insertReceipeIngredient] ajoute l'ingrédient donné à la receipe donnée.
  /// Si l'ingrédient est déjà présent, les quantités sont fusionnées
  /// Renvoie les ingrédients mis à jour
  Future<List<ReceipeIngredientExt>> insertReceipeIngredient(
      ReceipeIngredient ingredient) async {
    final receipeIngredients = (await db.query("receipe_ingredients",
            where: "idReceipe = ?", whereArgs: [ingredient.idReceipe]))
        .map(RI.fromSQLMap)
        .toList();

    final alreadyPresent = receipeIngredients.indexWhere(
        (element) => element.idIngredient == ingredient.idIngredient);
    if (alreadyPresent != -1) {
      final link = receipeIngredients[alreadyPresent];
      final newLink =
          link.copyWith(quantity: link.quantity.add(ingredient.quantity.val));
      await updateReceipeIngredient(newLink);
    } else {
      await db.insert("receipe_ingredients", ingredient.toSQLMap());
    }

    return await _loadReceipeIngredients(ingredient.idReceipe);
  }

  Future<List<ReceipeIngredientExt>> _loadReceipeIngredients(
      int idReceipe) async {
    // load the link objects
    final receipeIngredients = (await db.query("receipe_ingredients",
            where: "idReceipe = ?", whereArgs: [idReceipe]))
        .map(RI.fromSQLMap);

    // load the ingredients
    final ingredients =
        await _loadIngredients(receipeIngredients.map((e) => e.idIngredient));

    final out = receipeIngredients
        .map((link) =>
            ReceipeIngredientExt(ingredients[link.idIngredient]!, link))
        .toList();
    out.sort((a, b) => a.ingredient.name.compareTo(b.ingredient.name));
    return out;
  }

  /// [deleteReceipeIngredient] remove the [Ingredient] from the [Receipe]
  Future<void> deleteReceipeIngredient(ReceipeIngredient link) async {
    await db.delete("receipe_ingredients",
        where: "idReceipe = ? AND idIngredient = ?",
        whereArgs: [link.idReceipe, link.idIngredient]);
  }

  /// [updateReceipeIngredient] update the given link
  Future<void> updateReceipeIngredient(ReceipeIngredient ing) async {
    await db.update("receipe_ingredients", ing.toSQLMap(),
        where: "idReceipe = ? AND idIngredient = ?",
        whereArgs: [ing.idReceipe, ing.idIngredient]);
  }

  Future<MenuExt> getMenu(int id) async {
    // load the menu
    final menu = M.fromSQLMap(
        (await db.query("menus", where: "id = ?", whereArgs: [id])).first);

    // load the link objects
    final menuIngredients = await _loadMenuIngredients(id);

    final menuReceipes = await _loadMenuReceipes(id);

    return MenuExt(menu, menuIngredients, menuReceipes);
  }

  // load the ingredients
  Future<Map<int, Ingredient>> _loadIngredients(Iterable<int> ids) async {
    return Map.fromEntries((await db.query("ingredients",
            where: "id IN ${_arrayPlaceholders(ids)}", whereArgs: ids.toList()))
        .map(I.fromSQLMap)
        .map((ing) => MapEntry(ing.id, ing)));
  }

  Future<List<MenuExt>> _loadMenusContent(Iterable<Menu> menus) async {
    // load the link objects
    final menuIngredients = (await db.query("menu_ingredients",
            where: "idMenu IN ${_arrayPlaceholders(menus)}",
            whereArgs: menus.map((e) => e.id).toList()))
        .map(MI.fromSQLMap);

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
    final menuReceipes = (await db.query("menu_receipes",
            where: "idMenu IN ${_arrayPlaceholders(menus)}",
            whereArgs: menus.map((e) => e.id).toList()))
        .map(MR.fromSQLMap);

    // load the receipes
    final receipesTmp = (await db.query("receipes",
            where: "id IN ${_arrayPlaceholders(menuReceipes)}",
            whereArgs: menuReceipes.map((e) => e.idReceipe).toList()))
        .map(R.fromSQLMap);

    final receipes = await _loadReceipesIngs(receipesTmp);
    final receipesDict =
        Map.fromEntries(receipes.map((e) => MapEntry(e.receipe.id, e)));
    final receipesByMenu = <int, List<ReceipeExt>>{};
    for (var menuReceipe in menuReceipes) {
      final l = receipesByMenu.putIfAbsent(menuReceipe.idMenu, () => []);
      l.add(receipesDict[menuReceipe.idReceipe]!);
    }

    // final build the complete menu
    final out = menus
        .map((m) => MenuExt(
              m,
              ingredientsByMenu[m.id] ?? [],
              receipesByMenu[m.id] ?? [],
            ))
        .toList();
    return out;
  }

  Future<List<MenuIngredientExt>> _loadMenuIngredients(int idMenu) async {
    // load the link objects
    final menuIngredients = (await db.query("menu_ingredients",
            where: "idMenu = ?", whereArgs: [idMenu]))
        .map(MI.fromSQLMap);

    // load the ingredients
    final ingredients =
        await _loadIngredients(menuIngredients.map((e) => e.idIngredient));

    return menuIngredients
        .map((link) => MenuIngredientExt(ingredients[link.idIngredient]!, link))
        .toList();
  }

  Future<List<ReceipeExt>> _loadMenuReceipes(int idMenu) async {
    // load the link objects
    final menuReceipes = (await db
            .query("menu_receipes", where: "idMenu = ?", whereArgs: [idMenu]))
        .map(MR.fromSQLMap);

    // load the receipes
    final receipes = (await db.query("receipes",
            where: "id IN ${_arrayPlaceholders(menuReceipes)}",
            whereArgs: menuReceipes.map((e) => e.idReceipe).toList()))
        .map(R.fromSQLMap);

    return await _loadReceipesIngs(receipes);
  }

  /// [getMeals] loads all meals and their contents,
  /// returning a list sorted by time.
  Future<List<MealExt>> getMeals() async {
    // load all the meals
    final meals = (await db.query("meals")).map(Mea.fromSQLMap);

    // load all the menus
    final menus = (await db.query("menus")).map(M.fromSQLMap);

    final menusExt = await _loadMenusContent(menus);
    final menusDict =
        Map.fromEntries(menusExt.map((e) => MapEntry(e.menu.id, e)));

    // finally build the complete meals
    final out = meals.map((r) => MealExt(r, menusDict[r.idMenu]!)).toList();
    out.sort((a, b) => a.meal.date.compareTo(b.meal.date));
    return out;
  }

  Future<void> updateMeal(MealM meal) async {
    await db.update("meals", meal.toSQLMap(true),
        where: "id = ?", whereArgs: [meal.id]);
  }

  /// [deleteMeal] deletes the meal
  Future<void> deleteMeal(IdMeal meal) async {
    // Les liens MenuIngredients sont supprimés par cascade
    await db.delete("meals", where: "id = ?", whereArgs: [meal]);
  }

  /// [insertMenuIngredient] ajoute l'ingrédient donné au menu donné.
  /// Si l'ingrédient est déjà présent, les quantités sont fusionnées
  /// Renvoie les ingrédients mis à jour
  Future<List<MenuIngredientExt>> insertMenuIngredient(
      MenuIngredient ingredient) async {
    final menuIngredients = (await db.query("menu_ingredients",
            where: "idMenu = ?", whereArgs: [ingredient.idMenu]))
        .map(MI.fromSQLMap)
        .toList();

    final alreadyPresent = menuIngredients.indexWhere(
        (element) => element.idIngredient == ingredient.idIngredient);
    if (alreadyPresent != -1) {
      final link = menuIngredients[alreadyPresent];
      final newLink =
          link.copyWith(quantity: link.quantity.add(ingredient.quantity.val));
      await updateMenuIngredient(newLink);
    } else {
      await db.insert("menu_ingredients", ingredient.toSQLMap());
    }

    return await _loadMenuIngredients(ingredient.idMenu);
  }

  /// [deleteMenuIngredient] retire l'ingrédient donné du menu donné.
  Future<void> deleteMenuIngredient(MenuIngredient link) async {
    await db.delete("menu_ingredients",
        where: "idMenu = ? AND idIngredient = ?",
        whereArgs: [link.idMenu, link.idIngredient]);
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

class UtilisationsIngredient {
  final int receipes;
  final int menus;
  const UtilisationsIngredient(this.receipes, this.menus);
}
