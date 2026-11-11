import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'model.dart';

class Monitor extends ChangeNotifier {
  final Map<String, Runner> runners = {};
  final Map<String, ValueNotifier<int>> signals = {};
  final List<String> alerts = [];
  final List<WebSocketChannel> channels = [];
  final List<StreamSubscription<dynamic>> subscriptions = [];
  final Map<String, String> connections = {};
  final void Function(String) onAlert;
  Timer? repaint, demoTimer;
  bool active = true;
  String error = '';
  Monitor(this.onAlert) {
    repaint = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }
  ValueNotifier<int> signal(String id) =>
      signals.putIfAbsent(id, () => ValueNotifier(0));
  void ingest(dynamic payload) {
    if (payload is List) {
      for (final item in payload) {
        ingest(item);
      }
      return;
    }
    if (payload is! Map) return;
    final map = Map<String, dynamic>.from(payload);
    for (final key in ['reports', 'data', 'report']) {
      if (map[key] is List || map[key] is Map) {
        ingest(map[key]);
        return;
      }
    }
    final id =
        '${map['device_id'] ?? map['deviceId'] ?? map['runner_id'] ?? map['id'] ?? ''}';
    if (id.isEmpty) return;
    if (!runners.containsKey(id) && runners.length >= 1000) return;
    final runner = runners.putIfAbsent(id, () => Runner(id));
    final previous = runner.health;
    runner.update(map);
    signal(id).value++;
    if (runner.health != previous && runner.health != Health.normal) {
      final message =
          '${runner.health.name.toUpperCase()}: Runner $id • ${runner.warnings.join(', ')}';
      alerts.insert(0, message);
      if (alerts.length > 100) alerts.removeLast();
      onAlert(message);
    }
  }

  Future<void> connect(String base) async {
    if (!base.startsWith('ws://') && !base.startsWith('wss://')) {
      error = 'Use a ws:// or wss:// address';
      notifyListeners();
      return;
    }
    error = '';
    for (final path in ['time_based_reports', 'event_based_reports']) {
      unawaited(_open(base.replaceAll(RegExp(r'/$'), ''), path));
    }
  }

  Future<void> _open(String base, String path) async {
    if (!active) return;
    connections[path] = 'Connecting';
    notifyListeners();
    try {
      final channel = WebSocketChannel.connect(Uri.parse('$base/$path'));
      channels.add(channel);
      await channel.ready;
      if (!active) {
        await channel.sink.close();
        return;
      }
      connections[path] = 'Live';
      notifyListeners();
      final done = Completer<void>();
      subscriptions.add(
        channel.stream.listen(
          (data) {
            try {
              ingest(jsonDecode('$data'));
            } catch (e) {
              error = 'Unrecognized report: $e';
            }
          },
          onError: (Object e) {
            error = 'Connection error: $e';
            if (!done.isCompleted) done.complete();
          },
          onDone: () {
            if (!done.isCompleted) done.complete();
          },
        ),
      );
      await done.future;
      channels.remove(channel);
    } catch (e) {
      error = 'Cannot connect to $path: $e';
    }
    if (active) {
      connections[path] = 'Reconnecting';
      notifyListeners();
      await Future<void>.delayed(const Duration(seconds: 5));
      if (active) unawaited(_open(base, path));
    }
  }

  void demo() {
    final random = Random(42);
    demoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      for (var i = 1; i <= 1000; i++) {
        ingest({
          'device_id': i,
          'heart_rate': 105 + random.nextInt(35),
          'breath_rate': 48 + random.nextInt(10),
          'temperature': i % 71 == 0 ? 39.6 : 37.2,
          'blood_oxygen': i % 39 == 0 ? 92 : 98,
          'distance': max(0, 22000 - i * 12 + timer.tick * 3.8),
        });
      }
    });
  }

  @override
  void dispose() {
    active = false;
    repaint?.cancel();
    demoTimer?.cancel();
    for (final s in subscriptions) {
      s.cancel();
    }
    for (final c in channels) {
      c.sink.close();
    }
    for (final s in signals.values) {
      s.dispose();
    }
    super.dispose();
  }
}
