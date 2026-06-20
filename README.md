# 🎵 Nova Media Vision - Advanced Video & Audio Player

A high-performance, feature-rich, and premium Media Player application built with **Flutter**. Designed to deliver a desktop-grade media consumption experience on mobile devices, this app provides seamless local Video and Audio playback. By utilizing advanced local caching and background media indexing, it ensures a **"Zero-Lag"** user interface.

---

## 🚀 Core Features

### 🎬 Advanced Video Playback
- **Universal Format Support:** Smooth hardware-accelerated playback for all popular video codecs and formats.
- **Picture-in-Picture (PiP) Mode:** Keep videos playing in a floating overlay window while multitasking on your device.
- **Intelligent Gestures:** Swipe controls for screen brightness, volume adjustment, and quick seeking.
- **Precision Controls:**
  - **A-B Repeat:** Loop specific segments of video files for study or practice.
  - **Video Trimmer:** In-app video trimming with customizable resolution, frame rate, format, and cover thumbnail preview extraction.
  - **Mirror & Flip:** Instantly mirror or vertically flip video streams.
  - **Custom Aspect Ratios:** Dynamic scaling options (Fit, Crop, Stretch, 16:9, 4:3, 21:9, etc.).
  - **Kids Lock:** Prevent accidental touch inputs with interactive touch feedback effects.
  - **Snapshot Tool:** Capture high-quality screenshots directly from the video stream to your gallery.
  - **Network Stream:** Stream online video content instantly using HTTP, HTTPS, or direct links.

### 🎧 Premium Audio Player & Suite
- **Global Background Playback:** Continuous music streaming powered by `just_audio_background` with persistent media notifications.
- **Dynamic Sleep Timer:** Automatically turn off media playback after a set duration.
- **Set as Ringtone:** Easily assign any audio file as your device ringtone with system settings permission integration.
- **Smart Organization:** Browse audio by:
  - **Tracks / All Files**
  - **Playlists** (Create, delete, rename, and customize)
  - **Favorites** (Quick-toggle tags)
  - **Albums & Folders** (System-level directory navigation)

### 🎛️ Audio Enhancement Suite
- **Built-in Equalizer:** Personalize your sound profile with precision controls.
- **Reverb Effects:** Simulate room acoustics (Small Room, Medium Room, Large Room, Medium Hall, Large Hall, Plate).
- **Bass Boost & Virtualizer:** Fine-tune low-end frequencies and expand spatial audio imaging.

### 🎨 Theme & UI Customization
- **Theme Engine:** Smooth transition between Classic Light, Modern Dark, and Follow Device System defaults.
- **Custom Accent Colors:** Modify player interface accent colors, progress bar tints, and background shades.
- **Typography Selection:** Choose from premium integrated fonts (Inter, Roboto, Olio Script) and adjust text scale dynamically.
- **Multi-language Support:** Complete application localization with dynamic locale switching (supporting English, Arabic, and other languages).

### 🔒 Privacy & Offline-First Design
- **100% Local Storage:** Favorites, playlists, and user configurations are stored locally on-device. No accounts, no sign-ups, and no personal tracking.
- **No Cloud Uploads:** Your media remains private on your phone.
- **Permission Transparency:** Securely handles storage/media permissions only to index and render your files.

---

## 🛠️ Architecture & Tech Stack

This project is built using a highly structured, scalable, and reactive codebase following the **BLoC (Business Logic Component)** architecture pattern.

| Layer / Component | Technology / Package | Description |
| :--- | :--- | :--- |
| **Framework** | [Flutter (Dart)](https://flutter.dev) | High-performance cross-platform application engine. |
| **State Management** | [flutter_bloc](https://pub.dev/packages/flutter_bloc) | Predictable, reactive, and unidirectional state transitions. |
| **Local Database** | [Hive](https://pub.dev/packages/hive) | Lightning-fast NoSQL local key-value database for caching media counts and player states. |
| **Media Player Backend** | [better_player_plus](https://pub.dev/packages/better_player_plus) & [just_audio](https://pub.dev/packages/just_audio) | Robust playback adapters for audio and video streams. |
| **Local Indexing** | [photo_manager](https://pub.dev/packages/photo_manager) | Asynchronous device-wide media indexing. |
| **Crashlytics / Config** | [Firebase Core & Remote Config](https://pub.dev/packages/firebase_core) | Dynamic feature configuration and analytics. |
| **Monetization** | [Google Mobile Ads](https://pub.dev/packages/google_mobile_ads) | Monetized via non-intrusive App Open, Interstitial, and Banner advertisements. |

---

## 📂 Directory Structure

```plaintext
lib/
├── blocs/               # BLoC / Cubit state management components
│   ├── audio/           # Audio playback logic
│   ├── bottom_nav/      # Bottom navigation bar state
│   ├── count/           # Home dashboard counter logic
│   ├── favourite/       # Favorites management logic
│   ├── theme/           # App-wide dark/light theme state
│   └── video/           # Video scanning and parsing logic
├── core/                # Core configurations, constants, app keys
├── models/              # Hive adapters and media asset models
├── screens/             # UI Views & Layouts
│   ├── home_screen.dart # Dashboard counting local media assets
│   ├── audio_screen.dart# Audio browsing and lists
│   ├── video_screen.dart# Video browsing and list screen
│   ├── player_screen.dart# Advanced custom gesture video player interface
│   ├── settings_screen.dart # Configuration dashboard (equalizer, theme, language, etc.)
│   └── splash_screen.dart# Initializer and configuration screen
├── services/            # Low-level service layers (Ads, Connectivity, Notification, Hive, Adaptors)
├── utils/               # App theme colors, imports, and multi-language localizations
├── widgets/             # Reusable custom UI components and loaders
└── main.dart            # Application bootstrap & multi-provider configuration
```

---

## 🚀 Getting Started

### Prerequisites
Before setting up the project, make sure you have the following installed:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `^3.10.7` or later)
- Dart SDK
- Android SDK / Xcode (for iOS)
- Firebase Account (for Google Services config)

### Installation Steps

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/kevalsatani2001/media_player_app.git
   cd media_player_app
   ```

2. **Configure Firebase:**
   - Place your `google-services.json` inside the `android/app/` folder.
   - Place your `GoogleService-Info.plist` inside the `ios/Runner/` folder.

3. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

4. **Generate Hive Adapters:**
   If you make any modifications to the data models:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the Application:**
   - **Debug Mode:**
     ```bash
     flutter run
     ```
   - **Release Mode (Android):**
     ```bash
     flutter build apk --release
     ```

---

## 📄 License & Terms

All rights reserved. Created and maintained by Keval Satani. Unauthorized duplication or publishing is prohibited. For details, refer to the in-app [Privacy Policy Screen](file:///d:/Devlopments/media_player/lib/screens/privacy_policy_screen.dart).