import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:lucide_icons/lucide_icons.dart';
import 'core/utils/app_logger.dart';
import 'core/observers/navigation_observer.dart';
import 'core/services/auth_service.dart';
import 'core/services/environment_service.dart';
import 'core/config/image_config.dart';
import 'core/network/connectivity_monitor.dart';
import 'core/api/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'injection_container.dart' as di;
import 'presentation/pages/discover/discover_screen.dart';
import 'presentation/pages/home/home_screen.dart';
import 'presentation/pages/create_event/create_event_conversation.dart';
import 'core/auth/auth_bloc.dart';
import 'presentation/bloc/events/events_bloc.dart';
import 'presentation/bloc/events/events_event.dart';
import 'presentation/bloc/user/user_bloc.dart';
import 'presentation/bloc/user/user_event.dart';
import 'presentation/bloc/posts/posts_bloc.dart';
import 'presentation/bloc/posts/posts_event.dart';
import 'presentation/bloc/communities/communities_bloc.dart';
import 'presentation/bloc/communities/communities_event.dart';
import 'presentation/bloc/qna/qna_bloc.dart';
import 'presentation/bloc/tickets/tickets_bloc.dart';
import 'presentation/bloc/payment/payment_bloc.dart';
import 'domain/entities/event.dart';
import 'presentation/pages/profile/profile_screen.dart';
import 'presentation/pages/community/new_community_screen.dart';
import 'presentation/pages/calendar/calendar_screen.dart';
import 'presentation/pages/splash/splash_screen.dart';
import 'presentation/pages/auth/onboarding_screen.dart';
import 'presentation/pages/auth/login_screen.dart';
import 'presentation/pages/auth/complete_profile_screen.dart';
import 'presentation/pages/create_post/create_post_screen.dart';
import 'presentation/pages/my_events/my_events_screen.dart';
import 'presentation/pages/event_management/event_management_dashboard.dart';

// Enable Flutter Driver extension for E2E testing
// Only import when actually running Flutter Driver tests
// import 'package:flutter_driver/driver_extension.dart';

// Global navigation key for navigating without context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // NOTE: Flutter Driver extension disabled for integration tests
  // If you need Flutter Driver tests, use a separate test entry point
  // try {
  //   enableFlutterDriverExtension();
  // } catch (e) {
  //   // Extension not available in release mode, ignore
  // }

  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment variables
  await EnvironmentService.initialize();

  // Initialize logger
  AppLogger().init();

  // Initialize image configuration
  ImageConfig.initialize();

  // Initialize connectivity monitor BEFORE app starts
  // This ensures we can detect network recovery and retry failed requests
  await ConnectivityMonitor.instance.initialize();

  // Set status bar style - Light theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  try {
    await di.init();

    // Link ConnectivityMonitor with RetryInterceptor
    // This enables automatic retry when network recovers
    final dioClient = di.sl<DioClient>();
    ConnectivityMonitor.instance.registerRetryInterceptor(
      dioClient.retryInterceptor,
    );

    // Start periodic health checks
    ConnectivityMonitor.instance.startPeriodicHealthCheck(
      interval: const Duration(minutes: 1),
    );

    runApp(const NotionSocialApp());
  } catch (e) {
    runApp(
      MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Color(0xFFFF0055),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gagal Inisialisasi App',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF666666)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotionSocialApp extends StatelessWidget {
  const NotionSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => di.sl<AuthBloc>()),
        BlocProvider<EventsBloc>(create: (context) => di.sl<EventsBloc>()),
        BlocProvider<UserBloc>(
          create: (context) => di.sl<UserBloc>()..add(LoadUserProfile()),
        ),
        BlocProvider<PostsBloc>(create: (context) => di.sl<PostsBloc>()),
        BlocProvider<CommunitiesBloc>(
          create: (context) => di.sl<CommunitiesBloc>()..add(LoadCommunities()),
        ),
        BlocProvider<QnABloc>(create: (context) => di.sl<QnABloc>()),
        BlocProvider<TicketsBloc>(create: (context) => di.sl<TicketsBloc>()),
        BlocProvider<PaymentBloc>(create: (context) => di.sl<PaymentBloc>()),
      ],
      child: MaterialApp(
        title: 'flyerr',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        navigatorObservers: [AppNavigationObserver()],
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const MainNavigationWrapper(),
          '/login': (context) => const LoginScreen(),
          '/complete-profile': (context) => const CompleteProfileScreen(),
          '/my-events': (context) => const MyEventsScreen(),
          '/event-management': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as String?;
            if (args == null) {
              // Fallback to my events if no event ID provided
              return const MyEventsScreen();
            } else {
              return EventManagementDashboard(eventId: args);
            }
          },
        },
      ),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  int _homeTabIndex =
      0; // Track which tab is active in HomeScreen (0=Feed, 1=Events)
  bool _isSpeedDialOpen = false;

  void _onHomeTabChanged(int tabIndex) {
    final oldTab = _homeTabIndex == 0 ? 'Feed' : 'Events';
    final newTab = tabIndex == 0 ? 'Feed' : 'Events';
    AppLogger().info('Home sub-tab changed: $oldTab -> $newTab');
    setState(() {
      _homeTabIndex = tabIndex;
    });
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
    });
  }

  void _closeSpeedDial() {
    setState(() {
      _isSpeedDialOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }

        // Close speed dial if open
        if (_isSpeedDialOpen) {
          _closeSpeedDial();
          return;
        }

        if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFFFFFFFF),
              title: const Text(
                'Keluar dari App',
                style: TextStyle(color: Color(0xFF000000)),
              ),
              content: const Text(
                'Yakin mau keluar?',
                style: TextStyle(color: Color(0xFF666666)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(color: Color(0xFFBBC863)),
                  ),
                ),
              ],
            ),
          );

          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Smooth page transition with fade and slide
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                // Fade + slight slide from bottom for smooth transition
                final offsetAnimation = Tween<Offset>(
                  begin: const Offset(0.0, 0.03),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ));

                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  ),
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  HomeScreen(
                    key: const Key('home_feed'),
                    onTabChanged: _onHomeTabChanged,
                  ), // Home with Feed/Events tabs
                  const DiscoverScreen(), // Redesigned Discover Page
                  const NewCommunityScreen(key: Key('communities_screen')),
                  ProfileScreen(
                    key: const Key('profile_screen'),
                  ), // Removed const to allow refresh
                ],
              ),
            ),
            // Backdrop overlay when speed dial is open
            if (_isSpeedDialOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closeSpeedDial,
                  child: Container(color: Colors.black.withValues(alpha: 0.5)),
                ),
              ),
          ],
        ),
        bottomNavigationBar: Container(
          key: const Key('bottom_nav'),
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      // Nav items
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Flexible(
                            child: _buildNavItem(
                              LucideIcons.home,
                              LucideIcons.home,
                              'Beranda',
                              0,
                              itemKey: const Key('home_tab'),
                            ),
                          ),
                          Flexible(
                            child: _buildNavItem(
                              LucideIcons.compass,
                              LucideIcons.compass,
                              'Jelajah',
                              1,
                              itemKey: const Key('events_tab'),
                            ),
                          ),
                          Flexible(
                            child: _buildNavItem(
                              LucideIcons.users,
                              LucideIcons.users,
                              'Komunitas',
                              2,
                              itemKey: const Key('communities_tab'),
                            ),
                          ),
                          Flexible(
                            child: _buildNavItem(
                              LucideIcons.user,
                              LucideIcons.user,
                              'Profil',
                              3,
                              itemKey: const Key('profile_tab'),
                            ),
                          ),
                        ],
                      ),
                      // Sliding indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        bottom: 4,
                        left: (_currentIndex * constraints.maxWidth / 4) +
                            (constraints.maxWidth / 4 - 28) / 2,
                        child: Container(
                          width: 28,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        floatingActionButton:
            (_currentIndex == 0 && _homeTabIndex == 1) ||
                _currentIndex == 2 ||
                _currentIndex == 3
            ? null // Hide FAB on: Home Events tab, Communities, and Profile
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Speed dial options
                  if (_isSpeedDialOpen) ...[
                    _buildSpeedDialOption(
                      label: 'Bikin Event',
                      icon: LucideIcons.calendar,
                      onTap: () async {
                        _closeSpeedDial();
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CreateEventConversation(),
                          ),
                        );
                        if (result != null && result is Event) {
                          // Refresh events list via bloc instead of manual insert
                          // This prevents duplicate events
                          if (mounted) {
                            context.read<EventsBloc>().add(
                              const LoadEventsByMode(mode: 'for_you'),
                            );
                          }
                          setState(() {
                            _currentIndex = 0;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSpeedDialOption(
                      label: 'Bikin Postingan',
                      icon: LucideIcons.filePlus,
                      onTap: () {
                        _closeSpeedDial();
                        // Show bottom sheet
                        CreatePostSheet.show(context);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildSpeedDialOption(
                      label: 'Kalender',
                      icon: LucideIcons.calendarDays,
                      onTap: () {
                        _closeSpeedDial();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CalendarScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Main FAB
                  FloatingActionButton(
                    key: const Key('fab_create'),
                    heroTag: "main_fab",
                    onPressed: _toggleSpeedDial,
                    backgroundColor: const Color(0xFFBBC863),
                    elevation: _isSpeedDialOpen ? 8 : 6,
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 200),
                      turns: _isSpeedDialOpen ? 0.125 : 0,
                      child: Icon(
                        _isSpeedDialOpen ? LucideIcons.x : LucideIcons.plus,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData outlineIcon,
    IconData filledIcon,
    String label,
    int index, {
    Key? itemKey,
  }) {
    final isActive = _currentIndex == index;
    return InkWell(
      key: itemKey,
      onTap: () {
        AppLogger().info('Tab changed: $_currentIndex -> $index');

        // DO NOT manually reload - BLoCs are now singletons with persistent state
        // Cache is preserved across tab switches

        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              outlineIcon,
              color: isActive ? AppColors.secondary : AppColors.textPrimary,
              size: 28,
            ),
            const SizedBox(height: 6),
            // Space reserved for indicator
            const SizedBox(height: 3),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDialOption({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AnimatedScale(
      scale: _isSpeedDialOpen ? 1.0 : 0.8,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _isSpeedDialOpen ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFBBC863),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Icon button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFBBC863),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFBBC863).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: const Color(0xFF000000), size: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
