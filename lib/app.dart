import 'package:material_ui/material_ui.dart';

import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

class OnTimeQuestApp extends StatelessWidget {
  const OnTimeQuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnTime Quest',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomeShell(),
    );
  }
}
