import 'package:atable/logic/shop.dart';
import 'package:atable/logic/utils.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/foundation.dart';

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
    return "Ingredient(id: $id, nom: '$nom', categorie: $categorie)";
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

/// [Recette] regroupe plusieurs ingrédients
class Recette {
  final int id;
  final int nbPersonnes;
  final String label;
  final CategoriePlat categorie;

  const Recette({
    required this.id,
    required this.nbPersonnes,
    required this.label,
    required this.categorie,
  });

  @override
  String toString() {
    return "Recette(id: $id, nbPersonnes: $nbPersonnes, label: $label, categorie: $categorie)";
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "nbPersonnes": nbPersonnes,
      "label": label,
      "categorie": categorie.index,
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }

  factory Recette.fromSQLMap(Map<String, dynamic> map) {
    return Recette(
        id: map["id"],
        nbPersonnes: map["nbPersonnes"],
        label: map["label"],
        categorie: CategoriePlat.values[map["categorie"]]);
  }

  Recette copyWith({
    int? id,
    int? nbPersonnes,
    String? label,
    CategoriePlat? categorie,
  }) {
    return Recette(
      id: id ?? this.id,
      nbPersonnes: nbPersonnes ?? this.nbPersonnes,
      label: label ?? this.label,
      categorie: categorie ?? this.categorie,
    );
  }
}

/// [searchRecettes] filtre la liste par nom
/// Les résultats sont triés par catégorie, puis par nom
List<Recette> searchRecettes(List<Recette> candidates, String nom) {
  nom = normalizeNom(nom);
  final out =
      candidates.where((rec) => normalizeNom(rec.label).contains(nom)).toList();
  out.sort((a, b) => a.label.compareTo(b.label));
  mergeSort<Recette>(out,
      compare: (a, b) => a.categorie.index - b.categorie.index);
  return out;
}

/// [RecetteIngredient] détermine les quantités d'une recette
class RecetteIngredient {
  final int idRecette;
  final int idIngredient;
  final double quantite;
  final Unite unite;

  const RecetteIngredient({
    required this.idRecette,
    required this.idIngredient,
    required this.quantite,
    required this.unite,
  });

  RecetteIngredient copyWith({
    int? idRecette,
    int? idIngredient,
    double? quantite,
    Unite? unite,
  }) {
    return RecetteIngredient(
      idRecette: idRecette ?? this.idRecette,
      idIngredient: idIngredient ?? this.idIngredient,
      quantite: quantite ?? this.quantite,
      unite: unite ?? this.unite,
    );
  }

  Map<String, dynamic> toSQLMap() {
    final out = {
      "idRecette": idRecette,
      "idIngredient": idIngredient,
      "quantite": quantite,
      "unite": unite.index,
    };
    return out;
  }

  factory RecetteIngredient.fromSQLMap(Map<String, dynamic> map) {
    return RecetteIngredient(
      idRecette: map["idRecette"],
      idIngredient: map["idIngredient"],
      quantite: map["quantite"],
      unite: Unite.values[map["unite"]],
    );
  }
}

/// [Menu] est un ensemble d'ingrédients et quantités (relatives)
/// Les différents plats d'un même repas sont spécifiés
/// pour chaque ingrédients.
/// Un même [Menu] peut être utilisé dans plusieurs [Repas].
class Menu {
  final int id;

  /// [nbPersonnes] défini pour combien
  /// sont exprimés les quantités des ingrédients
  final int nbPersonnes;

  /// [label] est un RecetteIngredient unique, optionnel
  final String label;

  const Menu({
    required this.id,
    required this.nbPersonnes,
    required this.label,
  });

  Menu copyWith({
    int? id,
    int? nbPersonnes,
    String? label,
  }) {
    return Menu(
        id: id ?? this.id,
        nbPersonnes: nbPersonnes ?? this.nbPersonnes,
        label: label ?? this.label);
  }

  @override
  String toString() {
    return "Menu(id: $id, nbPersonnes: $nbPersonnes, label: $label)";
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "nbPersonnes": nbPersonnes,
      "label": label,
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }

  factory Menu.fromSQLMap(Map<String, dynamic> map) {
    return Menu(
      id: map["id"],
      nbPersonnes: map["nbPersonnes"],
      label: map["label"],
    );
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

class MenuRecette {
  final int idMenu;
  final int idRecette;

  const MenuRecette({
    required this.idMenu,
    required this.idRecette,
  });

  MenuRecette copyWith({
    int? idMenu,
    int? idRecette,
  }) {
    return MenuRecette(
      idMenu: idMenu ?? this.idMenu,
      idRecette: idRecette ?? this.idRecette,
    );
  }

  @override
  String toString() {
    return "MenuRecette(idMenu: $idMenu, idRecette: $idRecette)";
  }

  Map<String, dynamic> toSQLMap() {
    return {
      "idMenu": idMenu,
      "idRecette": idRecette,
    };
  }

  factory MenuRecette.fromSQLMap(Map<String, dynamic> map) {
    return MenuRecette(
      idMenu: map["idMenu"],
      idRecette: map["idRecette"],
    );
  }
}

/// [Repas] est un menu pour une date et un nombre de personnes donnés
class Repas {
  final int id;
  final int idMenu;

  final DateTime date;

  /// [nbPersonnes] est le nombre de personnes
  /// à utiliser dans le calcul des quantités.
  final int nbPersonnes;

  const Repas({
    required this.id,
    required this.idMenu,
    required this.date,
    required this.nbPersonnes,
  });

  Repas copyWith({
    int? id,
    int? idMenu,
    DateTime? date,
    int? nbPersonnes,
  }) {
    return Repas(
        id: id ?? this.id,
        idMenu: idMenu ?? this.idMenu,
        date: date ?? this.date,
        nbPersonnes: nbPersonnes ?? this.nbPersonnes);
  }

  @override
  String toString() {
    return "Repas(id: $id, idMenu: $idMenu, date: $date, nbPersonnes: $nbPersonnes)";
  }

  Map<String, dynamic> toSQLMap(bool ignoreID) {
    final out = {
      "idMenu": idMenu,
      "date": date.toIso8601String(),
      "nbPersonnes": nbPersonnes,
    };
    if (!ignoreID) {
      out["id"] = id;
    }
    return out;
  }

  factory Repas.fromSQLMap(Map<String, dynamic> map) {
    return Repas(
      id: map["id"],
      idMenu: map["idMenu"],
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
    return "${date.hour}h${date.minute.toString().padLeft(2, '0')}";
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

class IngQuant {
  final Ingredient ingredient;
  final double quantite;
  final Unite unite;
  const IngQuant(this.ingredient, this.quantite, this.unite);
}

abstract class IngQuantI {
  IngQuant iq();
}

/// [RecetteIngredientExt] regroupe un [Ingredient] et un [RecetteIngredient].
class RecetteIngredientExt implements IngQuantI {
  final Ingredient ingredient;
  final RecetteIngredient link;

  const RecetteIngredientExt(this.ingredient, this.link);

  RecetteIngredientExt copyWith(
      {Ingredient? ingredient, RecetteIngredient? link}) {
    return RecetteIngredientExt(
        ingredient ?? this.ingredient, link ?? this.link);
  }

  @override
  IngQuant iq() => IngQuant(ingredient, link.quantite, link.unite);
}

/// [MenuIngredientExt] regroupe un [Ingredient] et un [MenuIngredient].
class MenuIngredientExt implements IngQuantI {
  final Ingredient ingredient;
  final MenuIngredient link;

  const MenuIngredientExt(this.ingredient, this.link);

  MenuIngredientExt copyWith({Ingredient? ingredient, MenuIngredient? link}) {
    return MenuIngredientExt(ingredient ?? this.ingredient, link ?? this.link);
  }

  @override
  IngQuant iq() => IngQuant(ingredient, link.quantite, link.unite);
}

typedef Plats = Map<CategoriePlat, List<MenuIngredientExt>>;

/// [ingredientsByPlats] renvoie la liste des ingrédients regroupés par
/// plat
Plats ingredientsByPlats(List<MenuIngredientExt> ingredients) {
  final Map<CategoriePlat, List<MenuIngredientExt>> crible = {};
  for (var ing in ingredients) {
    final l = crible.putIfAbsent(ing.link.categorie, () => []);
    l.add(ing);
  }
  return crible;
}

/// [recettesByPlats] renvoie la liste des recettes regroupées par
/// plat
Map<CategoriePlat, List<RecetteExt>> recettesByPlats(
    List<RecetteExt> recettes) {
  final Map<CategoriePlat, List<RecetteExt>> crible = {};
  for (var ing in recettes) {
    final l = crible.putIfAbsent(ing.recette.categorie, () => []);
    l.add(ing);
  }
  return crible;
}

/// [RecetteExt] est une [Recette] associé à tous ses ingrédients.
class RecetteExt {
  final Recette recette;
  final List<RecetteIngredientExt> ingredients;
  const RecetteExt(this.recette, this.ingredients);

  RecetteExt copyWith(
      {Recette? recette, List<RecetteIngredientExt>? ingredients}) {
    return RecetteExt(recette ?? this.recette, ingredients ?? this.ingredients);
  }
}

/// [MenuExt] est un [Menu] associé à tous ses ingrédients.
class MenuExt {
  final Menu menu;
  final List<MenuIngredientExt> ingredients;
  final List<RecetteExt> recettes;

  const MenuExt(this.menu, this.ingredients, this.recettes);

  MenuExt copyWith(
      {Menu? menu,
      List<MenuIngredientExt>? ingredients,
      List<RecetteExt>? recettes}) {
    return MenuExt(menu ?? this.menu, ingredients ?? this.ingredients,
        recettes ?? this.recettes);
  }
}

class RepasExt {
  final Repas repas;
  final MenuExt menu;

  const RepasExt(this.repas, this.menu);

  RepasExt copyWith({Repas? repas, MenuExt? menu}) {
    return RepasExt(repas ?? this.repas, menu ?? this.menu);
  }

  /// [requiredQuantites] renvoie les ingrédients avec les
  /// quantités nécessaires au nombre de personne du repas
  Map<CategoriePlat, List<IngQuant>> requiredQuantites() {
    final out = <CategoriePlat, List<IngQuant>>{};
    // résoud les ingrédients libres
    final factorIngredients =
        repas.nbPersonnes.toDouble() / menu.menu.nbPersonnes.toDouble();
    for (var ing in menu.ingredients) {
      final quantite = ing.link.quantite * factorIngredients;
      final ingQuant =
          ing.copyWith(link: ing.link.copyWith(quantite: quantite)).iq();
      final l = out.putIfAbsent(ing.link.categorie, () => []);
      l.add(ingQuant);
    }
    // résoud les recettes
    for (var recette in menu.recettes) {
      final factorIngredients =
          repas.nbPersonnes.toDouble() / recette.recette.nbPersonnes.toDouble();
      for (var ing in recette.ingredients) {
        final quantite = ing.link.quantite * factorIngredients;
        final ingQuant =
            ing.copyWith(link: ing.link.copyWith(quantite: quantite)).iq();
        final l = out.putIfAbsent(recette.recette.categorie, () => []);
        l.add(ingQuant);
      }
    }
    return out;
  }
}
