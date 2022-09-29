/// [MomentRepas] est une simplication des horaires de repas
/// (en pratique, un repas à 12h15 ou 12h20 n'a aucune influence)
enum MomentRepas { matin, midi, gouter, soir }

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
        return 8;
      case MomentRepas.midi:
        return 12;
      case MomentRepas.gouter:
        return 16;
      case MomentRepas.soir:
        return 19;
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
      case 8:
        return MomentRepas.matin;
      case 12:
        return MomentRepas.midi;
      case 16:
        return MomentRepas.gouter;
      case 19:
        return MomentRepas.soir;
      default:
        return null;
    }
  }
}

const _days = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];

/// [formatDate] renvoie la date formatée
String formatDate(DateTime date) {
  return "${_days[date.weekday - 1]} ${date.day}/${date.month}";
}
