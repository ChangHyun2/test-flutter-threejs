import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;

// ============================================================================
// 오브젝트 피팅 설정 상수
// ============================================================================
/// 카메라와 오브젝트 사이의 여유 공간 배율
const double kCameraDistanceMultiplier = 1.5;

// ============================================================================
// 카메라 유틸리티 함수
// ============================================================================

/// obj의 정중앙 좌표를 계산
three.Vector3 calculateObjectCenter(three.Object3D obj) {
  final box = three.BoundingBox();
  box.setFromObject(obj);
  final center = three.Vector3(0, 0, 0);
  box.getCenter(center);
  return center;
}

/// obj의 바운딩 박스 크기를 계산
three.Vector3 calculateObjectSize(three.Object3D obj) {
  final box = three.BoundingBox();
  box.setFromObject(obj);
  final size = three.Vector3(0, 0, 0);
  box.getSize(size);

  print(box);
  return size;
}

/// 현재 뷰포트가 차지하는 높이, 너비 내에 obj이 원본 비율을 유지하면서
/// 최대한 공간을 차지하도록 카메라 위치를 계산
///
/// [obj]: 화면에 맞출 3D 오브젝트
/// [camera]: 조정할 카메라
/// [viewportWidth]: 뷰포트 너비
/// [viewportHeight]: 뷰포트 높이
/// [distanceMultiplier]: 카메라 거리 배율 (기본값: kCameraDistanceMultiplier)
void fitCameraToObject(
  three.Object3D obj,
  three.PerspectiveCamera camera,
  double viewportWidth,
  double viewportHeight, {
  double distanceMultiplier = kCameraDistanceMultiplier,
}) {
  // 1. obj의 중심점과 크기 계산
  final center = calculateObjectCenter(obj);
  final size = calculateObjectSize(obj);

  // 2. 정면 뷰에서 보이는 x, y 크기
  final objWidth = size.x;
  final objHeight = size.y;

  // 3. 뷰포트와 객체의 비율 비교
  final viewportAspect = viewportWidth / viewportHeight;
  final objectAspect = objWidth / objHeight;

  // 4. 제약 조건 판단
  // - 객체가 뷰포트보다 상대적으로 넓으면: 가로(x)가 제약
  // - 객체가 뷰포트보다 상대적으로 높으면: 세로(y)가 제약
  final constrainingDimension = (viewportAspect > objectAspect)
      ? objHeight
      : objWidth;

  // 5. FOV 계산
  final fov = camera.fov * math.pi / 180;
  final effectiveFov = (viewportAspect > objectAspect)
      ? fov
      : fov / viewportAspect;

  // 6. 카메라 거리 계산
  final cameraDistance =
      (constrainingDimension / 2) /
      math.tan(effectiveFov / 2) *
      distanceMultiplier;

  // 7. 카메라를 obj 중심점을 바라보도록 배치
  // z축으로 거리만큼 떨어진 위치에 배치
  camera.position.setValues(center.x, center.y, center.z + cameraDistance);

  // 8. 카메라가 obj 중심을 바라보도록 설정
  camera.lookAt(center);

  print('Object center: ${center.x}, ${center.y}, ${center.z}');
  print('Object size: ${size.x}, ${size.y}, ${size.z}');
  print('Camera distance: $cameraDistance');
}
