import '../utils/app_imports.dart';

class DevModeBlockScreen extends StatefulWidget {
  const DevModeBlockScreen({super.key});

  static bool isVisible = false;

  @override
  State<DevModeBlockScreen> createState() => _DevModeBlockScreenState();
}

class _DevModeBlockScreenState extends State<DevModeBlockScreen> with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    DevModeBlockScreen.isVisible = true;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    DevModeBlockScreen.isVisible = false;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatusAndNavigate();
    }
  }

  Future<void> _checkStatusAndNavigate() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
    });

    final bool isEnabled = await SecurityService.isDevModeEnabled();
    if (!isEnabled) {
      // Developer options turned off, proceed to the main/landing screen
      if (mounted) {
        final Box settingsBox = Hive.box('settings');
        final selectedLang = settingsBox.get('languageCode');
        final isNewApp = settingsBox.get('isNewApp', defaultValue: true);
        String route;

        if (selectedLang == null || isNewApp) {
          route = '/language';
        } else {
          final seenOnboarding = settingsBox.get('seenOnboarding', defaultValue: false);
          route = !seenOnboarding ? '/onboarding' : '/';
        }
        Navigator.pushReplacementNamed(context, route);
      }
    } else {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppThemeColors>()!;
    return WillPopScope(
      onWillPop: () async => false, // Prevent backing out of the blocker screen
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
                systemNavigationBarColor: const Color(0xFF121212),
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
                systemNavigationBarColor: const Color(0xFFF5F5F5),
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
        child: Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Circular Warning Icon matching app design
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: colors.primary,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 32),
                // Block Title
                AppText(
                  "devModeTitle",
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colors.textSecondary,
                  align: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Block Message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: AppText(
                    "devModeMessage",
                    fontSize: 14,
                    height: 1.5,
                    color: colors.subTextColor.withOpacity(0.70),
                    align: TextAlign.center,
                  ),
                ),
                const Spacer(),
                // Go to Settings Button using AppButton
                AppButton(
                  title: "goToSettings",
                  onTap: () async {
                    await SecurityService.openDevSettings();
                  },
                ),
                const SizedBox(height: 14),
                // Check Again Button using AppButton with outline style
                AppButton(
                  title: "",
                  backgroundColor: Colors.transparent,
                  borderColor: colors.dividerColor,
                  textColor: colors.textSecondary,
                  onTap: _checkStatusAndNavigate,
                  loading: _isChecking,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_isChecking) ...[
                        Icon(Icons.refresh_rounded, color: colors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _isChecking ? "Checking..." : "Check Again",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
