/// A reusable building block of the day, e.g. "Prysznic, 25 min".
class Block {
  const Block({
    required this.id,
    required this.name,
    required this.minutes,
    this.icon = 'glass',
    this.warnBeforeEnd = true,
    this.allowPlusFive = true,
  });

  final String id;
  final String name;
  final int minutes;

  /// Sprite id, see `Sprites.blockIcons`.
  final String icon;

  /// Sound 2 minutes before the end (stored; the sound itself is a follow-up).
  final bool warnBeforeEnd;

  /// Show "+5 min" for this block.
  final bool allowPlusFive;

  Block copyWith({
    String? name,
    int? minutes,
    String? icon,
    bool? warnBeforeEnd,
    bool? allowPlusFive,
  }) => Block(
    id: id,
    name: name ?? this.name,
    minutes: minutes ?? this.minutes,
    icon: icon ?? this.icon,
    warnBeforeEnd: warnBeforeEnd ?? this.warnBeforeEnd,
    allowPlusFive: allowPlusFive ?? this.allowPlusFive,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'minutes': minutes,
    'icon': icon,
    'warnBeforeEnd': warnBeforeEnd,
    'allowPlusFive': allowPlusFive,
  };

  factory Block.fromJson(Map<String, dynamic> j) => Block(
    id: j['id'] as String,
    name: j['name'] as String,
    minutes: j['minutes'] as int,
    icon: j['icon'] as String? ?? 'glass',
    warnBeforeEnd: j['warnBeforeEnd'] as bool? ?? true,
    allowPlusFive: j['allowPlusFive'] as bool? ?? true,
  );
}

/// A saved, ordered set of blocks, e.g. "Wyjście na siłownię".
class BlockSet {
  const BlockSet({
    required this.id,
    required this.name,
    required this.blockIds,
  });

  final String id;
  final String name;
  final List<String> blockIds;

  BlockSet copyWith({String? name, List<String>? blockIds}) => BlockSet(
    id: id,
    name: name ?? this.name,
    blockIds: blockIds ?? this.blockIds,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'blockIds': blockIds,
  };

  factory BlockSet.fromJson(Map<String, dynamic> j) => BlockSet(
    id: j['id'] as String,
    name: j['name'] as String,
    blockIds: (j['blockIds'] as List).cast<String>(),
  );
}
