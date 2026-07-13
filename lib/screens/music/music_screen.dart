import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_shell.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Music',
      activeTab: AppTab.music,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const _SpinningAlbumArt(),
            const SizedBox(height: 24),
            const _SongPickCard(),
            const SizedBox(height: 28),
            const Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Text('Your playlists',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  SizedBox(width: 8),
                  Icon(Icons.add_circle_outline, color: AppColors.textPrimary),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _PlaylistCarousel(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SpinningAlbumArt extends StatefulWidget {
  const _SpinningAlbumArt();

  @override
  State<_SpinningAlbumArt> createState() => _SpinningAlbumArtState();
}

class _SpinningAlbumArtState extends State<_SpinningAlbumArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Slowly spins while a track is playing, like a vinyl record — matches
    // the circular album art + tonearm graphic in the mockup.
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          boxShadow: [
            BoxShadow(color: AppColors.accentPink.withOpacity(0.35), blurRadius: 40, spreadRadius: 6),
          ],
        ),
        child: const Center(
          child: Icon(Icons.album_rounded, size: 90, color: Colors.white24),
        ),
      ),
    );
  }
}

class _SongPickCard extends StatelessWidget {
  const _SongPickCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Song pick for Rest day',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Spooky - Simon Ray, Mich...',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('132 BPM', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCarousel extends StatelessWidget {
  const _PlaylistCarousel();

  @override
  Widget build(BuildContext context) {
    // Sample data — replace with the user's actual Spotify playlists
    // fetched via /me/playlists.
    const playlists = [
      {'name': 'Playlist 1', 'bpm': 132, 'trackCount': '100+'},
      {'name': 'Playlist 2', 'bpm': 122, 'trackCount': '80+'},
      {'name': 'Playlist 3', 'bpm': 140, 'trackCount': '60+'},
    ];

    return SizedBox(
      height: 340,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.75),
        itemCount: playlists.length,
        itemBuilder: (context, i) {
          final p = playlists[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              decoration: AppTheme.cardDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            color: Colors.black,
                            child: const Center(
                              child: Icon(Icons.graphic_eq_rounded, size: 60, color: Colors.white24),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              _Pill(text: p['trackCount'] as String),
                              const SizedBox(width: 6),
                              _Pill(text: '${p['bpm']}bpm'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(p['name'] as String,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }
}
