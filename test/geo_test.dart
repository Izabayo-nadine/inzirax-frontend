import 'package:flutter_test/flutter_test.dart';
import 'package:inzirax/core/geo.dart';

void main() {
  test('calculates approximate great-circle distance in metres', () {
    const johannesburg = GeoPoint(-26.2041, 28.0473);
    const nearby = GeoPoint(-26.2041, 28.0573);

    expect(johannesburg.distanceTo(nearby), closeTo(1000, 100));
  });

  test('serialises coordinate payloads for FastAPI', () {
    expect(const GeoPoint(-26.2, 28.0).toJson(), {'lat': -26.2, 'lng': 28.0});
  });
}
