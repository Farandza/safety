import 'package:flutter_test/flutter_test.dart';
import 'package:safety/monitor.dart';

void main() {
  test(
    'Ingests 1000 devices, caps cardinality and alerts once per transition',
    () {
      final alerts = <String>[];
      final monitor = Monitor(alerts.add);
      for (var i = 0; i < 1000; i++) {
        monitor.ingest({'device_id': i, 'blood_oxygen': 98, 'heart_rate': 120});
      }
      expect(monitor.runners.length, 1000);
      monitor.ingest({'device_id': 1001, 'heart_rate': 120});
      expect(monitor.runners.length, 1000);
      monitor.ingest({'device_id': 1, 'blood_oxygen': 92});
      monitor.ingest({'device_id': 1, 'blood_oxygen': 92});
      expect(alerts.length, 1);
      monitor.dispose();
    },
  );
}
