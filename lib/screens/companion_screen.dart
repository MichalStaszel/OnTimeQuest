import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../art/scenes.dart';
import '../art/sprites.dart';
import '../models/companion.dart';
import '../state/app_state.dart';
import '../theme/palette.dart';
import '../widgets/ui.dart';
import 'today_screen.dart';
import '../art/companion_art.dart';

/// Screen 07: the companion's room, feeding, evolution path and shop.
class CompanionScreen extends StatelessWidget {
  const CompanionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = app.companion;
    final stage = app.stage;
    final sp = app.species;
    final next = nextUnlock(sp, app.onTimeCount);
    final apples = c.food['apple'] ?? 0, cookies = c.food['cookie'] ?? 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        ScreenTitle(
          sp.stages[stage].name == sp.name
              ? sp.name
              : '${sp.name} · ${sp.stages[stage].name}',
          over: 'Etap ${stage + 1} z ${sp.stages.length}',
          trailing: Pill(
            text: pts(c.coins),
            sprite: Sprites.coin,
            color: Palette.gold,
          ),
        ),
        const SizedBox(height: 12),
        const CompanionRoom(),
        if (next != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Następna nagroda: ${next.name}',
                  style: ts(size: 12.5, color: Palette.muted),
                ),
              ),
              Text(
                '${app.onTimeCount} / ${next.needed} na czas',
                style: ts(size: 12.5, color: Palette.muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: app.unlockProgress,
              minHeight: 6,
              color: Palette.lilac,
              backgroundColor: Palette.tabs,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Meter(
                label: 'Najedzony',
                value: app.fullness,
                color: Palette.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Meter(
                label: 'Humor',
                value: app.mood,
                color: Palette.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
          child: Row(
            children: [
              const SpriteBox(Sprites.apple, size: 20),
              Text(' × $apples', style: numStyle(22)),
              const SizedBox(width: 12),
              const SpriteBox(Sprites.cookie, size: 20),
              Text(' × $cookies', style: numStyle(22)),
              const Spacer(),
              TextButton(
                onPressed: apples + cookies == 0 ? null : () => app.feed(),
                child: Text(
                  'Nakarm',
                  style: ts(
                    size: 14,
                    weight: 600,
                    color: apples + cookies == 0 ? Palette.faint : Palette.gold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (apples + cookies == 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Jedzenie dostajesz za etapy skończone w czasie i za dotarcie na czas.',
              style: ts(size: 12, color: Palette.faint),
            ),
          ),
        const SectionLabel('Ewolucja'),
        Row(
          children: [
            for (var i = 0; i < stages.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _EvoSlot(
                  index: i,
                  current: stage,
                  onTime: app.onTimeCount,
                  species: sp,
                ),
              ),
            ],
          ],
        ),
        const SectionLabel('Nagrody za punktualność'),
        Row(
          children: [
            for (var i = 0; i < perks.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _PerkSlot(
                  index: i,
                  species: sp,
                  unlocked: app.onTimeCount >= perks[i].onTimeNeeded,
                ),
              ),
            ],
          ],
        ),
        SectionLabel(
          'Sklep',
          trailing: Text(
            'punkty: ${pts(c.coins)}',
            style: ts(size: 12, color: Palette.muted),
          ),
        ),
        Row(
          children: [
            for (var i = 0; i < shopItems.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(child: _ShopTile(item: shopItems[i])),
            ],
          ],
        ),
        if (c.owned.contains('hat'))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: c.wearingHat,
              onChanged: (_) => app.toggleHat(),
              title: Text('${sp.name} nosi czapkę', style: ts(size: 13.5)),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => app.setSpecies(sp.id == 'car' ? 'tiko' : 'car'),
          icon: Icon(
            sp.id == 'car'
                ? Icons.pets_outlined
                : Icons.directions_car_outlined,
            size: 18,
          ),
          label: Text(
            sp.id == 'car'
                ? 'Zamień na Tiko (postęp zostaje)'
                : 'Zamień na auto Kaszlak (postęp zostaje)',
            style: ts(size: 13),
          ),
        ),
      ],
    );
  }
}

/// One perk: preview when unlocked, silhouette and "N×" when not.
class _PerkSlot extends StatelessWidget {
  const _PerkSlot({
    required this.index,
    required this.species,
    required this.unlocked,
  });

  final int index;
  final Species species;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final perk = perks[index];
    final sprite = switch (perk.id) {
      'sparkles' => Sprites.sparkle,
      'glow' => Sprites.flame,
      _ => composeCompanion(
        CompanionLook(species: species.id, stage: 1, perks: {perk.id}),
      ),
    };
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: unlocked
                  ? Palette.gold.withValues(alpha: 0.1)
                  : Palette.card2,
              borderRadius: BorderRadius.circular(10),
              border: unlocked ? Border.all(color: Palette.gold) : null,
            ),
            child: Center(
              child: SpriteBox(sprite, size: 36, silhouette: !unlocked),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          unlocked ? species.perkNames[index] : '${perk.onTimeNeeded}× na czas',
          style: ts(size: 10.5, color: Palette.muted),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _EvoSlot extends StatelessWidget {
  const _EvoSlot({
    required this.index,
    required this.current,
    required this.onTime,
    required this.species,
  });

  final int index;
  final int current;
  final int onTime;
  final Species species;

  @override
  Widget build(BuildContext context) {
    final stages = species.stages;
    final s = stages[index];
    final unlocked = index <= current;
    final isNow = index == current;
    final label = unlocked
        ? s.name
        : (index == stages.length - 1 ? '?' : '${s.onTimeNeeded}×');
    return Tooltip(
      message: '${s.name}: ${s.description}',
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: isNow
                    ? Palette.gold.withValues(alpha: 0.1)
                    : Palette.card2,
                borderRadius: BorderRadius.circular(10),
                border: isNow
                    ? Border.all(color: Palette.gold, width: 1.5)
                    : null,
              ),
              child: Center(
                child: SpriteBox(
                  companionSprite(index, species: species.id),
                  size: 40,
                  silhouette: !unlocked,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: ts(size: 10.5, color: Palette.muted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({required this.item});

  final ShopItem item;

  static const _sprites = {
    'apple': Sprites.apple,
    'hat': Sprites.hat,
    'plant': Sprites.plant,
    'lamp': Sprites.lamp,
  };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final owned =
        item.kind != ItemKind.food && app.companion.owned.contains(item.id);
    final affordable = app.companion.coins >= item.price;
    return AppCard(
      radius: 11,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      onTap: owned
          ? null
          : () {
              final ok = app.buy(item);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? (item.kind == ItemKind.food
                              ? 'Kupione: ${item.name} ×${item.amount}'
                              : 'Kupione: ${item.name}')
                        : 'Brakuje ${item.price - app.companion.coins} punktów',
                  ),
                ),
              );
            },
      child: Column(
        children: [
          SpriteBox(_sprites[item.id]!, size: 26),
          const SizedBox(height: 3),
          Text(
            item.name,
            style: ts(size: 11, color: Palette.muted),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            owned
                ? 'masz'
                : (item.kind == ItemKind.food
                      ? '${item.price} · ×${item.amount}'
                      : '${item.price}'),
            style: numStyle(
              17,
              color: owned
                  ? Palette.teal
                  : (affordable ? Palette.gold : Palette.faint),
            ),
          ),
        ],
      ),
    );
  }
}
