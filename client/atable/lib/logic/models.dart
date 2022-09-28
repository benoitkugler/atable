/// Ingredient est l'objet fondamental composant
/// un menu.
class Ingredient {
  final int id;
  final String nom;
  final Unite unite;
  final CategorieIngredient categorie;

  const Ingredient({
    required this.id,
    required this.nom,
    required this.unite,
    required this.categorie,
  });

  @override
  String toString() {
    return "Ingredient(id: $id, nom: $nom, unite: $unite, categorie: $categorie)";
  }

  factory Ingredient.fromSQLMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map["id"],
      nom: map["nom"],
      unite: Unite.values[map["unite"]],
      categorie: CategorieIngredient.values[map["categorie"]],
    );
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "nom": nom,
      "unite": unite.index,
      "categorie": categorie.index,
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }
}

/// [Menu] est un ensemble d'ingrédients
/// prévu pour une date et un nombre de personnes.
class Menu {
  final int id;
  final DateTime date;
  final int nbPersonnes;

  const Menu({
    required this.id,
    required this.date,
    required this.nbPersonnes,
  });

  @override
  String toString() {
    return "Repas(id: $id, date: $date, nbPersonnes: $nbPersonnes)";
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "date": date.toIso8601String(),
      "nbPersonnes": nbPersonnes,
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }

  factory Menu.fromSQLMap(Map<String, dynamic> map) {
    return Menu(
      id: map["id"],
      date: DateTime.parse(map["date"]),
      nbPersonnes: map["nbPersonnes"],
    );
  }
}

class MenuIngredient {
  final int idMenu;
  final int idIngredient;

  /// [quantite] est la quantité requise pour 1 personne,
  /// exprimée dans l'unité de l'ingrédient
  final double quantite;
  final CategoriePlat categorie;

  const MenuIngredient({
    required this.idMenu,
    required this.idIngredient,
    required this.quantite,
    required this.categorie,
  });

  @override
  String toString() {
    return "MenuIngredient(idMenu: $idMenu, idIngredient: $idIngredient, quantite: $quantite, categorie: $categorie)";
  }

  Map<String, dynamic> toSQLMap() {
    return {
      "idMenu": idMenu,
      "idIngredient": idIngredient,
      "quantite": quantite,
      "categorie": categorie.index,
    };
  }

  factory MenuIngredient.fromSQLMap(Map<String, dynamic> map) {
    return MenuIngredient(
      idMenu: map["idMenu"],
      idIngredient: map["idIngredient"],
      quantite: map["quantite"],
      categorie: CategoriePlat.values[map["categorie"]],
    );
  }
}

/// Unite décrit comment est mesuré un ingrédient
enum Unite { kg, L, piece }

/// Categorie indique dans quel rayon se trouve un ingrédient
enum CategorieIngredient {
  /// [inconnue] est la valeur par défaut d'une catégorie
  inconnue,

  legumes,
  viandes,
  epicerie,
  laitages
}

/// CategoriePlat permet de regrouper les ingrédients
/// d'un menu en sous plats
enum CategoriePlat { entree, platPrincipal, dessert, divers }

/// [MenuIngredientExt] regroupe un [Ingredient] et un [MenuIngredient].
class MenuIngredientExt {
  final Ingredient ingredient;
  final double quantite;
  final CategoriePlat categorie;
  const MenuIngredientExt(this.ingredient, this.quantite, this.categorie);
}

/// [MenuExt] est un [Menu] associé à tous ses ingrédients.
class MenuExt {
  final Menu menu;
  final List<MenuIngredientExt> ingredients;
  const MenuExt(this.menu, this.ingredients);
}
