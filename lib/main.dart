import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'model.dart';
import 'monitor.dart';

const demoMode = bool.fromEnvironment('DEMO');
const navy = Color(0xff142b3a), teal = Color(0xff087f78);
Color statusColor(Health h) => switch (h) {
  Health.normal => teal,
  Health.warning => const Color(0xffbd7916),
  Health.emergency => const Color(0xffd94752),
};
void main() => runApp(const SafetyApp());

class SafetyApp extends StatelessWidget {
  const SafetyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Safety • StrideSense',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: teal),
      scaffoldBackgroundColor: const Color(0xfff3f6f7),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xfff3f6f7),
        foregroundColor: navy,
      ),
      cardTheme: const CardThemeData(elevation: 0, color: Colors.white),
    ),
    home: const Login(),
  );
}

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final user = TextEditingController(), password = TextEditingController();
  String? error;
  @override
  void dispose() {
    user.dispose();
    password.dispose();
    super.dispose();
  }

  void login() {
    if (user.text.trim() == 'official' && password.text == 'Safety2026!') {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const Dashboard()));
    } else {
      setState(() => error = 'Incorrect official ID or password');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                size: 54,
                color: teal,
              ),
              const SizedBox(height: 26),
              const Text(
                'Safety',
                style: TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
              const Text(
                'STRIDESENSE / RACE OPERATIONS',
                style: TextStyle(letterSpacing: 2, fontSize: 11, color: teal),
              ),
              const SizedBox(height: 24),
              const Text(
                'Every runner. Every heartbeat.',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text('Sign in to your official monitoring station.'),
              const SizedBox(height: 28),
              TextField(
                controller: user,
                decoration: const InputDecoration(
                  labelText: 'Official ID',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: password,
                obscureText: true,
                onSubmitted: (_) => login(),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: login,
                  child: const Text('Enter monitoring station →'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'AUTHORIZED SAFETY PERSONNEL ONLY',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late Monitor monitor;
  Health? filter;
  bool byPosition = true;
  String search = '';
  final notifications = FlutterLocalNotificationsPlugin();
  int notificationId = 0;
  @override
  void initState() {
    super.initState();
    monitor = Monitor(alert);
    unawaited(initNotifications());
    if (demoMode) {
      monitor.demo();
    } else {
      monitor.connect(
        const String.fromEnvironment(
          'WS_URL',
          defaultValue: 'ws://10.0.2.2:8080',
        ),
      );
    }
  }

  Future<void> initNotifications() async {
    try {
      await notifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  void alert(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
    unawaited(
      notifications
          .show(
            notificationId++,
            'Safety health alert',
            message,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'health',
                'Runner health alerts',
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
          )
          .catchError((Object _) {}),
    );
  }

  @override
  void dispose() {
    monitor.dispose();
    super.dispose();
  }

  void settings() {
    final controller = TextEditingController(text: 'ws://10.0.2.2:8080');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Generator connection'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'WebSocket server',
            helperText: 'Use your computer’s LAN IP on a device.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final address = controller.text;
              Navigator.pop(ctx);
              setState(() {
                monitor.dispose();
                monitor = Monitor(alert);
                monitor.connect(address);
              });
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: monitor,
    builder: (context, _) {
      final all = monitor.runners.values.toList()
        ..sort(
          (a, b) => byPosition
              ? b.distance.compareTo(a.distance)
              : a.id.compareTo(b.id),
        );
      final positions = {for (var i = 0; i < all.length; i++) all[i].id: i + 1};
      final visible = all
          .where(
            (r) =>
                (filter == null || r.health == filter) &&
                r.id.toLowerCase().contains(search.toLowerCase()),
          )
          .toList();
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.health_and_safety, color: teal),
              SizedBox(width: 8),
              Text('Safety', style: TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          actions: [
            IconButton(
              onPressed: settings,
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Connection settings',
            ),
            IconButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => SafeArea(
                  child: SizedBox(
                    height: 440,
                    child: Column(
                      children: [
                        const ListTile(title: Text('Health alerts')),
                        Expanded(
                          child: monitor.alerts.isEmpty
                              ? const Center(
                                  child: Text('No health alerts yet'),
                                )
                              : ListView.builder(
                                  itemCount: monitor.alerts.length,
                                  itemBuilder: (_, i) => ListTile(
                                    leading: const Icon(
                                      Icons.warning_amber,
                                      color: Colors.red,
                                    ),
                                    title: Text(monitor.alerts[i]),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              icon: Badge(
                label: Text('${monitor.alerts.length}'),
                child: const Icon(Icons.notifications_outlined),
              ),
            ),
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
              ),
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              Text(
                demoMode
                    ? 'SIMULATED RACE • 1,000 DEVICES'
                    : 'STRIDESENSE • LIVE RACE OPERATIONS',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.6,
                  color: teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Race overview',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: navy,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                demoMode
                    ? 'Demo mode · synthetic vitals'
                    : monitor.connections.entries
                          .map(
                            (e) =>
                                '${e.key.startsWith('time') ? 'Vitals' : 'Events'}: ${e.value}',
                          )
                          .join('  •  '),
                style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
              if (monitor.error.isNotEmpty)
                Text(
                  monitor.error,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  summary('Runners', all.length, navy),
                  ...Health.values.map(
                    (h) => summary(
                      h.name,
                      all.where((r) => r.health == h).length,
                      statusColor(h),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                onChanged: (v) => setState(() => search = v),
                decoration: InputDecoration(
                  hintText: 'Find a device',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All runners'),
                      selected: filter == null,
                      onSelected: (_) => setState(() => filter = null),
                    ),
                    ...Health.values.map(
                      (h) => Padding(
                        padding: const EdgeInsets.only(left: 7),
                        child: ChoiceChip(
                          label: Text(h.name),
                          selected: filter == h,
                          onSelected: (_) => setState(() => filter = h),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    '${visible.length} RUNNERS',
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<bool>(
                    value: byPosition,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: true,
                        child: Text(
                          'Race position',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text(
                          'Device ID',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => byPosition = v!),
                  ),
                ],
              ),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.sensors, size: 45, color: teal),
                            const SizedBox(height: 12),
                            Text(
                              all.isEmpty
                                  ? 'Waiting for runner reports'
                                  : 'No matching runners',
                            ),
                            if (all.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(14),
                                child: Text(
                                  'Start the generator and check your connection settings.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.blueGrey),
                                ),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, i) {
                          final r = visible[i];
                          return ValueListenableBuilder<int>(
                            valueListenable: monitor.signal(r.id),
                            builder: (_, value, child) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xffeef4f4),
                                  child: Text(
                                    '#${positions[r.id]}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: navy,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  'Runner ${r.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '${(r.distance / 1000).toStringAsFixed(2)} km  •  ${r.heart.round()} BPM',
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '● ${r.health.name}',
                                      style: TextStyle(
                                        color: statusColor(r.health),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      r.updated == null
                                          ? 'No data'
                                          : DateTime.now()
                                                    .difference(r.updated!)
                                                    .inSeconds >
                                                10
                                          ? 'Stale data'
                                          : 'Updated just now',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RunnerPage(runner: r, monitor: monitor),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
  Widget summary(String label, int count, Color color) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 5),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
          ),
        ],
      ),
    ),
  );
}

class RunnerPage extends StatelessWidget {
  final Runner runner;
  final Monitor monitor;
  const RunnerPage({super.key, required this.runner, required this.monitor});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Runner ${runner.id}')),
    body: ValueListenableBuilder<int>(
      valueListenable: monitor.signal(runner.id),
      builder: (context, _, child) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'INDIVIDUAL HEALTH OBSERVATION',
            style: const TextStyle(
              color: teal,
              fontSize: 10,
              letterSpacing: 1.7,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '● ${runner.health.name.toUpperCase()}',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: statusColor(runner.health),
            ),
          ),
          Text(
            'Last report: ${runner.updated?.toLocal() ?? 'Pending'}',
            style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              vital(
                'HEART RATE',
                '${runner.heart.round()}',
                'BPM · 5-report avg',
              ),
              vital(
                'BREATHING',
                '${runner.breath.round()}',
                '/min · 5-report avg',
              ),
              vital(
                'DISTANCE',
                (runner.distance / 1000).toStringAsFixed(2),
                'kilometers',
              ),
              vital('BLOOD OXYGEN', '${runner.oxygen.round()}', '% saturation'),
              vital('TEMPERATURE', runner.temperature.toStringAsFixed(1), '°C'),
              vital(
                'BLOOD PRESSURE',
                '${runner.systolic.round()}/${runner.diastolic.round()}',
                'mmHg',
              ),
            ],
          ),
          const SizedBox(height: 22),
          chart('Heart rate', true),
          const SizedBox(height: 14),
          chart('Breathing rate', false),
          const SizedBox(height: 22),
          const Text(
            'Vital event log',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          if (runner.events.isEmpty)
            const Text('Waiting for temperature, BP or oxygen events.'),
          ...runner.events.map(
            (e) => Card(
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Text(e, style: const TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  Widget vital(String title, String value, String unit) => Container(
    width: 155,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.blueGrey,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
        ),
      ],
    ),
  );
  Widget chart(String title, bool heart) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title · last 10 minutes',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(
              painter: VitalsPainter(runner.history.toList(), heart),
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('−10 min', style: TextStyle(fontSize: 10)),
              Text(
                'Normal / warning / emergency zones',
                style: TextStyle(fontSize: 9, color: Colors.blueGrey),
              ),
              Text('Now', style: TextStyle(fontSize: 10)),
            ],
          ),
        ],
      ),
    ),
  );
}

class VitalsPainter extends CustomPainter {
  final List<Sample> samples;
  final bool heart;
  VitalsPainter(this.samples, this.heart);
  @override
  void paint(Canvas canvas, Size size) {
    final max = heart ? 220.0 : 110.0;
    double y(double v) => size.height * (1 - v / max);
    void zone(double low, double high, Color c) => canvas.drawRect(
      Rect.fromLTRB(0, y(high), size.width, y(low)),
      Paint()..color = c.withValues(alpha: .12),
    );
    zone(0, max, Colors.red);
    zone(heart ? 40 : 25, heart ? 170 : 85, Colors.orange);
    zone(heart ? 60 : 45, heart ? 150 : 60, teal);
    final text = TextPainter(textDirection: TextDirection.ltr);
    for (final v in heart ? [60.0, 150.0, 170.0] : [25.0, 45.0, 60.0, 85.0]) {
      text.text = TextSpan(
        text: '${v.round()}',
        style: const TextStyle(fontSize: 9, color: Colors.blueGrey),
      );
      text.layout();
      text.paint(canvas, Offset(2, y(v)));
    }
    final now = DateTime.now();
    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final s = samples[i];
      final x =
          (1 - now.difference(s.time).inMilliseconds / 600000).clamp(0.0, 1.0) *
          size.width;
      final yy = y(heart ? s.heart : s.breath).clamp(0.0, size.height);
      if (i == 0) {
        path.moveTo(x, yy);
      } else {
        path.lineTo(x, yy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = teal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant VitalsPainter oldDelegate) => true;
}
