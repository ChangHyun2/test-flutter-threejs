# Transforms & Coordinate Systems

## Overview

- 변환 파이프라인: 모델(Model) → 월드(World) → 뷰(View) → 프로젝션(Projection) → NDC → 화면 좌표.
- 회전 표현: 오일러(축 순서 의존) vs 쿼터니언(짐벌락 방지). Three.js는 내부적으로 쿼터니언 선호.

## Theory

- Model Matrix: 로컬 좌표계를 메시의 스케일/회전/이동으로 정의.
- World Matrix: 상위 `Object3D`의 변환이 곱해진 결과.
- View Matrix: 카메라의 월드 변환의 역행렬(월드→카메라 공간).
- Projection Matrix: 퍼스펙티브(FOV, aspect, near, far) 또는 오쏘그래픽(left/right/top/bottom).
- Handedness: Three.js는 기본 오른손 좌표(카메라 -Z 바라봄).

## Practical Notes

- `lookAt`은 카메라/오브젝트 forward 벡터를 타겟으로 정렬. 부모 변환의 영향 고려.
- 큰 계층에서 불필요한 재계산 방지: `matrixAutoUpdate=false` + 필요 시 `updateMatrixWorld(true)`.
- 회전 누적 오차/짐벌락 회피: 가능하면 `quaternion.setFromAxisAngle`/`setFromRotationMatrix` 사용.

## Checklist

- 좌표계 일관성(단위: m/mm) 고정, near/far는 가능한 타이트하게 설정(Z-fighting 방지).
- 변환 비용이 큰 오브젝트는 업데이트 최소화.

## Snippet

```js
obj.matrixAutoUpdate = false;
obj.position.set(0, 0.1, 0);
obj.quaternion.setFromAxisAngle(new THREE.Vector3(0, 1, 0), Math.PI * 0.5);
obj.updateMatrix();
scene.updateMatrixWorld(true);
```
