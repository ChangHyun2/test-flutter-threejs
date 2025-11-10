# 통합 실습 가이드 - 영역 선택/확대/화살표 표현

## 개요

이 가이드는 앞서 학습한 모든 내용을 통합하여 **얼굴 모델에서 여드름 영역을 선택하고, 확대하며, 변화량을 화살표로 표시하는** 완전한 시스템을 구축합니다.

---

## 1. 프로젝트 구조

```
project/
├── src/
│   ├── core/
│   │   ├── Scene.js              # 씬 초기화
│   │   ├── Camera.js             # 카메라 관리
│   │   └── Renderer.js           # 렌더러 설정
│   ├── models/
│   │   ├── ModelLoader.js        # GLTF/OBJ 로더
│   │   └── FaceModel.js          # 얼굴 모델 클래스
│   ├── interactions/
│   │   ├── Raycaster.js          # 레이캐스팅
│   │   └── SelectionManager.js   # 선택 관리
│   ├── visualization/
│   │   ├── HighlightRenderer.js  # 하이라이트
│   │   ├── ZoomController.js     # 확대 제어
│   │   └── ArrowVisualizer.js    # 화살표 표시
│   ├── animation/
│   │   └── TransitionManager.js  # 애니메이션
│   └── utils/
│       ├── GeometryUtils.js      # Geometry 유틸
│       ├── ScaleManager.js       # 스케일 관리
│       └── PerformanceMonitor.js # 성능 모니터
├── assets/
│   └── models/
│       ├── face_before.glb
│       └── face_after.glb
└── index.html
```

---

## 2. 핵심 클래스 구현

### 2.1 Scene 초기화

```javascript
// src/core/Scene.js
import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';

export class SceneManager {
  constructor(container) {
    this.container = container;
    
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(0x1a1a1a);
    
    this.setupCamera();
    this.setupRenderer();
    this.setupLights();
    this.setupControls();
  }
  
  setupCamera() {
    const aspect = this.container.clientWidth / this.container.clientHeight;
    this.camera = new THREE.PerspectiveCamera(50, aspect, 0.1, 1000);
    this.camera.position.set(0, 0, 15);
  }
  
  setupRenderer() {
    this.renderer = new THREE.WebGLRenderer({ 
      antialias: true,
      alpha: true
    });
    
    this.renderer.setSize(
      this.container.clientWidth, 
      this.container.clientHeight
    );
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    
    this.container.appendChild(this.renderer.domElement);
  }
  
  setupLights() {
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    this.scene.add(ambientLight);
    
    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(5, 10, 7.5);
    this.scene.add(directionalLight);
    
    const fillLight = new THREE.DirectionalLight(0xffffff, 0.3);
    fillLight.position.set(-5, 0, -5);
    this.scene.add(fillLight);
  }
  
  setupControls() {
    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.enableDamping = true;
    this.controls.dampingFactor = 0.05;
    this.controls.minDistance = 5;
    this.controls.maxDistance = 50;
  }
  
  onWindowResize() {
    this.camera.aspect = this.container.clientWidth / this.container.clientHeight;
    this.camera.updateProjectionMatrix();
    
    this.renderer.setSize(
      this.container.clientWidth,
      this.container.clientHeight
    );
  }
  
  render() {
    this.renderer.render(this.scene, this.camera);
  }
  
  update() {
    this.controls.update();
  }
}
```

### 2.2 FaceModel 클래스

```javascript
// src/models/FaceModel.js
import * as THREE from 'three';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

export class FaceModel {
  constructor(scene) {
    this.scene = scene;
    this.loader = new GLTFLoader();
    
    this.root = new THREE.Group();
    this.root.name = 'FaceModel';
    this.scene.add(this.root);
    
    this.mainMesh = null;
    this.keypoints = [];
  }
  
  async load(url, options = {}) {
    return new Promise((resolve, reject) => {
      this.loader.load(
        url,
        (gltf) => {
          this.mainMesh = gltf.scene.children[0];
          
          // 스케일 정규화
          if (options.normalizeScale) {
            this.normalizeScale(options.targetSize || 10);
          }
          
          // 중심 정렬
          if (options.center) {
            this.centerModel();
          }
          
          this.root.add(this.mainMesh);
          resolve(this);
        },
        (progress) => {
          if (options.onProgress) {
            options.onProgress(progress.loaded / progress.total);
          }
        },
        reject
      );
    });
  }
  
  normalizeScale(targetSize) {
    const box = new THREE.Box3().setFromObject(this.mainMesh);
    const size = box.getSize(new THREE.Vector3());
    const maxDim = Math.max(size.x, size.y, size.z);
    const scale = targetSize / maxDim;
    
    this.mainMesh.scale.multiplyScalar(scale);
  }
  
  centerModel() {
    const box = new THREE.Box3().setFromObject(this.mainMesh);
    const center = box.getCenter(new THREE.Vector3());
    this.mainMesh.position.sub(center);
  }
  
  setKeypoints(keypoints) {
    this.keypoints = keypoints;
  }
  
  getGeometry() {
    return this.mainMesh.geometry;
  }
  
  getMesh() {
    return this.mainMesh;
  }
}
```

### 2.3 SelectionManager

```javascript
// src/interactions/SelectionManager.js
import * as THREE from 'three';

export class SelectionManager {
  constructor(scene, camera, canvas) {
    this.scene = scene;
    this.camera = camera;
    this.canvas = canvas;
    
    this.raycaster = new THREE.Raycaster();
    this.pointer = new THREE.Vector2();
    
    this.selectedFaces = new Set();
    this.targetMesh = null;
    
    this.brushRadius = 0.5;
    this.isSelecting = false;
    
    this.setupEventListeners();
  }
  
  setTargetMesh(mesh) {
    this.targetMesh = mesh;
  }
  
  setupEventListeners() {
    this.canvas.addEventListener('pointerdown', this.onPointerDown.bind(this));
    this.canvas.addEventListener('pointermove', this.onPointerMove.bind(this));
    this.canvas.addEventListener('pointerup', this.onPointerUp.bind(this));
  }
  
  onPointerDown(event) {
    if (event.shiftKey) {
      this.isSelecting = true;
      this.selectAtPointer(event);
    }
  }
  
  onPointerMove(event) {
    if (this.isSelecting) {
      this.selectAtPointer(event);
    }
  }
  
  onPointerUp(event) {
    this.isSelecting = false;
  }
  
  updatePointer(event) {
    const rect = this.canvas.getBoundingClientRect();
    this.pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
    this.pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
  }
  
  selectAtPointer(event) {
    if (!this.targetMesh) return;
    
    this.updatePointer(event);
    this.raycaster.setFromCamera(this.pointer, this.camera);
    
    const intersects = this.raycaster.intersectObject(this.targetMesh);
    
    if (intersects.length > 0) {
      const faceIndex = intersects[0].faceIndex;
      this.selectRegion(faceIndex, this.brushRadius);
    }
  }
  
  selectRegion(centerFaceIndex, radius) {
    const geometry = this.targetMesh.geometry;
    const position = geometry.attributes.position;
    
    const centerPoint = this.getFaceCenter(geometry, centerFaceIndex);
    
    const faceCount = geometry.index 
      ? geometry.index.count / 3 
      : position.count / 3;
    
    for (let i = 0; i < faceCount; i++) {
      const faceCenter = this.getFaceCenter(geometry, i);
      const distance = centerPoint.distanceTo(faceCenter);
      
      if (distance <= radius) {
        this.selectedFaces.add(i);
      }
    }
  }
  
  getFaceCenter(geometry, faceIndex) {
    const position = geometry.attributes.position;
    const index = geometry.index;
    
    let idx0, idx1, idx2;
    
    if (index) {
      idx0 = index.getX(faceIndex * 3);
      idx1 = index.getX(faceIndex * 3 + 1);
      idx2 = index.getX(faceIndex * 3 + 2);
    } else {
      idx0 = faceIndex * 3;
      idx1 = faceIndex * 3 + 1;
      idx2 = faceIndex * 3 + 2;
    }
    
    const v1 = new THREE.Vector3().fromBufferAttribute(position, idx0);
    const v2 = new THREE.Vector3().fromBufferAttribute(position, idx1);
    const v3 = new THREE.Vector3().fromBufferAttribute(position, idx2);
    
    return new THREE.Vector3()
      .add(v1)
      .add(v2)
      .add(v3)
      .divideScalar(3);
  }
  
  clearSelection() {
    this.selectedFaces.clear();
  }
  
  getSelectedFaces() {
    return this.selectedFaces;
  }
}
```

### 2.4 HighlightRenderer

```javascript
// src/visualization/HighlightRenderer.js
import * as THREE from 'three';

export class HighlightRenderer {
  constructor(scene) {
    this.scene = scene;
    this.highlightMesh = null;
  }
  
  update(originalMesh, selectedFaces) {
    this.clear();
    
    if (selectedFaces.size === 0) return;
    
    const highlightGeometry = this.extractSelectedFaces(
      originalMesh.geometry,
      selectedFaces
    );
    
    const highlightMaterial = new THREE.MeshBasicMaterial({
      color: 0xff6600,
      transparent: true,
      opacity: 0.6,
      side: THREE.DoubleSide,
      depthTest: true,
      depthWrite: false
    });
    
    this.highlightMesh = new THREE.Mesh(highlightGeometry, highlightMaterial);
    
    this.highlightMesh.position.copy(originalMesh.position);
    this.highlightMesh.rotation.copy(originalMesh.rotation);
    this.highlightMesh.scale.copy(originalMesh.scale);
    
    this.highlightMesh.position.z += 0.001;
    
    this.scene.add(this.highlightMesh);
  }
  
  extractSelectedFaces(geometry, faceSet) {
    const position = geometry.attributes.position;
    const normal = geometry.attributes.normal;
    const uv = geometry.attributes.uv;
    const index = geometry.index;
    
    const newPositions = [];
    const newNormals = [];
    const newUvs = [];
    
    for (const faceIndex of faceSet) {
      let idx0, idx1, idx2;
      
      if (index) {
        idx0 = index.getX(faceIndex * 3);
        idx1 = index.getX(faceIndex * 3 + 1);
        idx2 = index.getX(faceIndex * 3 + 2);
      } else {
        idx0 = faceIndex * 3;
        idx1 = faceIndex * 3 + 1;
        idx2 = faceIndex * 3 + 2;
      }
      
      [idx0, idx1, idx2].forEach(idx => {
        newPositions.push(
          position.getX(idx),
          position.getY(idx),
          position.getZ(idx)
        );
        
        if (normal) {
          newNormals.push(
            normal.getX(idx),
            normal.getY(idx),
            normal.getZ(idx)
          );
        }
        
        if (uv) {
          newUvs.push(
            uv.getX(idx),
            uv.getY(idx)
          );
        }
      });
    }
    
    const newGeometry = new THREE.BufferGeometry();
    newGeometry.setAttribute('position',
      new THREE.Float32BufferAttribute(newPositions, 3)
    );
    
    if (newNormals.length > 0) {
      newGeometry.setAttribute('normal',
        new THREE.Float32BufferAttribute(newNormals, 3)
      );
    }
    
    if (newUvs.length > 0) {
      newGeometry.setAttribute('uv',
        new THREE.Float32BufferAttribute(newUvs, 2)
      );
    }
    
    return newGeometry;
  }
  
  clear() {
    if (this.highlightMesh) {
      this.scene.remove(this.highlightMesh);
      this.highlightMesh.geometry.dispose();
      this.highlightMesh.material.dispose();
      this.highlightMesh = null;
    }
  }
}
```

### 2.5 ArrowVisualizer

```javascript
// src/visualization/ArrowVisualizer.js
import * as THREE from 'three';
import { gsap } from 'gsap';

export class ArrowVisualizer {
  constructor(scene) {
    this.scene = scene;
    this.arrowGroup = new THREE.Group();
    this.arrowGroup.name = 'ChangeArrows';
    this.scene.add(this.arrowGroup);
    
    this.scaleManager = new ScaleManager();
  }
  
  visualizeChanges(beforeKeypoints, afterKeypoints, options = {}) {
    this.clearArrows();
    
    const config = {
      color: 0xff6600,
      minLength: 0.1,
      scaleFactor: 5.0,
      showLabels: true,
      animate: true,
      ...options
    };
    
    const arrows = [];
    
    for (let i = 0; i < beforeKeypoints.length; i++) {
      const before = beforeKeypoints[i];
      const after = afterKeypoints[i];
      
      const change = new THREE.Vector3()
        .subVectors(after.position, before.position);
      
      const magnitude = change.length();
      
      if (magnitude < config.minLength) continue;
      
      const arrow = this.createArrow(
        before.position,
        change,
        magnitude,
        config
      );
      
      this.arrowGroup.add(arrow);
      arrows.push(arrow);
      
      if (config.showLabels) {
        const label = this.createLabel(
          after.position,
          `${magnitude.toFixed(2)}mm`
        );
        this.arrowGroup.add(label);
      }
    }
    
    if (config.animate) {
      this.animateArrows(arrows);
    }
  }
  
  createArrow(origin, direction, magnitude, config) {
    const displayLength = magnitude * config.scaleFactor;
    const normalizedDir = direction.clone().normalize();
    
    const arrow = new THREE.ArrowHelper(
      normalizedDir,
      origin,
      displayLength,
      config.color,
      displayLength * 0.2,
      displayLength * 0.1
    );
    
    arrow.userData = {
      magnitude: magnitude,
      targetLength: displayLength
    };
    
    return arrow;
  }
  
  createLabel(position, text) {
    const canvas = document.createElement('canvas');
    const context = canvas.getContext('2d');
    canvas.width = 256;
    canvas.height = 64;
    
    context.fillStyle = 'rgba(0, 0, 0, 0.7)';
    context.fillRect(0, 0, canvas.width, canvas.height);
    
    context.font = '24px Arial';
    context.fillStyle = 'white';
    context.textAlign = 'center';
    context.fillText(text, 128, 40);
    
    const texture = new THREE.CanvasTexture(canvas);
    const material = new THREE.SpriteMaterial({ map: texture });
    const sprite = new THREE.Sprite(material);
    
    sprite.position.copy(position);
    sprite.position.y += 0.3;
    sprite.scale.set(0.5, 0.125, 1);
    
    return sprite;
  }
  
  animateArrows(arrows) {
    const timeline = gsap.timeline();
    
    arrows.forEach((arrow, index) => {
      const targetLength = arrow.userData.targetLength;
      arrow.setLength(0);
      
      timeline.to(
        { length: 0 },
        {
          length: targetLength,
          duration: 0.8,
          ease: 'power2.out',
          onUpdate: function() {
            arrow.setLength(this.targets()[0].length);
          }
        },
        index * 0.1
      );
    });
  }
  
  clearArrows() {
    while (this.arrowGroup.children.length > 0) {
      const child = this.arrowGroup.children[0];
      
      if (child.geometry) child.geometry.dispose();
      if (child.material) {
        if (child.material.map) child.material.map.dispose();
        child.material.dispose();
      }
      
      this.arrowGroup.remove(child);
    }
  }
}

class ScaleManager {
  constructor() {
    this.worldToReal = 1.0;
    this.arrowScale = 10.0;
    this.minArrowLength = 0.1;
    this.maxArrowLength = 5.0;
  }
  
  realToDisplay(realMagnitude) {
    const worldMagnitude = realMagnitude * this.worldToReal;
    const displayLength = worldMagnitude * this.arrowScale;
    
    return Math.max(
      this.minArrowLength,
      Math.min(this.maxArrowLength, displayLength)
    );
  }
}
```

---

## 3. 메인 애플리케이션

```javascript
// src/main.js
import { SceneManager } from './core/Scene.js';
import { FaceModel } from './models/FaceModel.js';
import { SelectionManager } from './interactions/SelectionManager.js';
import { HighlightRenderer } from './visualization/HighlightRenderer.js';
import { ArrowVisualizer } from './visualization/ArrowVisualizer.js';
import { PerformanceMonitor } from './utils/PerformanceMonitor.js';

class FaceAnalysisApp {
  constructor(container) {
    this.sceneManager = new SceneManager(container);
    
    this.beforeModel = null;
    this.afterModel = null;
    
    this.selectionManager = new SelectionManager(
      this.sceneManager.scene,
      this.sceneManager.camera,
      this.sceneManager.renderer.domElement
    );
    
    this.highlightRenderer = new HighlightRenderer(
      this.sceneManager.scene
    );
    
    this.arrowVisualizer = new ArrowVisualizer(
      this.sceneManager.scene
    );
    
    this.performanceMonitor = new PerformanceMonitor();
    
    this.setupEventListeners();
    this.animate();
  }
  
  async loadModels() {
    this.beforeModel = new FaceModel(this.sceneManager.scene);
    await this.beforeModel.load('assets/models/face_before.glb', {
      normalizeScale: true,
      center: true,
      targetSize: 10
    });
    
    this.afterModel = new FaceModel(this.sceneManager.scene);
    await this.afterModel.load('assets/models/face_after.glb', {
      normalizeScale: true,
      center: true,
      targetSize: 10
    });
    
    this.afterModel.getMesh().visible = false;
    
    this.selectionManager.setTargetMesh(this.beforeModel.getMesh());
    
    console.log('Models loaded');
  }
  
  setupEventListeners() {
    window.addEventListener('resize', () => {
      this.sceneManager.onWindowResize();
    });
    
    // UI 버튼
    document.getElementById('btnShowBefore')?.addEventListener('click', () => {
      this.showBefore();
    });
    
    document.getElementById('btnShowAfter')?.addEventListener('click', () => {
      this.showAfter();
    });
    
    document.getElementById('btnShowChanges')?.addEventListener('click', () => {
      this.showChanges();
    });
    
    document.getElementById('btnClearSelection')?.addEventListener('click', () => {
      this.clearSelection();
    });
  }
  
  showBefore() {
    this.beforeModel.getMesh().visible = true;
    this.afterModel.getMesh().visible = false;
    this.arrowVisualizer.clearArrows();
  }
  
  showAfter() {
    this.beforeModel.getMesh().visible = false;
    this.afterModel.getMesh().visible = true;
    this.arrowVisualizer.clearArrows();
  }
  
  showChanges() {
    this.beforeModel.getMesh().visible = true;
    this.afterModel.getMesh().visible = true;
    
    // 예시 키포인트
    const beforeKeypoints = [
      { name: 'nose', position: new THREE.Vector3(0, 1, 0.5) },
      { name: 'leftCheek', position: new THREE.Vector3(-0.5, 0.5, 0.3) },
      { name: 'rightCheek', position: new THREE.Vector3(0.5, 0.5, 0.3) }
    ];
    
    const afterKeypoints = [
      { name: 'nose', position: new THREE.Vector3(0, 1.05, 0.55) },
      { name: 'leftCheek', position: new THREE.Vector3(-0.52, 0.52, 0.32) },
      { name: 'rightCheek', position: new THREE.Vector3(0.52, 0.52, 0.32) }
    ];
    
    this.arrowVisualizer.visualizeChanges(beforeKeypoints, afterKeypoints, {
      scaleFactor: 5.0,
      animate: true
    });
  }
  
  clearSelection() {
    this.selectionManager.clearSelection();
    this.highlightRenderer.clear();
  }
  
  animate() {
    requestAnimationFrame(() => this.animate());
    
    this.performanceMonitor.begin();
    
    // 선택 영역 하이라이트 업데이트
    const selectedFaces = this.selectionManager.getSelectedFaces();
    if (selectedFaces.size > 0 && this.beforeModel) {
      this.highlightRenderer.update(
        this.beforeModel.getMesh(),
        selectedFaces
      );
    }
    
    this.sceneManager.update();
    this.sceneManager.render();
    
    this.performanceMonitor.end();
  }
}

// 초기화
const container = document.getElementById('canvas-container');
const app = new FaceAnalysisApp(container);
app.loadModels();
```

---

## 4. HTML UI

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>얼굴 분석 시스템</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: 'Noto Sans KR', sans-serif;
      background: #0a0a0a;
      color: #fff;
    }
    
    #canvas-container {
      width: 100vw;
      height: 100vh;
      position: relative;
    }
    
    .controls {
      position: fixed;
      top: 20px;
      right: 20px;
      display: flex;
      flex-direction: column;
      gap: 10px;
      z-index: 100;
    }
    
    .btn {
      padding: 12px 24px;
      background: rgba(255, 102, 0, 0.9);
      color: white;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-size: 14px;
      font-weight: 600;
      transition: all 0.3s;
    }
    
    .btn:hover {
      background: rgba(255, 102, 0, 1);
      transform: translateY(-2px);
    }
    
    .info-panel {
      position: fixed;
      bottom: 20px;
      left: 20px;
      background: rgba(0, 0, 0, 0.8);
      padding: 15px;
      border-radius: 6px;
      font-size: 12px;
      line-height: 1.6;
    }
  </style>
</head>
<body>
  <div id="canvas-container"></div>
  
  <div class="controls">
    <button id="btnShowBefore" class="btn">이전 모델</button>
    <button id="btnShowAfter" class="btn">이후 모델</button>
    <button id="btnShowChanges" class="btn">변화량 표시</button>
    <button id="btnClearSelection" class="btn">선택 초기화</button>
  </div>
  
  <div class="info-panel">
    <div><strong>조작법:</strong></div>
    <div>• 마우스 드래그: 회전</div>
    <div>• 휠: 줌</div>
    <div>• Shift + 클릭/드래그: 영역 선택</div>
  </div>
  
  <script type="module" src="/src/main.js"></script>
</body>
</html>
```

---

## 5. 실행 및 테스트

### 개발 서버 실행
```bash
npm install three gsap stats.js
npm install -D vite
npx vite
```

### 테스트 체크리스트
- [ ] 모델 로딩 확인
- [ ] 카메라 컨트롤 (OrbitControls)
- [ ] Shift + 드래그로 영역 선택
- [ ] 선택 영역 주황색 하이라이트
- [ ] 비포/애프터 전환
- [ ] 화살표 애니메이션
- [ ] FPS 60 유지 확인
- [ ] 메모리 누수 없는지 확인

---

## 6. 확장 아이디어

### 6.1 측정 도구
- 두 점 사이 거리 측정
- 면적 계산
- 부피 변화 계산

### 6.2 비교 모드
- 슬라이더로 비포/애프터 블렌딩
- 사이드 바이 사이드 뷰
- 스플릿 스크린

### 6.3 데이터 분석
- 변화량 히스토그램
- 영역별 통계
- CSV 내보내기

### 6.4 UI/UX 개선
- 미니맵
- 북마크 기능
- 애니메이션 타임라인 제어

---

## 7. 최종 체크리스트

### 기능
- [ ] 모델 로딩 및 표시
- [ ] 영역 선택 (브러시)
- [ ] 하이라이트 렌더링
- [ ] 화살표 시각화
- [ ] 비포/애프터 전환
- [ ] 애니메이션 효과

### 성능
- [ ] 60 FPS 유지
- [ ] Draw Call 최소화
- [ ] 메모리 관리
- [ ] 모바일 최적화

### 코드 품질
- [ ] 모듈화된 구조
- [ ] 에러 핸들링
- [ ] 주석 및 문서화
- [ ] 타입 안전성 (TypeScript)

### 사용자 경험
- [ ] 직관적인 UI
- [ ] 반응형 디자인
- [ ] 로딩 인디케이터
- [ ] 도움말/가이드

---

## 결론

이 통합 가이드는 Three.js의 핵심 개념들을 실전 프로젝트에 적용하는 방법을 보여줍니다. 각 컴포넌트는 독립적으로 작동하면서도 전체 시스템의 일부로 통합됩니다.

**다음 단계:**
1. 실제 얼굴 모델 데이터로 테스트
2. Flutter 앱과 통합
3. 실시간 분석 기능 추가
4. 머신러닝 모델 연동

**핵심 학습 포인트:**
- 모듈화된 아키텍처 설계
- Three.js 최적화 기법
- 인터랙티브 3D 시각화
- 성능과 UX의 균형

계속 학습하고 실험하면서 더 나은 3D 웹 애플리케이션을 만들어보세요! 🚀

