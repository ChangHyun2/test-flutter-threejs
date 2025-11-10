# Rendering Pipeline (Scene → Camera → Renderer)

## Overview

- Three.js는 CPU에서 씬 그래프를 구성하고, 카메라 행렬로 클립 공간에 투영한 뒤 WebGL로 draw call을 발행해 GPU 렌더링을 수행한다.
- 핵심 메트릭: 프레임 타임(ms), FPS, draw call 수, 삼각형 수, 텍스처/버퍼 전송량.

## Theory

- Scene Graph: `Object3D` 계층 → 월드 변환 계산(모델→월드).
- Camera: 월드→뷰(View)→프로젝션(Clip) 매트릭스. 퍼스펙티브(원근) vs 직교.
- GPU Stages(개념): 입력 어셈블리 → 버텍스 셰이더 → 래스터라이저 → 프래그먼트 셰이더 → 합성.
- State Changes: 바인딩(프로그램/VAO/VBO/텍스처/프레임버퍼) 변경이 많을수록 비용↑.
- Draw Call: `gl.drawElements/Arrays` 호출 1회=1 draw call. 많은 메시에선 병목.

## Practical Notes

- 큰 비용: draw call 난립, 과도한 머티리얼/텍스처 스위치, 고해상도 렌더 타겟, 동적 할당/업로드.
- 배치 전략: 메시 병합(Geometry merge/Instancing), 텍스처 아틀라스, 머티리얼 재사용.
- 해상도 스케일: 모바일에서 렌더러 `setPixelRatio` 조정, 포스트프로세싱 해상도 절감.
- 업데이트 루프: 필요한 오브젝트만 `matrixAutoUpdate=false` + 수동 업데이트로 CPU 절감.

## Checklist

- draw calls ≤ (목표 플랫폼 가이드라인), 삼각형 수 관리, 텍스처 수/해상도 제한.
- `WebGLRenderer.info`/Spector.js로 state change/draw call 병목 파악.

## Snippet

```js
// pseudo
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(w, h);
renderer.info.reset(); // per-frame
renderer.render(scene, camera);
console.log(renderer.info.render.calls);
```
