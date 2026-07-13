import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart';

/// Sample-accurate looping for the web preview.
///
/// HTMLMediaElement looping may insert a scheduling gap between repetitions.
/// Web Audio decodes the WAV once and loops the in-memory AudioBuffer instead.
class LoopAudioPlayer {
  LoopAudioPlayer() {
    _gain.connect(_context.destination);
    _gain.gain.value = _volume;
  }

  final AudioContext _context = AudioContext();
  late final GainNode _gain = _context.createGain();
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();

  AudioBuffer? _buffer;
  AudioBufferSourceNode? _source;
  bool _playing = false;
  double _volume = 1;
  double _speed = 1;

  bool get playing => _playing;
  Stream<bool> get playingStream => _playingController.stream;

  Future<void> setAsset(String path) async {
    _stopSource();
    final webPath = path.startsWith('assets/') ? 'assets/$path' : path;
    final response = await window.fetch(webPath.toJS).toDart;
    if (!response.ok) {
      throw StateError(
        'Não foi possível carregar $webPath (${response.status})',
      );
    }
    final bytes = await response.arrayBuffer().toDart;
    _buffer = await _context.decodeAudioData(bytes).toDart;
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    _gain.gain.value = volume;
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    _source?.playbackRate.value = speed;
  }

  Future<void> play() async {
    final buffer = _buffer;
    if (buffer == null || _playing) return;
    await _context.resume().toDart;
    final source = _context.createBufferSource();
    source
      ..buffer = buffer
      ..loop = true
      ..playbackRate.value = _speed
      ..connect(_gain)
      ..start(0);
    _source = source;
    _setPlaying(true);
  }

  Future<void> pause() async => _stopSource();

  Future<void> seek(Duration position) async {
    // A new AudioBufferSourceNode always starts at zero after pause.
  }

  Future<void> dispose() async {
    _stopSource();
    await _playingController.close();
    await _context.close().toDart;
  }

  void _stopSource() {
    final source = _source;
    _source = null;
    if (source != null) {
      source.stop();
      source.disconnect();
    }
    _setPlaying(false);
  }

  void _setPlaying(bool value) {
    if (_playing == value) return;
    _playing = value;
    if (!_playingController.isClosed) _playingController.add(value);
  }
}
