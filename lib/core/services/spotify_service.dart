import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import '../../models/intensity_profile.dart';
import 'bpm_service.dart';

/// A saved album shown in the album picker (before its tracks are fetched
/// and ranked by energy — that only happens once the user selects one).
class SpotifyAlbum {
  final String id;
  final String name;
  final String artist;
  final String? imageUrl;

  const SpotifyAlbum({
    required this.id,
    required this.name,
    required this.artist,
    this.imageUrl,
  });
}

/// Handles Spotify auth (Authorization Code + PKCE, required since Spotify
/// deprecated the Implicit Grant for new apps) and playback control via the
/// Web API. Note: real-time "resume/skip/seek" control requires the user to
/// have an active Spotify device (phone app open, or the official Spotify
/// App Remote SDK embedded — see note at bottom of file).
class SpotifyService {
  static const _clientId = 'b98b393db8364724bfeadb709d1ad0fd';
  static const _redirectUri = 'runmusicapp://spotify-callback';
  static const _scopes =
      'user-read-playback-state user-modify-playback-state playlist-read-private user-read-private';

  final _storage = const FlutterSecureStorage();
  final _bpmService = BpmService();
  String? _accessToken;

  /// Starts the PKCE OAuth flow in an in-app browser tab.
  Future<void> authenticate() async {
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _codeChallengeFromVerifier(codeVerifier);

    final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': _clientId,
      'response_type': 'code',
      'redirect_uri': _redirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': codeChallenge,
      'scope': _scopes,
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: 'runmusicapp',
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) throw Exception('Spotify auth failed: no code returned');

    await _exchangeCodeForToken(code, codeVerifier);
  }

  Future<void> _exchangeCodeForToken(String code, String codeVerifier) async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Spotify token exchange failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    _accessToken = data['access_token'];
    await _storage.write(key: 'spotify_access_token', value: data['access_token']);
    await _storage.write(key: 'spotify_refresh_token', value: data['refresh_token']);
  }

  Future<void> _ensureToken() async {
    _accessToken ??= await _storage.read(key: 'spotify_access_token');
    if (_accessToken == null) {
      throw Exception('Not authenticated with Spotify yet');
    }
  }

  /// Uses the stored refresh_token to obtain a new access_token, since
  /// Spotify access tokens expire after ~1 hour.
  Future<void> _refreshAccessToken() async {
    final refreshToken = await _storage.read(key: 'spotify_refresh_token');
    if (refreshToken == null) {
      throw Exception('No Spotify refresh token stored — please log in again');
    }

    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': _clientId,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Spotify token refresh failed: ${response.body}');
    }

    final data = jsonDecode(response.body);
    _accessToken = data['access_token'];
    await _storage.write(key: 'spotify_access_token', value: data['access_token']);
    // Spotify only returns a new refresh_token sometimes — keep the old one if absent.
    if (data['refresh_token'] != null) {
      await _storage.write(key: 'spotify_refresh_token', value: data['refresh_token']);
    }
  }

  /// Wraps an HTTP call so that a 401 (expired access token) triggers one
  /// automatic refresh-and-retry, instead of surfacing the error to the UI.
  Future<http.Response> _authorizedRequest(
    Future<http.Response> Function(String token) request,
  ) async {
    await _ensureToken();
    var response = await request(_accessToken!);

    if (response.statusCode == 401) {
      await _refreshAccessToken();
      response = await request(_accessToken!);
    }

    return response;
  }

  /// Whether we already have a stored Spotify token (doesn't validate it's
  /// still unexpired — a real app would also check/refresh via the
  /// refresh_token before treating this as "safe to skip login").
  Future<bool> isAuthenticated() async {
    _accessToken ??= await _storage.read(key: 'spotify_access_token');
    return _accessToken != null;
  }

  /// Fetches the current user's saved ("Your Library") albums, for the
  /// album picker shown in the Start Run sheet.
  Future<List<SpotifyAlbum>> getUserSavedAlbums({int limit = 20}) async {
    final res = await _authorizedRequest((token) => http.get(
          Uri.parse('https://api.spotify.com/v1/me/albums?limit=$limit'),
          headers: {'Authorization': 'Bearer $token'},
        ));

    if (res.statusCode != 200) {
      throw Exception('Failed to load Spotify albums: ${res.body}');
    }

    final items = jsonDecode(res.body)['items'] as List;
    return items.map((item) {
      final album = item['album'];
      final images = album['images'] as List;
      return SpotifyAlbum(
        id: album['id'],
        name: album['name'],
        artist: (album['artists'] as List).map((a) => a['name']).join(', '),
        imageUrl: images.isNotEmpty ? images.first['url'] : null,
      );
    }).toList();
  }

  /// Fetches all tracks on an album, and tries to rank them by real tempo
  /// (BPM) via GetSongBPM.com — since Spotify permanently shut down its own
  /// /audio-features endpoint for all new apps in November 2024 (along with
  /// /audio-analysis, /recommendations, /related-artists), with no official
  /// replacement.
  ///
  /// GetSongBPM lookups happen per-track and can fail individually (rate
  /// limits, no match found, network issues) — any track without a BPM
  /// match keeps its natural album-position rank instead, so a few misses
  /// never break the whole list. If GetSongBPM is unreachable entirely,
  /// every track just falls back to position-based ranking, so a run can
  /// never be blocked by a third-party outage.
  Future<List<AlbumTrack>> getRankedAlbumTracks(String albumId) async {
    final albumRes = await _authorizedRequest((token) => http.get(
          Uri.parse('https://api.spotify.com/v1/albums/$albumId/tracks'),
          headers: {'Authorization': 'Bearer $token'},
        ));

    if (albumRes.statusCode != 200) {
      throw Exception('Failed to load album tracks: ${albumRes.body}');
    }

    final trackItems = jsonDecode(albumRes.body)['items'] as List;

    // Look up real BPM per track (in parallel), tolerating individual failures.
    final bpmResults = await Future.wait(trackItems.map((t) async {
      final artist = (t['artists'] as List).map((a) => a['name']).join(', ');
      return _bpmService.lookupBpm(title: t['name'], artist: artist);
    }));

    final tracks = <AlbumTrack>[];
    for (var i = 0; i < trackItems.length; i++) {
      final t = trackItems[i];
      tracks.add(AlbumTrack(
        spotifyUri: t['uri'],
        title: t['name'],
        artist: (t['artists'] as List).map((a) => a['name']).join(', '),
        bpm: bpmResults[i],
        energyRank: i + 1, // provisional — replaced below if enough real BPMs came back
      ));
    }

    // Only re-sort by real BPM if we got a usable number of matches —
    // otherwise a handful of real values mixed with fallback ordering
    // would produce a misleading, half-real ranking.
    final matchedCount = bpmResults.where((b) => b != null).length;
    if (matchedCount >= (trackItems.length / 2).ceil()) {
      final withBpm = tracks.where((t) => t.bpm != null).toList()
        ..sort((a, b) => a.bpm!.compareTo(b.bpm!));
      final withoutBpm = tracks.where((t) => t.bpm == null).toList();
      final reranked = [...withBpm, ...withoutBpm];
      return [
        for (var i = 0; i < reranked.length; i++)
          AlbumTrack(
            spotifyUri: reranked[i].spotifyUri,
            title: reranked[i].title,
            artist: reranked[i].artist,
            bpm: reranked[i].bpm,
            energyRank: i + 1,
          ),
      ];
    }

    return tracks;
  }

  /// Starts playback of a specific track on the user's active device.
  Future<void> playTrack(AlbumTrack track) async {
    await _authorizedRequest((token) => http.put(
          Uri.parse('https://api.spotify.com/v1/me/player/play'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'uris': [track.spotifyUri]}),
        ));
  }

  /// Fades out the current track and fades in [track]. The Web API itself
  /// has no native crossfade — this achieves it by ramping volume down,
  /// switching tracks, then ramping back up.
  Future<void> crossfadeTo(AlbumTrack track, {required Duration fadeDuration}) async {
    await _ensureToken();
    final steps = 5;
    final stepDelay = fadeDuration ~/ (steps * 2);

    for (var i = steps; i >= 0; i--) {
      await _setVolume((i / steps * 100).round());
      await Future.delayed(stepDelay);
    }
    await playTrack(track);
    for (var i = 0; i <= steps; i++) {
      await _setVolume((i / steps * 100).round());
      await Future.delayed(stepDelay);
    }
  }

  Future<void> _setVolume(int percent) async {
    await _authorizedRequest((token) => http.put(
          Uri.parse('https://api.spotify.com/v1/me/player/volume?volume_percent=$percent'),
          headers: {'Authorization': 'Bearer $token'},
        ));
  }

  String _generateCodeVerifier() {
    final rand = Random.secure();
    final values = List<int>.generate(64, (_) => rand.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  String _codeChallengeFromVerifier(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }
}

/// NOTE on real-world reliability:
/// The Web API's /me/player/play and /volume endpoints require an active
/// Spotify Connect device and have noticeable latency (300-800ms), which is
/// fine for "switch to a more intense song" but too slow for tight crossfades.
/// For a smoother in-run experience, consider embedding the official
/// Spotify App Remote SDK (via the `spotify_sdk` package) instead, which
/// gives lower-latency local playback control on iOS/Android.