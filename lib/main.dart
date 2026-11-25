import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'audio/sound_player.dart';
import 'data/local_store.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.open();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(store, sound: DeviceSoundPlayer()),
      child: const OnTimeQuestApp(),
    ),
  );
}
