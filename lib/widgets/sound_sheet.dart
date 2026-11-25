import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../audio/sound_settings.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import 'ui.dart';

/// Bottom sheet: beeps on/off and which narrator (or none).
Future<void> showSoundSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  backgroundColor: Palette.card,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  builder: (_) => const SoundSheet(),
);

class SoundSheet extends StatelessWidget {
  const SoundSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.soundSettings;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Dźwięki', style: ts(size: 20, weight: 600)),
            const SizedBox(height: 4),
            Text(
              'Krótkie sygnały i lektor podpowiadają, ile zostało, '
              'żeby nie trzeba było patrzeć na ekran.',
              style: ts(size: 13, color: Palette.muted),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: s.beeps,
              activeThumbColor: Palette.bg,
              activeTrackColor: Palette.teal,
              title: Text('Sygnały dźwiękowe', style: ts(size: 15)),
              subtitle: Text(
                'start etapu, 2 min do końca, koniec, Gotowe',
                style: ts(size: 12, color: Palette.muted),
              ),
              onChanged: (v) => app.setSoundSettings(s.copyWith(beeps: v)),
            ),
            const SizedBox(height: 4),
            const SectionLabel('Lektor'),
            for (final n in Narrator.values)
              _NarratorTile(
                narrator: n,
                selected: s.narrator == n,
                onTap: () => app.setSoundSettings(s.copyWith(narrator: n)),
              ),
            const SizedBox(height: 10),
            AppButton(
              'Posłuchaj',
              tone: ButtonTone.outline,
              onPressed: s.silent ? null : () => app.sound.preview(s),
            ),
          ],
        ),
      ),
    );
  }
}

class _NarratorTile extends StatelessWidget {
  const _NarratorTile({
    required this.narrator,
    required this.selected,
    required this.onTap,
  });

  final Narrator narrator;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: selected ? Palette.card2 : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? Palette.gold : Palette.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? Palette.gold : Palette.muted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(narrator.label, style: ts(size: 15, weight: 600)),
                      Text(
                        narrator.blurb,
                        style: ts(size: 12, color: Palette.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
