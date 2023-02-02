import 'package:atable/logic/utils.dart';
import 'package:diacritic/diacritic.dart';

/// Ingredient est l'objet fondamental composant
/// un menu.
class Ingredient {
  final int id;
  final String nom;
  final CategorieIngredient categorie;

  const Ingredient({
    required this.id,
    required this.nom,
    required this.categorie,
  });

  @override
  String toString() {
    return "Ingredient(id: $id, nom: $nom, categorie: $categorie)";
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
        categorie: categorie ?? this.categorie);
  }

  factory Ingredient.fromSQLMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map["id"],
      nom: map["nom"],
      categorie: CategorieIngredient.values[map["categorie"]],
    );
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "nom": nom,
      "categorie": categorie.index,
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }
}

String normalizeNom(String nom) => removeDiacritics(nom.trim().toLowerCase());

/// [searchIngredients] filtre la liste par nom
List<Ingredient> searchIngredients(List<Ingredient> candidates, String nom) {
  nom = normalizeNom(nom);
  candidates =
      candidates.where((ing) => normalizeNom(ing.nom).contains(nom)).toList();
  // supprime les éventuels doublons
  final seen = <String>{};
  final List<Ingredient> out = [];
  for (var ing in candidates) {
    final nom = normalizeNom(ing.nom);
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
  /// exprimée dans l'unité [unite]
  final double quantite;
  final Unite unite;
  final CategoriePlat categorie;

  const MenuIngredient({
    required this.idMenu,
    required this.idIngredient,
    required this.quantite,
    required this.unite,
    required this.categorie,
  });

  MenuIngredient copyWith({
    int? idMenu,
    int? idIngredient,
    double? quantite,
    Unite? unite,
    CategoriePlat? categorie,
  }) {
    return MenuIngredient(
        idMenu: idMenu ?? this.idMenu,
        idIngredient: idIngredient ?? this.idIngredient,
        quantite: quantite ?? this.quantite,
        unite: unite ?? this.unite,
        categorie: categorie ?? this.categorie);
  }

  @override
  String toString() {
    return "MenuIngredient(idMenu: $idMenu, idIngredient: $idIngredient, quantite: $quantite, unite: $unite, categorie: $categorie)";
  }

  Map<String, dynamic> toSQLMap() {
    return {
      "idMenu": idMenu,
      "idIngredient": idIngredient,
      "quantite": quantite,
      "unite": unite.index,
      "categorie": categorie.index,
    };
  }

  factory MenuIngredient.fromSQLMap(Map<String, dynamic> map) {
    return MenuIngredient(
      idMenu: map["idMenu"],
      idIngredient: map["idIngredient"],
      quantite: map["quantite"],
      unite: Unite.values[map["unite"]],
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
      return "Autre";
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
  final MenuIngredient link;

  const MenuIngredientExt(this.ingredient, this.link);

  MenuIngredientExt copyWith({Ingredient? ingredient, MenuIngredient? link}) {
    return MenuIngredientExt(ingredient ?? this.ingredient, link ?? this.link);
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
      final l = crible.putIfAbsent(ing.link.categorie, () => []);
      l.add(ing);
    }
    return crible;
  }
}
