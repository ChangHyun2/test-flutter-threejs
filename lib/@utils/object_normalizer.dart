import 'dart:math' as math;
import 'package:three_js/three_js.dart' as three;

/// 결과 요약: 정규화에 사용된 정보 제공
class NormalizationReport {
  final double scaleFactor;
  final three.Vector3 preScaleSize;
  final three.Vector3 preScaleCenter;
  final three.Vector3 anchorUsed;
  final double targetExtent;

  const NormalizationReport({
    required this.scaleFactor,
    required this.preScaleSize,
    required this.preScaleCenter,
    required this.anchorUsed,
    required this.targetExtent,
  });
}

/// OrbitControls에 적용할 추천 거리 범위 힌트
class OrbitDistanceHint {
  final double minDistance;
  final double maxDistance;

  const OrbitDistanceHint({
    required this.minDistance,
    required this.maxDistance,
  });
}

/// Object3D 정규화 유틸리티
///
/// - 서로 다른 크기의 오브젝트를 동일한 스케일/기준점으로 맞춰 다룰 수 있게 함
/// - 일반적으로 로드 직후(카메라 피팅 전에) 한 번 호출하는 것이 좋음
class ObjectNormalizer {
  /// 오브젝트를 "최대 변 길이 = [targetExtent]" 기준으로 정규화
  ///
  /// 1) 바운딩 박스 중심과 크기를 구한 뒤
  /// 2) `max(size.x, size.y, size.z)` 를 기준으로 스케일 계수를 계산하고
  /// 3) 기준점(anchor)으로 중심을 맞춥니다.
  ///
  /// 주의: 스케일/이동 후에는 항상 `updateMatrixWorld(true)`로 월드 행렬을 갱신하세요.
  static NormalizationReport normalizeInPlace(
    three.Object3D object, {
    double targetExtent = 1.0,
    three.Vector3? anchor,
    bool centerToAnchor = true,
  }) {
    object.updateMatrixWorld(true);

    final box = three.BoundingBox();
    box.setFromObject(object);

    final center = three.Vector3(0, 0, 0);
    box.getCenter(center);

    final size = three.Vector3(0, 0, 0);
    box.getSize(size);

    final maxExtent = math.max(size.x, math.max(size.y, size.z));
    if (maxExtent == 0) {
      return NormalizationReport(
        scaleFactor: 1.0,
        preScaleSize: size,
        preScaleCenter: center,
        anchorUsed: anchor ?? three.Vector3(0, 0, 0),
        targetExtent: targetExtent,
      );
    }

    final double scaleFactor = targetExtent / maxExtent;
    object.scale.setValues(scaleFactor, scaleFactor, scaleFactor);

    if (centerToAnchor) {
      final targetAnchor = anchor ?? three.Vector3(0, 0, 0);
      final offset = three.Vector3(
        center.x - targetAnchor.x,
        center.y - targetAnchor.y,
        center.z - targetAnchor.z,
      );
      object.position.setValues(
        object.position.x - offset.x,
        object.position.y - offset.y,
        object.position.z - offset.z,
      );
    }

    object.updateMatrixWorld(true);

    return NormalizationReport(
      scaleFactor: scaleFactor,
      preScaleSize: size,
      preScaleCenter: center,
      anchorUsed: anchor ?? three.Vector3(0, 0, 0),
      targetExtent: targetExtent,
    );
  }

  /// 주어진 `targetExtent`를 기준으로 OrbitControls의 추천 거리 범위를 계산
  ///
  /// - 일반적으로 min은 `~1.2x`, max는 `~8x` 정도가 조작성 면에서 무난합니다.
  static OrbitDistanceHint recommendOrbitDistances({
    required double targetExtent,
    double minFactor = 1.2,
    double maxFactor = 8.0,
  }) {
    final minDistance = targetExtent * minFactor;
    final maxDistance = targetExtent * maxFactor;
    return OrbitDistanceHint(minDistance: minDistance, maxDistance: maxDistance);
  }
}


