import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/data_service.dart';
import 'providers/theme_provider.dart';
import 'providers/prayer_provider.dart';
import 'providers/worship_provider.dart';
import 'providers/quran_provider.dart';
import 'services/quran_audio_download_service.dart';
import 'widgets/mini_audio_player.dart';
import 'services/media_audio_handler.dart';
import 'widgets/active_adhan_banner.dart';
import 'widgets/app_bottom_nav_bar.dart';

import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/worship_screen.dart';
import 'screens/quran_screen.dart';
import 'screens/settings_screen.dart';

import 'dart:async';
import 'services/settings_controller.dart';
import 'services/app_notification_service.dart';
import 'services/adhan_scheduler_service.dart';
import 'services/muezzin_download_service.dart';
import 'services/hijri_date_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent storage, notifications, hijri and asset data
  await initializeMediaAudio();
  await StorageService().init();
  await DataService().init();
  await SettingsController().init();
  AppNotificationService().navigatorKey = appNavigatorKey;
  await AppNotificationService().init();
  await AppNotificationService().requestPermissionsAndBatteryOptimization();
  await HijriDateService.loadStoredAdjustment();
  // Mandatory check on first run & critical transition days (28, 29, 30, 1)
  await HijriDateService.checkAndEnforceMandatorySync();
  AdhanSchedulerService().init();

  // Non-blocking background syncs: Download all full Adhans
  unawaited(MuezzinDownloadService().downloadAllMuezzinsInBackground());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsController()),
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ChangeNotifierProvider(create: (_) => WorshipProvider()),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(create: (_) => QuranAudioDownloadService()),
      ],
      child: const NoorAlAtraApp(),
    ),
  );
}

class NoorAlAtraApp extends StatelessWidget {
  const NoorAlAtraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'نور العترة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(settings.themePalette),
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return SwipeToPopScope(child: child ?? const SizedBox());
      },
      home: const MainNavigationScreen(),
    );
  }
}

/// Allows swiping from the edge to exit / go back from any pushed window or sub-screen
class SwipeToPopScope extends StatefulWidget {
  final Widget child;
  const SwipeToPopScope({super.key, required this.child});

  @override
  State<SwipeToPopScope> createState() => _SwipeToPopScopeState();
}

class _SwipeToPopScopeState extends State<SwipeToPopScope> {
  double? _dragStartX;
  double? _dragStartY;
  bool _isEligibleForPop = false;
  bool _hasPopped = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        final canPop = appNavigatorKey.currentState?.canPop() ?? false;
        if (!canPop) {
          _isEligibleForPop = false;
          return;
        }

        final size = MediaQuery.sizeOf(context);
        final x = event.position.dx;
        final y = event.position.dy;

        // Touch starts within edge zone (65px from right or left edge)
        const edgeZone = 65.0;
        if (x <= edgeZone || x >= (size.width - edgeZone)) {
          _dragStartX = x;
          _dragStartY = y;
          _isEligibleForPop = true;
          _hasPopped = false;
        } else {
          _isEligibleForPop = false;
        }
      },
      onPointerMove: (event) {
        if (!_isEligibleForPop || _hasPopped || _dragStartX == null || _dragStartY == null) {
          return;
        }

        final deltaX = event.position.dx - _dragStartX!;
        final deltaY = (event.position.dy - _dragStartY!).abs();

        // If movement is predominantly vertical, cancel pop gesture
        if (deltaY > 40 && deltaY > deltaX.abs()) {
          _isEligibleForPop = false;
          return;
        }

        final size = MediaQuery.sizeOf(context);
        const popThreshold = 55.0;

        // Swiping from right edge inwards (RTL back gesture)
        final startedFromRight = _dragStartX! >= (size.width - 65.0);
        // Swiping from left edge inwards (LTR back gesture)
        final startedFromLeft = _dragStartX! <= 65.0;

        if ((startedFromRight && deltaX < -popThreshold) ||
            (startedFromLeft && deltaX > popThreshold)) {
          _hasPopped = true;
          _isEligibleForPop = false;
          appNavigatorKey.currentState?.maybePop();
        }
      },
      onPointerUp: (_) => _reset(),
      onPointerCancel: (_) => _reset(),
      child: widget.child,
    );
  }

  void _reset() {
    _isEligibleForPop = false;
    _hasPopped = false;
    _dragStartX = null;
    _dragStartY = null;
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  static _MainNavigationScreenState? _instance;

  /// Static helper to switch tabs from anywhere in the widget tree
  static void switchTab(BuildContext context, int tabIndex) {
    if (_instance != null) {
      _instance!.setIndex(tabIndex);
      return;
    }
    final state = context.findAncestorStateOfType<_MainNavigationScreenState>();
    if (state != null) {
      state.setIndex(tabIndex);
    }
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    MainNavigationScreen._instance = this;
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNotificationService().requestPermissionsAndBatteryOptimization();
    });
  }

  @override
  void dispose() {
    if (MainNavigationScreen._instance == this) {
      MainNavigationScreen._instance = null;
    }
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AdhanSchedulerService().syncAdhanPlayingState();
    }
  }

  void setIndex(int index) {
    if (!mounted || index < 0 || index >= _screens.length) return;

    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
    // Tab taps go straight to their destination without building the intervening
    // screens during an animation. PageView still supports manual swiping.
    // Compare the exact page so tapping during a swipe also snaps into place.
    if (_pageController.hasClients && _pageController.page != index.toDouble()) {
      _pageController.jumpToPage(index);
    }
  }

  final List<Widget> _screens = const [
    _KeepAlivePage(child: HomeScreen()),
    _KeepAlivePage(child: CalendarScreen()),
    _KeepAlivePage(child: WorshipScreen()),
    _KeepAlivePage(child: QuranScreen()),
    _KeepAlivePage(child: SettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setIndex(0);
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              if (_currentIndex != index) {
                setState(() => _currentIndex = index);
              }
            },
            children: _screens,
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ActiveAdhanBanner(isDark: Theme.of(context).brightness == Brightness.dark),
              const MiniAudioPlayer(bottomPadding: 6),
              AppBottomNavBar(
                currentIndex: _currentIndex,
                onTap: setIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper widget to keep pages alive when swiping between tabs in PageView
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
