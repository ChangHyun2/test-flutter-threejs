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

// ============================================================================
// 카메라 동기화 컨트롤러
// ============================================================================

/// 카메라 상태를 담는 데이터 클래스
class CameraState {
  final three.Vector3 position;
  final three.Vector3 target;
  final double zoom;

  CameraState({
    required this.position,
    required this.target,
    required this.zoom,
  });

  CameraState copyWith({
    three.Vector3? position,
    three.Vector3? target,
    double? zoom,
  }) {
    return CameraState(
      position: position ?? this.position.clone(),
      target: target ?? this.target.clone(),
      zoom: zoom ?? this.zoom,
    );
  }
}

/// 여러 뷰어 간 카메라를 동기화하는 컨트롤러
class CameraSyncController {
  final _controller = StreamController<CameraState>.broadcast();
  Stream<CameraState> get stream => _controller.stream;

  /// 카메라 상태 변경을 브로드캐스트
  void updateCamera(CameraState state) {
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  void dispose() {
    _controller.close();
  }
}

/// Three.js 3D 뷰어 위젯
class ThreejsViewer extends StatefulWidget {
  final List<ThreejsViewerItem> items;
  final CameraSyncController? syncController;

  const ThreejsViewer({super.key, required this.items, this.syncController});

  @override
  State<ThreejsViewer> createState() => _ThreejsViewerState();
}

class _ThreejsViewerState extends State<ThreejsViewer> {
  bool _isLoaded = false;
  late three.ThreeJS _threeJs;
  OrbitControls? _controls;
  StreamSubscription<CameraState>? _syncSubscription;
  Timer? _syncTimer;
  bool _isUpdatingFromSync = false; // 동기화로 인한 업데이트 중인지 플래그
  CameraState? _lastCameraState; // 마지막으로 전송한 카메라 상태

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
          _setupSync();
        }
      },
      setup: _setupScene,
    );
  }

  /// 카메라 동기화 설정
  void _setupSync() {
    if (widget.syncController != null) {
      // 다른 뷰어의 카메라 변경사항을 구독
      _syncSubscription = widget.syncController!.stream.listen((state) {
        if (!_isUpdatingFromSync && _controls != null && mounted) {
          _isUpdatingFromSync = true;
          _applyCameraState(state);
          _isUpdatingFromSync = false;
        }
      });
    }
  }

  @override
  void didUpdateWidget(ThreejsViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('did update widget');
    _draw();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _syncSubscription?.cancel();
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

    // 카메라 변경사항 감지를 위한 이벤트 리스너 설정
    if (widget.syncController != null) {
      _setupControlsChangeListener();
    }
  }

  /// OrbitControls의 변경사항을 감지하여 동기화 컨트롤러에 전달
  void _setupControlsChangeListener() {
    // OrbitControls의 change 이벤트를 감지하기 위해
    // animation loop에서 변경사항을 체크
    _syncTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || _controls == null) {
        timer.cancel();
        return;
      }

      if (!_isUpdatingFromSync && widget.syncController != null) {
        _controls!.update();
        _notifyCameraChange();
      }
    });
  }

  /// 현재 카메라 상태를 동기화 컨트롤러에 전달
  void _notifyCameraChange() {
    if (widget.syncController == null || _controls == null) return;

    final camera = _threeJs.camera as three.PerspectiveCamera;
    final position = camera.position.clone();
    final target = _controls!.target.clone();
    final zoom = camera.zoom;

    final state = CameraState(position: position, target: target, zoom: zoom);

    // 변경사항이 있을 때만 전송 (성능 최적화)
    if (_lastCameraState == null ||
        _hasCameraChanged(_lastCameraState!, state)) {
      _lastCameraState = state;
      widget.syncController!.updateCamera(state);
    }
  }

  /// 카메라 상태가 변경되었는지 확인
  bool _hasCameraChanged(CameraState oldState, CameraState newState) {
    const threshold = 0.001; // 작은 변화는 무시

    // 위치 변경 확인
    if ((oldState.position.x - newState.position.x).abs() > threshold ||
        (oldState.position.y - newState.position.y).abs() > threshold ||
        (oldState.position.z - newState.position.z).abs() > threshold) {
      return true;
    }

    // 타겟 변경 확인
    if ((oldState.target.x - newState.target.x).abs() > threshold ||
        (oldState.target.y - newState.target.y).abs() > threshold ||
        (oldState.target.z - newState.target.z).abs() > threshold) {
      return true;
    }

    // 줌 변경 확인
    if ((oldState.zoom - newState.zoom).abs() > threshold) {
      return true;
    }

    return false;
  }

  /// 동기화된 카메라 상태를 현재 뷰어에 적용
  void _applyCameraState(CameraState state) {
    if (_controls == null) return;

    final camera = _threeJs.camera as three.PerspectiveCamera;

    // 카메라 위치 업데이트
    camera.position.setValues(
      state.position.x,
      state.position.y,
      state.position.z,
    );
    camera.zoom = state.zoom;
    camera.updateProjectionMatrix();

    // OrbitControls 타겟 업데이트
    _controls!.target.setValues(state.target.x, state.target.y, state.target.z);
    _controls!.update();
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
