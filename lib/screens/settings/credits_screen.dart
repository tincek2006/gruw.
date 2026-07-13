import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

/// Lists attributions for every third-party service this app relies on.
/// The GetSongBPM.com link here is REQUIRED by their API terms — removing
/// it risks the API key being suspended without notice. See bpm_service.dart.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.screenBackground,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    ),
                    const Text(
                      'Credits',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _CreditTile(
                      title: 'Song tempo data',
                      subtitle: 'getsongbpm.com',
                      onTap: () => _openUrl('https://getsongbpm.com'),
                    ),
                    const SizedBox(height: 12),
                    _CreditTile(
                      title: 'Music playback',
                      subtitle: 'Spotify',
                      onTap: () => _openUrl('https://www.spotify.com'),
                    ),
                    const SizedBox(height: 12),
                    _CreditTile(
                      title: 'Activity tracking',
                      subtitle: 'Strava',
                      onTap: () => _openUrl('https://www.strava.com'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreditTile({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.accentPinkSoft, fontSize: 13)),
              ],
            ),
            const Icon(Icons.open_in_new, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
