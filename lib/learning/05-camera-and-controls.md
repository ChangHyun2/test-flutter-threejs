# Camera & Controls

## Overview

- 카메라 선택과 파라미터는 뷰 품질/깊이 정밀도/UX에 큰 영향. 컨트롤은 상호작용 핵심.

## Theory

- PerspectiveCamera: FOV/Aspect/Near/Far. Near/Far 범위가 넓을수록 깊이 정밀도 저하.
- OrthographicCamera: 평행 투영. 측정/UI 오버레이에 유리.
- Clipping Planes: 너무 큰 far, 너무 작은 near는 Z-fighting 원인.
- Controls: Orbit/Trackball/MapControls—회전 중심, 줌 제한, 패닝 정책.

## Practical Notes

- `fitCameraToObject`로 컨텐츠 기반 카메라 초기화(센터/거리 산출).
- 컨트롤 타겟(lookAt 대상) 일관성 유지 → 여러 뷰 동기화가 쉬워짐.
- 모바일: 최대 줌/패닝 경계 설정, 제스처 민감도 튜닝.

## Checklist

- 목적에 맞는 카메라 유형 선택, near/far 타이트하게.
- 컨트롤 `enableDamping`, 거리/각도 제한으로 UX/성능 안정화.

## Snippet

```js
const cam = new THREE.PerspectiveCamera(60, w / h, 0.1, 500);
const controls = new OrbitControls(cam, canvas);
controls.enableDamping = true;
controls.minDistance = 0.5;
controls.maxDistance = 50;
```
