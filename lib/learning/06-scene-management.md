# Scene Management

## Overview
- 씬 그래프는 업데이트/탐색/렌더의 기본 단위. 불필요한 갱신과 메모리 누수를 막는 것이 핵심.

## Theory
- Scene Graph: 부모-자식 변환 전파, `visible`/`layers`로 렌더 포함/제외.
- Frustum Culling: 뷰 프러스텀 외의 객체는 스킵. 바운딩 구체/박스 기반.
- Lifecycle: 버텍스/인덱스/텍스처/머티리얼/렌더타겟은 사용 종료 시 `dispose`.

## Practical Notes
- 대규모 씬: 공간 파티셔닝(BVH/Octree—외부 라이브러리), LOD, 배치/인스턴싱 혼용.
- 업데이트 억제: 정적 오브젝트 `matrixAutoUpdate=false`, 애니메이션 없는 라이트/카메라 최소화.
- 가시성: `visible=false`와 `frustumCulled=false`의 차이 이해(후자는 컬링만 비활성).

## Checklist
- 제거 전 `geometry.dispose()`, `material.dispose()`, 텍스처/타겟도 dispose.
- 디버그: 바운딩 박스 시각화, 프러스텀 컬링 플래그 점검.

## Snippet
```js
mesh.geometry.dispose();
if (Array.isArray(mesh.material)) mesh.material.forEach(m=>m.dispose());
else mesh.material.dispose();
scene.remove(mesh);
```


