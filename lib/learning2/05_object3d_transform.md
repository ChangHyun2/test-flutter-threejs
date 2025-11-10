# Object3D 변형과 그룹화

## 1. Object3D 기초

### Object3D란?
**Object3D**는 Three.js의 모든 3D 객체가 상속받는 기본 클래스입니다. Mesh, Camera, Light, Group 등이 모두 Object3D를 상속합니다.

### 계층 구조
```
Scene (Object3D)
  ├─ Group (Object3D)
  │   ├─ Mesh (Object3D)
  │   └─ Mesh (Object3D)
  ├─ Light (Object3D)
  └─ Camera (Object3D)
```

### 주요 속성
```javascript
const mesh = new THREE.Mesh(geometry, material);

// Transform 속성
mesh.position.set(x, y, z);        // Vector3
mesh.rotation.set(x, y, z);        // Euler
mesh.scale.set(x, y, z);           // Vector3
mesh.quaternion.set(x, y, z, w);   // Quaternion

// 계층 구조
mesh.parent                         // 부모 객체
mesh.children                       // 자식 배열
mesh.add(childObject)              // 자식 추가
mesh.remove(childObject)           // 자식 제거

// 변환 행렬
mesh.matrix                        // 로컬 변환 행렬
mesh.matrixWorld                   // 월드 변환 행렬
mesh.updateMatrix()                // 행렬 업데이트
mesh.updateMatrixWorld()           // 월드 행렬 업데이트

// 기타
mesh.visible = true                // 렌더링 여부
mesh.castShadow = true             // 그림자 생성
mesh.receiveShadow = true          // 그림자 받기
mesh.userData = {}                 // 커스텀 데이터
```

---

## 2. Position (위치)

### 기본 사용
```javascript
// 개별 설정
mesh.position.x = 5;
mesh.position.y = 10;
mesh.position.z = -3;

// 한 번에 설정
mesh.position.set(5, 10, -3);

// Vector3 복사
const targetPos = new THREE.Vector3(1, 2, 3);
mesh.position.copy(targetPos);

// 이동 (현재 위치에서 상대적)
mesh.position.add(new THREE.Vector3(1, 0, 0));  // X축으로 1 이동
```

### 로컬 vs 월드 좌표

**로컬 좌표 (부모 기준):**
```javascript
const group = new THREE.Group();
group.position.set(10, 0, 0);

const mesh = new THREE.Mesh(geometry, material);
mesh.position.set(5, 0, 0);  // 그룹 기준 (5, 0, 0)

group.add(mesh);
scene.add(group);

// mesh의 월드 좌표는 (15, 0, 0)
```

**월드 좌표 얻기:**
```javascript
const worldPosition = new THREE.Vector3();
mesh.getWorldPosition(worldPosition);
console.log(worldPosition);  // Vector3(15, 0, 0)
```

**월드 좌표로 이동:**
```javascript
function setWorldPosition(object, worldPos) {
  if (object.parent) {
    const parentWorldPosition = new THREE.Vector3();
    object.parent.getWorldPosition(parentWorldPosition);
    object.position.copy(worldPos).sub(parentWorldPosition);
  } else {
    object.position.copy(worldPos);
  }
}
```

---

## 3. Rotation (회전)

### Euler 각도 (기본)
```javascript
// 라디안 단위
mesh.rotation.x = Math.PI / 4;  // 45도
mesh.rotation.y = Math.PI / 2;  // 90도
mesh.rotation.z = Math.PI;      // 180도

// 한 번에 설정
mesh.rotation.set(Math.PI / 4, Math.PI / 2, 0);

// 도(degree)를 라디안으로 변환
const deg2rad = (deg) => deg * Math.PI / 180;
mesh.rotation.y = deg2rad(45);
```

### 회전 순서
```javascript
// 기본: XYZ
mesh.rotation.order = 'XYZ';

// 다른 순서 가능
mesh.rotation.order = 'YXZ';
mesh.rotation.order = 'ZXY';
mesh.rotation.order = 'ZYX';
mesh.rotation.order = 'YZX';
mesh.rotation.order = 'XZY';

// 짐벌 락(Gimbal Lock) 문제 있음 → Quaternion 사용 권장
```

### Quaternion (사원수) - 고급
```javascript
// Euler → Quaternion (자동 변환됨)
mesh.rotation.set(0, Math.PI / 2, 0);
console.log(mesh.quaternion);

// Quaternion 직접 설정
mesh.quaternion.set(x, y, z, w);

// 축-각도 회전
const axis = new THREE.Vector3(0, 1, 0).normalize();
const angle = Math.PI / 2;
mesh.quaternion.setFromAxisAngle(axis, angle);

// 한 객체를 다른 객체 방향으로
mesh.quaternion.copy(targetMesh.quaternion);
```

### lookAt - 특정 지점 바라보기
```javascript
// 원점 바라보기
mesh.lookAt(0, 0, 0);

// 특정 Vector3 바라보기
const target = new THREE.Vector3(10, 5, -3);
mesh.lookAt(target);

// 다른 객체 바라보기
mesh.lookAt(otherMesh.position);
```

### 회전 애니메이션
```javascript
function animate() {
  // Y축 중심 회전 (초당 90도)
  mesh.rotation.y += Math.PI / 2 * deltaTime;
  
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
}
```

---

## 4. Scale (스케일)

### 기본 사용
```javascript
// 균일 스케일
mesh.scale.set(2, 2, 2);  // 2배 확대

// 축별 스케일
mesh.scale.set(2, 1, 0.5);  // X축 2배, Y축 유지, Z축 절반

// 개별 설정
mesh.scale.x = 3;
mesh.scale.y = 1.5;
mesh.scale.z = 0.8;

// 음수 스케일 (미러링)
mesh.scale.x = -1;  // X축 반전
```

### 동적 스케일 조정
```javascript
// 현재 스케일에서 상대적 변경
mesh.scale.multiplyScalar(1.5);  // 1.5배 확대

// 특정 축만 스케일
mesh.scale.x *= 2;
```

### 펄스 애니메이션
```javascript
let time = 0;

function animate(deltaTime) {
  time += deltaTime;
  
  // 사인파로 펄스 효과
  const pulse = Math.sin(time * 3) * 0.2 + 1.0;
  mesh.scale.setScalar(pulse);
  
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
}
```

---

## 5. Group (그룹화)

### 그룹 생성 및 사용
```javascript
const group = new THREE.Group();

// 여러 메쉬 추가
const mesh1 = new THREE.Mesh(geometry1, material1);
const mesh2 = new THREE.Mesh(geometry2, material2);
const mesh3 = new THREE.Mesh(geometry3, material3);

group.add(mesh1);
group.add(mesh2);
group.add(mesh3);

scene.add(group);

// 그룹 전체 변형
group.position.set(0, 5, 0);
group.rotation.y = Math.PI / 4;
group.scale.set(2, 2, 2);
```

### 계층 구조 탐색
```javascript
// 자식 순회
group.children.forEach((child) => {
  console.log(child.name, child.type);
});

// 재귀적으로 모든 자손 탐색
group.traverse((object) => {
  if (object.isMesh) {
    console.log('Found mesh:', object.name);
  }
});

// 특정 자식 찾기
const targetMesh = group.getObjectByName('MyMesh');
const targetById = group.getObjectById(123);
```

### 실용 예제: 얼굴 모델 구조화
```javascript
class FaceModel {
  constructor() {
    this.root = new THREE.Group();
    this.root.name = 'FaceModel';
    
    // 메인 메쉬
    this.mainMesh = new THREE.Mesh(faceGeometry, faceMaterial);
    this.mainMesh.name = 'MainFace';
    this.root.add(this.mainMesh);
    
    // 선택 영역 그룹
    this.selectionGroup = new THREE.Group();
    this.selectionGroup.name = 'Selections';
    this.root.add(this.selectionGroup);
    
    // 화살표 그룹
    this.arrowGroup = new THREE.Group();
    this.arrowGroup.name = 'Arrows';
    this.root.add(this.arrowGroup);
  }
  
  addSelection(selectionMesh) {
    this.selectionGroup.add(selectionMesh);
  }
  
  addArrow(arrowMesh) {
    this.arrowGroup.add(arrowMesh);
  }
  
  clearSelections() {
    this.selectionGroup.clear();
  }
  
  clearArrows() {
    this.arrowGroup.clear();
  }
  
  setTransform(position, rotation, scale) {
    this.root.position.copy(position);
    this.root.rotation.copy(rotation);
    this.root.scale.copy(scale);
  }
}
```

---

## 6. 영역 확대 구현

### 방법 1: 독립 메쉬 확대
```javascript
function zoomSelectedRegion(originalMesh, selectedFaceIndices, zoomFactor = 2.0) {
  // 선택 영역 Geometry 추출
  const selectedGeometry = extractSelectedFaces(
    originalMesh.geometry, 
    selectedFaceIndices
  );
  
  // 확대된 메쉬 생성
  const zoomedMesh = new THREE.Mesh(
    selectedGeometry,
    originalMesh.material.clone()
  );
  
  // 중심점 계산
  const box = new THREE.Box3().setFromBufferAttribute(
    selectedGeometry.attributes.position
  );
  const center = box.getCenter(new THREE.Vector3());
  
  // 중심 기준으로 스케일
  zoomedMesh.geometry.translate(-center.x, -center.y, -center.z);
  zoomedMesh.scale.set(zoomFactor, zoomFactor, zoomFactor);
  zoomedMesh.geometry.translate(center.x, center.y, center.z);
  
  // 원본 Transform 상속
  zoomedMesh.position.copy(originalMesh.position);
  zoomedMesh.rotation.copy(originalMesh.rotation);
  
  return zoomedMesh;
}
```

### 방법 2: 별도 씬 오버레이 (픽처 인 픽처)
```javascript
class ZoomOverlay {
  constructor(renderer, mainCamera) {
    this.renderer = renderer;
    this.mainCamera = mainCamera;
    
    // 확대 뷰용 씬과 카메라
    this.zoomScene = new THREE.Scene();
    this.zoomCamera = new THREE.PerspectiveCamera(50, 1, 0.1, 100);
    
    // 오버레이 위치/크기 (화면 우상단 1/4 크기)
    this.viewport = {
      x: 0.7,  // 화면의 70% 위치
      y: 0.7,
      width: 0.3,
      height: 0.3
    };
  }
  
  setTarget(mesh) {
    this.zoomScene.clear();
    
    const clonedMesh = mesh.clone();
    this.zoomScene.add(clonedMesh);
    
    // 카메라를 메쉬에 맞춤
    fitCameraToObject(this.zoomCamera, clonedMesh);
  }
  
  render() {
    const width = this.renderer.domElement.width;
    const height = this.renderer.domElement.height;
    
    // 오버레이 영역 계산
    const x = width * this.viewport.x;
    const y = height * this.viewport.y;
    const w = width * this.viewport.width;
    const h = height * this.viewport.height;
    
    // 뷰포트 설정
    this.renderer.setViewport(x, y, w, h);
    this.renderer.setScissor(x, y, w, h);
    this.renderer.setScissorTest(true);
    
    // 확대 씬 렌더
    this.renderer.render(this.zoomScene, this.zoomCamera);
    
    // 뷰포트 복원
    this.renderer.setViewport(0, 0, width, height);
    this.renderer.setScissorTest(false);
  }
}

// 사용
const overlay = new ZoomOverlay(renderer, camera);
const selectedMesh = extractSelectedFaces(faceMesh, selectedFaces);
overlay.setTarget(selectedMesh);

function animate() {
  // 메인 씬 렌더
  renderer.render(scene, camera);
  
  // 오버레이 렌더
  overlay.render();
  
  requestAnimationFrame(animate);
}
```

---

## 7. Morph Target (모프 타겟)

### 개념
**Morph Target**은 정점 위치를 보간하여 형태를 변형하는 기법입니다. 얼굴 표정, 립싱크 등에 사용됩니다.

### Morph Target 생성
```javascript
// 원본 Geometry
const geometry = new THREE.BoxGeometry(1, 1, 1);

// Morph Target 1: 위로 늘림
const stretchedPositions = geometry.attributes.position.array.slice();
for (let i = 0; i < stretchedPositions.length; i += 3) {
  stretchedPositions[i + 1] *= 2;  // Y축 2배
}

// Morph Target 2: 옆으로 늘림
const widenedPositions = geometry.attributes.position.array.slice();
for (let i = 0; i < widenedPositions.length; i += 3) {
  widenedPositions[i] *= 2;  // X축 2배
}

// Geometry에 Morph Target 추가
geometry.morphAttributes.position = [
  new THREE.Float32BufferAttribute(stretchedPositions, 3),
  new THREE.Float32BufferAttribute(widenedPositions, 3)
];

// Mesh 생성
const mesh = new THREE.Mesh(geometry, material);

// Morph Target 영향도 설정 (0~1)
mesh.morphTargetInfluences[0] = 0.5;  // 50% 늘림
mesh.morphTargetInfluences[1] = 0.3;  // 30% 넓힘
```

### GLTF에서 Morph Target 사용
```javascript
const loader = new GLTFLoader();
loader.load('face_with_morphs.glb', (gltf) => {
  const mesh = gltf.scene.getObjectByName('FaceMesh');
  
  console.log('Morph targets:', mesh.morphTargetDictionary);
  // { "Smile": 0, "Frown": 1, "Blink": 2 }
  
  // 이름으로 접근
  mesh.morphTargetInfluences[mesh.morphTargetDictionary['Smile']] = 1.0;
  
  // 애니메이션
  function animate() {
    const time = performance.now() / 1000;
    mesh.morphTargetInfluences[0] = Math.sin(time) * 0.5 + 0.5;
    
    renderer.render(scene, camera);
    requestAnimationFrame(animate);
  }
  animate();
});
```

### 국소 영역 확대 (Morph Target 활용)
```javascript
function createLocalZoomMorph(geometry, selectedVertexIndices, zoomFactor) {
  const position = geometry.attributes.position;
  const morphPositions = position.array.slice();
  
  // 선택 영역 중심 계산
  const center = new THREE.Vector3();
  selectedVertexIndices.forEach(idx => {
    center.x += position.getX(idx);
    center.y += position.getY(idx);
    center.z += position.getZ(idx);
  });
  center.divideScalar(selectedVertexIndices.length);
  
  // 선택된 정점만 확대
  selectedVertexIndices.forEach(idx => {
    const i = idx * 3;
    const x = morphPositions[i];
    const y = morphPositions[i + 1];
    const z = morphPositions[i + 2];
    
    // 중심에서의 벡터
    const dx = x - center.x;
    const dy = y - center.y;
    const dz = z - center.z;
    
    // 확대 적용
    morphPositions[i] = center.x + dx * zoomFactor;
    morphPositions[i + 1] = center.y + dy * zoomFactor;
    morphPositions[i + 2] = center.z + dz * zoomFactor;
  });
  
  // Morph Target 추가
  if (!geometry.morphAttributes.position) {
    geometry.morphAttributes.position = [];
  }
  
  geometry.morphAttributes.position.push(
    new THREE.Float32BufferAttribute(morphPositions, 3)
  );
  
  return geometry.morphAttributes.position.length - 1;  // 인덱스 반환
}

// 사용
const morphIndex = createLocalZoomMorph(mesh.geometry, selectedVertices, 1.5);
mesh.morphTargetInfluences[morphIndex] = 1.0;  // 활성화
```

---

## 8. Skinning (스키닝) - 본 애니메이션

### 개념
**Skinning**은 정점을 본(bone)에 바인딩하여 골격 애니메이션을 구현하는 기법입니다.

### SkinnedMesh 기본
```javascript
// 본 생성
const bones = [];

const rootBone = new THREE.Bone();
rootBone.position.set(0, 0, 0);
bones.push(rootBone);

const childBone = new THREE.Bone();
childBone.position.set(0, 2, 0);
rootBone.add(childBone);
bones.push(childBone);

// Skeleton 생성
const skeleton = new THREE.Skeleton(bones);

// SkinnedMesh 생성
const skinnedMesh = new THREE.SkinnedMesh(geometry, material);
skinnedMesh.add(rootBone);
skinnedMesh.bind(skeleton);

scene.add(skinnedMesh);

// 본 애니메이션
function animate() {
  childBone.rotation.z = Math.sin(performance.now() / 1000) * 0.5;
  
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
}
```

### GLTF 스킨 애니메이션
```javascript
const loader = new GLTFLoader();
loader.load('character.glb', (gltf) => {
  const model = gltf.scene;
  scene.add(model);
  
  // 애니메이션 믹서
  const mixer = new THREE.AnimationMixer(model);
  
  // 모든 애니메이션 재생
  gltf.animations.forEach((clip) => {
    mixer.clipAction(clip).play();
  });
  
  // 업데이트 루프
  const clock = new THREE.Clock();
  function animate() {
    const delta = clock.getDelta();
    mixer.update(delta);
    
    renderer.render(scene, camera);
    requestAnimationFrame(animate);
  }
  animate();
});
```

### 본 헬퍼 (디버깅)
```javascript
import { SkeletonHelper } from 'three/addons/helpers/SkeletonHelper.js';

const skeletonHelper = new SkeletonHelper(skinnedMesh);
scene.add(skeletonHelper);
```

---

## 9. Transform 행렬

### Matrix4 기초
```javascript
// 로컬 변환 행렬
const matrix = object.matrix;

// 월드 변환 행렬
const worldMatrix = object.matrixWorld;

// 수동 행렬 업데이트
object.matrixAutoUpdate = false;
object.matrix.compose(position, quaternion, scale);
object.matrixWorldNeedsUpdate = true;
```

### 행렬 분해
```javascript
const position = new THREE.Vector3();
const quaternion = new THREE.Quaternion();
const scale = new THREE.Vector3();

object.matrixWorld.decompose(position, quaternion, scale);

console.log('World position:', position);
console.log('World rotation:', quaternion);
console.log('World scale:', scale);
```

### 행렬 적용
```javascript
// 행렬을 다른 객체에 적용
targetObject.matrix.copy(sourceObject.matrix);
targetObject.matrixAutoUpdate = false;
```

---

## 실무 체크리스트

- [ ] Object3D 계층 구조 설계
- [ ] Group으로 논리적 그룹화 구현
- [ ] 영역 확대 메커니즘 선택 (독립 메쉬 vs 오버레이)
- [ ] Morph Target으로 국소 변형 구현
- [ ] Transform 변환 함수 유틸리티 작성
- [ ] 로컬/월드 좌표 변환 이해
- [ ] Quaternion 회전으로 짐벌 락 회피
- [ ] 애니메이션 믹서 구현 (GLTF)
- [ ] 메모리 누수 방지 (dispose 처리)

---

## 참고 자료

- [Object3D 문서](https://threejs.org/docs/#api/en/core/Object3D)
- [Group 문서](https://threejs.org/docs/#api/en/objects/Group)
- [Quaternion 문서](https://threejs.org/docs/#api/en/math/Quaternion)
- [SkinnedMesh 문서](https://threejs.org/docs/#api/en/objects/SkinnedMesh)
- [AnimationMixer 문서](https://threejs.org/docs/#api/en/animation/AnimationMixer)

