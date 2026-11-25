/// A reusable building block of the day, e.g. "Prysznic, 25 min".
class Block {
  const Block({
    required this.id,
    required this.name,
    required this.minutes,
    this.icon = 'flag',
  });

  final String id;
  final String name;
  final int minutes;

  /// Sprite id, see `Sprites.blockIcons`.
  final String icon;

  Block copyWith({String? name, int? minutes, String? icon}) => Block(
    id: id,
    name: name ?? this.name,
    minutes: minutes ?? this.minutes,
    icon: icon ?? this.icon,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'minutes': minutes,
    'icon': icon,
  };

  factory Block.fromJson(Map<String, dynamic> j) => Block(
    id: j['id'] as String,
    name: j['name'] as String,
    minutes: j['minutes'] as int,
    icon: j['icon'] as String? ?? 'flag',
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
