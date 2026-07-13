import 'dart:async';
import 'dart:collection';
import 'package:geolocator/geolocator.dart';

/// Wraps `geolocator`'s position stream and converts raw GPS samples into
/// a smoothed current pace (minutes per km), since raw instantaneous GPS
/// speed is noisy (satellite drift, tunnels, tree cover, etc).
class GpsService {
  StreamSubscription<Position>? _positionSub;
  final _paceController = StreamController<double>.broadcast();
  final _distanceController = StreamController<double>.broadcast();

  /// Rolling window of (timestamp, speed m/s) samples used to smooth pace.
  final Queue<_Sample> _window = Queue();
  static const _windowDuration = Duration(seconds: 8);

  double _totalDistanceMeters = 0;
  Position? _lastPosition;

  /// Emits smoothed pace in minutes/km every time a new GPS fix arrives.
  Stream<double> get paceStream => _paceController.stream;

  /// Emits cumulative distance in meters.
  Stream<double> get distanceStream => _distanceController.stream;

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    return serviceEnabled &&
        (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse);
  }

  Future<void> start() async {
    final granted = await requestPermission();
    if (!granted) {
      throw Exception('Location permission not granted');
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 2, // meters — update every ~2m moved
    );

    _positionSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(_onPosition);
  }

  void _onPosition(Position position) {
    final now = DateTime.now();

    // Update cumulative distance.
    if (_lastPosition != null) {
      final segment = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      // Ignore GPS jitter: don't count sub-1m "movement" while standing still.
      if (segment > 1.0) {
        _totalDistanceMeters += segment;
        _distanceController.add(_totalDistanceMeters);
      }
    }
    _lastPosition = position;

    // position.speed is in m/s, provided by the platform location API.
    final speed = position.speed.isFinite && position.speed >= 0
        ? position.speed
        : 0.0;

    _window.addLast(_Sample(now, speed));
    while (_window.isNotEmpty &&
        now.difference(_window.first.time) > _windowDuration) {
      _window.removeFirst();
    }

    final avgSpeed =
        _window.map((s) => s.speedMs).reduce((a, b) => a + b) / _window.length;

    if (avgSpeed > 0.3) {
      // convert m/s -> min/km
      final minPerKm = (1000 / avgSpeed) / 60;
      _paceController.add(minPerKm);
    }
  }

  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }

  double get totalDistanceMeters => _totalDistanceMeters;

  void dispose() {
    _positionSub?.cancel();
    _paceController.close();
    _distanceController.close();
  }
}

class _Sample {
  final DateTime time;
  final double speedMs;
  _Sample(this.time, this.speedMs);
}
