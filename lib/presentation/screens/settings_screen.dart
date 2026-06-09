import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final quality = ref.watch(qualityProvider).quality;
    final qualityNotifier = ref.read(qualityProvider.notifier);
    final accent = theme.accent;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeProvider.notifier).registerRoute('settings');
    });

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            child: const Text('Settings',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900)),
          ),
        ),
        // Theme section
        _sectionHeader('THEME'),
        _card(child: _Toggle(
          emoji: '\u{1F308}',
          title: 'Rainbow Mode',
          subtitle: "Change the whole app's colour",
          value: theme.rainbow,
          onChanged: themeNotifier.setRainbow,
          accent: accent,
        )),
        _card(child: _Toggle(
          emoji: '\u2728',
          title: 'Aurora Mode',
          subtitle: 'Animated cinematic gradient background',
          value: theme.aurora,
          onChanged: themeNotifier.setAurora,
          accent: accent,
        )),
        _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('\u270F\uFE0F Custom Colour',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppColors.customColours.map((c) {
                final selected = theme.baseAccent.toLowerCase() == c.hex.toLowerCase() && !theme.rainbow;
                return GestureDetector(
                  onTap: () => themeNotifier.setBaseAccent(c.hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: c.color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: selected
                          ? [BoxShadow(color: c.color.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 18, color: Colors.black)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        )),
        _card(child: _Toggle(
          emoji: '\u{1F3A8}',
          title: 'Per-Screen Colour',
          subtitle: 'Each screen has its own colour',
          value: theme.perScreen,
          onChanged: themeNotifier.setPerScreen,
          accent: accent,
        )),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: GestureDetector(
              onTap: themeNotifier.reset,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Center(
                  child: Text('Reset to Black & White',
                      style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ),
        // Playback section
        _sectionHeader('PLAYBACK'),
        _card(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Audio Quality',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Streamed from JioSaavn (Melo API)',
                style: TextStyle(color: AppColors.muted, fontSize: 11)),
            const SizedBox(height: 12),
            Row(
              children: ['96kbps', '160kbps', '320kbps'].map((q) {
                final selected = quality == q;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => qualityNotifier.setQuality(q),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? accent : AppColors.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(q,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? (accent.computeLuminance() > 0.4
                                        ? Colors.black
                                        : Colors.white)
                                    : AppColors.foreground)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        )),
        // Account section
        _sectionHeader('ACCOUNT'),
        _card(child: Row(
          children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('\u{1F7E2} Connect Spotify',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text(
                    'Optional. Only needed if you want to import your Spotify playlists & liked songs.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ]),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(20)),
              child: Text('Connect',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent.computeLuminance() > 0.4 ? Colors.black : Colors.white)),
            ),
          ],
        )),
        _card(child: Row(
          children: const [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('\u{1F4E5} Import Playlists',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('After connecting, choose which playlists to bring in.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ]),
            ),
            SizedBox(width: 12),
            _DisabledBtn(label: 'Import'),
          ],
        )),
        // About section
        _sectionHeader('ABOUT'),
        _card(child: const Text.rich(
          TextSpan(children: [
            TextSpan(text: 'YVL', style: TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: ' uses open sources: '),
            TextSpan(text: 'JioSaavn (meloapi)',
                style: TextStyle(color: AppColors.muted)),
            TextSpan(text: ' for songs & albums, '),
            TextSpan(text: 'LrcLib', style: TextStyle(color: AppColors.muted)),
            TextSpan(text: ' for synced lyrics.'),
          ]),
          style: TextStyle(fontSize: 13, height: 1.5),
        )),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  SliverToBoxAdapter _sectionHeader(String label) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 2)),
      ),
    );
  }

  SliverToBoxAdapter _card({required Widget child}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;
  final Color accent;

  const _Toggle({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$emoji $title',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          ]),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52,
            height: 30,
            decoration: BoxDecoration(
              color: value ? accent : AppColors.secondary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.all(3),
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                    color: AppColors.background, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DisabledBtn extends StatelessWidget {
  final String label;
  const _DisabledBtn({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.secondary, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.muted)),
    );
  }
}
