# Postprocessing & Pipeline

## Overview
- 후처리는 품질 향상(AA/블룸/SSAO 등)에 유용하지만 비용 큼. 파이프라인 설계가 중요.

## Theory
- EffectComposer: 렌더 패스 체인. `RenderPass` → 여러 EffectPass(FXAA, Bloom, SSAO…).
- MRT(Multiple Render Targets): G-buffer 등 복수 타겟 출력(지연 렌더링 개념).
- Deferred vs Forward: 지연은 많은 라이트에 유리, 투명/MSAA 등 제약 존재.

## Practical Notes
- 안티앨리어싱: MSAA(멀티샘플—WebGL2 멀티샘플 FBO) vs FXAA/TAA(포스트).
- 해상도 스케일: 포스트패스 해상도 하향(예: SSAO 0.5x)로 성능 절약.
- 패스 최소화: 꼭 필요한 효과만, 순서와 파라미터를 프로젝트 표준으로 고정.

## Checklist
- 각 패스 비용 측정 후 유지/삭제 결정.
- 모바일: 블룸/SSAO 파라미터 보수적으로, 다운샘플 체인 적극 활용.

## Snippet
```js
const composer = new EffectComposer(renderer);
composer.addPass(new RenderPass(scene, camera));
composer.addPass(new SMAAPass(width, height)); // or FXAA
// composer.addPass(new UnrealBloomPass(...));
composer.render();
```


