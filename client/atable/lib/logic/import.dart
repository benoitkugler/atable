import 'dart:math';

import 'package:atable/logic/ingredientsDB.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/utils.dart';

/// [MenuImport] correspond à un ingrédient avec quantité
class MenuImport {
  final String nom;
  final double quantite;
  final Unite unite;

  const MenuImport(this.nom, this.quantite, this.unite);

  @override
  bool operator ==(Object other) {
    return (other is MenuImport) &&
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
    case "ml":
      return _UniteQuantite(quantite / 1000, Unite.L);
    default:
      return _UniteQuantite(quantite, Unite.piece);
  }
}

/// [parseIngredients] attend un texte composé de lignes,
/// une ligne décrivant un ingrédient associé à une quantité
List<MenuImport> parseIngredients(String text) {
  // suivant le format, des quotes peuvent entourer text
  if (text.startsWith('"')) text = text.substring(1);
  if (text.endsWith('"')) text = text.substring(0, text.length - 1);

  final out = <MenuImport>[];
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
    out.add(MenuImport(name, uq.quantite, uq.unite));
  }
  return out;
}

/// [bestMatch] renvoie l'ingrédient le plus proche (en terme de nom)
/// parmi [candidates] et les suggestions [ingredientsSuggestions]
List<Ingredient> bestMatch(List<Ingredient> candidates, List<MenuImport> ings) {
  candidates = [...candidates, ...ingredientsSuggestions];

  return List<Ingredient>.generate(ings.length, (index) {
    final nom = normalizeNom(ings[index].nom);

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