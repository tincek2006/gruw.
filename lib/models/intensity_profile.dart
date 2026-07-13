/// The three intensity tiers the user can pick when starting a run,
/// each mapped to a target pace range (minutes per km).
enum RunIntensity { easy, moderate, intense }

extension RunIntensityX on RunIntensity {
  String get label {
    switch (this) {
      case RunIntensity.easy:
        return 'Easy';
      case RunIntensity.moderate:
        return 'Moderate';
      case RunIntensity.intense:
        return 'Intense';
    }
  }

  /// Slowest acceptable pace (min/km) before we consider the runner
  /// "too slow" for this intensity tier. Tune these to the user's fitness.
  double get maxAcceptablePaceMinPerKm {
    switch (this) {
      case RunIntensity.easy:
        return 7.0; // slower than 7:00/km on "easy" triggers a warning
      case RunIntensity.moderate:
        return 5.75;
      case RunIntensity.intense:
        return 4.75;
    }
  }
}

/// A single track within a Spotify album, pre-tagged with a relative
/// "energy" so the cadence engine can pick a *more intense* track when
/// it needs to nudge the runner to speed up.
class AlbumTrack {
  final String spotifyUri; // e.g. spotify:track:xxxx
  final String title;
  final String artist;
  final int bpm;

  /// 1 (chill) - 5 (highest energy) — derived from Spotify audio-features
  /// endpoint (energy + tempo), see SpotifyService.rankTracksByEnergy.
  final int energyRank;

  const AlbumTrack({
    required this.spotifyUri,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.energyRank,
  });
}

class RunSession {
  final RunIntensity intensity;
  final List<AlbumTrack> albumTracks; // pre-sorted by energyRank ascending
  final DateTime startedAt;
  int currentTrackIndex;
  double totalDistanceMeters;
  int? stravaActivityId;

  RunSession({
    required this.intensity,
    required this.albumTracks,
    required this.startedAt,
    this.currentTrackIndex = 0,
    this.totalDistanceMeters = 0,
    this.stravaActivityId,
  });

  AlbumTrack get currentTrack => albumTracks[currentTrackIndex];

  bool get hasMoreIntenseTrack =>
      currentTrackIndex < albumTracks.length - 1;
}
