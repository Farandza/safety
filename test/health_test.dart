import 'package:flutter_test/flutter_test.dart';
import 'package:safety/model.dart';

void main() {
  test('Threshold boundaries and combined warnings', () {
    final r = Runner('1');
    expect(r.health, Health.normal);
    r.oxygen = 94;
    expect(r.health, Health.warning);
    r.temperature = 38.6;
    expect(r.health, Health.emergency);
    r.oxygen = 98;
    r.temperature = 39.1;
    expect(r.health, Health.emergency);
  });
  test('Rolling averages use only the last five reports', () {
    final r = Runner('1');
    for (final n in [50, 100, 110, 120, 130, 140]) {
      r.update({'heart_rate': n});
    }
    expect(r.heart, 120);
    expect(r.hearts.length, 5);
  });
  test('Tenths of degrees and bounded event log', () {
    final r = Runner('1');
    for (var i = 0; i < 150; i++) {
      r.update({'temperature': 396});
    }
    expect(r.temperature, 39.6);
    expect(r.events.length, 100);
  });
  test('Breathing and BP boundary values', () {
    final r = Runner('1');
    r.breath = 25;
    expect(r.health, Health.warning);
    r.breath = 24;
    expect(r.health, Health.emergency);
    r.breath = 50;
    r.systolic = 140;
    expect(r.health, Health.warning);
    r.systolic = 141;
    expect(r.health, Health.emergency);
  });
}
