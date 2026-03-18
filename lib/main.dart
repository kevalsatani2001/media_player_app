import 'package:just_audio_background/just_audio_background.dart';
import 'package:media_player/models/player_data.dart';
import 'package:media_player/services/ads_service.dart';
import 'package:media_player/services/connectivity_service.dart';
import 'package:media_player/services/notification_service.dart';
import 'package:media_player/utils/app_imports.dart';
Offset position = Offset(245.4, 673.4);
bool isPositionInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppNotificationService.init();
  await AppNotificationService.requestPermissions();
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
  // final String initialLang = HiveService.languageCode.isEmpty
  //     ? PlatformDispatcher.instance.locale.languageCode
  //     : HiveService.languageCode;

  // 1. Hive mathi saved language check karo
  String savedLang = HiveService.languageCode;

  // 2. System ni current language melvo
  final String systemLang = PlatformDispatcher.instance.locale.languageCode;
  final List<String> supported = AppStrings.translations.keys.toList();

  String finalLang;

  // STEP A: Jo Hive ma pela thi kai save hoy to e j lo
  if (savedLang.isNotEmpty) {
    finalLang = savedLang;
  }
  // STEP B: Jo Hive khali hoy, to system language check karo
  else if (supported.contains(systemLang)) {
    finalLang = systemLang;
    // System language support ma chhe, to save kari do jethi next time khali na male
    HiveService.saveLanguage(finalLang);
  }
  // STEP C: Jo kai na male to English (Default)
  else {
    finalLang = 'en';
    HiveService.saveLanguage(finalLang);
  }

  // CRITICAL: Jo 'en' pan supported list ma na hoy (bhul thi), to pepli key upadi lo
  if (!supported.contains(finalLang)) {
    finalLang = supported.isNotEmpty ? supported.first : 'en';
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<FavouriteBloc>(
          lazy: false,
          create: (context) => FavouriteBloc(Hive.box('favourites'))..add(LoadFavourite()),
        ), BlocProvider<LocaleBloc>(
          create: (context) => LocaleBloc()..add(ChangeLocale(Locale(finalLang))),
        ),
        BlocProvider<HomeCountBloc>(
          create: (context) => HomeCountBloc()..add(LoadCounts()),
        ),
        ChangeNotifierProvider(create: (_) => GlobalPlayer()),
        BlocProvider(create: (_) => ThemeBloc()),
        // BlocProvider(
        //   create: (_) =>
        //   LocaleBloc()..add(ChangeLocale(Locale(HiveService.languageCode))),
        // ),
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
    AdHelper.showAppOpenAdIfAvailable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint("App Resumed - Showing Ad");
      AdHelper.showAppOpenAdIfAvailable();
    }

    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      GlobalPlayer().savePlayerState();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);

    if (locales != null && locales.isNotEmpty) {
      final newLocale = locales.first;
      final String langCode = newLocale.languageCode;
      final List<String> supported = AppStrings.translations.keys.toList();

      if (supported.contains(langCode)) {
        // Support che to change karo
        context.read<LocaleBloc>().add(ChangeLocale(newLocale));
        HiveService.saveLanguage(langCode);
      } else {
        // Support nathi to Toast batavo (Fluttertoast package vapri ne)
        print("cccc   ===> $langCode");
        Fluttertoast.showToast(
          msg: "Language '$langCode' is not supported. Falling back to English.",
          toastLength: Toast.LENGTH_SHORT,
        );

        // Default 'en' set kari do
        context.read<LocaleBloc>().add(ChangeLocale(const Locale('en')));
        HiveService.saveLanguage('en');
      }
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
              navigatorKey: NavigatorKey.root,
              builder: (context, child) {
                return ConnectivityWrapper(child: child!);
              },
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
                // '/recent': (_) => const RecentScreen(),
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
  }}

class NavigatorKey {
  static final GlobalKey<NavigatorState> root = GlobalKey<NavigatorState>();
}