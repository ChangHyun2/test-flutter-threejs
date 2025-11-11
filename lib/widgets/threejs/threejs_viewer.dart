import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test_app/utils/camera_utils.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_controls/three_js_controls.dart';

// ============================================================================
// 카메라 설정 상수
// ============================================================================
/// 카메라 시야각 (Field of View)
const double _kCameraFov = 50.0;

/// 카메라 near plane (가까운 클리핑 평면)
const double _kCameraNear = 0.1;

/// 카메라 far plane (먼 클리핑 평면)
const double _kCameraFar = 1000.0;

const Color _kBackgroundColor = Colors.white;

class ThreejsViewerItem {
  final three.Object3D object;
  final bool isFigure;

  ThreejsViewerItem({required this.object, required this.isFigure});
}

/// Three.js 3D 뷰어 위젯
class ThreejsViewer extends StatefulWidget {
  final List<ThreejsViewerItem> items;

  const ThreejsViewer({super.key, required this.items});

  @override
  State<ThreejsViewer> createState() => _ThreejsViewerState();
}

class _ThreejsViewerState extends State<ThreejsViewer> {
  bool _isLoaded = false;
  late three.ThreeJS _threeJs;
  OrbitControls? _controls;

  @override
  void initState() {
    print('initState');
    super.initState();
    _threeJs = three.ThreeJS(
      onSetupComplete: () {
        print('set up complete');
        if (mounted) {
          setState(() => _isLoaded = true);
          _draw();
        }
      },
      setup: _setupScene,
    );
  }

  @override
  void didUpdateWidget(ThreejsViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('did update widget');
    _draw();
  }

  @override
  void dispose() {
    _controls?.dispose();
    _threeJs.dispose();
    super.dispose();
  }

  /// 3D 씬 설정
  Future<void> _setupScene() async {
    // 씬 생성 및 배경색 설정
    print('setup scene');
    _threeJs.scene = three.Scene();
    _threeJs.scene.background = three.Color.fromHex32(_kBackgroundColor.value);

    // 조명 추가 - 더 밝고 입체감 있게
    final ambientLight = three.AmbientLight(0xffffff, 0.6);
    _threeJs.scene.add(ambientLight);

    final directionalLight1 = three.DirectionalLight(0xffffff, 0.8);
    directionalLight1.position.setValues(5, 5, 5);
    _threeJs.scene.add(directionalLight1);

    final directionalLight2 = three.DirectionalLight(0xffffff, 0.4);
    directionalLight2.position.setValues(-5, -5, -5);
    _threeJs.scene.add(directionalLight2);

    // 카메라 설정
    _threeJs.camera = three.PerspectiveCamera(
      _kCameraFov,
      _threeJs.width / _threeJs.height,
      _kCameraNear,
      _kCameraFar,
    );

    // OrbitControls 설정 - 마우스로 회전/줌 가능
    _controls = OrbitControls(_threeJs.camera, _threeJs.globalKey);
    _controls!.enableDamping = true;
    _controls!.dampingFactor = 0.15;
    _controls!.screenSpacePanning = false;
    _controls!.minDistance = 80;
    _controls!.maxDistance = 500;
    _controls!.maxPolarAngle = 3.14159265359; // PI
  }

  void _draw() {
    widget.items.forEach((item) {
      _threeJs.scene.add(item.object);

      if (item.isFigure) {
        fitCameraToObject(
          item.object,
          _threeJs.camera as three.PerspectiveCamera,
          _threeJs.width,
          _threeJs.height,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return Stack(
      children: [
        // Three.js 뷰어
        _threeJs.build(),
        // 로딩 오버레이
        if (!_isLoaded)
          Container(
            color: _kBackgroundColor,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '3D 뷰어 로딩 중...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
