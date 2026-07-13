import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/intensity_profile.dart';
import 'spotify_service.dart';

/// Listens to the live pace stream (from GpsService) and, when the runner
/// is consistently slower than their chosen intensity's target pace,
/// speaks a warning and — if they don't speed up within 10s — asks
/// SpotifyService to crossfade into a more energetic track.
class CadenceEngine {
  final RunSession session;
  final SpotifyService spotifyService;
  final FlutterTts _tts = FlutterTts();

  Timer? _graceTimer;
  bool _warningActive = false;
  StreamSubscription<double>? _paceSub;

  final _stateController = StreamController<CadenceState>.broadcast();
  Stream<CadenceState> get stateStream => _stateController.stream;

  static const _graceWindow = Duration(seconds: 10);

  CadenceEngine({required this.session, required this.spotifyService}) {
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
  }

  void listenTo(Stream<double> paceStream) {
    _paceSub = paceStream.listen(_onPaceUpdate);
  }

  void _onPaceUpdate(double currentPaceMinPerKm) {
    final targetMax = session.intensity.maxAcceptablePaceMinPerKm;
    final tooSlow = currentPaceMinPerKm > targetMax;

    if (tooSlow && !_warningActive) {
      _warningActive = true;
      _speakWarning();
      _stateController.add(CadenceState.warning);

      _graceTimer = Timer(_graceWindow, () {
        // Still too slow after the grace window -> switch song.
        if (_warningActive) {
          _triggerSongChange();
        }
      });
    } else if (!tooSlow && _warningActive) {
      // Runner sped back up in time — cancel the pending switch.
      _warningActive = false;
      _graceTimer?.cancel();
      _stateController.add(CadenceState.onTrack);
    }
  }

  Future<void> _speakWarning() async {
    await _tts.speak(
      "You're running too slow. Speed up, or the song will change.",
    );
  }

  Future<void> _triggerSongChange() async {
    _warningActive = false;
    if (!session.hasMoreIntenseTrack) {
      // Already on the most energetic track in the album — nothing to escalate to.
      _stateController.add(CadenceState.maxIntensityReached);
      return;
    }
    session.currentTrackIndex += 1;
    await spotifyService.crossfadeTo(session.currentTrack, fadeDuration: const Duration(seconds: 3));
    _stateController.add(CadenceState.trackSwitched);
  }

  void dispose() {
    _graceTimer?.cancel();
    _paceSub?.cancel();
    _stateController.close();
    _tts.stop();
  }
}

enum CadenceState { onTrack, warning, trackSwitched, maxIntensityReached }
