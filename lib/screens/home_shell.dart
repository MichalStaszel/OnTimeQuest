import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'blocks_screen.dart';
import 'countdown_screen.dart';
import 'plan_screen.dart';
import 'progress_screen.dart';

/// Bottom navigation: Plan / Bloki / Postęp.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    // A game was running when the app was closed: jump straight back in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<AppState>().session != null) {
        CountdownScreen.open(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: const [PlanScreen(), BlocksScreen(), ProgressScreen()],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.schedule), label: 'Plan'),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Bloki'),
          NavigationDestination(icon: Icon(Icons.star), label: 'Postęp'),
        ],
      ),
    );
  }
}
