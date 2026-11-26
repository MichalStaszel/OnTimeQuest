import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'companion_screen.dart';
import 'countdown_screen.dart';
import 'missions_screen.dart';
import 'onboarding_screen.dart';
import 'progress_screen.dart';
import 'today_screen.dart';

/// Onboarding until a companion is picked, then the four tabs:
/// Dziś / Plan / Tiko / Postęp.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  /// Selected tab. Other screens (e.g. the reward's "Nakarm Tiko") set it.
  static final tab = ValueNotifier<int>(0);

  static const today = 0, plan = 1, companion = 2, progress = 3;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  void _select(int i) => HomeShell.tab.value = i;

  @override
  void initState() {
    super.initState();
    // A game was running when the app was closed: jump straight back in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final app = context.read<AppState>();
      if (mounted && app.companion.onboarded && app.session != null) {
        CountdownScreen.open(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = context.select<AppState, bool>(
      (a) => a.companion.onboarded,
    );
    if (!onboarded) return const OnboardingScreen();
    return ValueListenableBuilder(
      valueListenable: HomeShell.tab,
      builder: (context, tab, _) => _tabs(tab),
    );
  }

  Widget _tabs(int tab) {
    final app = context.watch<AppState>();
    // Minimal mode hides the companion tab.
    final visible = app.minimal ? const [0, 1, 3] : const [0, 1, 2, 3];
    final selected = visible.indexOf(tab);
    final car = app.species.id == 'car';
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: selected < 0 ? 0 : tab,
          children: const [
            TodayScreen(),
            MissionsScreen(),
            CompanionScreen(),
            ProgressScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (i) => _select(visible[i]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            label: 'Dziś',
          ),
          const NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            label: 'Plan',
          ),
          if (!app.minimal)
            NavigationDestination(
              icon: Icon(
                car ? Icons.directions_car_outlined : Icons.pets_outlined,
              ),
              label: app.species.name,
            ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Postęp',
          ),
        ],
      ),
    );
  }
}
