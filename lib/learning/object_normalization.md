### 3D Object 정규화(Object Normalization) — 실무 가이드 (입문자용)

이 문서는 서로 다른 크기·위치를 가진 3D 모델을 일관된 기준으로 맞추는 “정규화”를 실무적으로 이해하고 바로 적용할 수 있도록 정리했습니다. Flutter + three_js를 기준으로 설명하지만, 개념은 대부분의 3D 엔진에 동일하게 적용됩니다.

---

## 왜 정규화가 필요할까?
- **일관된 조작성**: 모델 크기가 제각각이면 같은 컨트롤 설정에서도 조작감이 크게 달라집니다.
- **카메라 피팅과 프레이밍**: 모델이 너무 크거나 작으면 화면에 안 보이거나 너무 작게 보임.
- **UI/UX 일관성**: 여러 모델을 비교/전환할 때 동일한 기준으로 보여주는 것이 사용자 경험에 중요.

정규화는 “모델을 공통의 기준 스케일과 기준점(예: 원점)”에 맞추는 작업입니다.

---

## 핵심 개념 한 장 요약
- **바운딩 박스(Bounding Box)**: 모델이 차지하는 최소 직육면체. 중심(`center`), 크기(`size`)를 얻는다.
- **목표 크기(Target Extent)**: “최대 변 길이 = 1.0” 처럼 합의된 기준값.
- **스케일 계수(Scale Factor)**: `scale = targetExtent / max(size.x, size.y, size.z)`
- **중심 정렬(Centering)**: 모델 중심을 기준점(보통 원점)으로 이동.
- **후처리(Update)**: 월드 행렬 갱신, 카메라 피팅, 컨트롤러 타겟/거리 재설정.

---

## 단계별 절차
1) 모델의 월드 행렬을 최신 상태로 갱신  
2) 바운딩 박스로 중심(center)과 크기(size) 계산  
3) 스케일 계수 계산 후 균등 스케일 적용  
4) 중심을 기준점(anchor, 기본 원점)으로 이동  
5) 행렬 재갱신 및 카메라/컨트롤러 재설정

---

## 코드로 바로 적용하기

### 1) 유틸리티 추가
`lib/@utils/object_normalizer.dart` 파일이 제공됩니다. 이 유틸은 오브젝트를 “최대 변 길이 = targetExtent(기본 1.0)” 기준으로 스케일링하고, 중심을 기준점으로 보정합니다.

```dart
import 'package:flutter_test_app/@utils/object_normalizer.dart';
import 'package:flutter_test_app/utils/camera_utils.dart';
import 'package:three_js/three_js.dart' as three;

Future<void> setupScene({
  required three.Object3D object,
  required three.PerspectiveCamera camera,
  required double viewportWidth,
  required double viewportHeight,
}) async {
  // (1) 로드 직후: 정규화
  final report = ObjectNormalizer.normalizeInPlace(
    object,
    targetExtent: 1.0, // 원하는 공통 기준
    centerToAnchor: true,
  );

  // (2) 컨트롤 거리 힌트 (선택)
  final distances = ObjectNormalizer.recommendOrbitDistances(
    targetExtent: report.targetExtent,
  );
  // controls.minDistance = distances.minDistance;
  // controls.maxDistance = distances.maxDistance;

  // (3) 카메라 피팅 (중요)
  fitCameraToObject(object, camera, viewportWidth, viewportHeight);
}
```

### 2) 카메라 피팅 함수(기존 코드)
아래는 프로젝트에 이미 포함된 카메라 피팅 함수의 핵심부입니다. 정규화 후 한 번 더 호출해 주는 것이 중요합니다.

```40:88:/Users/changhyun/dev/test/lib/utils/camera_utils.dart
void fitCameraToObject(
  three.Object3D obj,
  three.PerspectiveCamera camera,
  double viewportWidth,
  double viewportHeight, {
  double distanceMultiplier = kCameraDistanceMultiplier,
}) {
  // ... 정면 기준 크기, FOV 기반 거리 계산 ...
  camera.position.setValues(center.x, center.y, center.z + cameraDistance);
  camera.lookAt(center);
}
```

---

## 선택지: 어떤 기준으로 “맞출” 것인가?

- **최대 변 길이 기준(권장)**: 가장 쉬움. 회전·모양에 관계없이 항상 “한 변”이 기준이 됨.
- **구 반지름 기준**: 모든 방향에서 동일한 반경을 보장해야 할 때 유리.
- **특정 축 기준(예: 높이 = 1)**: 사람/건물처럼 의미 있는 높이를 기준으로 맞출 때.

처음에는 “최대 변 길이 = 1.0”을 추천합니다. 이후 필요할 때만 다른 기준으로 확장하세요.

---

## 컨트롤러·카메라 실무 팁

- **OrbitControls**
  - 스케일 변경 후 `controls.target`을 모델 중심(또는 기준점)으로 재설정하세요.
  - 조작감 표준화를 위해 정규화 `targetExtent`에 비례해서 `minDistance`, `maxDistance`를 잡습니다.
    - 예: `min ≈ 1.2 × targetExtent`, `max ≈ 8 × targetExtent`

- **카메라**
  - 정규화 후 반드시 피팅을 다시 수행하세요.
  - 필요하면 `near/far`를 `targetExtent`에 비례해 조정하세요. 너무 작으면 클리핑, 너무 크면 깊이 정밀도 저하.

- **조명/그림자**
  - 섀도우 카메라 범위(정사영/원근영)도 새 크기에 맞춰 조정해야 “클리핑” 없이 잘 나옵니다.

- **TransformControls/Picker**
  - 스케일·이동 후에는 `controls.detach → attach` 또는 `controls.update()`로 새 행렬 반영.

---

## 흔한 문제와 해결책

- 모델이 안 보인다
  - 카메라가 너무 가까움/멀거나 `near/far`가 맞지 않을 수 있음 → 피팅 재호출, near/far 조정.
- 컨트롤이 너무 민감/둔함
  - `minDistance/maxDistance`가 모델 크기와 불일치 → 정규화 기준값에 비례해 재설정.
- 애니메이션/피직스 깨짐
  - 자식 지오메트리를 직접 스케일하면 스켈레탈/물리 파이프라인이 틀어질 수 있음 → 가능하면 “부모 노드”에 스케일을 적용.
- 바운딩 값이 0 또는 이상함
  - 지오메트리가 비어있거나 월드 행렬 미갱신일 수 있음 → `object.updateMatrixWorld(true)` 확인, 로더 직후 `computeBoundingBox/computeBoundingSphere` 수행 고려.

---

## 성능 팁
- 바운딩 계산은 비싸므로 “로드 직후 한 번”만 수행하고 결과를 캐시하세요.
- 매우 복잡한 모델은 프리프로세싱 단계(툴체인)에서 스케일·피벗을 표준화하면 런타임 부담이 줄어듭니다.

---

## 최소 체크리스트
1. `updateMatrixWorld(true)` 호출했는가?
2. 바운딩 `center/size`로 스케일 계수를 구했는가?
3. 중심을 기준점으로 이동했는가?
4. 스케일/이동 후 행렬 재갱신 했는가?
5. 카메라 피팅/컨트롤러 타겟·거리 재설정 했는가?

---

## 부록: API 요약
- `ObjectNormalizer.normalizeInPlace(object, targetExtent: 1.0, centerToAnchor: true)`
  - 모델을 “최대 변 길이 = 1.0” 기준으로 스케일하고 중심을 기준점(기본 원점)으로 이동
  - 반환값 `NormalizationReport`: 스케일 계수, 정규화 전 크기/중심 등
- `ObjectNormalizer.recommendOrbitDistances(targetExtent: 1.0)`
  - OrbitControls `minDistance/maxDistance` 추천치 제공


