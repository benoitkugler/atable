import 'dart:convert';

import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:diacritic/diacritic.dart';
import 'package:http/http.dart';

/// [Horaire] est une simplication des horaires de repas
/// (en pratique, un repas à 12h15 ou 12h20 n'a aucune influence)
enum Horaire { matin, midi, gouter, soir, cinquieme }

const _matin = 8;
const _midi = 12;
const _gouter = 16;
const _soir = 19;
const _cinquieme = 22;

extension HoraireE on Horaire {
  String get label {
    switch (this) {
      case Horaire.matin:
        return "Petit déjeuner";
      case Horaire.midi:
        return "Midi";
      case Horaire.gouter:
        return "Goûter";
      case Horaire.soir:
        return "Soir";
      case Horaire.cinquieme:
        return "Cinquième";
    }
  }

  int get hour {
    switch (this) {
      case Horaire.matin:
        return _matin;
      case Horaire.midi:
        return _midi;
      case Horaire.gouter:
        return _gouter;
      case Horaire.soir:
        return _soir;
      case Horaire.cinquieme:
        return _cinquieme;
    }
  }

  DateTime toDateTime(DateTime day) {
    return DateTime(day.year, day.month, day.day, hour);
  }

  static Horaire? fromDateTime(DateTime time) {
    if (time.minute != 0) {
      return null;
    }
    switch (time.hour) {
      case _matin:
        return Horaire.matin;
      case _midi:
        return Horaire.midi;
      case _gouter:
        return Horaire.gouter;
      case _soir:
        return Horaire.soir;
      case _cinquieme:
        return Horaire.cinquieme;
      default:
        return null;
    }
  }
}

const _days = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
const _shortMonths = [
  "Jan.",
  "Fév.",
  "Mar.",
  "Avr.",
  "Mai.",
  "Juin",
  "Jui.",
  "Aoû.",
  "Sep.",
  "Oct.",
  "Nov.",
  "Déc."
];

/// [formatDate] renvoie la date formatée
String formatDate(DateTime date) {
  return "${_days[date.weekday - 1]} ${date.day.toString().padLeft(2, "0")} ${_shortMonths[date.month - 1]}";
}

/// [formatHeure] renvoie l'horaire du menu, formaté.
String formatHeure(DateTime date) {
  final moment = HoraireE.fromDateTime(date);
  if (moment != null) {
    return moment.label;
  }
  return "${date.hour}h${date.minute.toString().padLeft(2, '0')}";
}

String capitalize(String text) {
  if (text.isEmpty) return "";
  return "${text[0].toUpperCase()}${text.substring(1).toLowerCase()}";
}

String formatQuantite(double quantite) {
  if (quantite.floorToDouble() == quantite) return quantite.toInt().toString();
  if (quantite < 1) return quantite.toStringAsFixed(3);
  return quantite.toStringAsFixed(2);
}

String formatUnite(Unite unite) {
  switch (unite) {
    case Unite.kg:
      return "Kg";
    case Unite.g:
      return "gr";
    case Unite.l:
      return "L";
    case Unite.cL:
      return "cL";
    case Unite.piece:
      return "P";
  }
}

// formatQuantiteU choices the best representation
String formatQuantiteU(double val, Unite unite) {
  if (unite == Unite.g && val >= 1000) {
    val = val / 1000;
    unite = Unite.kg;
  } else if (unite == Unite.cL && val >= 100) {
    val = val / 100;
    unite = Unite.l;
  }
  return "${formatQuantite(val)} ${formatUnite(unite)}";
}

String formatIngredientKind(IngredientKind cat) {
  switch (cat) {
    case IngredientKind.empty:
      return "Autre";
    case IngredientKind.legumes:
      return "Fruits et légumes";
    case IngredientKind.feculents:
      return "Féculents";
    case IngredientKind.viandes:
      return "Viandes et poissons";
    case IngredientKind.epicerie:
      return "Epicerie";
    case IngredientKind.laitages:
      return "Laitage";
    case IngredientKind.boulangerie:
      return "Boulangerie";
  }
}

String formatPlatKind(PlatKind cat) {
  switch (cat) {
    case PlatKind.entree:
      return "Entrée";
    case PlatKind.platPrincipal:
      return "Plat principal";
    case PlatKind.dessert:
      return "Dessert";
    case PlatKind.empty:
      return "Autre";
  }
}

final a = 'a'.codeUnits.first;
final z = 'z'.codeUnits.first;
final A = 'A'.codeUnits.first;
final Z = 'Z'.codeUnits.first;
final c0 = '0'.codeUnits.first;
final c9 = '9'.codeUnits.first;

bool _isAlphaNum(int char) {
  return a <= char && char <= z ||
      A <= char && char <= Z ||
      c0 <= char && char <= c9;
}

String normalizeName(String name) => String.fromCharCodes(
    removeDiacritics(name.trim().toLowerCase()).codeUnits.where(_isAlphaNum));

/// jsonDecodeResp calls [jsonDecode] on the response body,
/// and throws an error if the server returned one.
dynamic jsonDecodeResp(Response resp) {
  if (resp.statusCode == 200) return jsonDecode(resp.body);

  final json = jsonDecode(resp.body);
  if (json is Map) {
    throw json["message"];
  } else {
    throw "Requête invalide (code ${resp.statusCode})";
  }
}
