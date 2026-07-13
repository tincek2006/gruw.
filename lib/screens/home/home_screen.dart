import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/spotify_service.dart';
import '../../core/services/strava_service.dart';
import '../../core/services/gps_service.dart';
import '../../models/intensity_profile.dart';
import '../../widgets/app_shell.dart';
import 'active_run_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Home',
      activeTab: AppTab.home,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              "Today's plans & tunes",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const _TodaysPlanCard(),
            const SizedBox(height: 20),
            const _TipOfTheDayCard(),
            const SizedBox(height: 28),
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const _GoalReachChart(),
            const SizedBox(height: 24),
            _StartRunButton(onPressed: () => _openStartRunSheet(context)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _openStartRunSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _StartRunSheet(),
    );
  }
}

class _TodaysPlanCard extends StatelessWidget {
  const _TodaysPlanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rest day',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                SizedBox(height: 10),
                Text('distance: 0km', style: TextStyle(color: AppColors.textSecondary)),
                Text('Intensity: Extreme', style: TextStyle(color: AppColors.textSecondary)),
                Text('Vibes: Groovy', style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 72,
                  height: 72,
                  color: Colors.black,
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 6),
              const Text('Spooky', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TipOfTheDayCard extends StatelessWidget {
  const _TipOfTheDayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tip of the day',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          const Text(
            'On rest days you should primarily relax and recharge, so eat lots of '
            'protein and magnesium dense foods for better recovery.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Discover other tips'),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalReachChart extends StatelessWidget {
  const _GoalReachChart();

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    // Sample goal-completion values (0-1) per weekday — replace with real data source.
    const values = [0.8, 0.55, 0.7, 0.25, 1.0, 0.75, 0.4];
    const highlightIndex = 4; // Friday, outlined bar in the mockup

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          const Text('Goal reach by day',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(days[value.toInt()],
                            style: const TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                  ),
                ),
                barGroups: List.generate(days.length, (i) {
                  final isHighlighted = i == highlightIndex;
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: values[i] * 100,
                      width: 14,
                      borderRadius: BorderRadius.circular(8),
                      color: isHighlighted ? Colors.transparent : AppColors.accentPinkSoft,
                      backDrawRodData: BackgroundBarChartRodData(show: false),
                    ),
                  ]);
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartRunButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _StartRunButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: const Text('Start run'),
      ),
    );
  }
}

/// The popup shown right after "Start run" is pressed: pick intensity + album.
class _StartRunSheet extends StatefulWidget {
  const _StartRunSheet();

  @override
  State<_StartRunSheet> createState() => _StartRunSheetState();
}

class _StartRunSheetState extends State<_StartRunSheet> {
  RunIntensity _selectedIntensity = RunIntensity.easy;
  SpotifyAlbum? _selectedAlbum;
  List<SpotifyAlbum>? _albums; // null = not loaded yet
  bool _loading = false;
  bool _loadingAlbums = false;
  String? _albumsError;

  final _spotifyService = SpotifyService();
  final _stravaService = StravaService();
  final _gpsService = GpsService();

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _loadingAlbums = true;
      _albumsError = null;
    });
    try {
      final isAuthed = await _spotifyService.isAuthenticated();
      if (!isAuthed) {
        await _spotifyService.authenticate();
      }
      final albums = await _spotifyService.getUserSavedAlbums();
      if (mounted) setState(() => _albums = albums);
    } catch (e) {
      if (mounted) setState(() => _albumsError = 'Could not load Spotify albums: $e');
    } finally {
      if (mounted) setState(() => _loadingAlbums = false);
    }
  }

  Future<void> _confirmAndStart() async {
    if (_selectedAlbum == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an album first')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final tracks = await _spotifyService.getRankedAlbumTracks(_selectedAlbum!.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ActiveRunScreen(
          intensity: _selectedIntensity,
          albumTracks: tracks,
          spotifyService: _spotifyService,
          stravaService: _stravaService,
          gpsService: _gpsService,
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start run: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildAlbumPicker() {
    if (_loadingAlbums) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentPink),
            ),
            SizedBox(width: 12),
            Text('Loading your Spotify albums…', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    if (_albumsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_albumsError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _loadAlbums, child: const Text('Retry')),
        ],
      );
    }

    final albums = _albums ?? [];
    if (albums.isEmpty) {
      return const Text('No saved albums found on Spotify.',
          style: TextStyle(color: AppColors.textSecondary));
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: albums.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final album = albums[i];
          final selected = _selectedAlbum?.id == album.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedAlbum = album),
            child: Container(
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.accentPink : AppColors.cardBorder,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: album.imageUrl != null
                        ? Image.network(album.imageUrl!, width: 78, height: 60, fit: BoxFit.cover)
                        : Container(width: 78, height: 60, color: Colors.black26,
                            child: const Icon(Icons.album_rounded, color: Colors.white24)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      album.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Set up your run',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),
          const Text('Intensity', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: RunIntensity.values.map((intensity) {
              final selected = intensity == _selectedIntensity;
              return ChoiceChip(
                label: Text(intensity.label),
                selected: selected,
                onSelected: (_) => setState(() => _selectedIntensity = intensity),
                selectedColor: AppColors.accentPink,
                backgroundColor: AppColors.cardBackground,
                labelStyle: TextStyle(color: selected ? Colors.black : AppColors.textPrimary),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Album', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          _buildAlbumPicker(),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _confirmAndStart,
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Text('Start'),
            ),
          ),
        ],
      ),
    );
  }
}
