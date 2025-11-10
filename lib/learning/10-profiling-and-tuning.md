# Profiling & Tuning

## Overview
- 병목을 계측하고 가설→실험→검증 사이클로 최적화. 숫자 없는 최적화는 실패 확률↑.

## Theory
- Metrics: 프레임 타임, FPS, CPU/GPU 시간 분할, draw calls, 삼각형 수, 텍스처/버퍼 업로드.
- Tools: `WebGLRenderer.info`, Chrome DevTools Performance, Spector.js(WebGL 캡처/리소스/드로우 확인).
- 접근: 상위 병목부터(해상도/포스트/드로우콜) → 하위(셰이더/메모리/데이터 전송).

## Practical Notes
- 해상도 스케일부터 시험(픽셀 코스트↓). 포스트패스 on/off로 비용 측정.
- draw call 절감: 배치/인스턴싱/머티리얼 정리. 텍스처 스위치 최소화.
- GPU 업로드: 초기 로딩 시점에 몰아주기, 런타임 업로드 최소화.

## Checklist
- 측정 기준선 저장(씬별, 디바이스별). 변경 전/후 숫자 비교 기록.
- 각 최적화의 효과가 미미하면 롤백. 유지보수 용이성 고려.

## Snippet
```js
renderer.info.autoReset = true;
// per frame:
renderer.render(scene, camera);
const info = renderer.info;
console.log(info.render.calls, info.render.triangles);
```


