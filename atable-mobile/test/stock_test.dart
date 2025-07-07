import 'package:atable/logic/stock.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  test("arithmetic", () {
    const qu1 = NormalizedQuantity(pieces: 1, l: 2, kg: 3);
    const qu2 = NormalizedQuantity(pieces: 0, l: 0, kg: 1);
    expect(qu1 + qu2, const NormalizedQuantity(pieces: 1, l: 2, kg: 4));
    expect(qu1 - qu2, const NormalizedQuantity(pieces: 1, l: 2, kg: 2));
    expect(const NormalizedQuantity() - qu1,
        const NormalizedQuantity(pieces: -1, l: -2, kg: -3));
    expect(qu1 - const NormalizedQuantity(), qu1);
  });
}
