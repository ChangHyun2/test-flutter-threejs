# Geometry Optimization

## Overview

- 목표: 동일한 시각 품질로 삼각형 수/전송량/CPU 업데이트 비용을 최소화.
- 핵심: `BufferGeometry` 인덱싱, LOD, 압축(GLTF+Draco), 인스턴싱.

## Theory

- BufferGeometry: 연속 메모리(typed arrays). 인덱스 사용 시 버텍스 재사용 → 메모리/대역폭 절감.
- LOD(Level of Detail): 거리/화면 점유에 따라 저해상도 메시로 교체.
- Instancing: 동일 지오메트리/머티리얼을 여러 위치에 렌더링(한 번의 draw call).
- Compression: GLTF+Draco로 포맷 크기↓, 전송/로드 시간↓(디코딩 비용 고려).

## Practical Notes

- OBJ→GLTF 변환 권장(머티리얼/PBR/스키닝/애니메이션/압축 생태계).
- 필요 없는 속성 제거(예: tangents, colors), 노멀은 필요시 생성.
- 동적 변형이 없으면 `geometry.computeBoundsTree`(BVH, 외부 라이브러리)로 레이캐스트 최적화.

## Checklist

- 인덱스 유무 확인, 삼각형 수 목표 설정, LOD 임계값 튜닝.
- 파일 포맷: GLTF(binary .glb) + Draco/meshopt.

## Snippet

```js
const geo = new THREE.BufferGeometry();
geo.setAttribute("position", new THREE.Float32BufferAttribute(vertices, 3));
geo.setIndex(indices); // enable indexing
geo.computeVertexNormals();
```
