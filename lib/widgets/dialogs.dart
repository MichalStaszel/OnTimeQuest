import 'package:material_ui/material_ui.dart';

import '../theme/palette.dart';

/// Asks for a short text (mission name, set name).
///
/// The controller lives in a State so it is disposed only after the dialog's
/// exit animation ends. Disposing it when the Future completes crashes,
/// because the TextField is still on screen while the dialog fades out.
Future<String?> askText(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TextDialog(title: title, initial: initial),
  );
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Anuluj'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('OK', style: TextStyle(color: Palette.mint)),
        ),
      ],
    );
  }
}

/// Minutes stepper (−5 −1 +1 +5).
class MinutesStepper extends StatelessWidget {
  const MinutesStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget btn(int delta) => Expanded(
      child: TextButton(
        onPressed: () => onChanged((value + delta).clamp(1, 600)),
        child: Text(
          delta > 0 ? '+$delta' : '$delta',
          style: const TextStyle(fontFamily: Fonts.numbers, fontSize: 24),
        ),
      ),
    );
    return Row(
      children: [
        btn(-5),
        btn(-1),
        SizedBox(
          width: 90,
          child: Text(
            '$value min',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: Fonts.numbers,
              fontSize: 30,
              color: Palette.amber,
            ),
          ),
        ),
        btn(1),
        btn(5),
      ],
    );
  }
}

Future<int?> askMinutes(
  BuildContext context, {
  required String title,
  required int initial,
}) {
  var value = initial;
  return showDialog<int>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title),
        content: MinutesStepper(
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, value),
            child: const Text('OK', style: TextStyle(color: Palette.mint)),
          ),
        ],
      ),
    ),
  );
}

Future<bool> confirm(
  BuildContext context,
  String question, {
  String yes = 'Tak',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(question),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Nie'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(yes, style: const TextStyle(color: Palette.tomato)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
