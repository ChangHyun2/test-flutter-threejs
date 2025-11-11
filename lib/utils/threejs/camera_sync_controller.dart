import 'dart:async';
import 'package:three_js/three_js.dart' as three;

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
