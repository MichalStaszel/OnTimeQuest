import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'chiptune.dart';
import 'cues.dart';
import 'sound_settings.dart';
import 'voice_lines.dart';

/// Plays cues. The app uses [DeviceSoundPlayer]; tests use the silent base
/// class, which only remembers what it was asked to play.
class SoundPlayer {
  final List<String> played = [];

  Future<void> play(Cue cue, SoundSettings s) async {
    played.add(cue.kind.name);
  }

  Future<void> preview(SoundSettings s) =>
      play(const Cue(CueKind.twoMinutesLeft, name: 'Prysznic', minutes: 2), s);

  void dispose() {}
}

/// Real audio: a chiptune jingle, then the narrator.
///
/// Voice: a pre-recorded clip from `assets/voice/<narrator>/<line id>.mp3`
/// when it exists, otherwise the phone's Polish text-to-speech with a
/// pitch and speed that give each narrator a character.
class DeviceSoundPlayer extends SoundPlayer {
  final _beeps = AudioPlayer(playerId: 'beeps');
  final _clips = AudioPlayer(playerId: 'voice');
  final _tts = FlutterTts();
  final _rng = math.Random();
  final Map<CueKind, Uint8List> _wavs = {};
  Set<String>? _clipAssets;
  bool _ttsReady = false;
  Narrator? _ttsVoiceFor;
  Map<String, String>? _plVoiceMale, _plVoiceFemale;

  @override
  Future<void> play(Cue cue, SoundSettings s) async {
    try {
      if (s.beeps) await _beep(cue.kind);
      if (s.narrator != Narrator.none) {
        final line = pickLine(s.narrator, cue.kind, _rng);
        if (line != null) {
          // Let the jingle finish before talking.
          if (s.beeps) await Future.delayed(const Duration(milliseconds: 350));
          await _say(line, cue, s.narrator);
        }
      }
    } catch (_) {
      // Sound is a nice-to-have; never break the countdown over it.
    }
  }

  Future<void> _beep(CueKind k) async {
    final notes = melodyFor(k);
    if (notes == null) return;
    final wav = _wavs[k] ??= renderWav(notes);
    await _beeps.play(BytesSource(wav, mimeType: 'audio/wav'));
  }

  Future<void> _say(VoiceLine line, Cue cue, Narrator n) async {
    final clip = 'assets/voice/${n.name}/${line.id}.mp3';
    _clipAssets ??= await _loadClipList();
    if (!line.hasPlaceholders && _clipAssets!.contains(clip)) {
      await _clips.play(AssetSource(clip.substring('assets/'.length)));
      return;
    }
    await _prepareTts(n);
    await _tts.stop();
    await _tts.speak(line.fill(cue));
  }

  Future<Set<String>> _loadClipList() async {
    try {
      final m = await AssetManifest.loadFromAssetBundle(rootBundle);
      return m.listAssets().where((a) => a.startsWith('assets/voice/')).toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> _prepareTts(Narrator n) async {
    if (!_ttsReady) {
      await _tts.setLanguage('pl-PL');
      await _tts.awaitSpeakCompletion(false);
      await _findPolishVoices();
      _ttsReady = true;
    }
    if (_ttsVoiceFor == n) return;
    _ttsVoiceFor = n;
    final voice = n == Narrator.male ? _plVoiceMale : _plVoiceFemale;
    if (voice != null) await _tts.setVoice(voice);
    // Character comes mostly from pitch and pace: a low, hurried sports
    // commentator and a bright, quick "Minutka".
    if (n == Narrator.male) {
      await _tts.setPitch(voice != null ? 0.85 : 0.7);
      await _tts.setSpeechRate(0.55);
    } else {
      await _tts.setPitch(voice != null ? 1.3 : 1.45);
      await _tts.setSpeechRate(0.55);
    }
  }

  /// Google's Polish voices have codes, not genders. These are the known
  /// male and female ones; if none is installed the default voice is used
  /// and only the pitch differs.
  Future<void> _findPolishVoices() async {
    const male = ['bmg', 'jmk', 'male'];
    const female = ['oda', 'zfg', 'afb', 'female'];
    try {
      final all = (await _tts.getVoices as List?) ?? const [];
      final pl = [
        for (final v in all)
          if (v is Map &&
              '${v['locale']}'.toLowerCase().replaceAll('_', '-') == 'pl-pl')
            {'name': '${v['name']}', 'locale': '${v['locale']}'},
      ];
      Map<String, String>? find(List<String> hints) {
        for (final v in pl) {
          final name = v['name']!.toLowerCase();
          if (name.contains('female') && hints.contains('male')) continue;
          if (hints.any(name.contains)) return v;
        }
        return null;
      }

      _plVoiceMale = find(male);
      _plVoiceFemale = find(female);
    } catch (_) {}
  }

  @override
  void dispose() {
    unawaited(_beeps.dispose());
    unawaited(_clips.dispose());
    unawaited(_tts.stop());
  }
}
