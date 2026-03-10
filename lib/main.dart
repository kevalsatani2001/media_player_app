import 'package:just_audio_background/just_audio_background.dart';
import 'package:media_player/models/player_data.dart';
import 'package:media_player/services/ads_service.dart';
import 'package:media_player/utils/app_imports.dart';
Offset position = const Offset(0, 0);
bool isPositionInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  AdHelper.loadAppOpenAd();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
    androidShowNotificationBadge: true,
  );

  await Hive.initFlutter();

  // Register adapters only once
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MediaItemAdapter());
  if (!Hive.isAdapterRegistered(2))
    Hive.registerAdapter(PlaylistModelAdapter());
  if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(PlayerStateAdapter());
  await HiveService.init();
  await Hive.openBox('player_state');
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await PhotoManager.requestPermissionExtend();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<FavouriteBloc>(
          lazy: false, // âœ¨ àª† àª‰àª®à«‡àª°àªµàª¾àª¥à«€ àªàªª àª¶àª°à«‚ àª¥àª¤àª¾ àªœ àª•à«‹àª² àª¥àª¶à«‡
          create: (context) => FavouriteBloc(Hive.box('favourites'))..add(LoadFavourite()),
        ),
        BlocProvider<HomeCountBloc>(
          // âœ¨ àªàªª àª–à«àª²àª¤àª¾àª¨à«€ àª¸àª¾àª¥à«‡ àªœ àª²à«‹àª¡àª¿àª‚àª— àª¶àª°à«‚ àª•àª°à«€ àª¦à«‡àª¶à«‡
          create: (context) => HomeCountBloc()..add(LoadCounts()),
        ),
        ChangeNotifierProvider(create: (_) => GlobalPlayer()),
        BlocProvider(create: (_) => ThemeBloc()),
        BlocProvider(
          create: (_) =>
          LocaleBloc()..add(ChangeLocale(Locale(HiveService.languageCode))),
        ),
        // BlocProvider(create: (_) => FavouriteChangeBloc()),
        BlocProvider<FavouriteChangeBloc>(create: (_) => FavouriteChangeBloc()),
        BlocProvider<VideoBloc>(
          create: (_) =>
          VideoBloc(Hive.box('videos'))
            ..add(LoadVideosFromGallery(showLoading: true)),
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

final RouteObserver<ModalRoute<void>> routeObserver =
RouteObserver<ModalRoute<void>>();

class MyApp extends StatefulWidget {
  MyApp({super.key});

  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver{
  // final FlutterLocalization _localization = FlutterLocalization.instance;
  final GlobalPlayer player = GlobalPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AdHelper.loadAppOpenAd(); // àªªàª¹à«‡àª²à«€ àªàª¡ àª²à«‹àª¡ àª•àª°à«‹
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 1. àªàª¡ àª¬àª¤àª¾àªµàªµàª¾ àª®àª¾àªŸà«‡
    if (state == AppLifecycleState.resumed) {
      AdHelper.showAppOpenAdIfAvailable();
    }

    // 2. àª¸à«àªŸà«‡àªŸ àª¸à«‡àªµ àª•àª°àªµàª¾ àª®àª¾àªŸà«‡ (àª¬àª‚àª¨à«‡ àª²à«‹àªœàª¿àª• àªàª• àªœ àª«àª‚àª•à«àª¶àª¨àª®àª¾àª‚ àª°àª¾àª–à«‹)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      GlobalPlayer().savePlayerState();
    }
  }

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
              localizationsDelegates: [
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
                '/language': (_) => LanguageScreen(),
                '/onboarding': (_) => const OnboardingScreen(),
                '/folder': (_) => const FolderScreen(),
              },
            );
          },
        );
      },
    );
  }
}