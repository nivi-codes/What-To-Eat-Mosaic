import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/preferences_provider.dart';
import '../widgets/bottom_nav_scaffold.dart';
import '../screens/welcome_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/onboarding_done_screen.dart';
import '../screens/eat_home_screen.dart';
import '../screens/eat_flow_screen.dart';
import '../screens/suggestions_screen.dart';
import '../screens/recipe_view_screen.dart';
import '../screens/menu_screen.dart';
import '../screens/community_screen.dart';
import '../screens/saved_screen.dart';
import '../screens/me_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildRouter(PreferencesProvider prefsProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/eat',
    redirect: (context, state) {
      final onboarded = prefsProvider.isOnboarded;
      final loc = state.matchedLocation;
      final onUnguarded = loc.startsWith('/welcome') ||
          loc.startsWith('/onboarding');

      if (!onboarded && !onUnguarded) return '/welcome';
      if (onboarded && loc == '/welcome') return '/eat';
      return null;
    },
    refreshListenable: prefsProvider,
    routes: [
      // ── Onboarding ──────────────────────────────────────────────
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/done',
        builder: (context, state) => const OnboardingDoneScreen(),
      ),

      // ── Eat flow (fullscreen, over shell) ───────────────────────
      GoRoute(
        path: '/eat/flow',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const EatFlowScreen(),
      ),
      GoRoute(
        path: '/eat/suggestions',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SuggestionsScreen(),
      ),
      GoRoute(
        path: '/eat/recipe/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RecipeViewScreen(
          recipeId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/eat/menu/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MenuScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/community/recipe/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RecipeViewScreen(
          recipeId: state.pathParameters['id']!,
          fromCommunity: true,
        ),
      ),
      GoRoute(
        path: '/saved/recipe/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RecipeViewScreen(
          recipeId: state.pathParameters['id']!,
          title: state.uri.queryParameters['title'],
        ),
      ),
      GoRoute(
        path: '/saved/menu/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => MenuScreen(
          id: state.pathParameters['id']!,
          name: state.uri.queryParameters['name'],
        ),
      ),

      // ── Main shell with bottom nav ───────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => BottomNavScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/eat',
              builder: (context, state) => const EatHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/community',
              builder: (context, state) => const CommunityScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/saved',
              builder: (context, state) => const SavedScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/me',
              builder: (context, state) => const MeScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
}
