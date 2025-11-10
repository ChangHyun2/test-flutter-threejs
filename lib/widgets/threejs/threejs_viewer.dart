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
  late three.ThreeJS threeJs;
  late Widget _viewer;

  @override
  void initState() {
    super.initState();
    threeJs = three.ThreeJS(
      onSetupComplete: () {
        print('set up complete');
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      },
      setup: _setupScene,
    );
    _viewer = threeJs.build();
  }

  /// 3D 씬 설정
  Future<void> _setupScene() async {
    // 씬 생성 및 배경색 설정
    print('setup scene');
    threeJs.scene = three.Scene();
    threeJs.scene.background = three.Color.fromHex32(
      widget.backgroundColor.value,
    );

    // 카메라 설정
    threeJs.camera = three.PerspectiveCamera(
      _kCameraFov,
      threeJs.width / threeJs.height,
      _kCameraNear,
      _kCameraFar,
    );

    final sessionId = _kDefaultSessionId;

    final obj = await loadObjFileBySessionId(sessionId);
    if (obj != null) {
      threeJs.scene.add(obj);
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
        threeJs.camera as three.PerspectiveCamera,
        threeJs.width,
        threeJs.height,
      );
    } else {
      final camPos = widget.cameraPosition ?? three.Vector3(0, 0, 5);
      threeJs.camera.position.setValues(camPos.x, camPos.y, camPos.z);
    }
  }

  @override
  void dispose() {
    threeJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Three.js 뷰어
        _viewer,
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
