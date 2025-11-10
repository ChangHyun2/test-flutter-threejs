# Materials & Lighting

## Overview

- 셰이딩 모델 선택은 품질/성능을 결정. PBR(物理ベース) 머티리얼이 현대 파이프라인 표준.

## Theory

- Materials: `MeshBasic`(조명 무시), `Lambert`(디퓨즈), `Phong`(스펙큘러), `Standard/Physical`(PBR).
- PBR Params: baseColor/albedo, metalness, roughness, normal, emissive, ao, clearcoat 등.
- Lights: Ambient, Directional, Point, Spot, Hemisphere. 섀도: shadow map(해상도/편향/범위).
- BRDF 개념: 러프니스/금속성에 따른 라이트 응답. IBL(환경맵)로 사실감 향상.

## Practical Notes

- 환경맵: PMREM으로 미리 필터링된 큐브맵/HDR 사용 → `scene.environment`.
- 섀도 튜닝: `shadow.mapSize`, `camera.near/far`, `bias/normalBias`.
- 머티리얼 재사용: 동일 파라미터는 인스턴스 공유 → state change 감소.

## Checklist

- PBR 텍스처 세트 일관 해상도/색공간 관리(SRGB vs Linear).
- 실시간 섀도 대상 최소화, 라이트 수 제한, 환경광 적극 사용.

## Snippet

```js
const mat = new THREE.MeshStandardMaterial({
  map: albedoTex,
  normalMap: normalTex,
  roughness: 0.5,
  metalness: 0.1,
  envMapIntensity: 1.0,
});
scene.environment = pmremEnv;
```
