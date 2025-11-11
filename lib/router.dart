import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'config/route_config.dart';
import 'screens/dashboard_screen.dart';
import 'screens/historical_screen.dart';
import 'screens/simulation_screen.dart';
import 'screens/acne_screen.dart';
import 'widgets/layout/main_layout.dart';
import 'screens/threejs_pool_usage_example.dart';
import 'screens/test_transparent_gray_screen.dart';
import 'screens/obj_to_gltf_screen.dart';
import 'widgets/sessions/sessions_list.dart';
import 'mock/sessions.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.dashboard.path,
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        // 현재 route에 따라 right drawer 결정
        Widget? rightDrawerChild;
        if (state.matchedLocation == Routes.simulation.path) {
          rightDrawerChild = SessionsList(sessions: mockSessions);
        }

        return MainLayout(child: child, rightDrawerChild: rightDrawerChild);
      },
      routes: [
        GoRoute(
          path: Routes.dashboard.path,
          name: Routes.dashboard.name,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const DashboardScreen(),
          ),
        ),
        GoRoute(
          path: Routes.historical.path,
          name: Routes.historical.name,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const HistoricalScreen(),
          ),
        ),
        GoRoute(
          path: Routes.simulation.path,
          name: Routes.simulation.name,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const SimulationScreen(),
          ),
        ),
        GoRoute(
          path: Routes.acne.path,
          name: Routes.acne.name,
          pageBuilder: (context, state) =>
              NoTransitionPage(key: state.pageKey, child: const AcneScreen()),
        ),
        GoRoute(
          path: Routes.threejsPoolUsageExample.path,
          name: Routes.threejsPoolUsageExample.name,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ThreeJSPoolUsageExample(),
          ),
        ),
        GoRoute(
          path: Routes.testTransparentGray.path,
          name: Routes.testTransparentGray.name,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const TestTransparentGrayScreen(),
          ),
        ),
        GoRoute(
          path: Routes.objToGltf.path,
          name: Routes.objToGltf.name,
          pageBuilder: (context, state) => NoTransitionPage(
            key: state.pageKey,
            child: const ObjToGltfScreen(),
          ),
        ),
      ],
    ),
  ],
);
