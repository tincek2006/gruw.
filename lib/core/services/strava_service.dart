import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

/// Handles Strava OAuth and activity creation.
///
/// IMPORTANT: Strava's API does not support "remote start" of a GPS
/// recording session on their own mobile app — there's no endpoint that
/// opens the Strava app and begins tracking for you. What this service
/// *can* do (and what "start run in Strava" should mean in practice) is:
///   1. Track the run entirely inside our own app using GpsService, then
///   2. When the run ends, upload it to Strava as a completed activity via
///      the /activities endpoint (or /uploads for a GPX/TCX file for full
///      GPS-track fidelity).
/// This is the standard pattern most third-party running apps use.
class StravaService {
  // TODO: replace with your own app's values from strava.com/settings/api
  static const _clientId = '265010';
  static const _clientSecret = '71577d5093a1a3b85dca977c7319731123e7f53c';
  static const _redirectUri = 'runmusicapp://strava-callback';

  final _storage = const FlutterSecureStorage();
  String? _accessToken;

  Future<void> authenticate() async {
    final authUrl = Uri.https('www.strava.com', '/oauth/mobile/authorize', {
      'client_id': _clientId,
      'redirect_uri': _redirectUri,
      'response_type': 'code',
      'approval_prompt': 'auto',
      'scope': 'activity:write,activity:read_all',
    });

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: 'runmusicapp',
    );

    final code = Uri.parse(result).queryParameters['code'];
    if (code == null) throw Exception('Strava auth failed: no code returned');

    final tokenRes = await http.post(
      Uri.parse('https://www.strava.com/oauth/token'),
      body: {
        'client_id': _clientId,
        'client_secret': _clientSecret,
        'code': code,
        'grant_type': 'authorization_code',
      },
    );

    final data = jsonDecode(tokenRes.body);
    _accessToken = data['access_token'];
    await _storage.write(key: 'strava_access_token', value: data['access_token']);
    await _storage.write(key: 'strava_refresh_token', value: data['refresh_token']);
  }

  Future<void> _ensureToken() async {
    _accessToken ??= await _storage.read(key: 'strava_access_token');
    if (_accessToken == null) throw Exception('Not authenticated with Strava yet');
  }

  /// Called when the run finishes: uploads the completed run as a Strava
  /// activity. [distanceMeters] and [movingTimeSeconds] come from GpsService;
  /// for a full GPS track (visible as a map on Strava), use uploadGpxFile
  /// instead of this simplified endpoint.
  Future<int> createActivity({
    required DateTime startDate,
    required double distanceMeters,
    required int movingTimeSeconds,
    String name = 'Run',
  }) async {
    await _ensureToken();
    final res = await http.post(
      Uri.parse('https://www.strava.com/api/v3/activities'),
      headers: {'Authorization': 'Bearer $_accessToken'},
      body: {
        'name': name,
        'type': 'Run',
        'start_date_local': startDate.toIso8601String(),
        'elapsed_time': movingTimeSeconds.toString(),
        'distance': distanceMeters.toString(),
      },
    );

    if (res.statusCode != 201) {
      throw Exception('Strava activity creation failed: ${res.body}');
    }
    final data = jsonDecode(res.body);
    return data['id'];
  }

  /// Preferred alternative: upload a GPX file built from the recorded GPS
  /// points so the run shows a real map/route on Strava, not just totals.
  Future<void> uploadGpxFile(List<int> gpxBytes, {String name = 'Run'}) async {
    await _ensureToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://www.strava.com/api/v3/uploads'),
    )
      ..headers['Authorization'] = 'Bearer $_accessToken'
      ..fields['data_type'] = 'gpx'
      ..fields['name'] = name
      ..files.add(http.MultipartFile.fromBytes('file', gpxBytes, filename: 'run.gpx'));

    final streamedRes = await request.send();
    if (streamedRes.statusCode != 201) {
      throw Exception('Strava GPX upload failed with status ${streamedRes.statusCode}');
    }
  }
}
