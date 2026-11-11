import 'dart:collection';

enum Health { normal, warning, emergency }

class Sample {
  final DateTime time;
  final double heart, breath;
  Sample(this.time, this.heart, this.breath);
}

class Runner {
  final String id;
  double heart = 100,
      breath = 50,
      oxygen = 98,
      temperature = 37,
      systolic = 120,
      diastolic = 75,
      distance = 0;
  DateTime? updated;
  final Queue<double> hearts = Queue(), breaths = Queue();
  final Queue<Sample> history = Queue();
  final Queue<String> events = Queue();
  Runner(this.id);
  List<String> get warnings => [
    if (heart < 40 || heart > 170)
      'Heart rate ${heart.round()} BPM'
    else if (heart < 60 || heart > 150)
      'Heart rate ${heart.round()} BPM',
    if (breath < 45 || breath > 60) 'Breathing ${breath.round()}/min',
    if (systolic >= 130) 'Systolic BP ${systolic.round()} mmHg',
    if (diastolic >= 80) 'Diastolic BP ${diastolic.round()} mmHg',
    if (oxygen < 95) 'Blood oxygen ${oxygen.toStringAsFixed(1)}%',
    if (temperature > 38.5) 'Temperature ${temperature.toStringAsFixed(1)}°C',
  ];
  Health get health {
    if (heart < 40 ||
        heart > 170 ||
        breath < 25 ||
        breath > 85 ||
        systolic > 140 ||
        diastolic > 90 ||
        oxygen < 90 ||
        temperature > 39 ||
        warnings.length >= 2)
      return Health.emergency;
    return warnings.isEmpty ? Health.normal : Health.warning;
  }

  void update(Map<String, dynamic> data) {
    double? number(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value != null) return double.tryParse('$value');
      }
      return null;
    }

    void rolling(Queue<double> values, double value) {
      values.add(value);
      if (values.length > 5) values.removeFirst();
    }

    final h = number(['heart_rate', 'heartRate', 'heartbeat', 'bpm']);
    final b = number([
      'breath_rate',
      'breathRate',
      'breath',
      'respiratory_rate',
    ]);
    if (h != null) {
      rolling(hearts, h);
      heart = hearts.reduce((a, b) => a + b) / hearts.length;
    }
    if (b != null) {
      rolling(breaths, b);
      breath = breaths.reduce((a, b) => a + b) / breaths.length;
    }
    oxygen =
        number(['blood_oxygen', 'bloodOxygen', 'spo2', 'oxygen']) ?? oxygen;
    final t = number(['temperature', 'temp']);
    if (t != null) temperature = t > 100 ? t / 10 : t;
    systolic = number(['systolic', 'systolic_bp']) ?? systolic;
    diastolic = number(['diastolic', 'diastolic_bp']) ?? diastolic;
    distance = number(['distance', 'distance_meters']) ?? distance;
    updated = DateTime.tryParse('${data['timestamp']}') ?? DateTime.now();
    if (h != null || b != null) history.add(Sample(updated!, heart, breath));
    while (history.isNotEmpty &&
        (history.first.time.isBefore(
              DateTime.now().subtract(const Duration(minutes: 10)),
            ) ||
            history.length > 1200)) {
      history.removeFirst();
    }
    if (t != null ||
        data.keys.any(
          (k) => [
            'blood_oxygen',
            'bloodOxygen',
            'spo2',
            'oxygen',
            'systolic',
            'diastolic',
          ].contains(k),
        )) {
      events.addFirst(
        '${updated!.toLocal().toString().substring(11, 19)} • ${temperature.toStringAsFixed(1)}°C • ${systolic.round()}/${diastolic.round()} mmHg • O₂ ${oxygen.round()}%',
      );
      if (events.length > 100) events.removeLast();
    }
  }
}
