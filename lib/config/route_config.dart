import 'package:flutter/material.dart';

/// 라우트 정보를 담는 클래스
class RouteInfo {
  final String path;
  final String name;
  final IconData icon;
  final String title;

  const RouteInfo({
    required this.path,
    required this.name,
    required this.icon,
    required this.title,
  });
}

/// 앱 전체 라우트 상수
class Routes {
  Routes._(); // private constructor

  static const dashboard = RouteInfo(
    path: '/dashboard',
    name: 'dashboard',
    icon: Icons.dashboard,
    title: 'Dashboard',
  );

  static const historical = RouteInfo(
    path: '/historical',
    name: 'historical',
    icon: Icons.history,
    title: 'Historical',
  );

  static const simulation = RouteInfo(
    path: '/simulation',
    name: 'simulation',
    icon: Icons.science,
    title: 'Simulation',
  );

  static const acne = RouteInfo(
    path: '/acne',
    name: 'acne',
    icon: Icons.face,
    title: 'Acne',
  );

  static const threejsPoolUsageExample = RouteInfo(
    path: '/threejs-pool-usage-example',
    name: 'threejs-pool-usage-example',
    icon: Icons.view_in_ar,
    title: 'ThreeJS Pool',
  );

  /// 메뉴에 표시할 라우트 목록
  static const List<RouteInfo> menuRoutes = [
    dashboard,
    historical,
    simulation,
    acne,
    threejsPoolUsageExample,
  ];
}
