import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nrbgymkhana/core/utils/theme_settings_screen.dart';
import 'package:nrbgymkhana/features/Events/presentation/screens_ui/events_screen.dart';
import 'package:nrbgymkhana/features/ClubTour/presentation/screen_ui/tourMainPage.dart';
import 'package:nrbgymkhana/features/Events/presentation/screens_ui/events_details.dart';
import 'package:nrbgymkhana/features/Events/presentation/widgets/ticketswidget.dart';
import 'package:nrbgymkhana/features/Lost&Found/presentation/screen_ui/lostandfoundpage.dart';
import 'package:nrbgymkhana/features/NotificationsandMessaging/presentation/screens_ui/notifmessagescreen_main.dart';
import 'package:nrbgymkhana/features/Profile/presentation/screens_ui/contactpage.dart';
import 'package:nrbgymkhana/features/Profile/presentation/screens_ui/profile_Screen.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/screen_ui/cardspage.dart';
import 'package:nrbgymkhana/features/thewall/presentation/screens/all_facilities.dart';
import 'package:nrbgymkhana/features/NotificationsandMessaging/presentation/widgets/notification_overlay_service.dart';
import 'package:nrbgymkhana/features/app_auths/presentation/providers/auth_provider.dart';
import 'package:nrbgymkhana/features/app_auths/presentation/screens_ui/login_screen.dart';
import 'package:nrbgymkhana/features/app_auths/presentation/screens_ui/onboarding_screen.dart';
import 'package:nrbgymkhana/features/common/sharedpreff/localstorage.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/BookFacilityPage.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/allbookingspage.dart';
import 'package:nrbgymkhana/features/bookings/presentation/screen_ui/booking_category.dart';
import 'package:nrbgymkhana/features/bottomnavbar/utils/overallscaffold.dart';
import 'package:nrbgymkhana/features/home/presentation/screens_ui/home_screen.dart';
import 'package:nrbgymkhana/features/subscriptions/presentation/screen_ui/subs_cat.dart';
import 'package:nrbgymkhana/features/subscriptions/presentation/screen_ui/subspage.dart';
import 'package:nrbgymkhana/features/thewall/presentation/screens/noticeboard.dart';
import 'package:nrbgymkhana/features/thewall/presentation/screens/thewallmain.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authProvider = ref.watch(authStateChangesProvider);
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  NotificationOverlayService.navigatorKey = rootNavigatorKey;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => OverallScaffold(
          navigationShell: navigationShell,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => HomeScreen(),
                routes: [
                  // Route with a custom animation
                  GoRoute(
                    path: 'subspage',
                    pageBuilder: (context, state) => _createCustomPage(
                      state: state,
                      child: SubsPage(),
                    ),
                    routes: [
                      GoRoute(
                        path:
                            'subs-category/:category', // Adding a dynamic segment for category
                        pageBuilder: (context, state) {
                          final category = state.pathParameters['category'] ??
                              'Unknown'; // Retrieve category parameter
                          return _createCustomPage(
                            state: state,
                            child: SubsCatPage(category: category),
                          );
                        },
                      ),
                    ],
                  ),

                  GoRoute(
                      path: 'book-facility',
                      pageBuilder: (context, state) => _createCustomPage(
                            state: state,
                            child: BookFacilityPage(),
                          ),
                      routes: [
                        GoRoute(
                          path:
                              'book-category/:category', // Adding a dynamic segment for category
                          pageBuilder: (context, state) {
                            final category = state.pathParameters['category'] ??
                                'Unknown'; // Retrieve category parameter
                            return _createCustomPage(
                              state: state,
                              child: BookingsCatPage(category: category),
                            );
                          },
                        ),
                      ]),
                  GoRoute(
                    path: 'all-bookings',
                    pageBuilder: (context, state) => _createCustomPage(
                      state: state,
                      child: BookingsOverviewPage(),
                    ),
                  ),
                  // Default transition for reports
                  GoRoute(
                    path: 'card-manager',
                    pageBuilder: (context, state) => _createCustomPage(
                      state: state,
                      child: CardsPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'updates',
                    pageBuilder: (context, state) => _createCustomPage(
                      state: state,
                      child: NoticeListScreen(),
                    ),
                  ),
                  // Default transition for hire facility
                  GoRoute(
                    path: 'lost-found',
                    pageBuilder: (context, state) => _createCustomPage(
                      state: state,
                      child: LostandFoundPage(),
                    ),
                  ),
                  // Route with a custom animation
                  GoRoute(
                    path: 'club-tour',
                    pageBuilder: (context, state) => _createCustomPage(
                      state: state,
                      child: ClubTourPage(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/the-wall',
                builder: (context, state) => TheWall(),
                routes: [
                  GoRoute(
                    path: 'Events-thewall',
                    builder: (context, state) => EventsScreen(),
                    routes: [
                      GoRoute(
                        path: 'event-details',
                        builder: (context, state) {
                          final event = state.extra as DocumentSnapshot;
                          return EventDetailsPage(event: event);
                        },
                      ),
                      GoRoute(
                        path:
                            'ticket/:eventId/:orderId', // ✅ Dynamic segments added
                        name: 'Ticket',
                        builder: (context, state) {
                          final eventId = state.pathParameters['eventId']!;
                          final orderId = state.pathParameters['orderId']!;
                          return EventTicketScreen(
                              eventId: eventId, orderId: orderId);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'noticeboard-thewall',
                    builder: (context, state) => NoticeListScreen(),
                  ),
                  GoRoute(
                    path: 'lost-found-thewall',
                    builder: (context, state) => LostandFoundPage(),
                  ),
                  GoRoute(
                    path: 'club-facilities-thewall',
                    builder: (context, state) => ClubFacilitiesPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => NotificationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/profile',
                  builder: (context, state) => ProfileScreen(),
                  routes: [
                    GoRoute(
                      path: '/faq-page',
                      builder: (context, state) => ContactSupportPage(),
                    ),
                    GoRoute(
                      path: 'theme-settings',
                      builder: (context, state) => const ThemeSettingsScreen(),
                    ),
                  ]),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, GoRouterState state) async {
      final isAuthenticated = authProvider.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );

      final location = state.uri.toString();
      final isOnboarding = location == '/onboarding';
      final isLoggingIn = location == '/login';

      if (isAuthenticated && (isLoggingIn || isOnboarding)) return '/';

      if (!isAuthenticated && !isLoggingIn && !isOnboarding) return '/login';

      if (!isAuthenticated && isLoggingIn) {
        final seen = await LocalStorage.hasSeenOnboarding();
        if (!seen) return '/onboarding';
      }

      return null;
    },
    refreshListenable:
        GoRouterRefreshStream(ref.watch(authStateChangesProvider.stream)),
  );
});

// Helper function to create a page with custom animation
CustomTransitionPage _createCustomPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0), // Right to left
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    },
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
    stream.listen((_) => notifyListeners());
  }
}
