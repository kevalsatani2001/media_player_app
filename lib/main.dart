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
        // BlocProvider<ScreenSettingsCubit>(
        //   create: (context) => ScreenSettingsCubit(),
        // ),
        ChangeNotifierProvider(create: (_) => GlobalPlayer()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
      child: BlocProvider(
        create: (context) => ScreenSettingsBloc(
          SettingsProvider(), // Create a new instance right here
        ),
        child:  MyApp(),
      ),
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

/*
## zoomin icon

<svg width="35" height="35" viewBox="0 0 35 35" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle cx="17.5" cy="17.5" r="17.5" fill="#3D57F9" />

    <!-- Centered group -->
    <g transform="translate(-5 -5)">
        <path
            d="M26.0039 20.1141C26.3002 20.114 26.5844 19.9963 26.7939 19.7867L31.5911 14.9895V17.8792C31.5911 18.4963 32.0914 18.9966 32.7086 18.9966C33.3257 18.9966 33.826 18.4963 33.826 17.8792V12.2919C33.826 11.6748 33.3257 11.1745 32.7086 11.1745H27.1214C26.5042 11.1745 26.0039 11.6748 26.0039 12.2919C26.0039 12.9091 26.5042 13.4094 27.1214 13.4094H30.0111L25.2139 18.2066C24.7775 18.643 24.7776 19.3506 25.2141 19.7869C25.4236 19.9963 25.7077 20.114 26.0039 20.1141ZM12.5945 33.5235H18.1817C18.7989 33.5235 19.2992 33.0232 19.2992 32.4061C19.2992 31.7889 18.7989 31.2886 18.1817 31.2886H15.292L20.0892 26.4914C20.518 26.0474 20.5057 25.3401 20.0618 24.9113C19.6288 24.4931 18.9422 24.4931 18.5092 24.9113L13.712 29.7085V26.8188C13.712 26.2017 13.2117 25.7014 12.5945 25.7014C11.9774 25.7014 11.4771 26.2017 11.4771 26.8188V32.4061C11.4771 33.0232 11.9773 33.5235 12.5945 33.5235Z"
            fill="white"
        />
    </g>
</svg>





## zoomout icon

<svg width="35" height="35" viewBox="0 0 35 35" fill="none" xmlns="http://www.w3.org/2000/svg">
    <!-- Background -->
    <circle cx="17.5" cy="17.5" r="17.5" fill="#3D57F9" />

    <!-- Centered icon -->
    <g transform="translate(-5 -5)">
        <path
            d="M30.9864 20.1004H25.3992C24.782 20.1004 24.2817 19.6 24.2817 18.9829V13.3957C24.2817 12.7785 24.7821 12.2782 25.3992 12.2782C26.0164 12.2782 26.5167 12.7785 26.5167 13.3957V16.2854L31.3139 11.4882C31.7469 11.0699 32.4334 11.0699 32.8665 11.4882C33.3103 11.9169 33.3227 12.6243 32.8939 13.0682L28.0967 17.8655H30.9864C31.6036 17.8655 32.1039 18.3658 32.1039 18.9829C32.1039 19.6001 31.6036 20.1004 30.9864 20.1004Z"
            fill="white"
        />
        <path
            d="M13.0936 24.584H18.6809C19.2981 24.584 19.7983 25.0843 19.7983 25.7014V31.2886C19.7983 31.9058 19.298 32.4061 18.6809 32.4061C18.0637 32.4061 17.5634 31.9058 17.5634 31.2886V28.3989L12.7662 33.1961C12.3332 33.6144 11.6466 33.6144 11.2136 33.1961C10.7697 32.7674 10.7574 32.06 11.1862 31.6161L15.9834 26.8189H13.0936C12.4765 26.8189 11.9762 26.3185 11.9762 25.7014C11.9762 25.0842 12.4765 24.584 13.0936 24.584Z"
            fill="white"
        />
    </g>
</svg>



##ic_swap_vert

<svg width="35" height="35" viewBox="0 0 35 35" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="17.5" cy="17.5" r="17.5" fill="#3D57F9"/>
  <g stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
    <path d="M14 10v12m0 0l-3-3m3 3l3-3"/>
    <path d="M21 25V13m0 0l-3 3m3-3l3 3"/>
  </g>
</svg>


## ic_a_b_repeat

<svg width="35" height="35" viewBox="0 0 35 35" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle cx="17.5" cy="17.5" r="17.5" fill="#3D57F9"/>
    <g stroke="white" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round">
        <path d="M10 14h10l-2-2m2 2l-2 2"/>
        <path d="M25 21H15l2 2m-2-2l2-2"/>
    </g>
    <text x="8" y="12" fill="white" font-size="6" font-family="Arial">A</text>
    <text x="24" y="27" fill="white" font-size="6" font-family="Arial">B</text>
</svg>



## ic_swap_hor

<svg width="35" height="35" viewBox="0 0 35 35" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle cx="17.5" cy="17.5" r="17.5" fill="#3D57F9"/>
    <g stroke="white" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round">
        <path d="M11 14H24M24 14L20 10M24 14L20 18" />
        <path d="M24 21H11M11 21L15 17M11 21L15 25" />
    </g>
</svg>


## ic_camera

<svg width="35" height="35" viewBox="0 0 35 35" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle cx="17.5" cy="17.5" r="17.5" fill="#3D57F9"/>
    <g stroke="white" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round">
        <path d="M10 13C10 11.8954 10.8954 11 12 11H15L17 9H20L22 11H25C26.1046 11 27 11.8954 27 13V23C27 24.1046 26.1046 25 25 25H12C10.8954 25 10 24.1046 10 23V13Z" />
        <circle cx="18.5" cy="18" r="3" />
    </g>
</svg>


 */