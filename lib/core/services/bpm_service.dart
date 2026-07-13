import 'dart:convert';
import 'package:http/http.dart' as http;

/// Looks up real tempo (BPM) data from GetSongBPM.com, since Spotify
/// permanently shut down its own /audio-features endpoint for new apps
/// in November 2024 (see spotify_service.dart for details).
///
/// IMPORTANT — GetSongBPM's terms require a visible backlink to
/// getsongbpm.com somewhere in the app (or app store listing), or they
/// may suspend the API key without notice. See CreditsScreen, which
/// satisfies this requirement — don't remove that link.
///
/// Register a free API key at https://getsongbpm.com/api
class BpmService {
  // TODO: replace with your own key from https://getsongbpm.com/api
  static const _apiKey = 'YOUR_GETSONGBPM_API_KEY';
  static const _baseUrl = 'https://api.getsong.co';

  /// Looks up a track's tempo by title + artist. Returns null (rather than
  /// throwing) on any failure — a missing/wrong BPM should never crash a
  /// run, it should just fall back to position-based ordering.
  Future<int?> lookupBpm({required String title, required String artist}) async {
    try {
      final lookup = 'song:$title artist:$artist';
      final uri = Uri.parse('$_baseUrl/search/').replace(queryParameters: {
        'api_key': _apiKey,
        'type': 'both',
        'lookup': lookup,
      });

      final res = await http.get(uri).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return null;

      final results = jsonDecode(res.body)['search'];
      if (results is! List || results.isEmpty) return null;

      final tempo = results.first['tempo'];
      if (tempo == null) return null;

      return double.tryParse(tempo.toString())?.round();
    } catch (_) {
      // Network error, timeout, rate limit, unregistered key, no match, etc.
      // Any failure here just means "no BPM data for this track" — the
      // caller falls back to album-position ordering, never crashes.
      return null;
    }
  }
}
