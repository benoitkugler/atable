import 'package:atable/logic/shop.dart';
import 'package:flutter_test/flutter_test.dart';

main() {
  test("QuantitiesN arithmetic", () {
    const qu1 = QuantitiesNorm(pieces: 1, l: 2, kg: 3);
    const qu2 = QuantitiesNorm(pieces: 0, l: 0, kg: 1);
    expect(qu1 + qu2, const QuantitiesNorm(pieces: 1, l: 2, kg: 4));
    expect(qu1 - qu2, const QuantitiesNorm(pieces: 1, l: 2, kg: 2));
    expect(const QuantitiesNorm() - qu1,
        const QuantitiesNorm(pieces: -1, l: -2, kg: -3));
    expect(qu1 - const QuantitiesNorm(), qu1);
  });
}
