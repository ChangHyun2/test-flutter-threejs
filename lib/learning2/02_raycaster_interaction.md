# Raycaster와 인터랙션 처리

## 1. Three.js Raycaster 구조

### Raycaster란?
**Raycaster**는 3D 공간에서 광선(ray)을 쏴서 교차하는 객체를 찾는 도구입니다. 마우스/터치 입력으로 3D 객체를 선택하는 핵심 메커니즘입니다.

### 기본 원리
```
카메라 → 화면 좌표 → 3D 광선 → 객체 교차 판정
```

### 생성 및 사용
```javascript
// Raycaster 생성
const raycaster = new THREE.Raycaster();
const pointer = new THREE.Vector2();

// 마우스/터치 좌표를 정규화된 좌표로 변환 (-1 ~ +1)
function onPointerMove(event) {
  pointer.x = (event.clientX / window.innerWidth) * 2 - 1;
  pointer.y = -(event.clientY / window.innerHeight) * 2 + 1;
}

// 교차 체크
function checkIntersection() {
  raycaster.setFromCamera(pointer, camera);
  const intersects = raycaster.intersectObjects(scene.children, true);
  
  if (intersects.length > 0) {
    const hit = intersects[0];
    console.log('Hit object:', hit.object);
    console.log('Hit point:', hit.point);
    console.log('Hit face:', hit.face);
    console.log('Distance:', hit.distance);
  }
}
```

---

## 2. Raycaster 반환 정보 상세

### Intersection 객체 구조
```typescript
interface Intersection {
  distance: number;        // 카메라에서 교차점까지의 거리
  point: Vector3;          // 3D 공간에서의 교차점 좌표
  face: Face;              // 교차한 면 (vertex indices)
  faceIndex: number;       // 면 인덱스 (BufferGeometry)
  object: Object3D;        // 교차한 3D 객체
  uv: Vector2;             // 교차점의 UV 좌표
  uv2: Vector2;            // 두 번째 UV 세트 (있는 경우)
  instanceId: number;      // 인스턴스드 메쉬의 ID
}
```

### Face 정보
```javascript
// face는 삼각형의 세 꼭짓점 인덱스를 포함
{
  a: 0,     // 첫 번째 vertex index
  b: 1,     // 두 번째 vertex index
  c: 2,     // 세 번째 vertex index
  normal: Vector3,    // 면의 노말 벡터
  materialIndex: 0    // 사용된 머티리얼 인덱스
}
```

---

## 3. 영역 선택 구현

### 단일 면(Face) 선택
```javascript
let selectedFaces = new Set();

function selectFace(event) {
  updatePointer(event);
  raycaster.setFromCamera(pointer, camera);
  
  const intersects = raycaster.intersectObject(faceMesh, true);
  
  if (intersects.length > 0) {
    const faceIndex = intersects[0].faceIndex;
    
    // 토글 방식
    if (selectedFaces.has(faceIndex)) {
      selectedFaces.delete(faceIndex);
    } else {
      selectedFaces.add(faceIndex);
    }
    
    updateHighlight();
  }
}

canvas.addEventListener('click', selectFace);
```

### 반경 기반 영역 선택
```javascript
function selectRegion(centerFaceIndex, radius) {
  const geometry = faceMesh.geometry;
  const position = geometry.attributes.position;
  
  // 중심 면의 중점 계산
  const centerPoint = getFaceCenter(geometry, centerFaceIndex);
  
  // 반경 내 모든 면 검색
  const faceCount = position.count / 3;
  
  for (let i = 0; i < faceCount; i++) {
    const faceCenter = getFaceCenter(geometry, i);
    const distance = centerPoint.distanceTo(faceCenter);
    
    if (distance <= radius) {
      selectedFaces.add(i);
    }
  }
}

function getFaceCenter(geometry, faceIndex) {
  const position = geometry.attributes.position;
  const idx = faceIndex * 3;
  
  const v1 = new THREE.Vector3().fromBufferAttribute(position, idx);
  const v2 = new THREE.Vector3().fromBufferAttribute(position, idx + 1);
  const v3 = new THREE.Vector3().fromBufferAttribute(position, idx + 2);
  
  return new THREE.Vector3()
    .add(v1)
    .add(v2)
    .add(v3)
    .divideScalar(3);
}
```

### 브러시 선택 (드래그)
```javascript
let isSelecting = false;
let brushRadius = 0.1;

function onPointerDown(event) {
  isSelecting = true;
  selectAtPointer(event);
}

function onPointerMove(event) {
  if (isSelecting) {
    selectAtPointer(event);
  }
}

function onPointerUp(event) {
  isSelecting = false;
}

function selectAtPointer(event) {
  updatePointer(event);
  raycaster.setFromCamera(pointer, camera);
  
  const intersects = raycaster.intersectObject(faceMesh);
  
  if (intersects.length > 0) {
    const faceIndex = intersects[0].faceIndex;
    selectRegion(faceIndex, brushRadius);
    updateHighlight();
  }
}

canvas.addEventListener('pointerdown', onPointerDown);
canvas.addEventListener('pointermove', onPointerMove);
canvas.addEventListener('pointerup', onPointerUp);
```

---

## 4. 선택 영역 하이라이트

### 방법 1: 별도 Mesh 생성
```javascript
let highlightMesh = null;

function updateHighlight() {
  // 기존 하이라이트 제거
  if (highlightMesh) {
    scene.remove(highlightMesh);
    highlightMesh.geometry.dispose();
    highlightMesh.material.dispose();
  }
  
  // 선택된 면들로 새 지오메트리 생성
  const selectedGeometry = extractSelectedFaces(faceMesh.geometry, selectedFaces);
  
  const highlightMaterial = new THREE.MeshBasicMaterial({
    color: 0xff6600,
    transparent: true,
    opacity: 0.6,
    side: THREE.DoubleSide
  });
  
  highlightMesh = new THREE.Mesh(selectedGeometry, highlightMaterial);
  highlightMesh.position.copy(faceMesh.position);
  highlightMesh.rotation.copy(faceMesh.rotation);
  highlightMesh.scale.copy(faceMesh.scale);
  
  // 약간 앞으로 이동 (Z-fighting 방지)
  highlightMesh.position.z += 0.001;
  
  scene.add(highlightMesh);
}

function extractSelectedFaces(geometry, faceSet) {
  const position = geometry.attributes.position;
  const normal = geometry.attributes.normal;
  const uv = geometry.attributes.uv;
  
  const newPositions = [];
  const newNormals = [];
  const newUvs = [];
  
  for (const faceIndex of faceSet) {
    const idx = faceIndex * 3;
    
    // 세 꼭짓점 복사
    for (let i = 0; i < 3; i++) {
      const vi = idx + i;
      
      newPositions.push(
        position.getX(vi),
        position.getY(vi),
        position.getZ(vi)
      );
      
      if (normal) {
        newNormals.push(
          normal.getX(vi),
          normal.getY(vi),
          normal.getZ(vi)
        );
      }
      
      if (uv) {
        newUvs.push(
          uv.getX(vi),
          uv.getY(vi)
        );
      }
    }
  }
  
  const newGeometry = new THREE.BufferGeometry();
  newGeometry.setAttribute('position', 
    new THREE.Float32BufferAttribute(newPositions, 3));
  
  if (newNormals.length > 0) {
    newGeometry.setAttribute('normal', 
      new THREE.Float32BufferAttribute(newNormals, 3));
  }
  
  if (newUvs.length > 0) {
    newGeometry.setAttribute('uv', 
      new THREE.Float32BufferAttribute(newUvs, 2));
  }
  
  return newGeometry;
}
```

### 방법 2: Shader로 하이라이트 (더 효율적)
```javascript
const material = new THREE.MeshStandardMaterial({
  color: 0xcccccc,
  onBeforeCompile: (shader) => {
    // Uniform 추가
    shader.uniforms.selectedFaces = { value: new Float32Array(maxFaces) };
    
    // Vertex Shader 수정
    shader.vertexShader = shader.vertexShader.replace(
      '#include <common>',
      `
      #include <common>
      attribute float faceIndex;
      varying float vFaceIndex;
      `
    );
    
    shader.vertexShader = shader.vertexShader.replace(
      '#include <begin_vertex>',
      `
      #include <begin_vertex>
      vFaceIndex = faceIndex;
      `
    );
    
    // Fragment Shader 수정
    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <common>',
      `
      #include <common>
      uniform float selectedFaces[${maxFaces}];
      varying float vFaceIndex;
      `
    );
    
    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <color_fragment>',
      `
      #include <color_fragment>
      
      int fIdx = int(vFaceIndex);
      if (fIdx >= 0 && fIdx < ${maxFaces} && selectedFaces[fIdx] > 0.5) {
        diffuseColor.rgb = mix(diffuseColor.rgb, vec3(1.0, 0.4, 0.0), 0.6);
      }
      `
    );
    
    material.userData.shader = shader;
  }
});

// 선택 업데이트
function updateShaderSelection() {
  const shader = material.userData.shader;
  if (!shader) return;
  
  const selectedArray = new Float32Array(maxFaces);
  for (const faceIndex of selectedFaces) {
    selectedArray[faceIndex] = 1.0;
  }
  
  shader.uniforms.selectedFaces.value = selectedArray;
}
```

---

## 5. OrbitControls와 선택 로직 통합

### 문제: OrbitControls가 선택 이벤트를 방해
```javascript
// OrbitControls는 기본적으로 모든 포인터 이벤트를 가로챔
// 해결: 클릭/드래그 구분
```

### 해결 1: 클릭 vs 드래그 구분
```javascript
let pointerDownPosition = new THREE.Vector2();
let pointerUpPosition = new THREE.Vector2();
const clickThreshold = 5; // 픽셀

function onPointerDown(event) {
  pointerDownPosition.set(event.clientX, event.clientY);
}

function onPointerUp(event) {
  pointerUpPosition.set(event.clientX, event.clientY);
  
  const distance = pointerDownPosition.distanceTo(pointerUpPosition);
  
  // 거의 움직이지 않았으면 클릭으로 간주
  if (distance < clickThreshold) {
    handleClick(event);
  }
}

function handleClick(event) {
  updatePointer(event);
  raycaster.setFromCamera(pointer, camera);
  
  const intersects = raycaster.intersectObject(faceMesh);
  if (intersects.length > 0) {
    const faceIndex = intersects[0].faceIndex;
    toggleFaceSelection(faceIndex);
  }
}
```

### 해결 2: 조건부 OrbitControls 활성화
```javascript
const controls = new OrbitControls(camera, renderer.domElement);

// Shift 키를 누르면 선택 모드
let isSelectionMode = false;

document.addEventListener('keydown', (e) => {
  if (e.key === 'Shift') {
    isSelectionMode = true;
    controls.enabled = false;
  }
});

document.addEventListener('keyup', (e) => {
  if (e.key === 'Shift') {
    isSelectionMode = false;
    controls.enabled = true;
  }
});

canvas.addEventListener('pointerdown', (e) => {
  if (isSelectionMode) {
    startSelection(e);
  }
});
```

### 해결 3: 오른쪽 클릭으로 선택
```javascript
canvas.addEventListener('contextmenu', (e) => {
  e.preventDefault();
  handleSelection(e);
});

// OrbitControls는 왼쪽 클릭과 드래그만 처리
controls.mouseButtons = {
  LEFT: THREE.MOUSE.ROTATE,
  MIDDLE: THREE.MOUSE.DOLLY,
  RIGHT: null  // 오른쪽 클릭 비활성화
};
```

---

## 6. Flutter와 Three.js 인터랙션 통합

### Flutter → Three.js 이벤트 전달

**Flutter 측 (Dart):**
```dart
class ThreeJSViewer extends StatefulWidget {
  @override
  _ThreeJSViewerState createState() => _ThreeJSViewerState();
}

class _ThreeJSViewerState extends State<ThreeJSViewer> {
  late ThreeJsController controller;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        
        // Three.js로 좌표 전달
        controller.evalJavaScript('''
          handleTouch(
            ${localPosition.dx}, 
            ${localPosition.dy},
            ${box.size.width},
            ${box.size.height}
          );
        ''');
      },
      child: ThreeJs(
        onCreated: (controller) {
          this.controller = controller;
          _initScene();
        },
      ),
    );
  }
}
```

**Three.js 측 (JavaScript):**
```javascript
// Flutter에서 호출할 전역 함수
window.handleTouch = function(x, y, width, height) {
  // 정규화된 좌표로 변환
  pointer.x = (x / width) * 2 - 1;
  pointer.y = -(y / height) * 2 + 1;
  
  raycaster.setFromCamera(pointer, camera);
  const intersects = raycaster.intersectObject(mesh);
  
  if (intersects.length > 0) {
    const faceIndex = intersects[0].faceIndex;
    selectFace(faceIndex);
    
    // Flutter로 결과 전송
    sendToFlutter({ type: 'faceSelected', faceIndex: faceIndex });
  }
};

function sendToFlutter(data) {
  // flutter_threejs 패키지의 메시지 채널
  if (window.flutterChannel) {
    window.flutterChannel.postMessage(JSON.stringify(data));
  }
}
```

### Flutter에서 선택 상태 수신
```dart
controller.onMessage.listen((message) {
  final data = jsonDecode(message);
  
  if (data['type'] == 'faceSelected') {
    setState(() {
      selectedFaceIndex = data['faceIndex'];
    });
    
    // UI 업데이트, 상세 정보 표시 등
    showFaceDetails(selectedFaceIndex);
  }
});
```

---

## 7. 성능 최적화

### Raycasting 최적화

**1. 교차 대상 제한**
```javascript
// 전체 씬 대신 특정 객체만
const intersects = raycaster.intersectObject(faceMesh, false);

// 재귀 검사 비활성화 (마지막 인자 false)
```

**2. 레이 길이 제한**
```javascript
raycaster.near = 0.1;
raycaster.far = 100;  // 불필요하게 먼 객체 제외
```

**3. 쓰로틀링**
```javascript
let lastRaycastTime = 0;
const raycastInterval = 50; // ms

function onPointerMove(event) {
  const now = Date.now();
  
  if (now - lastRaycastTime < raycastInterval) {
    return;
  }
  
  lastRaycastTime = now;
  performRaycast(event);
}
```

**4. BVH (Bounding Volume Hierarchy) 사용**
```javascript
import { computeBoundsTree, disposeBoundsTree, acceleratedRaycast } 
  from 'three-mesh-bvh';

THREE.BufferGeometry.prototype.computeBoundsTree = computeBoundsTree;
THREE.BufferGeometry.prototype.disposeBoundsTree = disposeBoundsTree;
THREE.Mesh.prototype.raycast = acceleratedRaycast;

// 지오메트리 로드 후
geometry.computeBoundsTree();

// 10배 이상 성능 향상 가능
```

---

## 8. 디버깅 도구

### 레이 시각화
```javascript
let rayHelper = null;

function visualizeRay() {
  if (rayHelper) {
    scene.remove(rayHelper);
  }
  
  const origin = raycaster.ray.origin.clone();
  const direction = raycaster.ray.direction.clone();
  
  rayHelper = new THREE.ArrowHelper(
    direction,
    origin,
    100,        // 길이
    0xff0000    // 색상
  );
  
  scene.add(rayHelper);
}
```

### 교차점 마커
```javascript
let intersectionMarker = null;

function showIntersectionPoint(point) {
  if (!intersectionMarker) {
    const geometry = new THREE.SphereGeometry(0.02);
    const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
    intersectionMarker = new THREE.Mesh(geometry, material);
    scene.add(intersectionMarker);
  }
  
  intersectionMarker.position.copy(point);
  intersectionMarker.visible = true;
}
```

### 콘솔 로깅
```javascript
function debugIntersection(intersect) {
  console.group('Intersection Debug');
  console.log('Object:', intersect.object.name);
  console.log('Distance:', intersect.distance.toFixed(3));
  console.log('Point:', intersect.point);
  console.log('Face Index:', intersect.faceIndex);
  console.log('UV:', intersect.uv);
  console.groupEnd();
}
```

---

## 실무 체크리스트

- [ ] Raycaster 초기화 및 좌표 정규화 구현
- [ ] 클릭 vs 드래그 구분 로직
- [ ] OrbitControls와 충돌 방지
- [ ] Set 자료구조로 선택 상태 관리
- [ ] 하이라이트 렌더링 구현
- [ ] Flutter 이벤트 브리지 연결
- [ ] 쓰로틀링으로 성능 최적화
- [ ] BVH 가속 구조 적용 검토
- [ ] 디버그 시각화 도구 준비

---

## 참고 자료

- [Three.js Raycaster 문서](https://threejs.org/docs/#api/en/core/Raycaster)
- [three-mesh-bvh (BVH 가속)](https://github.com/gkjohnson/three-mesh-bvh)
- [OrbitControls 문서](https://threejs.org/docs/#examples/en/controls/OrbitControls)

