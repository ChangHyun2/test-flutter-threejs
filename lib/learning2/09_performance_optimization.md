# 성능 최적화 전략

## 1. FPS 측정 및 모니터링

### Stats.js 통합
```bash
npm install stats.js
```

```javascript
import Stats from 'stats.js';

const stats = new Stats();
stats.showPanel(0);  // 0: fps, 1: ms, 2: mb, 3+: custom
document.body.appendChild(stats.dom);

function animate() {
  stats.begin();
  
  // 렌더링 로직
  renderer.render(scene, camera);
  
  stats.end();
  
  requestAnimationFrame(animate);
}

animate();
```

### FPS 카운터 직접 구현
```javascript
class FPSCounter {
  constructor() {
    this.frames = 0;
    this.lastTime = performance.now();
    this.fps = 0;
    this.element = null;
    
    this.createDisplay();
  }
  
  createDisplay() {
    this.element = document.createElement('div');
    this.element.style.position = 'fixed';
    this.element.style.top = '10px';
    this.element.style.left = '10px';
    this.element.style.color = 'lime';
    this.element.style.fontFamily = 'monospace';
    this.element.style.fontSize = '16px';
    this.element.style.background = 'rgba(0,0,0,0.7)';
    this.element.style.padding = '5px 10px';
    this.element.style.zIndex = '10000';
    document.body.appendChild(this.element);
  }
  
  update() {
    this.frames++;
    
    const currentTime = performance.now();
    const elapsed = currentTime - this.lastTime;
    
    if (elapsed >= 1000) {
      this.fps = Math.round((this.frames * 1000) / elapsed);
      this.frames = 0;
      this.lastTime = currentTime;
      
      this.element.textContent = `FPS: ${this.fps}`;
      
      // 경고 색상
      if (this.fps < 30) {
        this.element.style.color = 'red';
      } else if (this.fps < 50) {
        this.element.style.color = 'yellow';
      } else {
        this.element.style.color = 'lime';
      }
    }
  }
}

// 사용
const fpsCounter = new FPSCounter();

function animate() {
  requestAnimationFrame(animate);
  
  fpsCounter.update();
  
  renderer.render(scene, camera);
}
```

### Frame Time 측정
```javascript
class PerformanceMonitor {
  constructor(sampleSize = 60) {
    this.sampleSize = sampleSize;
    this.frameTimes = [];
    this.lastFrameTime = performance.now();
  }
  
  update() {
    const currentTime = performance.now();
    const frameTime = currentTime - this.lastFrameTime;
    
    this.frameTimes.push(frameTime);
    
    if (this.frameTimes.length > this.sampleSize) {
      this.frameTimes.shift();
    }
    
    this.lastFrameTime = currentTime;
  }
  
  getAverageFrameTime() {
    const sum = this.frameTimes.reduce((a, b) => a + b, 0);
    return sum / this.frameTimes.length;
  }
  
  getFPS() {
    return 1000 / this.getAverageFrameTime();
  }
  
  getMin() {
    return Math.min(...this.frameTimes);
  }
  
  getMax() {
    return Math.max(...this.frameTimes);
  }
  
  getReport() {
    return {
      fps: this.getFPS().toFixed(1),
      avg: this.getAverageFrameTime().toFixed(2) + 'ms',
      min: this.getMin().toFixed(2) + 'ms',
      max: this.getMax().toFixed(2) + 'ms'
    };
  }
}
```

---

## 2. 메모리 측정

### Three.js Renderer Info
```javascript
console.log(renderer.info);

/*
{
  memory: {
    geometries: 10,
    textures: 5
  },
  render: {
    frame: 1234,
    calls: 15,     // Draw calls
    triangles: 50000,
    points: 0,
    lines: 0
  },
  programs: 3
}
*/
```

### Memory API (Chrome)
```javascript
if (performance.memory) {
  console.log({
    totalJSHeapSize: (performance.memory.totalJSHeapSize / 1048576).toFixed(2) + ' MB',
    usedJSHeapSize: (performance.memory.usedJSHeapSize / 1048576).toFixed(2) + ' MB',
    jsHeapSizeLimit: (performance.memory.jsHeapSizeLimit / 1048576).toFixed(2) + ' MB'
  });
}
```

### 메모리 프로파일러
```javascript
class MemoryProfiler {
  constructor() {
    this.snapshots = [];
  }
  
  takeSnapshot(label = '') {
    if (!performance.memory) {
      console.warn('Memory API not available');
      return;
    }
    
    const snapshot = {
      label: label,
      timestamp: Date.now(),
      used: performance.memory.usedJSHeapSize,
      total: performance.memory.totalJSHeapSize,
      limit: performance.memory.jsHeapSizeLimit
    };
    
    this.snapshots.push(snapshot);
    
    return snapshot;
  }
  
  compare(index1, index2) {
    const s1 = this.snapshots[index1];
    const s2 = this.snapshots[index2];
    
    const diff = s2.used - s1.used;
    
    console.log(`Memory change from "${s1.label}" to "${s2.label}":`,
      (diff / 1048576).toFixed(2) + ' MB'
    );
    
    return diff;
  }
  
  printReport() {
    console.table(this.snapshots.map(s => ({
      label: s.label,
      used: (s.used / 1048576).toFixed(2) + ' MB',
      total: (s.total / 1048576).toFixed(2) + ' MB'
    })));
  }
}

// 사용
const profiler = new MemoryProfiler();

profiler.takeSnapshot('Initial');

// 모델 로드
loader.load('model.glb', (gltf) => {
  scene.add(gltf.scene);
  profiler.takeSnapshot('After model load');
  profiler.compare(0, 1);
});
```

---

## 3. Geometry 최적화

### 1. Geometry 병합
```javascript
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

// 나쁜 예: 1000개 메쉬 = 1000 draw calls
for (let i = 0; i < 1000; i++) {
  const mesh = new THREE.Mesh(geometry, material);
  mesh.position.set(i * 2, 0, 0);
  scene.add(mesh);
}

// 좋은 예: 하나의 메쉬 = 1 draw call
const geometries = [];
for (let i = 0; i < 1000; i++) {
  const geo = geometry.clone();
  geo.translate(i * 2, 0, 0);
  geometries.push(geo);
}

const merged = mergeGeometries(geometries);
const mesh = new THREE.Mesh(merged, material);
scene.add(mesh);
```

### 2. InstancedMesh (대량 복제)
```javascript
const geometry = new THREE.BoxGeometry(1, 1, 1);
const material = new THREE.MeshStandardMaterial({ color: 0x00ff00 });
const count = 10000;

const instancedMesh = new THREE.InstancedMesh(geometry, material, count);

const matrix = new THREE.Matrix4();
const color = new THREE.Color();

for (let i = 0; i < count; i++) {
  // 위치
  matrix.setPosition(
    Math.random() * 100 - 50,
    Math.random() * 100 - 50,
    Math.random() * 100 - 50
  );
  
  instancedMesh.setMatrixAt(i, matrix);
  
  // 색상 (선택)
  color.setHSL(Math.random(), 1.0, 0.5);
  instancedMesh.setColorAt(i, color);
}

instancedMesh.instanceMatrix.needsUpdate = true;
if (instancedMesh.instanceColor) {
  instancedMesh.instanceColor.needsUpdate = true;
}

scene.add(instancedMesh);
```

### 3. LOD (Level of Detail)
```javascript
const lod = new THREE.LOD();

// 가까이: 고해상도
const highDetail = new THREE.Mesh(
  new THREE.IcosahedronGeometry(1, 4),
  material
);
lod.addLevel(highDetail, 0);

// 중간: 중해상도
const mediumDetail = new THREE.Mesh(
  new THREE.IcosahedronGeometry(1, 2),
  material
);
lod.addLevel(mediumDetail, 20);

// 멀리: 저해상도
const lowDetail = new THREE.Mesh(
  new THREE.IcosahedronGeometry(1, 0),
  material
);
lod.addLevel(lowDetail, 50);

scene.add(lod);

// 카메라 거리에 따라 자동 전환
function animate() {
  lod.update(camera);
  renderer.render(scene, camera);
}
```

### 4. Geometry 단순화
```javascript
import { SimplifyModifier } from 'three/addons/modifiers/SimplifyModifier.js';

const modifier = new SimplifyModifier();

// 50%로 폴리곤 감소
const simplified = geometry.clone();
const targetCount = Math.floor(geometry.attributes.position.count * 0.5);
modifier.modify(simplified, targetCount);
```

---

## 4. Material 최적화

### Material 공유
```javascript
// 나쁜 예: 각 메쉬마다 새 Material
for (let i = 0; i < 100; i++) {
  const material = new THREE.MeshStandardMaterial({ color: 0xff0000 });
  const mesh = new THREE.Mesh(geometry, material);
  scene.add(mesh);
}

// 좋은 예: Material 공유
const sharedMaterial = new THREE.MeshStandardMaterial({ color: 0xff0000 });
for (let i = 0; i < 100; i++) {
  const mesh = new THREE.Mesh(geometry, sharedMaterial);
  scene.add(mesh);
}
```

### Material 단순화
```javascript
// 조명 불필요시 MeshBasicMaterial 사용
const basicMaterial = new THREE.MeshBasicMaterial({ 
  color: 0xff0000,
  map: texture
});

// MeshLambertMaterial (Phong보다 빠름)
const lambertMaterial = new THREE.MeshLambertMaterial({
  color: 0xff0000
});

// 필요시에만 MeshStandardMaterial
const standardMaterial = new THREE.MeshStandardMaterial({
  color: 0xff0000,
  roughness: 0.5,
  metalness: 0.5
});
```

### flatShading으로 성능 향상
```javascript
material.flatShading = true;
// 정점 노말 대신 면 노말 사용 → 계산 간소화
```

---

## 5. 텍스처 최적화

### 텍스처 크기 최적화
```javascript
// 2의 거듭제곱 크기 사용 (POT: Power of Two)
// 좋음: 256, 512, 1024, 2048
// 나쁨: 300, 600, 1500

// 과도하게 큰 텍스처 축소
const loader = new THREE.TextureLoader();
const texture = loader.load('texture.jpg', (tex) => {
  // 최대 크기 제한
  if (tex.image.width > 2048 || tex.image.height > 2048) {
    console.warn('Texture too large, consider resizing');
  }
});
```

### 압축 텍스처
```javascript
import { KTX2Loader } from 'three/addons/loaders/KTX2Loader.js';

const ktx2Loader = new KTX2Loader();
ktx2Loader.setTranscoderPath('/basis/');
ktx2Loader.detectSupport(renderer);

ktx2Loader.load('texture.ktx2', (texture) => {
  material.map = texture;
  material.needsUpdate = true;
});
```

### 밉맵 최적화
```javascript
// POT 텍스처: 밉맵 자동 생성
texture.generateMipmaps = true;

// NPOT 텍스처: 밉맵 비활성화
texture.generateMipmaps = false;
texture.minFilter = THREE.LinearFilter;
texture.magFilter = THREE.LinearFilter;

// 밉맵 미사용 시 메모리 33% 절약
```

### 텍스처 아틀라스
```javascript
// 여러 작은 텍스처를 하나의 큰 텍스처로 합치기
// UV 좌표를 조정하여 사용
```

---

## 6. 렌더링 최적화

### Frustum Culling (자동)
```javascript
// Three.js가 자동으로 수행
// 카메라 시야 밖 객체는 렌더링 안 함

// 수동 제어 (특별한 경우)
mesh.frustumCulled = false;  // 항상 렌더링
```

### 수동 Culling
```javascript
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

// 렌더 전 체크
objects.forEach(obj => {
  obj.visible = isInViewport(obj, camera);
});
```

### 렌더 타겟 최적화
```javascript
// 필요시에만 렌더
let needsRender = true;

controls.addEventListener('change', () => {
  needsRender = true;
});

function animate() {
  requestAnimationFrame(animate);
  
  if (needsRender) {
    renderer.render(scene, camera);
    needsRender = false;
  }
}
```

### Shadow Map 최적화
```javascript
// Shadow Map 해상도 조정
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;

light.castShadow = true;
light.shadow.mapSize.width = 1024;   // 기본: 512
light.shadow.mapSize.height = 1024;

// 불필요한 객체는 그림자 비활성화
mesh.castShadow = false;
mesh.receiveShadow = false;
```

---

## 7. Draw Call 감소

### Draw Call 확인
```javascript
console.log('Draw calls:', renderer.info.render.calls);
```

### 배칭 전략
```javascript
// 1. 같은 Material 사용
// 2. Geometry 병합 (mergeGeometries)
// 3. InstancedMesh 사용
// 4. 정적 객체는 Group으로 묶기
```

### Material 정렬
```javascript
// Three.js가 자동으로 Material별로 정렬하여 렌더링
// 같은 Material을 사용하는 객체끼리 연속으로 그림
```

---

## 8. 메모리 관리

### 리소스 해제
```javascript
function disposeNode(node) {
  if (node.geometry) {
    node.geometry.dispose();
  }
  
  if (node.material) {
    if (Array.isArray(node.material)) {
      node.material.forEach(material => disposeMaterial(material));
    } else {
      disposeMaterial(node.material);
    }
  }
  
  if (node.texture) {
    node.texture.dispose();
  }
}

function disposeMaterial(material) {
  material.dispose();
  
  // 텍스처 해제
  for (const key in material) {
    const value = material[key];
    if (value && typeof value === 'object' && 'minFilter' in value) {
      value.dispose();
    }
  }
}

// 객체 제거 시
scene.traverse(disposeNode);
scene.remove(object);
```

### 순환 참조 방지
```javascript
// 나쁜 예
mesh.userData.parent = scene;  // 순환 참조

// 좋은 예
mesh.userData.parentId = 'scene_main';
```

### WeakMap 활용
```javascript
const meshData = new WeakMap();

meshData.set(mesh, { 
  id: 123,
  metadata: { ... }
});

// mesh가 삭제되면 자동으로 WeakMap 항목도 제거됨
```

---

## 9. 모바일 최적화

### 해상도 조정
```javascript
// Pixel Ratio 제한
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));

// 모바일에서 낮은 해상도
if (isMobile()) {
  renderer.setPixelRatio(1);
}
```

### 복잡도 감소
```javascript
function isMobile() {
  return /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
}

if (isMobile()) {
  // 간단한 Material
  material = new THREE.MeshLambertMaterial();
  
  // 낮은 폴리곤 모델
  geometry = lowPolyGeometry;
  
  // 그림자 비활성화
  renderer.shadowMap.enabled = false;
  
  // 안티앨리어싱 비활성화
  renderer.antialias = false;
}
```

### 터치 이벤트 최적화
```javascript
// 패시브 이벤트 리스너
canvas.addEventListener('touchstart', handler, { passive: true });
canvas.addEventListener('touchmove', handler, { passive: true });
```

---

## 10. 프로파일링 도구

### Chrome DevTools
```javascript
// Performance 탭
// 1. 녹화 시작
// 2. 상호작용
// 3. 녹화 중지
// 4. Flame Chart 분석

// Memory 탭
// 1. Heap Snapshot
// 2. 메모리 누수 확인
```

### three-devtools (확장 프로그램)
```javascript
// Chrome 확장 설치: three-devtools
// Scene 구조, Draw Calls, Memory 확인
```

### Custom 프로파일러
```javascript
class ThreeProfiler {
  constructor(renderer, scene) {
    this.renderer = renderer;
    this.scene = scene;
  }
  
  getReport() {
    return {
      // Renderer Info
      drawCalls: this.renderer.info.render.calls,
      triangles: this.renderer.info.render.triangles,
      
      // Scene
      objectCount: this.countObjects(this.scene),
      
      // Memory
      geometries: this.renderer.info.memory.geometries,
      textures: this.renderer.info.memory.textures,
      
      // Custom
      visibleObjects: this.countVisibleObjects(this.scene)
    };
  }
  
  countObjects(object) {
    let count = 1;
    object.children.forEach(child => {
      count += this.countObjects(child);
    });
    return count;
  }
  
  countVisibleObjects(object) {
    let count = object.visible ? 1 : 0;
    object.children.forEach(child => {
      count += this.countVisibleObjects(child);
    });
    return count;
  }
  
  printReport() {
    console.table(this.getReport());
  }
}

// 사용
const profiler = new ThreeProfiler(renderer, scene);
setInterval(() => {
  profiler.printReport();
}, 5000);
```

---

## 11. 최적화 체크리스트

### Geometry
- [ ] 불필요한 정점 제거
- [ ] Geometry 병합 (정적 객체)
- [ ] InstancedMesh 활용 (반복 객체)
- [ ] LOD 구현 (거리별 상세도)
- [ ] Frustum Culling 활성화

### Material
- [ ] Material 재사용
- [ ] 필요시에만 고급 Material 사용
- [ ] flatShading 적용 가능 여부 확인
- [ ] 불필요한 Material 제거

### Texture
- [ ] POT 크기 사용
- [ ] 텍스처 압축 (KTX2/Basis)
- [ ] 밉맵 최적화
- [ ] 텍스처 아틀라스

### Lighting
- [ ] 라이트 개수 최소화
- [ ] Shadow Map 해상도 조정
- [ ] 정적 라이팅 Bake (가능시)

### Rendering
- [ ] Draw Call 최소화
- [ ] Pixel Ratio 제한
- [ ] 필요시에만 렌더 (정적 씬)
- [ ] Anti-aliasing 선택적 적용

### Memory
- [ ] 리소스 dispose 구현
- [ ] 순환 참조 제거
- [ ] WeakMap/WeakSet 활용
- [ ] 메모리 프로파일링

### Mobile
- [ ] 해상도 낮춤
- [ ] 복잡도 감소
- [ ] 터치 이벤트 최적화
- [ ] 배터리 소모 고려

---

## 실무 체크리스트

- [ ] FPS/메모리 모니터링 도구 통합
- [ ] Draw Call 최소화 전략
- [ ] Geometry/Material 최적화
- [ ] 텍스처 압축 및 크기 조정
- [ ] LOD 시스템 구현
- [ ] 메모리 프로파일러 설정
- [ ] 모바일 대응 최적화
- [ ] 정기 성능 측정 및 리포트

---

## 참고 자료

- [Three.js Performance Tips](https://threejs.org/docs/#manual/en/introduction/How-to-dispose-of-objects)
- [Stats.js](https://github.com/mrdoob/stats.js/)
- [BufferGeometryUtils](https://threejs.org/docs/#examples/en/utils/BufferGeometryUtils)
- [Chrome DevTools](https://developer.chrome.com/docs/devtools/performance/)

