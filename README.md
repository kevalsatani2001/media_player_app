# ðŸŽµ Media Player App

A high-performance, feature-rich Media Player application built with **Flutter**. This app provides
a seamless experience for browsing and playing local Video and Audio files, utilizing advanced
caching for a **"Zero-Lag"** user interface.

---

## ðŸš€ Key Features

* **âš¡ Instant Dashboard:** Real-time counts for Videos, Audios, Favorites, and Playlists shown
  immediately on app startup.
* **ðŸš€ Zero-Lag UI:** Uses **Hive** for instant data retrieval while background sync handles heavy
  media indexing.
* **ðŸ” Smart Media Scanning:** Automatically fetches and categorizes device media using
  `photo_manager`.
* **ðŸ§  Reactive State:** Powered by `flutter_bloc` for predictable, smooth, and scalable state
  transitions.
* **ðŸ“‚ Favorites & Playlists:** Custom management system to organize your media assets exactly how
  you want them.
* **ðŸ”„ Silent Background Sync:** Metadata synchronization and file counting happen in the background
  without blocking the main UI thread.

---

## ðŸ› ï¸ Tech Stack

| Component            | Technology                                                 |
|:---------------------|:-----------------------------------------------------------|
| **Frontend**         | [Flutter](https://flutter.dev) (Dart)                      |
| **State Management** | [flutter_bloc](https://pub.dev/packages/flutter_bloc)      |
| **Local Database**   | [Hive](https://pub.dev/packages/hive) (Fast NoSQL storage) |
| **Media Fetching**   | [photo_manager](https://pub.dev/packages/photo_manager)    |
| **Architecture**     | Clean BLoC Pattern                                         |

---

## ðŸ“‚ Project Structure

```plaintext
lib/
â”œâ”€â”€ blocs/              # Business Logic (HomeCount, Player, etc.)
â”œâ”€â”€ models/             # Data Models (MediaAsset, Playlist)
â”œâ”€â”€ screens/            # UI Layers
â”‚   â”œâ”€â”€ home/           # Dashboard with counts & navigation
â”‚   â”œâ”€â”€ player/         # Video & Audio playback controllers
â”‚   â””â”€â”€ library/        # Media Lists and Grids (Video/Audio)
â”œâ”€â”€ utils/              # app_imports.dart, constants, helpers
â””â”€â”€ main.dart           # App Entry point & Bloc Providers