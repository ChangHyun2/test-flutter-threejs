# Three.js 좌표계와 카메라 시스템

## 1. Three.js 좌표계 기초

### 오른손 좌표계 (Right-Handed Coordinate System)
Three.js는 **오른손 좌표계**를 사용합니다.

```
      +Y (위)
       |
       |
       |_______ +X (오른쪽)
      /
     /
   +Z (앞)
```

**오른손 법칙 확인:**
- 엄지: +X 방향
- 검지: +Y 방향  
- 중지: +Z 방향

### 기본 축 방향
- **X축**: 빨강 (오른쪽이 양수)
- **Y축**: 초록 (위쪽이 양수)
- **Z축**: 파랑 (화면 밖으로 나오는 방향이 양수)

### 좌표계 시각화 코드
```javascript
// AxisHelper로 좌표계 확인
const axesHelper = new THREE.AxesHelper(5);
scene.add(axesHelper);
```

### 왼손 좌표계와 비교
일부 3D 소프트웨어(Unity, DirectX)는 왼손 좌표계를 사용:
- Z축 방향이 반대 (화면 안쪽이 양수)
- 모델 임포트 시 Z축 반전 필요할 수 있음

### 실무 체크리스트
- [ ] OBJ/GLTF 파일의 원본 좌표계 확인
- [ ] 임포트 후 모델 방향 검증 (앞/뒤 반전 여부)
- [ ] 스케일 단위 통일 (미터/센티미터/밀리미터)

---

## 2. PerspectiveCamera vs OrthographicCamera

### PerspectiveCamera (원근 카메라)

**특징:**
- 실제 눈으로 보는 것처럼 **원근감** 표현
- 멀리 있는 물체가 작게 보임
- 게임, VR, 실사 렌더링에 적합

**생성자:**
```javascript
const camera = new THREE.PerspectiveCamera(
  fov,    // Field of View (시야각, 도 단위)
  aspect, // 종횡비 (width / height)
  near,   // 근평면 (가까운 클리핑)
  far     // 원평면 (먼 클리핑)
);
```

**주요 파라미터:**
- `fov`: 45~75도가 일반적 (넓을수록 왜곡 증가)
- `aspect`: 화면 비율에 맞춰 설정
- `near/far`: 렌더링 범위 (너무 넓으면 깊이 정밀도 저하)

**예제:**
```javascript
const camera = new THREE.PerspectiveCamera(
  50,                          // 50도 시야각
  window.innerWidth / window.innerHeight,
  0.1,                         // 0.1 단위부터
  1000                         // 1000 단위까지
);
camera.position.set(0, 0, 5);
```

### OrthographicCamera (직교 카메라)

**특징:**
- **원근감 없음** (평행 투영)
- 거리에 관계없이 크기 동일
- CAD, 건축 설계, 2D 오버레이에 적합

**생성자:**
```javascript
const camera = new THREE.OrthographicCamera(
  left,   // 왼쪽 평면
  right,  // 오른쪽 평면
  top,    // 위쪽 평면
  bottom, // 아래쪽 평면
  near,   // 근평면
  far     // 원평면
);
```

**예제:**
```javascript
const aspect = window.innerWidth / window.innerHeight;
const frustumSize = 10;

const camera = new THREE.OrthographicCamera(
  frustumSize * aspect / -2,  // left
  frustumSize * aspect / 2,   // right
  frustumSize / 2,            // top
  frustumSize / -2,           // bottom
  0.1,
  1000
);
camera.position.set(10, 10, 10);
camera.lookAt(0, 0, 0);
```

### 카메라 선택 가이드

| 용도 | 추천 카메라 | 이유 |
|------|-------------|------|
| 얼굴 모델 뷰어 | Perspective | 자연스러운 3D 표현 |
| 측정/비교 뷰 | Orthographic | 왜곡 없는 정확한 비교 |
| 미니맵 | Orthographic | 탑다운 뷰 |
| AR/VR | Perspective | 현실감 |

---

## 3. fitCameraToObject - 자동 카메라 조정

### 개념
선택한 객체가 화면에 딱 맞게 보이도록 카메라 위치와 줌을 자동 조정하는 기법.

### 구현 원리

**1. 객체의 Bounding Box 계산**
```javascript
const box = new THREE.Box3().setFromObject(object);
const size = box.getSize(new THREE.Vector3());
const center = box.getCenter(new THREE.Vector3());
```

**2. 카메라 거리 계산 (Perspective)**
```javascript
const maxSize = Math.max(size.x, size.y, size.z);
const fitHeightDistance = maxSize / (2 * Math.atan((Math.PI * camera.fov) / 360));
const fitWidthDistance = fitHeightDistance / camera.aspect;
const distance = Math.max(fitHeightDistance, fitWidthDistance);
```

**3. 카메라 위치 업데이트**
```javascript
const direction = controls.target.clone()
  .sub(camera.position)
  .normalize()
  .multiplyScalar(distance);

camera.position.copy(center).sub(direction);
camera.lookAt(center);
```

### 완성 함수 (PerspectiveCamera)

```javascript
function fitCameraToObject(camera, object, controls, offset = 1.5) {
  const box = new THREE.Box3().setFromObject(object);
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  
  const maxSize = Math.max(size.x, size.y, size.z);
  const fitHeightDistance = maxSize / (2 * Math.atan((Math.PI * camera.fov) / 360));
  const fitWidthDistance = fitHeightDistance / camera.aspect;
  const distance = offset * Math.max(fitHeightDistance, fitWidthDistance);
  
  const direction = controls.target.clone()
    .sub(camera.position)
    .normalize()
    .multiplyScalar(distance);
  
  camera.position.copy(center).sub(direction);
  controls.target.copy(center);
  
  camera.near = distance / 100;
  camera.far = distance * 100;
  camera.updateProjectionMatrix();
  
  controls.update();
}
```

### OrthographicCamera용 구현

```javascript
function fitCameraToObjectOrtho(camera, object, controls) {
  const box = new THREE.Box3().setFromObject(object);
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  
  const maxDim = Math.max(size.x, size.y);
  
  camera.left = -maxDim / 2;
  camera.right = maxDim / 2;
  camera.top = maxDim / 2;
  camera.bottom = -maxDim / 2;
  
  camera.position.copy(center);
  camera.position.z += maxDim;
  
  controls.target.copy(center);
  camera.updateProjectionMatrix();
  controls.update();
}
```

### 애니메이션 버전 (부드러운 전환)

```javascript
import { gsap } from 'gsap';

function animateCameraToObject(camera, object, controls, duration = 1.0) {
  const box = new THREE.Box3().setFromObject(object);
  const size = box.getSize(new THREE.Vector3());
  const center = box.getCenter(new THREE.Vector3());
  
  const maxSize = Math.max(size.x, size.y, size.z);
  const distance = maxSize * 2;
  
  const targetPosition = center.clone().add(new THREE.Vector3(0, 0, distance));
  
  gsap.to(camera.position, {
    x: targetPosition.x,
    y: targetPosition.y,
    z: targetPosition.z,
    duration: duration,
    ease: 'power2.inOut',
    onUpdate: () => controls.update()
  });
  
  gsap.to(controls.target, {
    x: center.x,
    y: center.y,
    z: center.z,
    duration: duration,
    ease: 'power2.inOut'
  });
}
```

---

## 실무 적용 시나리오

### 얼굴 모델 뷰어에서의 활용

```javascript
// 1. 전체 얼굴 보기 (초기 뷰)
fitCameraToObject(camera, faceMesh, controls, 1.5);

// 2. 여드름 영역 확대
const selectedRegion = extractSelectedFaces(faceMesh, selectedIndices);
animateCameraToObject(camera, selectedRegion, controls, 0.8);

// 3. 비교 뷰 (2개 모델 동시)
const group = new THREE.Group();
group.add(beforeMesh);
group.add(afterMesh);
fitCameraToObject(camera, group, controls, 2.0);
```

### 반응형 대응

```javascript
function onWindowResize() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  
  // 현재 타겟 객체가 있다면 재조정
  if (currentTarget) {
    fitCameraToObject(camera, currentTarget, controls);
  }
}

window.addEventListener('resize', onWindowResize);
```

---

## 디버깅 팁

### 카메라 위치 확인
```javascript
console.log('Camera Position:', camera.position);
console.log('Camera Target:', controls.target);
console.log('Camera FOV:', camera.fov);
```

### Frustum 시각화
```javascript
const helper = new THREE.CameraHelper(camera);
scene.add(helper);
```

### 객체 경계 박스 시각화
```javascript
const box = new THREE.Box3().setFromObject(object);
const helper = new THREE.Box3Helper(box, 0xffff00);
scene.add(helper);
```

---

## 체크리스트

- [ ] 프로젝트 좌표계 방향 확인 (Y-up vs Z-up)
- [ ] 카메라 타입 선택 (Perspective/Orthographic)
- [ ] 적절한 near/far 클리핑 평면 설정
- [ ] fitCameraToObject 함수 구현 및 테스트
- [ ] 화면 리사이즈 핸들러 구현
- [ ] 카메라 애니메이션 전환 구현
- [ ] 디버그용 헬퍼 도구 준비

---

## 참고 자료

- [Three.js Camera 공식 문서](https://threejs.org/docs/#api/en/cameras/Camera)
- [Three.js PerspectiveCamera](https://threejs.org/docs/#api/en/cameras/PerspectiveCamera)
- [Three.js OrthographicCamera](https://threejs.org/docs/#api/en/cameras/OrthographicCamera)
- [Box3 API](https://threejs.org/docs/#api/en/math/Box3)

