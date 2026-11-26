import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../logic/format.dart';
import '../models/block.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/dialogs.dart';
import '../art/sprites.dart';
import '../widgets/ui.dart';

/// Create or edit a saved set: a name plus an ordered list of blocks.
class SetEditScreen extends StatefulWidget {
  const SetEditScreen({super.key, this.set});

  final BlockSet? set;

  static Future<void> open(BuildContext context, {BlockSet? set}) =>
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => SetEditScreen(set: set)));

  @override
  State<SetEditScreen> createState() => _SetEditScreenState();
}

class _SetEditScreenState extends State<SetEditScreen> {
  late final _name = TextEditingController(text: widget.set?.name ?? '');
  // Each entry gets its own key so the same block can appear twice.
  late final List<({Key key, Block block})> _items = [
    if (widget.set != null)
      for (final b in context.read<AppState>().blocksOf(widget.set!))
        (key: UniqueKey(), block: b),
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final total = _items.fold(0, (a, e) => a + e.block.minutes);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.set == null ? 'Nowy zestaw' : 'Zestaw'),
        actions: [
          if (widget.set != null)
            IconButton(
              tooltip: 'Usuń zestaw',
              icon: const Icon(Icons.delete, color: Palette.rose),
              onPressed: () async {
                if (!await confirm(context, 'Usunąć zestaw?', yes: 'Usuń')) {
                  return;
                }
                app.deleteSet(widget.set!.id);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nazwa, np. Wyjście na siłownię',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(child: SectionLabel('Kolejność bloków')),
                  Text(
                    durationLabel(total),
                    style: const TextStyle(
                      fontFamily: Fonts.numbers,
                      fontSize: 24,
                      color: Palette.gold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _items.length,
                onReorderItem: (o, n) =>
                    setState(() => _items.insert(n, _items.removeAt(o))),
                itemBuilder: (ctx, i) {
                  final b = _items[i].block;
                  return ListTile(
                    key: _items[i].key,
                    contentPadding: EdgeInsets.zero,
                    leading: SpriteBox(Sprites.forIcon(b.icon), size: 28),
                    title: Text(b.name),
                    subtitle: Text(
                      '${b.minutes} min',
                      style: const TextStyle(color: Palette.muted),
                    ),
                    trailing: IconButton(
                      tooltip: 'Usuń z zestawu',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _items.removeAt(i)),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final b = await showModalBottomSheet<Block>(
                        context: context,
                        builder: (ctx) => ListView(
                          shrinkWrap: true,
                          children: [
                            for (final b in app.blocks)
                              ListTile(
                                leading: SpriteBox(
                                  Sprites.forIcon(b.icon),
                                  size: 28,
                                ),
                                title: Text(b.name),
                                trailing: Text('${b.minutes} min'),
                                onTap: () => Navigator.pop(ctx, b),
                              ),
                          ],
                        ),
                      );
                      if (b != null) {
                        setState(
                          () => _items.add((key: UniqueKey(), block: b)),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('dodaj blok'),
                  ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Palette.gold,
                      foregroundColor: Palette.onAccent,
                    ),
                    child: const Text('Zapisz'),
                    onPressed: () {
                      final name = _name.text.trim();
                      if (name.isEmpty || _items.isEmpty) return;
                      app.saveSet(
                        id: widget.set?.id,
                        name: name,
                        blockIds: _items.map((e) => e.block.id).toList(),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
