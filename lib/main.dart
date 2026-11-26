import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'audio/sound_player.dart';
import 'data/local_store.dart';
import 'notifications/session_notifications.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.open();
  final app = AppState(store, sound: DeviceSoundPlayer());
  runApp(
    ChangeNotifierProvider.value(value: app, child: const OnTimeQuestApp()),
  );
  // Ongoing notification with progress, reminders, Gotowe / +5.
  unawaited(SessionNotifications(app, store).start());
}
