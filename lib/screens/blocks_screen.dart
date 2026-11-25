import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/format.dart';
import '../models/block.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/dialogs.dart';
import '../widgets/pixel_sprite.dart';
import '../widgets/pixel_ui.dart';
import 'set_edit_screen.dart';

/// Screen 2 from the mockups: reusable blocks and saved sets.
class BlocksScreen extends StatelessWidget {
  const BlocksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        const SectionLabel('Twoje bloki'),
        for (final b in app.blocks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => showBlockEditor(context, block: b),
              child: PixelPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    PixelSprite(Sprites.forIcon(b.icon), scale: 1.75),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(b.name, style: const TextStyle(fontSize: 17)),
                    ),
                    Text(
                      '${b.minutes} min',
                      style: const TextStyle(
                        fontFamily: Fonts.numbers,
                        fontSize: 24,
                        color: Palette.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () => showBlockEditor(context),
          icon: const Icon(Icons.add),
          label: const Text('nowy blok'),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Zestawy'),
        for (final s in app.sets)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => SetEditScreen.open(context, set: s),
              child: PixelPanel(
                color: Palette.plumDeep,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          durationLabel(
                            app.blocksOf(s).fold(0, (a, b) => a + b.minutes),
                          ),
                          style: const TextStyle(
                            fontFamily: Fonts.numbers,
                            fontSize: 24,
                            color: Palette.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app
                          .blocksOf(s)
                          .map((b) => '${b.name} ${b.minutes}')
                          .join(' · '),
                      style: const TextStyle(
                        color: Palette.lavender,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        TextButton.icon(
          onPressed: () => SetEditScreen.open(context),
          icon: const Icon(Icons.add),
          label: const Text('nowy zestaw'),
        ),
      ],
    );
  }
}

/// Bottom sheet to create or edit a block.
Future<void> showBlockEditor(BuildContext context, {Block? block}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _BlockEditor(block: block),
    ),
  );
}

class _BlockEditor extends StatefulWidget {
  const _BlockEditor({this.block});

  final Block? block;

  @override
  State<_BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<_BlockEditor> {
  late final _name = TextEditingController(text: widget.block?.name ?? '');
  late int _minutes = widget.block?.minutes ?? 10;
  late String _icon = widget.block?.icon ?? 'flag';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final isNew = widget.block == null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionLabel(isNew ? 'Nowy blok' : 'Edytuj blok'),
            TextField(
              controller: _name,
              autofocus: isNew,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nazwa'),
            ),
            const SizedBox(height: 12),
            MinutesStepper(
              value: _minutes,
              onChanged: (v) => setState(() => _minutes = v),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in Sprites.blockIcons.keys)
                  GestureDetector(
                    onTap: () => setState(() => _icon = id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _icon == id ? Palette.plum : Palette.ink,
                        border: Border.all(
                          color: _icon == id ? Palette.amber : Palette.black,
                          width: 3,
                        ),
                      ),
                      child: PixelSprite(Sprites.forIcon(id), scale: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (!isNew)
                  TextButton(
                    onPressed: () async {
                      final ok = await confirm(
                        context,
                        'Usunąć blok „${widget.block!.name}”?',
                        yes: 'Usuń',
                      );
                      if (!ok) return;
                      app.deleteBlock(widget.block!.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text(
                      'Usuń',
                      style: TextStyle(color: Palette.tomato),
                    ),
                  ),
                const Spacer(),
                PixelButton(
                  label: 'ZAPISZ',
                  onPressed: () {
                    final name = _name.text.trim();
                    if (name.isEmpty) return;
                    app.saveBlock(
                      id: widget.block?.id,
                      name: name,
                      minutes: _minutes,
                      icon: _icon,
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
