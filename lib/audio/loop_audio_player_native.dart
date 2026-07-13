import 'dart:async';

import 'package:just_audio/just_audio.dart';

class LoopAudioPlayer {
  LoopAudioPlayer() {
    unawaited(_player.setLoopMode(LoopMode.one));
  }

  final AudioPlayer _player = AudioPlayer();

  bool get playing => _player.playing;
  Stream<bool> get playingStream => _player.playingStream;

  Future<void> setAsset(String path) async {
    await _player.setAsset(path);
    await _player.setLoopMode(LoopMode.one);
  }

  Future<void> setVolume(double volume) => _player.setVolume(volume);
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);
  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> dispose() => _player.dispose();
}
