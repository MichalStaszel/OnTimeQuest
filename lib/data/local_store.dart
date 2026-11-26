import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../audio/sound_settings.dart';
import '../models/block.dart';
import '../models/history.dart';
import '../models/companion.dart';
import '../models/mission.dart';
import '../models/run_session.dart';
import '../notifications/mission_notice.dart';

/// Everything is stored on the device as JSON in shared_preferences.
/// Small data, no backend. Swap for sqflite/drift if history grows large.
class LocalStore {
  LocalStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<LocalStore> open() async =>
      LocalStore(await SharedPreferences.getInstance());

  static const _kBlocks = 'blocks.v1';
  static const _kSets = 'sets.v1';
  static const _kMissions = 'missions.v1';
  static const _kCompanion = 'companion.v1';
  static const _kLearned = 'history.learned.v1';
  static const _kSession = 'session.v1';
  static const _kSteps = 'history.steps.v1';
  static const _kArrivals = 'history.arrivals.v1';
  static const _kSound = 'settings.sound.v1';
  static const kQueuedActions = 'notifications.actions.v1';

  List<T>? _readList<T>(String key, T Function(Map<String, dynamic>) f) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    return (jsonDecode(raw) as List)
        .map((e) => f(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) =>
      _prefs.setString(key, jsonEncode(items));

  List<Block>? loadBlocks() => _readList(_kBlocks, Block.fromJson);
  Future<void> saveBlocks(List<Block> v) =>
      _writeList(_kBlocks, v.map((e) => e.toJson()).toList());

  List<BlockSet>? loadSets() => _readList(_kSets, BlockSet.fromJson);
  Future<void> saveSets(List<BlockSet> v) =>
      _writeList(_kSets, v.map((e) => e.toJson()).toList());

  List<StepRecord> loadStepHistory() =>
      _readList(_kSteps, StepRecord.fromJson) ?? [];
  Future<void> saveStepHistory(List<StepRecord> v) =>
      _writeList(_kSteps, v.map((e) => e.toJson()).toList());

  List<ArrivalRecord> loadArrivals() =>
      _readList(_kArrivals, ArrivalRecord.fromJson) ?? [];
  Future<void> saveArrivals(List<ArrivalRecord> v) =>
      _writeList(_kArrivals, v.map((e) => e.toJson()).toList());

  List<Mission>? loadMissions() => _readList(_kMissions, Mission.fromJson);
  Future<void> saveMissions(List<Mission> v) =>
      _writeList(_kMissions, v.map((e) => e.toJson()).toList());

  List<LearnedBlock> loadLearned() =>
      _readList(_kLearned, LearnedBlock.fromJson) ?? [];
  Future<void> saveLearned(List<LearnedBlock> v) =>
      _writeList(_kLearned, v.map((e) => e.toJson()).toList());

  CompanionState loadCompanion() {
    final raw = _prefs.getString(_kCompanion);
    return raw == null
        ? const CompanionState()
        : CompanionState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveCompanion(CompanionState c) =>
      _prefs.setString(_kCompanion, jsonEncode(c.toJson()));

  RunSession? loadSession() {
    final raw = _prefs.getString(_kSession);
    return raw == null
        ? null
        : RunSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSession(RunSession? s) => s == null
      ? _prefs.remove(_kSession)
      : _prefs.setString(_kSession, jsonEncode(s.toJson()));

  SoundSettings loadSound() {
    final raw = _prefs.getString(_kSound);
    return raw == null
        ? const SoundSettings()
        : SoundSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveSound(SoundSettings s) =>
      _prefs.setString(_kSound, jsonEncode(s.toJson()));

  /// Buttons pressed on notifications, saved by the background handler.
  /// Returns and clears them.
  Future<List<QueuedAction>> takeQueuedActions() async {
    await _prefs.reload();
    final raw = _prefs.getStringList(kQueuedActions);
    if (raw == null || raw.isEmpty) return const [];
    await _prefs.remove(kQueuedActions);
    return [
      for (final r in raw)
        QueuedAction.fromJson(jsonDecode(r) as Map<String, dynamic>),
    ]..sort((a, b) => a.at.compareTo(b.at));
  }

  /// Called from the notification background isolate.
  static Future<void> queueAction(QueuedAction a) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final list = prefs.getStringList(kQueuedActions) ?? [];
    await prefs.setStringList(kQueuedActions, [
      ...list,
      jsonEncode(a.toJson()),
    ]);
  }
}
