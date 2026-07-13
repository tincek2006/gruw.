import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/cadence_engine.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/spotify_service.dart';
import '../../core/services/strava_service.dart';
import '../../models/intensity_profile.dart';

class ActiveRunScreen extends StatefulWidget {
  final RunIntensity intensity;
  final List<AlbumTrack> albumTracks;
  final SpotifyService spotifyService;
  final StravaService stravaService;
  final GpsService gpsService;

  const ActiveRunScreen({
    super.key,
    required this.intensity,
    required this.albumTracks,
    required this.spotifyService,
    required this.stravaService,
    required this.gpsService,
  });

  @override
  State<ActiveRunScreen> createState() => _ActiveRunScreenState();
}

class _ActiveRunScreenState extends State<ActiveRunScreen> {
  late final RunSession _session;
  late final CadenceEngine _cadenceEngine;
  double _currentPace = 0;
  String _statusMessage = "Let's go!";
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _session = RunSession(
      intensity: widget.intensity,
      albumTracks: widget.albumTracks,
      startedAt: DateTime.now(),
    );
    _cadenceEngine = CadenceEngine(
      session: _session,
      spotifyService: widget.spotifyService,
    );
    _startRun();
  }

  Future<void> _startRun() async {
    await widget.gpsService.start();
    await widget.spotifyService.playTrack(_session.currentTrack);
    _stopwatch.start();

    widget.gpsService.paceStream.listen((pace) {
      if (mounted) setState(() => _currentPace = pace);
    });

    _cadenceEngine.listenTo(widget.gpsService.paceStream);
    _cadenceEngine.stateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        switch (state) {
          case CadenceState.warning:
            _statusMessage = 'Too slow — speed up!';
            break;
          case CadenceState.trackSwitched:
            _statusMessage = 'Switched to a more intense track 🔥';
            break;
          case CadenceState.onTrack:
            _statusMessage = 'Nice pace, keep going';
            break;
          case CadenceState.maxIntensityReached:
            _statusMessage = "You're already on the most intense track!";
            break;
        }
      });
    });
  }

  Future<void> _endRun() async {
    _stopwatch.stop();
    await widget.gpsService.stop();

    try {
      await widget.stravaService.createActivity(
        startDate: _session.startedAt,
        distanceMeters: widget.gpsService.totalDistanceMeters,
        movingTimeSeconds: _stopwatch.elapsed.inSeconds,
        name: '${widget.intensity.label} run',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload to Strava: $e')),
        );
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _cadenceEngine.dispose();
    widget.gpsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.screenBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.intensity.label,
                  style: const TextStyle(fontSize: 20, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentPace > 0 ? '${_currentPace.toStringAsFixed(2)} min/km' : '-- min/km',
                  style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.cardDecoration(),
                  child: Column(
                    children: [
                      Text('Now playing', style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(_session.currentTrack.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(_session.currentTrack.artist,
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(_statusMessage, style: const TextStyle(color: AppColors.accentPinkSoft)),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _endRun,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                  child: const Text('End run', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
