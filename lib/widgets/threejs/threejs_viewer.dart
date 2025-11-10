import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test_app/utils/camera_utils.dart';
import 'package:flutter_test_app/utils/loader.dart';
import 'package:flutter_test_app/utils/material_utils.dart';
import 'package:three_js/three_js.dart' as three;

// ============================================================================
// 카메라 설정 상수
// ============================================================================
/// 카메라 시야각 (Field of View)
const double _kCameraFov = 75.0;

/// 카메라 near plane (가까운 클리핑 평면)
const double _kCameraNear = 0.1;

/// 카메라 far plane (먼 클리핑 평면)
const double _kCameraFar = 1000.0;
const String _kDefaultSessionId = '1';
const String _kDefaultTextureFileName = 'Rgb_F.jpg';

/// Three.js 3D 뷰어 위젯
class ThreejsViewer extends StatefulWidget {
  /// 배경색
  final Color backgroundColor;

  /// 카메라 초기 위치
  final three.Vector3? cameraPosition;

  /// 회전 속도
  final double rotationSpeed;

  const ThreejsViewer({
    super.key,
    this.backgroundColor = Colors.black87,
    this.cameraPosition,
    this.rotationSpeed = 0.01,
  });

  @override
  State<ThreejsViewer> createState() => _ThreejsViewerState();
}

class _ThreejsViewerState extends State<ThreejsViewer> {
  bool _isLoaded = false;
  late three.ThreeJS _threeJs;

  @override
  void initState() {
    super.initState();
    _threeJs = three.ThreeJS(
      onSetupComplete: () {
        print('set up complete');
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      },
      setup: _setupScene,
    );
  }

  @override
  void dispose() {
    _threeJs.dispose();
    super.dispose();
  }

  /// 3D 씬 설정
  Future<void> _setupScene() async {
    // 씬 생성 및 배경색 설정
    print('setup scene');
    _threeJs.scene = three.Scene();
    _threeJs.scene.background = three.Color.fromHex32(
      widget.backgroundColor.value,
    );

    // 조명 추가
    final ambientLight = three.AmbientLight(0xffffff, 0.5);
    _threeJs.scene.add(ambientLight);

    final directionalLight = three.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.setValues(5, 5, 5);
    _threeJs.scene.add(directionalLight);

    // 카메라 설정
    _threeJs.camera = three.PerspectiveCamera(
      _kCameraFov,
      _threeJs.width / _threeJs.height,
      _kCameraNear,
      _kCameraFar,
    );

    final sessionId = _kDefaultSessionId;

    final obj = await loadObjFileBySessionId(sessionId);
    if (obj != null) {
      _threeJs.scene.add(obj);
    }
    final texture = await loadTextureFileBySessionId(
      sessionId,
      _kDefaultTextureFileName,
    );

    print('texture: $texture');
    print('obj: $obj');

    // obj가 존재하고 texture가 로드된 경우, obj의 모든 Mesh에 텍스처를 적용
    if (obj != null && texture != null) {
      applyTextureToObject(obj, texture);
    }

    // obj가 있으면 자동으로 카메라를 맞춤, 없으면 기본 위치 사용
    if (obj != null) {
      fitCameraToObject(
        obj,
        _threeJs.camera as three.PerspectiveCamera,
        _threeJs.width,
        _threeJs.height,
      );
    } else {
      final camPos = widget.cameraPosition ?? three.Vector3(0, 0, 5);
      _threeJs.camera.position.setValues(camPos.x, camPos.y, camPos.z);
    }
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
            color: widget.backgroundColor,
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
