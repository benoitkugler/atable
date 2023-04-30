import 'dart:math';

import 'package:atable/logic/ingredients_table.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/shop.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/utils.dart';
import 'package:csv/csv.dart';

/// [RecetteImport] correspond à un ingrédient avec quantité
class RecetteImport {
  final String nom;
  final double quantite;
  final Unite unite;

  const RecetteImport(this.nom, this.quantite, this.unite);

  @override
  bool operator ==(Object other) {
    return (other is RecetteImport) &&
        other.nom == nom &&
        other.quantite == quantite &&
        other.unite == unite;
  }

  @override
  int get hashCode => nom.hashCode + quantite.hashCode + unite.hashCode;

  @override
  String toString() {
    return "MenuItem($nom, $quantite, $unite)";
  }
}

final _reDigits = RegExp(r"\d+[.,]?\d?");
final _reFractions = RegExp(r"\d+/\d+");

/// convertit une chaine passant [_reDigits]
double _parseDigit(String text) {
  text = text.replaceAll(",", ".");
  return double.parse(text);
}

/// convertit une chaine passant [_reFractions]
double _parseFraction(String text) {
  final parts = text.split("/");
  return int.parse(parts[0]).toDouble() / int.parse(parts[1]).toDouble();
}

class _UniteQuantite {
  final double quantite;
  final Unite unite;
  _UniteQuantite(this.quantite, this.unite);
}

_UniteQuantite _parseUnite(String word, double quantite) {
  word = word.toLowerCase().trim();
  switch (word) {
    case "kg":
      return _UniteQuantite(quantite, Unite.kg);
    case "g":
      return _UniteQuantite(quantite / 1000, Unite.kg);
    case "l":
      return _UniteQuantite(quantite, Unite.L);
    case "cl":
      return _UniteQuantite(quantite / 100, Unite.L);
    case "ml":
      return _UniteQuantite(quantite / 1000, Unite.L);
    default:
      return _UniteQuantite(quantite, Unite.piece);
  }
}

/// [parseIngredients] attend un texte composé de lignes,
/// une ligne décrivant un ingrédient associé à une quantité
List<RecetteImport> parseIngredients(String text) {
  // suivant le format, des quotes peuvent entourer text
  if (text.startsWith('"')) text = text.substring(1);
  if (text.endsWith('"')) text = text.substring(0, text.length - 1);

  final out = <RecetteImport>[];
  final lines = text.split('\n');
  for (var line in lines) {
    if (line.trim().isEmpty) continue;

    // repère une quantité (nombre)
    double quantite = 1;
    String afterQuantite = line;
    final mDig = _reDigits.firstMatch(line);
    final mFrac = _reFractions.firstMatch(line);
    if (mFrac != null) {
      quantite = _parseFraction(mFrac.group(0)!);
      afterQuantite = line.substring(mFrac.end);
    } else if (mDig != null) {
      quantite = _parseDigit(mDig.group(0)!);
      afterQuantite = line.substring(mDig.end);
    }

    final words = afterQuantite.trim().split(" ");
    // repère une unité
    final uq = _parseUnite(words.first, quantite);
    final name = capitalize(
        uq.unite == Unite.piece ? words.join(" ") : words.sublist(1).join(" "));
    out.add(RecetteImport(name, uq.quantite, uq.unite));
  }
  return out;
}

/// [bestMatch] renvoie l'ingrédient le plus proche (en terme de nom)
/// parmi [candidates] et les suggestions [ingredientsSuggestions]
List<Ingredient> bestMatch(
    List<Ingredient> candidates, List<RecetteImport> ings) {
  candidates = [...candidates, ...ingredientsSuggestions];

  return bestMatchNames(candidates, ings.map((e) => e.nom).toList());
}

/// [bestMatchNames] renvoie l'ingrédient le plus proche (en terme de nom)
/// parmi [candidates] et les suggestions [ingredientsSuggestions]
List<Ingredient> bestMatchNames(
    List<Ingredient> candidates, List<String> toMatch) {
  candidates = [...candidates, ...ingredientsSuggestions];

  return List<Ingredient>.generate(toMatch.length, (index) {
    final nom = normalizeNom(toMatch[index]);

    Ingredient bestIngredient = candidates[0];
    int bestCost = _levenshtein(normalizeNom(bestIngredient.nom), nom);

    for (var ing in candidates) {
      final d = _levenshtein(normalizeNom(ing.nom), nom);
      if (d < bestCost) {
        bestCost = d;
        bestIngredient = ing;
      }
    }

    return bestIngredient;
  });
}

/// Levenshtein algorithm implementation based on:
/// http://en.wikipedia.org/wiki/Levenshtein_distance#Iterative_with_two_matrix_rows
int _levenshtein(String s, String t) {
  if (s == t) return 0;
  if (s.isEmpty) return t.length;
  if (t.isEmpty) return s.length;

  final v0 = List<int>.filled(t.length + 1, 0);
  final v1 = List<int>.filled(t.length + 1, 0);

  for (int i = 0; i < t.length + 1; i < i++) {
    v0[i] = i;
  }

  for (int i = 0; i < s.length; i++) {
    v1[0] = i + 1;

    for (int j = 0; j < t.length; j++) {
      final cost = (s[i] == t[j]) ? 0 : 1;
      v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
    }

    for (int j = 0; j < t.length + 1; j++) {
      v0[j] = v1[j];
    }
  }

  return v1[t.length];
}

// ---------------------------- import CSV ----------------------------

class RecetteI {
  final String nom;
  final int nbPersonnes;
  final List<RecetteImport> ingredients;

  const RecetteI(this.nom, this.nbPersonnes, this.ingredients);
}

class RecettesImporter {
  final List<RecetteI> recettes;
  const RecettesImporter(this.recettes);

  /// [RecetteImporter.fromCSV] décode le contenu d'un fichier .csv contenant des recettes
  /// Le format attendu est le suivant :
  ///   - chaque recette est une liste de 3 éléments (3 colonnes) :
  ///   nom de l'ingrédient, quantité, unité
  ///   - une ligne d'entête débute une recette : nom, vide, nombre de personnes
  ///   - une ligne vide sépare deux recettes
  factory RecettesImporter.fromCSV(String content) {
    final rows = const CsvToListConverter(eol: "\n").convert(content);
    final recettes = <RecetteI>[];
    RecetteI? currentRecette;
    for (var row in rows) {
      if (row.map((e) => "$e").join("").trim().isEmpty) {
        // ignore les lignes vides
        continue;
      }
      if (row.length != 3) {
        throw "Fichier .CSV invalide : 3 colonnes attendues";
      }

      if (row[1].toString().trim().isEmpty) {
        // entête : ajoute la recette courante
        if (currentRecette != null) {
          recettes.add(currentRecette);
        }
        currentRecette = RecetteI(row[0].toString().trim(), row[2], []);
      } else {
        // ingrédient
        final nom = capitalize(row[0].toString().trim());
        final quantiteRaw = (row[1] as num).toDouble();
        final qu = _parseUnite(row[2], quantiteRaw);
        currentRecette!.ingredients
            .add(RecetteImport(nom, qu.quantite, qu.unite));
      }
    }

    if (currentRecette != null) {
      recettes.add(currentRecette);
    }

    final out = RecettesImporter(recettes);
    out._normalizeIngredients();
    return out;
  }

  Set<String> _ingredients() {
    final allNames = <String>{};
    for (var recette in recettes) {
      for (var ingredient in recette.ingredients) {
        allNames.add(ingredient.nom);
      }
    }
    return allNames;
  }

  /// met à jour les ingrédients pour effacer les différences involontaires
  void _normalizeIngredients() {
    final allNames = _ingredients();

    for (var recette in recettes) {
      for (var i = 0; i < recette.ingredients.length; i++) {
        final ing = recette.ingredients[i];
        final n = ing.nom;
        if (!n.endsWith("s") && allNames.contains("${n}s")) {
          // pluriel
          recette.ingredients[i] =
              RecetteImport("${n}s", ing.quantite, ing.unite);
        }
      }
    }
  }

  /// [ingredients] renvoie la liste (sans doublons) des
  /// ingrédients importés.
  List<String> ingredients() {
    final out = _ingredients().toList(growable: false);
    out.sort();
    return out;
  }

  /// [applyIngredients] remplace les noms externes par les ingrédients
  /// connus précisés dans [map]
  List<RecetteExt> applyIngredients(Map<String, Ingredient> map) {
    return recettes
        .map((r) => RecetteExt(
              Recette(
                  id: 0,
                  nbPersonnes: r.nbPersonnes,
                  label: r.nom,
                  categorie: CategoriePlat.platPrincipal,
                  description: "Importée le ${formatDate(DateTime.now())}"),
              r.ingredients
                  .map((ing) => RecetteIngredientExt(
                      map[ing.nom]!,
                      RecetteIngredient(
                          idRecette: 0,
                          idIngredient: map[ing.nom]!.id,
                          quantite: ing.quantite,
                          unite: ing.unite)))
                  .toList(),
            ))
        .toList();
  }

  /// [write] conclut l'import en créant les nouveaux ingrédients et
  /// les recettes données.
  static Future<void> write(List<RecetteExt> recettes, DBApi db) async {
    // étape 1 : ajouter les nouveaux ingrédients
    var ingredients = <String, Ingredient>{}; // lié par nom
    for (var recette in recettes) {
      for (var ingredient in recette.ingredients) {
        if (ingredient.ingredient.id <= 0) {
          ingredients[ingredient.ingredient.nom] = ingredient.ingredient;
        }
      }
    }
    final newIngs = await db.insertIngredients(ingredients.values.toList());
    ingredients = Map.fromEntries(newIngs.map((e) => MapEntry(e.nom, e)));

    recettes = recettes.map((recette) {
      for (var i = 0; i < recette.ingredients.length; i++) {
        final ing = recette.ingredients[i];
        if (ing.ingredient.id <= 0) {
          final newIng = ingredients[ing.ingredient.nom]!;
          recette.ingredients[i] = ing.copyWith(
              ingredient: newIng,
              link: ing.link.copyWith(idIngredient: newIng.id));
        }
      }

      // assure l'unicité des liens
      final uniques = <RecetteIngredientExt>[];
      for (var ing in recette.ingredients) {
        final alreadyPresent = uniques.indexWhere(
            (element) => element.ingredient.id == ing.ingredient.id);
        if (alreadyPresent != -1) {
          final link = uniques[alreadyPresent];
          final newLink = link.copyWith(
              link: link.link
                  .copyWith(quantite: link.link.quantite + ing.link.quantite));
          uniques[alreadyPresent] = newLink;
        } else {
          uniques.add(ing);
        }
      }

      return recette.copyWith(ingredients: uniques);
    }).toList();

    // étape 2 : ajouter les recettes
    await db.insertRecettes(recettes);
  }
}
