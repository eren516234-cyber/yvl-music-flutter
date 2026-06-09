# YVL Music

A full-featured Flutter music streaming app powered by JioSaavn, with synced lyrics, playlists, and a rich player UI.

## Features

- **Home** — Genre tabs (For You, Rock, Hip-Hop, K-Pop, Pop, Bollywood, Lo-Fi, R&B), Quick Picks, New Drops album carousel
- **Explore** — Mood grid with gradient cards, Trending Now, Hot Albums
- **Search** — Real-time search for songs/artists/albums, recent searches, genre browse grid
- **Library** — Playlists (create/delete/play/shuffle), Liked songs, Downloads playlist
- **Settings** — Rainbow mode, Aurora mode, 8 custom accent colours, Per-screen colours, Audio quality (96/160/320kbps), Reset theme
- **Full Player** — Spinning vinyl art, blurred album background, 8 synced-lyrics modes (Line, Word, Char, Wave, Neon, Cinema, Float, Pulse), Re-sync button, Like/Add to playlist/Download actions, Shuffle/Prev/Pause/Next
- **Mini Player** — Persistent bottom bar with playback controls and seek progress

## Music API

Streams from JioSaavn via [saavn.dev](https://saavn.dev) with automatic fallback to two mirror endpoints.

## Lyrics

Fetched from [LrcLib](https://lrclib.net) with time-synced line highlighting and 8 animated display modes.

## Setup

1. Install Flutter 3.x
2. Run `flutter pub get`
3. Run `flutter run` for debug or `flutter build apk --release` for a release APK

## Architecture

- **State**: flutter_riverpod (StateNotifier)
- **Navigation**: go_router
- **Audio**: just_audio
- **Storage**: shared_preferences
- **Network images**: cached_network_image
