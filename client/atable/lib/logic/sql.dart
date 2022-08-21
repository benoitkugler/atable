import 'package:atable/logic/models.dart';
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
    FOREIGN KEY(idIngredient) REFERENCES ingredients(id)
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
    if (dbPath == null) {
      const dbName = "atable_database.db";
      dbPath = join(await getDatabasesPath(), dbName);
    }
    // Open the database and store the reference.
    final database = await openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      dbPath,
      version: 1,
      onCreate: (db, version) {
        // Run the CREATE TABLE statements on the database.
        return db.execute(_createSQLStatement);
      },
    );

    return DBApi._(database);
  }

  Future<List<Ingredient>> getIngredients() async {
    return (await db.query("ingredients")).map(Ingredient.fromSQLMap).toList();
  }

  Future<Ingredient> insertIngredient(Ingredient ing) async {
    final id = await db.insert("ingredients", ing.toSQLMap(true));
    return Ingredient(
        id: id, nom: ing.nom, unite: ing.unite, categorie: ing.categorie);
  }

  Future<void> deleteIngredient(int id) async {
    await db.delete("ingredients", where: "id = ?", whereArgs: [id]);
  }

  Future<Menu> insertMenu(Menu menu) async {
    final id = await db.insert("menus", menu.toSQLMap(true));
    return Menu(id: id, date: menu.date, nbPersonnes: menu.nbPersonnes);
  }

  Future<void> insertMenuIngredients(List<MenuIngredient> ingredients) async {
    final batch = db.batch();
    for (var ingredient in ingredients) {
      batch.insert("menu_ingredients", ingredient.toSQLMap());
    }
    await batch.commit();
  }
}
