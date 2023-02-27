import 'dart:io';

import 'package:atable/logic/ingredientsDB.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter_test/flutter_test.dart';

Future main() async {
  test('nextRepas', () async {
    expect(MomentRepasE.nextRepas(DateTime(2022, 1, 1, 7)),
        equals(DateTime(2022, 1, 1, MomentRepas.matin.hour)));
    expect(MomentRepasE.nextRepas(DateTime(2022, 1, 1, 8)),
        equals(DateTime(2022, 1, 1, MomentRepas.midi.hour)));
    expect(MomentRepasE.nextRepas(DateTime(2022, 1, 1, 9)),
        equals(DateTime(2022, 1, 1, MomentRepas.midi.hour)));
    expect(MomentRepasE.nextRepas(DateTime(2022, 1, 1, 22)),
        equals(DateTime(2022, 1, 2, MomentRepas.matin.hour)));
  });
}
