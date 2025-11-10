# 애니메이션 구현

## 1. Three.js 애니메이션 기초

### requestAnimationFrame
```javascript
function animate() {
  requestAnimationFrame(animate);
  
  // 애니메이션 로직
  mesh.rotation.y += 0.01;
  
  // 렌더링
  renderer.render(scene, camera);
}

animate();
```

### Delta Time (프레임 독립적 애니메이션)
```javascript
const clock = new THREE.Clock();

function animate() {
  requestAnimationFrame(animate);
  
  const deltaTime = clock.getDelta();  // 초 단위
  
  // 초당 90도 회전
  mesh.rotation.y += Math.PI / 2 * deltaTime;
  
  renderer.render(scene, camera);
}

animate();
```

### Three.js Clock
```javascript
const clock = new THREE.Clock();

function animate() {
  requestAnimationFrame(animate);
  
  const elapsedTime = clock.getElapsedTime();  // 시작부터 경과 시간
  const deltaTime = clock.getDelta();          // 마지막 프레임부터 경과 시간
  
  // 사인파 애니메이션
  mesh.position.y = Math.sin(elapsedTime * 2) * 2;
  
  renderer.render(scene, camera);
}

animate();
```

---

## 2. Tween.js - 트윈 애니메이션

### 설치 및 기본 사용
```bash
npm install @tweenjs/tween.js
```

```javascript
import * as TWEEN from '@tweenjs/tween.js';

// 트윈 생성
const tween = new TWEEN.Tween(mesh.position)
  .to({ x: 5, y: 2, z: 3 }, 2000)  // 2초 동안 목표 위치로
  .easing(TWEEN.Easing.Quadratic.Out)
  .onUpdate(() => {
    // 업데이트 콜백
  })
  .onComplete(() => {
    console.log('Animation complete!');
  })
  .start();

// 애니메이션 루프
function animate() {
  requestAnimationFrame(animate);
  
  TWEEN.update();  // 트윈 업데이트 (필수!)
  
  renderer.render(scene, camera);
}

animate();
```

### Easing 함수
```javascript
// Linear (일정한 속도)
TWEEN.Easing.Linear.None

// Quadratic (2차 함수)
TWEEN.Easing.Quadratic.In      // 가속
TWEEN.Easing.Quadratic.Out     // 감속
TWEEN.Easing.Quadratic.InOut   // 가속 후 감속

// Cubic (3차 함수, 더 부드러움)
TWEEN.Easing.Cubic.In
TWEEN.Easing.Cubic.Out
TWEEN.Easing.Cubic.InOut

// Elastic (탄성)
TWEEN.Easing.Elastic.In
TWEEN.Easing.Elastic.Out
TWEEN.Easing.Elastic.InOut

// Bounce (바운스)
TWEEN.Easing.Bounce.In
TWEEN.Easing.Bounce.Out
TWEEN.Easing.Bounce.InOut

// Back (오버슈트)
TWEEN.Easing.Back.In
TWEEN.Easing.Back.Out
TWEEN.Easing.Back.InOut
```

### 체이닝 (순차 실행)
```javascript
const tween1 = new TWEEN.Tween(mesh.position)
  .to({ x: 5 }, 1000)
  .easing(TWEEN.Easing.Cubic.Out);

const tween2 = new TWEEN.Tween(mesh.position)
  .to({ y: 3 }, 1000)
  .easing(TWEEN.Easing.Cubic.Out);

const tween3 = new TWEEN.Tween(mesh.position)
  .to({ z: 2 }, 1000)
  .easing(TWEEN.Easing.Cubic.Out);

// 체인
tween1.chain(tween2);
tween2.chain(tween3);

// 시작
tween1.start();
```

### 반복 및 요요
```javascript
const tween = new TWEEN.Tween(mesh.position)
  .to({ y: 5 }, 1000)
  .repeat(Infinity)        // 무한 반복
  .yoyo(true)              // 왕복 (앞뒤로)
  .easing(TWEEN.Easing.Quadratic.InOut)
  .start();
```

---

## 3. GSAP - 강력한 애니메이션 라이브러리

### 설치 및 기본 사용
```bash
npm install gsap
```

```javascript
import { gsap } from 'gsap';

// 기본 애니메이션
gsap.to(mesh.position, {
  x: 5,
  y: 2,
  z: 3,
  duration: 2,              // 초
  ease: 'power2.out',
  onComplete: () => {
    console.log('Done!');
  }
});
```

### GSAP의 장점
- **더 직관적인 API**
- **타임라인 관리**
- **강력한 플러그인 생태계**
- **더 나은 성능**
- **자동 단위 변환**

### Timeline (복잡한 시퀀스)
```javascript
const timeline = gsap.timeline({
  onComplete: () => console.log('Timeline complete!'),
  repeat: 1,
  yoyo: true
});

timeline
  .to(mesh.position, { x: 5, duration: 1 })
  .to(mesh.rotation, { y: Math.PI, duration: 0.5 }, '-=0.5')  // 0.5초 겹침
  .to(mesh.scale, { x: 2, y: 2, z: 2, duration: 1 });

// 제어
timeline.play();
timeline.pause();
timeline.reverse();
timeline.restart();
```

### Easing
```javascript
// Power (Quad, Cubic, Quart와 동일)
ease: 'power1.in'      // 약한 가속
ease: 'power2.out'     // 중간 감속
ease: 'power3.inOut'   // 강한 가속+감속
ease: 'power4.in'      // 매우 강한 가속

// Back (오버슈트)
ease: 'back.out'
ease: 'back.inOut'

// Elastic (탄성)
ease: 'elastic.out'
ease: 'elastic.inOut(1, 0.5)'  // 파라미터 조정

// Bounce
ease: 'bounce.out'
ease: 'bounce.inOut'

// Steps (계단식)
ease: 'steps(5)'

// Custom
ease: 'cubic-bezier(0.25, 0.1, 0.25, 1)'
```

### 병렬 실행
```javascript
// 여러 속성 동시 애니메이션
gsap.to(mesh, {
  'position.x': 5,
  'position.y': 3,
  'rotation.y': Math.PI * 2,
  'scale.x': 2,
  duration: 2,
  ease: 'power2.inOut'
});
```

---

## 4. 벡터 보간 (Vector Interpolation)

### lerp (선형 보간)
```javascript
const start = new THREE.Vector3(0, 0, 0);
const end = new THREE.Vector3(10, 5, 3);

// t: 0~1 (0=start, 1=end)
const t = 0.5;  // 중간점
const interpolated = new THREE.Vector3().lerpVectors(start, end, t);

console.log(interpolated);  // Vector3(5, 2.5, 1.5)
```

### 부드러운 추적 (Smooth Follow)
```javascript
const targetPosition = new THREE.Vector3(10, 5, 0);
const currentPosition = new THREE.Vector3(0, 0, 0);
const lerpFactor = 0.1;  // 추적 속도 (0~1)

function animate() {
  requestAnimationFrame(animate);
  
  // 부드럽게 목표 위치로 이동
  currentPosition.lerp(targetPosition, lerpFactor);
  mesh.position.copy(currentPosition);
  
  renderer.render(scene, camera);
}

animate();
```

### 스플라인 보간 (Spline Interpolation)
```javascript
// 여러 점을 부드럽게 연결
const curve = new THREE.CatmullRomCurve3([
  new THREE.Vector3(0, 0, 0),
  new THREE.Vector3(2, 3, 1),
  new THREE.Vector3(5, 2, 3),
  new THREE.Vector3(8, 4, 2),
  new THREE.Vector3(10, 1, 0)
]);

// t: 0~1 (곡선 상의 위치)
const t = 0.5;
const point = curve.getPoint(t);

// 애니메이션
let progress = 0;

function animate() {
  requestAnimationFrame(animate);
  
  progress += 0.001;
  if (progress > 1) progress = 0;
  
  const position = curve.getPoint(progress);
  mesh.position.copy(position);
  
  renderer.render(scene, camera);
}
```

---

## 5. 카메라 애니메이션

### 부드러운 카메라 이동
```javascript
function animateCameraTo(camera, targetPosition, duration = 2) {
  gsap.to(camera.position, {
    x: targetPosition.x,
    y: targetPosition.y,
    z: targetPosition.z,
    duration: duration,
    ease: 'power2.inOut'
  });
}

// 사용
animateCameraTo(camera, new THREE.Vector3(5, 5, 10), 1.5);
```

### OrbitControls 타겟 애니메이션
```javascript
function animateCameraAndTarget(camera, controls, newCamPos, newTarget, duration = 2) {
  const timeline = gsap.timeline();
  
  timeline
    .to(camera.position, {
      x: newCamPos.x,
      y: newCamPos.y,
      z: newCamPos.z,
      duration: duration,
      ease: 'power2.inOut'
    }, 0)  // 동시 시작
    .to(controls.target, {
      x: newTarget.x,
      y: newTarget.y,
      z: newTarget.z,
      duration: duration,
      ease: 'power2.inOut',
      onUpdate: () => controls.update()
    }, 0);
  
  return timeline;
}

// 사용
animateCameraAndTarget(
  camera,
  controls,
  new THREE.Vector3(3, 3, 3),   // 카메라 위치
  new THREE.Vector3(0, 1, 0),   // 타겟
  1.5
);
```

### 카메라 경로 애니메이션 (Dolly)
```javascript
const cameraPath = new THREE.CatmullRomCurve3([
  new THREE.Vector3(10, 5, 10),
  new THREE.Vector3(5, 8, 5),
  new THREE.Vector3(-5, 6, 8),
  new THREE.Vector3(-10, 4, -5),
  new THREE.Vector3(0, 5, -10)
]);

let progress = 0;

function animate() {
  requestAnimationFrame(animate);
  
  progress += 0.0005;
  if (progress > 1) progress = 0;
  
  // 카메라 위치
  const cameraPosition = cameraPath.getPoint(progress);
  camera.position.copy(cameraPosition);
  
  // 항상 중심 바라보기
  camera.lookAt(0, 0, 0);
  
  renderer.render(scene, camera);
}
```

---

## 6. 얼굴 모델 애니메이션 실전

### 비포/애프터 전환
```javascript
class FaceTransitionController {
  constructor(scene, camera, controls) {
    this.scene = scene;
    this.camera = camera;
    this.controls = controls;
    
    this.beforeMesh = null;
    this.afterMesh = null;
    this.currentState = 'before';
  }
  
  setModels(beforeMesh, afterMesh) {
    this.beforeMesh = beforeMesh;
    this.afterMesh = afterMesh;
    
    // 초기 상태: before만 보이기
    this.beforeMesh.visible = true;
    this.afterMesh.visible = false;
    this.afterMesh.material.opacity = 0;
    this.afterMesh.material.transparent = true;
  }
  
  transitionTo(state, duration = 1.5) {
    if (state === this.currentState) return;
    
    this.currentState = state;
    
    if (state === 'before') {
      this.showBefore(duration);
    } else if (state === 'after') {
      this.showAfter(duration);
    } else if (state === 'comparison') {
      this.showComparison(duration);
    }
  }
  
  showBefore(duration) {
    this.beforeMesh.visible = true;
    this.afterMesh.visible = true;
    
    gsap.to(this.beforeMesh.material, {
      opacity: 1,
      duration: duration,
      ease: 'power2.inOut'
    });
    
    gsap.to(this.afterMesh.material, {
      opacity: 0,
      duration: duration,
      ease: 'power2.inOut'
    });
  }
  
  showAfter(duration) {
    this.beforeMesh.visible = true;
    this.afterMesh.visible = true;
    
    gsap.to(this.beforeMesh.material, {
      opacity: 0,
      duration: duration,
      ease: 'power2.inOut'
    });
    
    gsap.to(this.afterMesh.material, {
      opacity: 1,
      duration: duration,
      ease: 'power2.inOut'
    });
  }
  
  showComparison(duration) {
    // 반반씩 보이기
    this.beforeMesh.visible = true;
    this.afterMesh.visible = true;
    
    gsap.to([this.beforeMesh.material, this.afterMesh.material], {
      opacity: 0.5,
      duration: duration,
      ease: 'power2.inOut'
    });
  }
  
  animateSlider(sliderValue) {
    // sliderValue: 0 (before) ~ 1 (after)
    this.beforeMesh.material.opacity = 1 - sliderValue;
    this.afterMesh.material.opacity = sliderValue;
  }
}

// 사용
const transitionController = new FaceTransitionController(scene, camera, controls);
transitionController.setModels(beforeFaceMesh, afterFaceMesh);

// 버튼 클릭으로 전환
document.getElementById('btnBefore').addEventListener('click', () => {
  transitionController.transitionTo('before');
});

document.getElementById('btnAfter').addEventListener('click', () => {
  transitionController.transitionTo('after');
});
```

### 변화 애니메이션 (모핑)
```javascript
function animateFaceChange(mesh, fromKeypoints, toKeypoints, duration = 2) {
  const geometry = mesh.geometry;
  const positionAttribute = geometry.attributes.position;
  
  // 시작 위치 저장
  const startPositions = positionAttribute.array.slice();
  
  // 목표 위치 계산
  const targetPositions = positionAttribute.array.slice();
  
  // 키포인트 기반으로 변형 계산
  fromKeypoints.forEach((from, index) => {
    const to = toKeypoints[index];
    const change = new THREE.Vector3().subVectors(to.position, from.position);
    
    // 영향 받는 정점들 업데이트
    from.affectedVertices.forEach(vertexIndex => {
      const i = vertexIndex * 3;
      targetPositions[i] += change.x;
      targetPositions[i + 1] += change.y;
      targetPositions[i + 2] += change.z;
    });
  });
  
  // 애니메이션
  const animData = { progress: 0 };
  
  gsap.to(animData, {
    progress: 1,
    duration: duration,
    ease: 'power2.inOut',
    onUpdate: () => {
      const t = animData.progress;
      
      for (let i = 0; i < startPositions.length; i++) {
        positionAttribute.array[i] = THREE.MathUtils.lerp(
          startPositions[i],
          targetPositions[i],
          t
        );
      }
      
      positionAttribute.needsUpdate = true;
      geometry.computeVertexNormals();
    }
  });
}
```

---

## 7. 화살표 성장 애니메이션

### 순차 성장
```javascript
function animateArrowsSequentially(arrows, options = {}) {
  const defaults = {
    duration: 0.8,
    stagger: 0.1,     // 각 화살표 사이 지연
    ease: 'power2.out'
  };
  
  const config = { ...defaults, ...options };
  
  const timeline = gsap.timeline();
  
  arrows.forEach((arrow, index) => {
    // 각 화살표의 목표 길이 저장
    const targetLength = arrow.userData.targetLength || 1.0;
    
    // 초기 길이 0
    arrow.setLength(0);
    
    // 타임라인에 추가
    timeline.to(
      { length: 0 },
      {
        length: targetLength,
        duration: config.duration,
        ease: config.ease,
        onUpdate: function() {
          arrow.setLength(this.targets()[0].length);
        }
      },
      index * config.stagger  // 시작 시간 오프셋
    );
  });
  
  return timeline;
}

// 사용
const arrows = [arrow1, arrow2, arrow3, arrow4];
animateArrowsSequentially(arrows, {
  duration: 1.0,
  stagger: 0.15
});
```

### 방사형 성장
```javascript
function animateArrowsRadial(arrows, centerPoint, options = {}) {
  const defaults = {
    duration: 1.2,
    ease: 'power2.out'
  };
  
  const config = { ...defaults, ...options };
  
  // 중심점에서의 거리별로 정렬
  const sortedArrows = arrows.slice().sort((a, b) => {
    const distA = a.position.distanceTo(centerPoint);
    const distB = b.position.distanceTo(centerPoint);
    return distA - distB;
  });
  
  // 거리 비례 지연
  const timeline = gsap.timeline();
  
  sortedArrows.forEach((arrow, index) => {
    const distance = arrow.position.distanceTo(centerPoint);
    const delay = distance * 0.05;  // 거리에 비례한 지연
    
    const targetLength = arrow.userData.targetLength || 1.0;
    arrow.setLength(0);
    
    timeline.to(
      { length: 0 },
      {
        length: targetLength,
        duration: config.duration,
        ease: config.ease,
        onUpdate: function() {
          arrow.setLength(this.targets()[0].length);
        }
      },
      delay
    );
  });
  
  return timeline;
}
```

---

## 8. 성능 최적화

### 애니메이션 우선순위
```javascript
class AnimationManager {
  constructor() {
    this.animations = [];
    this.enabled = true;
  }
  
  add(animation, priority = 0) {
    this.animations.push({ animation, priority, active: true });
    this.animations.sort((a, b) => b.priority - a.priority);
  }
  
  update(deltaTime) {
    if (!this.enabled) return;
    
    this.animations.forEach(item => {
      if (item.active) {
        item.animation.update(deltaTime);
      }
    });
  }
  
  pause() {
    this.enabled = false;
  }
  
  resume() {
    this.enabled = true;
  }
  
  clear() {
    this.animations = [];
  }
}
```

### 조건부 애니메이션
```javascript
// 카메라 시야 내에서만 애니메이션
function isInViewport(object, camera) {
  const frustum = new THREE.Frustum();
  const cameraViewProjectionMatrix = new THREE.Matrix4();
  
  camera.updateMatrixWorld();
  cameraViewProjectionMatrix.multiplyMatrices(
    camera.projectionMatrix,
    camera.matrixWorldInverse
  );
  
  frustum.setFromProjectionMatrix(cameraViewProjectionMatrix);
  
  return frustum.intersectsObject(object);
}

function animate() {
  requestAnimationFrame(animate);
  
  // 보이는 객체만 애니메이션
  animatedObjects.forEach(obj => {
    if (isInViewport(obj, camera)) {
      obj.update(deltaTime);
    }
  });
  
  renderer.render(scene, camera);
}
```

### 쓰로틀링
```javascript
import { throttle } from 'lodash';

// 고비용 애니메이션은 쓰로틀
const expensiveAnimation = throttle(() => {
  // 복잡한 계산...
}, 50);  // 50ms마다 최대 1회

function animate() {
  requestAnimationFrame(animate);
  
  expensiveAnimation();
  
  renderer.render(scene, camera);
}
```

---

## 9. Flutter 통합

### GSAP 애니메이션 Flutter 제어
```dart
// Dart
class ThreeJSAnimationController {
  final WebViewController webViewController;
  
  ThreeJSAnimationController(this.webViewController);
  
  Future<void> playTransition(String state) async {
    await webViewController.runJavascript('''
      transitionController.transitionTo('$state', 1.5);
    ''');
  }
  
  Future<void> animateArrows() async {
    await webViewController.runJavascript('''
      animateArrowsSequentially(arrows, { duration: 1.0, stagger: 0.1 });
    ''');
  }
  
  Future<void> setSliderValue(double value) async {
    await webViewController.runJavascript('''
      transitionController.animateSlider($value);
    ''');
  }
}
```

### Flutter Slider ↔ Three.js
```dart
Slider(
  value: _sliderValue,
  min: 0.0,
  max: 1.0,
  onChanged: (value) {
    setState(() {
      _sliderValue = value;
    });
    
    animationController.setSliderValue(value);
  },
)
```

---

## 실무 체크리스트

- [ ] 애니메이션 라이브러리 선택 (Tween.js vs GSAP)
- [ ] Delta Time 기반 프레임 독립적 구현
- [ ] 벡터 보간 함수 작성
- [ ] 카메라 애니메이션 유틸리티
- [ ] 비포/애프터 전환 시스템
- [ ] 화살표 순차/방사형 애니메이션
- [ ] 타임라인 관리 시스템
- [ ] 성능 최적화 (조건부/쓰로틀링)
- [ ] Flutter 애니메이션 제어 통합

---

## 참고 자료

- [Tween.js 문서](https://github.com/tweenjs/tween.js/)
- [GSAP 문서](https://greensock.com/docs/)
- [Three.js Animation 시스템](https://threejs.org/docs/#manual/en/introduction/Animation-system)
- [Easing Functions](https://easings.net/)

