# Animation & Update Loop

## Overview
- 안정적인 업데이트 루프와 타임스텝 처리는 인터랙션/애니메이션 품질을 좌우한다.

## Theory
- Game Loop: `requestAnimationFrame` 기반, delta time으로 프레임 독립적 업데이트.
- AnimationMixer: GLTF 클립 재생/블렌딩. 트랙/액션/웨이트.
- Interpolation: 선형/스무딩(지수 감쇠)/커브 기반 보간.

## Practical Notes
- Fixed vs Variable timestep: 물리엔진은 고정 스텝 추천, 일반 애니메이션은 가변 스텝 가능.
- Damping: 컨트롤/카메라 감쇠는 프레임 독립적 계산 필요.
- 효율: 화면 비활성 시 루프 중단/감속, 가시 오브젝트만 업데이트.

## Checklist
- delta 기반 업데이트 통일, 느린 프레임에서 누적 시간 클램프.
- 믹서/트위너/컨트롤 업데이트 순서 일관성 유지.

## Snippet
```js
const clock = new THREE.Clock();
function tick(){
  const dt = clock.getDelta();
  mixer?.update(dt);
  controls?.update();
  renderer.render(scene, camera);
  requestAnimationFrame(tick);
}
tick();
```


