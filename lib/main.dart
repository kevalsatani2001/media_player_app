// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
//
//
// import 'core/hive/hive_init.dart';
// import 'core/theme/app_theme.dart';
// import 'bloc/audio/audio_bloc.dart';
// import 'bloc/video/video_bloc.dart';
// import 'bloc/playlist/playlist_bloc.dart';
// import 'screens/home/bottom_bar_screen.dart';
//
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await HiveInit.init();
//
//
//   runApp(const MyApp());
// }
//
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider(create: (_) => AudioBloc()..add(LoadAudios())),
//         BlocProvider(create: (_) => VideoBloc()..add(LoadVideos())),
//         BlocProvider(create: (_) => PlaylistBloc()..add(LoadPlaylists())),
//       ],
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         theme: AppTheme.dark,
//         home: const HomeScreen(),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:media_player/blocs/favourite_change/favourite_change_bloc.dart';
import 'package:media_player/blocs/video/video_bloc.dart';
import 'package:media_player/screens/favourite_screen.dart';
import 'package:media_player/screens/language_screen.dart';
import 'package:media_player/screens/onboarding_screen.dart';
import 'package:media_player/screens/splash_screen.dart';
import 'package:media_player/utils/app_string.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'blocs/audio/audio_bloc.dart';
import 'blocs/count/count_bloc.dart';
import 'blocs/count/count_event.dart';
import 'blocs/favourite/favourite_bloc.dart';
import 'blocs/local/local_bloc.dart';
import 'blocs/local/local_state.dart';
import 'blocs/theme/theme_bloc.dart';
import 'blocs/theme/theme_state.dart';
import 'blocs/video/video_event.dart';
import 'models/media_item.dart';
import 'models/player_data.dart';
import 'models/playlist_model.dart';
import 'services/hive_service.dart';

import 'blocs/media/media_bloc.dart';
import 'blocs/player/player_bloc.dart';

import 'screens/bottom_bar_screen.dart';
import 'screens/video_screen.dart';
import 'screens/audio_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/recent_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  await Hive.initFlutter();

  // Register adapters only once
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MediaItemAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(PlaylistModelAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PlayerStateAdapter());
  await HiveService.init();
  await Hive.openBox('player_state');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeBloc()),
        BlocProvider(create: (_) => LocaleBloc()),
        BlocProvider(
          create: (_) => HomeCountBloc()..add(LoadCounts()),
        ),
        // BlocProvider(create: (_) => FavouriteChangeBloc()),
        BlocProvider<FavouriteChangeBloc>(
          create: (_) => FavouriteChangeBloc(),
        ),
        BlocProvider<VideoBloc>(
          create: (_) =>
          VideoBloc(Hive.box('videos'))..add(LoadVideosFromGallery(showLoading: true)),
        ),
        BlocProvider<FavouriteBloc>(
          create: (_) =>
          FavouriteBloc(Hive.box('favourites'))..add(LoadFavourite()),
        ),
        BlocProvider<AudioBloc>(
          create: (_) => AudioBloc(Hive.box('audios'))..add(LoadAudios()),
        ),
        BlocProvider<PlayerBloc>(create: (_) => PlayerBloc()),
        BlocProvider(create: (_) => MediaBloc()),
      ],
      child: MyApp(),
    ),
  );
}
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
class MyApp extends StatefulWidget {
  MyApp({super.key});
  static _MyAppState? of(BuildContext context) => context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // final FlutterLocalization _localization = FlutterLocalization.instance;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<LocaleBloc, LocaleState>(
          builder: (context, localeState) {
            final savedLang = HiveService.languageCode;
            return MaterialApp(
              navigatorObservers: [routeObserver],
              debugShowCheckedModeBanner: false,
              theme: themeState.themeData,
              // locale: localeState.locale,
              supportedLocales: AppStrings.translations.keys
                  .map((code) => Locale(code))
                  .toList(),
              localizationsDelegates:  [
                AppStrings.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              // localizationsDelegates: _localization.localizationsDelegates,
              locale: localeState.locale,
              initialRoute: '/splash',
              routes: {
                '/': (_) => const HomeScreen(),
                '/video': (_) => VideoScreen(),
                '/audio': (_) => AudioScreen(),
                '/playlist': (_) => PlaylistScreen(),
                '/favourite': (_) => const FavouriteScreen(),
                '/recent': (_) => const RecentScreen(),
                '/splash': (_) => const SplashScreen(),
                '/language': (_) =>  LanguageScreen(),
                '/onboarding': (_) => const OnboardingScreen(),
              },
            );
          },
        );
      },
    );
  }
}
