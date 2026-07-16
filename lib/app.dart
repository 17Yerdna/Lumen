import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'adaptive_shell.dart';
import 'backend.dart';
import 'bible_providers.dart';
import 'screens.dart';

const lumenGreen = Color(0xFF315C4A);
const lumenGold = Color(0xFFC98A2E);
const lumenCream = Color(0xFFFFFBF3);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void setMode(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

ThemeData lumenTheme(Brightness brightness) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: lumenGreen,
    brightness: brightness,
    surface: brightness == Brightness.light
        ? lumenCream
        : const Color(0xFF151A17),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: brightness == Brightness.light
          ? const Color(0xFFFFFEFA)
          : const Color(0xFF1D241F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: .6),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: .45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      indicatorColor: colorScheme.primaryContainer,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.primaryContainer,
    ),
    textTheme: ThemeData(brightness: brightness).textTheme.copyWith(
      headlineLarge: TextStyle(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 27,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 21,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 17,
        height: 1.65,
        color: colorScheme.onSurface,
      ),
    ),
  );
}

class LumenApp extends ConsumerStatefulWidget {
  const LumenApp({super.key});

  @override
  ConsumerState<LumenApp> createState() => _LumenAppState();
}

class _LumenAppState extends ConsumerState<LumenApp> {
  late final GoRouter _router = _buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(syncProvider);
    return MaterialApp.router(
      title: 'Lumen Biblia',
      debugShowCheckedModeBanner: false,
      theme: lumenTheme(Brightness.light),
      darkTheme: lumenTheme(Brightness.dark),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdaptiveShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reader',
                builder: (context, state) => const ReaderScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const NotesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/assistant',
        builder: (context, state) => AssistantScreen(
          passage: state.extra is AssistantPassage
              ? state.extra as AssistantPassage
              : null,
        ),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountScreen(),
      ),
    ],
  );
}
