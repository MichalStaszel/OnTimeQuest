import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../art/sprites.dart';
import '../logic/format.dart';
import '../models/block.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/dialogs.dart';
import '../widgets/ui.dart';
import 'set_edit_screen.dart';

/// Screen 04: the block library and saved sets.
class BlocksScreen extends StatelessWidget {
  const BlocksScreen({super.key, this.scrollToSets = false});

  final bool scrollToSets;

  static Future<void> open(BuildContext context, {bool sets = false}) =>
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BlocksScreen(scrollToSets: sets)),
      );

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final setsHeader = GlobalObjectKey('sets-$hashCode');
    if (scrollToSets) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final c = setsHeader.currentContext;
        if (c != null) Scrollable.ensureVisible(c);
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Bloki i zestawy')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            const SectionLabel('Bloki'),
            for (final b in app.blocks) ...[
              BlockTile(
                block: b,
                onTap: () => showBlockEditor(context, block: b),
              ),
              const SizedBox(height: 6),
            ],
            TextButton.icon(
              onPressed: () => showBlockEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('Nowy blok'),
            ),
            SectionLabel('Zestawy', key: setsHeader),
            for (final s in app.sets) ...[
              AppCard(
                onTap: () => SetEditScreen.open(context, set: s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(s.name, style: ts(size: 15, weight: 600)),
                        ),
                        Text(
                          durationLabel(
                            app.blocksOf(s).fold(0, (a, b) => a + b.minutes),
                          ),
                          style: numStyle(22, color: Palette.gold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      app
                          .blocksOf(s)
                          .map((b) => '${b.name} ${b.minutes}')
                          .join(' · '),
                      style: ts(size: 12.5, color: Palette.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextButton.icon(
              onPressed: () => SetEditScreen.open(context),
              icon: const Icon(Icons.add),
              label: const Text('Nowy zestaw'),
            ),
          ],
        ),
      ),
    );
  }
}

class BlockTile extends StatelessWidget {
  const BlockTile({super.key, required this.block, this.onTap});

  final Block block;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SpriteBox(Sprites.forIcon(block.icon), size: 28),
          const SizedBox(width: 12),
          Expanded(child: Text(block.name, style: ts(size: 14.5, weight: 600))),
          Text('${block.minutes}', style: numStyle(24)),
          Text(' min', style: ts(size: 12, color: Palette.muted)),
        ],
      ),
    );
  }
}

/// Bottom sheet to create or edit a block. Returns the saved block.
Future<Block?> showBlockEditor(BuildContext context, {Block? block}) {
  return showModalBottomSheet<Block>(
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
  late String _icon = widget.block?.icon ?? 'glass';
  late bool _warn = widget.block?.warnBeforeEnd ?? true;
  late bool _plusFive = widget.block?.allowPlusFive ?? true;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final b = context.read<AppState>().saveBlock(
      id: widget.block?.id,
      name: name,
      minutes: _minutes,
      icon: _icon,
      warnBeforeEnd: _warn,
      allowPlusFive: _plusFive,
    );
    Navigator.pop(context, b);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final isNew = widget.block == null;
    final suggestion = isNew
        ? null
        : app.suggestionFor(widget.block!.id, _minutes);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    isNew ? 'Nowy blok' : 'Edytuj blok',
                    style: ts(size: 18, weight: 600),
                  ),
                ),
                TextButton(onPressed: _save, child: const Text('Zapisz')),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              autofocus: isNew,
              textCapitalization: TextCapitalization.sentences,
              style: ts(size: 16, weight: 500),
              decoration: const InputDecoration(labelText: 'Nazwa'),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              children: [
                for (final id in Sprites.blockIcons.keys)
                  Material(
                    color: _icon == id
                        ? Palette.gold.withValues(alpha: 0.16)
                        : Palette.card2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: _icon == id
                          ? const BorderSide(color: Palette.gold, width: 1.5)
                          : BorderSide.none,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _icon = id),
                      child: Center(
                        child: SpriteBox(Sprites.forIcon(id), size: 32),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            MinutesStepper(
              value: _minutes,
              onChanged: (v) => setState(() => _minutes = v),
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 10),
              AppCard(
                color: Palette.gold.withValues(alpha: 0.1),
                borderColor: null,
                radius: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const SpriteBox(Sprites.tiko, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Z ${app.sampleCount(widget.block!.id)} ostatnich razy wychodzi średnio $suggestion min.',
                        style: ts(size: 12.5),
                      ),
                    ),
                    Pill(
                      text: 'Ustaw $suggestion',
                      color: Palette.gold,
                      onTap: () {
                        app.applySuggestion(widget.block!.id, suggestion);
                        setState(() => _minutes = suggestion);
                      },
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _warn,
              onChanged: (v) => setState(() => _warn = v),
              title: Text(
                'Dźwięk na 2 min przed końcem',
                style: ts(size: 13.5),
              ),
              subtitle: Text(
                'dźwięki dojdą w kolejnej wersji',
                style: ts(size: 11.5, color: Palette.faint),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _plusFive,
              onChanged: (v) => setState(() => _plusFive = v),
              title: Text('Pozwól na +5 min', style: ts(size: 13.5)),
            ),
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
                child: Text(
                  'Usuń blok',
                  style: ts(size: 14, color: Palette.rose),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
