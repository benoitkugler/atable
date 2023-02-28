/// [MomentRepas] est une simplication des horaires de repas
/// (en pratique, un repas à 12h15 ou 12h20 n'a aucune influence)
enum MomentRepas { matin, midi, gouter, soir }

const _matin = 8;
const _midi = 12;
const _gouter = 16;
const _soir = 19;

extension MomentRepasE on MomentRepas {
  String get label {
    switch (this) {
      case MomentRepas.matin:
        return "Petit déjeuner";
      case MomentRepas.midi:
        return "Midi";
      case MomentRepas.gouter:
        return "Goûter";
      case MomentRepas.soir:
        return "Soir";
    }
  }

  int get hour {
    switch (this) {
      case MomentRepas.matin:
        return _matin;
      case MomentRepas.midi:
        return _midi;
      case MomentRepas.gouter:
        return _gouter;
      case MomentRepas.soir:
        return _soir;
    }
  }

  DateTime toDateTime(DateTime day) {
    return DateTime(day.year, day.month, day.day, hour);
  }

  static MomentRepas? fromDateTime(DateTime time) {
    if (time.minute != 0) {
      return null;
    }
    switch (time.hour) {
      case _matin:
        return MomentRepas.matin;
      case _midi:
        return MomentRepas.midi;
      case _gouter:
        return MomentRepas.gouter;
      case _soir:
        return MomentRepas.soir;
      default:
        return null;
    }
  }

  static DateTime nextRepas(DateTime time) {
    // arrondi au plus proche repas
    if (time.hour < _matin) {
      return DateTime(time.year, time.month, time.day, _matin);
    } else if (time.hour < _midi) {
      return DateTime(time.year, time.month, time.day, _midi);
    } else if (time.hour < _gouter) {
      return DateTime(time.year, time.month, time.day, _gouter);
    } else if (time.hour < _soir) {
      return DateTime(time.year, time.month, time.day, _soir);
    } else {
      // lendemain
      return DateTime(time.year, time.month, time.day + 1, _matin);
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

String capitalize(String text) {
  if (text.isEmpty) return "";
  return "${text[0].toUpperCase()}${text.substring(1).toLowerCase()}";
}

String formatQuantite(double quantite) {
  if (quantite.floorToDouble() == quantite) return quantite.toInt().toString();
  return quantite.toStringAsFixed(2);
}
