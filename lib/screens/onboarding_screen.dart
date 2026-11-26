import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../art/sprites.dart';
import '../models/companion.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/ui.dart';

/// Screen 01: name, then pick a companion (Tiko or the car), or none at
/// all for minimal mode. The fox is shown as "wkrótce".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _name = TextEditingController();
  int _step = 0;

  /// 'tiko', 'car' or 'minimal' (no companion).
  String _pick = 'tiko';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: _step == 0 ? _nameStep() : _companionStep(),
        ),
      ),
    );
  }

  Widget _nameStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Krok 1 z 2', style: ts(size: 12.5, color: Palette.muted)),
        const SizedBox(height: 6),
        Text(
          'Cześć! Jak masz na imię?',
          style: ts(size: 26, weight: 600, height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          'OnTime Quest liczy plan od godziny, na którą musisz gdzieś być, '
          'a twój towarzysz rośnie za każde dotarcie na czas.',
          style: ts(size: 14, color: Palette.muted, height: 1.45),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: ts(size: 17),
          decoration: const InputDecoration(labelText: 'Imię'),
          onSubmitted: (_) => setState(() => _step = 1),
        ),
        const Spacer(),
        AppButton('Dalej', onPressed: () => setState(() => _step = 1)),
      ],
    );
  }

  Widget _companionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Krok 2 z 2', style: ts(size: 12.5, color: Palette.muted)),
        const SizedBox(height: 6),
        Text(
          'Kto będzie pilnował czasu razem z tobą?',
          style: ts(size: 24, weight: 600, height: 1.2),
        ),
        const SizedBox(height: 8),
        Text(
          'Rośnie i zmienia się, gdy docierasz na czas. Nigdy nie choruje i nie znika.',
          style: ts(size: 14, color: Palette.muted, height: 1.45),
        ),
        const SizedBox(height: 18),
        _Pick(
          selected: _pick == 'tiko',
          onTap: () => setState(() => _pick = 'tiko'),
          sprite: Sprites.tiko,
          gradient: const [Color(0xFF3A2A52), Color(0xFF1C1530)],
          name: 'Tiko',
          text: tikoSpecies.pickText,
        ),
        const SizedBox(height: 10),
        _Pick(
          selected: _pick == 'car',
          onTap: () => setState(() => _pick = 'car'),
          sprite: Sprites.carWreck,
          gradient: const [Color(0xFF1C3A4A), Color(0xFF0F1D26)],
          name: 'Garaż',
          text: carSpecies.pickText,
        ),
        const SizedBox(height: 10),
        const _Pick(
          sprite: Sprites.fox,
          gradient: [Color(0xFF4A2A1C), Color(0xFF21140F)],
          name: 'Rudi',
          text: 'Lisek, którego karmisz i ubierasz.',
          soon: true,
        ),
        const SizedBox(height: 10),
        _Pick(
          selected: _pick == 'minimal',
          onTap: () => setState(() => _pick = 'minimal'),
          sprite: Sprites.flag,
          gradient: const [Color(0xFF26303F), Color(0xFF151B26)],
          name: 'Bez towarzysza',
          text: 'Tryb minimalny: same bloki i odliczanie. Zmienisz w ustawieniach.',
        ),
        const Spacer(),
        AppButton(
          switch (_pick) {
            'car' => 'Wybieram Kaszlaka',
            'minimal' => 'Zaczynamy',
            _ => 'Wybieram Tiko',
          },
          onPressed: () => context.read<AppState>().completeOnboarding(
            name: _name.text,
            companionId: _pick == 'minimal' ? 'tiko' : _pick,
            minimal: _pick == 'minimal',
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('Wstecz'),
        ),
      ],
    );
  }
}

class _Pick extends StatelessWidget {
  const _Pick({
    required this.sprite,
    required this.gradient,
    required this.name,
    required this.text,
    this.selected = false,
    this.soon = false,
    this.onTap,
  });

  final VoidCallback? onTap;

  final Sprite sprite;
  final List<Color> gradient;
  final String name;
  final String text;
  final bool selected;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: soon ? 0.55 : 1,
      child: AppCard(
        onTap: soon ? null : onTap,
        borderColor: selected ? Palette.gold : Palette.line,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(child: SpriteBox(sprite, size: 52)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: ts(size: 16, weight: 600)),
                      if (soon) ...[
                        const SizedBox(width: 8),
                        const Pill(text: 'wkrótce'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(text, style: ts(size: 12.5, color: Palette.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
