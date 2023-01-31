import 'package:atable/logic/utils.dart';
import 'package:diacritic/diacritic.dart';

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

  Ingredient copyWith({
    int? id,
    String? nom,
    Unite? unite,
    CategorieIngredient? categorie,
  }) {
    return Ingredient(
        id: id ?? this.id,
        nom: nom ?? this.nom,
        unite: unite ?? this.unite,
        categorie: categorie ?? this.categorie);
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

String _normalize(String nom) => removeDiacritics(nom.trim().toLowerCase());

/// [searchIngredients] filtre la liste par nom
List<Ingredient> searchIngredients(List<Ingredient> candidates, String nom) {
  nom = _normalize(nom);
  candidates =
      candidates.where((ing) => _normalize(ing.nom).contains(nom)).toList();
  // supprime les éventuels doublons
  final seen = <String>{};
  final List<Ingredient> out = [];
  for (var ing in candidates) {
    final nom = _normalize(ing.nom);
    if (seen.contains(nom)) continue;
    seen.add(nom);
    out.add(ing);
  }
  return out;
}

/// [Menu] est un ensemble d'ingrédients
/// prévu pour une date et un nombre de personnes.
/// Les différents plats d'un même repas sont spécifiés
/// pour chaque ingrédients.
class Menu {
  final int id;
  final DateTime date;

  /// [nbPersonnes] est liés aux quantités des ingrédients
  final int nbPersonnes;

  const Menu({
    required this.id,
    required this.date,
    required this.nbPersonnes,
  });

  Menu copyWith({
    int? id,
    DateTime? date,
    int? nbPersonnes,
  }) {
    return Menu(
        id: id ?? this.id,
        date: date ?? this.date,
        nbPersonnes: nbPersonnes ?? this.nbPersonnes);
  }

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

  /// [formatJour] renvoie le jour du menu, formaté.
  String formatJour() => formatDate(date);

  /// [formatHeure] renvoie l'horaire du menu, formaté.
  String formatHeure() {
    final moment = MomentRepasE.fromDateTime(date);
    if (moment != null) {
      return moment.label;
    }
    return "${date.hour}h${date.minute}";
  }
}

class MenuIngredient {
  final int idMenu;
  final int idIngredient;

  /// [quantite] est la quantité requise pour le nombre de personnes
  /// défini dans le menu associé,
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

String formatUnite(Unite unite) {
  switch (unite) {
    case Unite.kg:
      return "Kg";
    case Unite.L:
      return "L";
    case Unite.piece:
      return "P";
  }
}

/// Categorie indique dans quel rayon se trouve un ingrédient
enum CategorieIngredient {
  /// [inconnue] est la valeur par défaut d'une catégorie
  inconnue,

  legumes,
  viandes,
  epicerie,
  laitages,
  boulangerie
}

String formatCategorieIngredient(CategorieIngredient cat) {
  switch (cat) {
    case CategorieIngredient.inconnue:
      return "-";
    case CategorieIngredient.legumes:
      return "Fruits et légumes";
    case CategorieIngredient.viandes:
      return "Viandes et poissons";
    case CategorieIngredient.epicerie:
      return "Epicerie";
    case CategorieIngredient.laitages:
      return "Laitage";
    case CategorieIngredient.boulangerie:
      return "Boulangerie";
  }
}

/// CategoriePlat permet de regrouper les ingrédients
/// d'un menu en sous plats
enum CategoriePlat { entree, platPrincipal, dessert, divers }

String formatCategoriePlat(CategoriePlat cat) {
  switch (cat) {
    case CategoriePlat.entree:
      return "Entrée";
    case CategoriePlat.platPrincipal:
      return "Plat principal";
    case CategoriePlat.dessert:
      return "Dessert";
    case CategoriePlat.divers:
      return "Autre";
  }
}

/// [MenuIngredientExt] regroupe un [Ingredient] et un [MenuIngredient].
class MenuIngredientExt {
  final Ingredient ingredient;

  /// [quantite] est la quantité requise pour 1 personne,
  /// exprimée dans l'unité de l'ingrédient
  final double quantite;
  final CategoriePlat categorie;

  const MenuIngredientExt(this.ingredient, this.quantite, this.categorie);

  factory MenuIngredientExt.from(Ingredient ing, MenuIngredient link) =>
      MenuIngredientExt(ing, link.quantite, link.categorie);

  MenuIngredientExt copyWith(
      {Ingredient? ingredient, double? quantite, CategoriePlat? categorie}) {
    return MenuIngredientExt(ingredient ?? this.ingredient,
        quantite ?? this.quantite, categorie ?? this.categorie);
  }
}

/// [MenuExt] est un [Menu] associé à tous ses ingrédients.
class MenuExt {
  final Menu menu;
  final List<MenuIngredientExt> ingredients;
  const MenuExt(this.menu, this.ingredients);

  /// [plats] renvoie la liste des ingrédients regroupés par
  /// plat
  Map<CategoriePlat, List<MenuIngredientExt>> plats() {
    final Map<CategoriePlat, List<MenuIngredientExt>> crible = {};
    for (var ing in ingredients) {
      final l = crible.putIfAbsent(ing.categorie, () => []);
      l.add(ing);
    }
    return crible;
  }
}
