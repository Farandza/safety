# Safety — StrideSense race monitoring

Download the installable APK from this repository’s **Releases** section. Download the source using **Code → Download ZIP**.

Flutter Android app for safety officials. Fixed reviewer login: **official / Safety2026!**. These embedded credentials are a demonstration access gate, not production authentication.

## Run

Install Flutter stable and Android SDK, then:

```sh
flutter pub get
flutter run --dart-define=WS_URL=ws://10.0.2.2:8080
```

Start the provided marathon generator and its producer/client first. The default app uses live WebSockets at `/time_based_reports` and `/event_based_reports`. Settings lets you change the host. For physical devices use the generator computer's LAN address; for iOS simulator use localhost. Both streams reconnect after five seconds. Non-TLS local networking is enabled for the supplied generator.

The pasted brief did not include its linked reports.proto or docker-compose.yml. The decoder currently supports flat JSON, report/data envelopes, arrays and common snake_case/camelCase fields. Confirm field names and distance units against the actual generator before field use. Distance is treated as meters. No generator integration is claimed without those source files.

## Reviewer Guide

- Android device: copy `safety.apk` to the device, allow installation from the file manager when prompted, and install. Grant notification permission. Sign in, configure the generator LAN IP, filter by state, sort by position/device, and tap a runner for charts.
- NoxPlayer / BlueStacks: drag the APK into the emulator. Configure the host address reachable from that emulator in Settings (10.0.2.2 is specific to Android Studio's emulator).
- Appetize: upload the APK to your Appetize account and launch the virtual device. It needs a publicly reachable secure WebSocket generator endpoint; your local computer's localhost is not reachable from Appetize.

Build installable APK: `flutter build apk --release`. Signing uses the Flutter development signing configuration; use your own release key for distribution. If a hosting service rejects the APK size, attach it to a GitHub Release or your own external storage.

Optional synthetic review build (live mode remains the default):

```sh
flutter run --dart-define=DEMO=true
flutter build apk --release --dart-define=DEMO=true
```

Demo produces 1,000 devices once per second with repeatable warning/emergency examples. Local OS notifications and in-app alerts fire on health-state transitions while the app runs; this is not a remote push service and background streaming is not guaranteed.

## Design and validation

Heart and breath rates use the last five reports; threshold rules follow the supplied brief, including escalation for two warnings. History is bounded to ten minutes / 1,200 points per runner and 100 event entries. Up to 1,000 runners are retained. ListView builds visible rows lazily; individual rows and runner details use per-device notifiers, with aggregate sorting/counts refreshed once a second. Charts show normal/warning/emergency zones. Stream parsing stays out of build methods.

Run `flutter analyze` and `flutter test`. Actual emulator/device and generator validation must be recorded separately from unit tests. The app is a field-test prototype; fixed login, unauthenticated generator feeds, and initial default vitals require further hardening before real safety operations.

### Validation in this workspace

`flutter analyze`: no issues. Six automated tests passed, including a 1,000-device ingestion/cap test, alert transition deduplication, login rejection, health boundaries, rolling averages, and history limits. This verifies functional handling of 1,000 devices; it is not a real-time throughput benchmark. Use `scripts/run.sh` in the prepared cloud workspace to load the installed SDK paths.

Browser smoke test: Chromium signed in with the reviewer credentials and displayed all 1,000 simulated runners (961 normal, 25 warning, 14 emergency), with no JavaScript page errors. Renderer and Roboto font assets are bundled for local loading. This browser check does not replace the requested Android/iOS device test.

The individual runner page was also opened in Chromium: live vital cards, both chart sections, and the event log rendered without page errors. Screenshots are in `docs/`. Android emulator acceleration is unavailable (`/dev/kvm` is absent); device validation is outstanding.

In this prepared environment, `scripts/build-apk.sh` builds the release APK and copies it to `safety.apk` in the project root.

### APK build result

Release APK successfully built and copied to **safety.apk** (51.9 MB). Android APK signature verification passed (v2 scheme). Package: `com.example.safety`, version 1.0.0, minimum Android API 24 (Android 7.0), target API 36. This APK uses the development signing key and the default live-generator mode. Android device execution and actual generator compatibility remain unverified.
