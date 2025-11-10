# 3D 모델 포맷과 데이터 관리

## 1. OBJ 파일 포맷

### OBJ 포맷 특징
- **텍스트 기반** 포맷 (사람이 읽을 수 있음)
- 가장 널리 사용되는 3D 포맷
- 정점, 면, 텍스처 좌표, 노말 정보 포함
- **애니메이션 미지원**
- MTL 파일과 함께 사용 (머티리얼 정의)

### OBJ 파일 구조
```obj
# 주석
mtllib model.mtl  # MTL 파일 참조

# 정점 위치 (x, y, z)
v 0.0 0.0 0.0
v 1.0 0.0 0.0
v 0.0 1.0 0.0

# 텍스처 좌표 (u, v)
vt 0.0 0.0
vt 1.0 0.0
vt 0.5 1.0

# 법선 벡터 (nx, ny, nz)
vn 0.0 0.0 1.0
vn 0.0 0.0 1.0
vn 0.0 0.0 1.0

# 머티리얼 사용
usemtl Material_01

# 면 정의 (v/vt/vn 인덱스)
f 1/1/1 2/2/2 3/3/3
```

### MTL 파일 구조
```mtl
# 머티리얼 정의
newmtl Material_01
Ka 0.2 0.2 0.2      # Ambient color
Kd 0.8 0.8 0.8      # Diffuse color
Ks 1.0 1.0 1.0      # Specular color
Ns 100.0            # Specular exponent
d 1.0               # Transparency (0=투명, 1=불투명)
illum 2             # Illumination model

# 텍스처 맵
map_Kd texture.jpg  # Diffuse map
map_Ks specular.jpg # Specular map
map_Bump normal.jpg # Normal/Bump map
```

### Three.js에서 OBJ 로드
```javascript
import { OBJLoader } from 'three/addons/loaders/OBJLoader.js';
import { MTLLoader } from 'three/addons/loaders/MTLLoader.js';

// MTL 먼저 로드
const mtlLoader = new MTLLoader();
mtlLoader.load('model.mtl', (materials) => {
  materials.preload();
  
  // OBJ 로드
  const objLoader = new OBJLoader();
  objLoader.setMaterials(materials);
  objLoader.load('model.obj', (object) => {
    // 스케일 조정
    object.scale.set(0.01, 0.01, 0.01);
    
    // 좌표계 변환 (필요시)
    object.rotation.x = -Math.PI / 2;
    
    scene.add(object);
  });
});
```

---

## 2. GLTF 파일 포맷

### GLTF 포맷 특징
- **GL Transmission Format** ("3D의 JPEG")
- **바이너리 기반** (효율적)
- 애니메이션, 스킨, 모프 타겟 지원
- PBR 머티리얼 네이티브 지원
- 파일 크기 작고 로딩 빠름
- **Three.js 권장 포맷**

### GLTF 파일 형식
| 형식 | 확장자 | 설명 |
|------|--------|------|
| glTF | .gltf | JSON + 별도 bin/이미지 |
| glTF-Binary | .glb | 하나의 바이너리 파일 |
| glTF-Embedded | .gltf | 모든 데이터 JSON 내 인코딩 |

### Three.js에서 GLTF 로드
```javascript
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

const loader = new GLTFLoader();

loader.load(
  'model.glb',
  (gltf) => {
    // 성공 콜백
    const model = gltf.scene;
    
    // 스케일 조정
    model.scale.set(0.1, 0.1, 0.1);
    
    scene.add(model);
    
    // 애니메이션이 있는 경우
    if (gltf.animations.length > 0) {
      const mixer = new THREE.AnimationMixer(model);
      const action = mixer.clipAction(gltf.animations[0]);
      action.play();
    }
  },
  (xhr) => {
    // 진행률 콜백
    console.log((xhr.loaded / xhr.total * 100) + '% loaded');
  },
  (error) => {
    // 에러 콜백
    console.error('Error loading GLTF:', error);
  }
);
```

### Draco 압축 GLTF
```javascript
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { DRACOLoader } from 'three/addons/loaders/DRACOLoader.js';

const dracoLoader = new DRACOLoader();
dracoLoader.setDecoderPath('/draco/');  // Draco 디코더 경로

const gltfLoader = new GLTFLoader();
gltfLoader.setDRACOLoader(dracoLoader);

gltfLoader.load('compressed_model.glb', (gltf) => {
  scene.add(gltf.scene);
});
```

---

## 3. OBJ vs GLTF 비교

| 특징 | OBJ | GLTF |
|------|-----|------|
| 파일 형식 | 텍스트 | 바이너리/JSON |
| 파일 크기 | 큼 | 작음 |
| 로딩 속도 | 느림 | 빠름 |
| 애니메이션 | ✗ | ✓ |
| 스킨/본 | ✗ | ✓ |
| PBR 머티리얼 | ✗ | ✓ |
| 압축 | ✗ | ✓ (Draco) |
| 편집 용이성 | ✓ | ✗ |
| 범용성 | 매우 높음 | 높음 |
| Three.js 추천 | - | ✓ |

### 선택 가이드
- **OBJ**: 단순 정적 모델, 레거시 지원, 디버깅 필요
- **GLTF**: 프로덕션 환경, 애니메이션, 최적화, PBR

---

## 4. 스케일과 단위 관리

### 단위 시스템 이해
```
1 Three.js 유닛 = 실제로는 무엇이든 될 수 있음
- 밀리미터 (mm)
- 센티미터 (cm)
- 미터 (m)
```

### 프로젝트 단위 통일
```javascript
// 프로젝트 전체에서 1 unit = 1mm로 결정

// Blender에서 익스포트 시 스케일 조정
// Blender 기본 단위: 1 unit = 1m
// → Three.js에서 1000배 축소 필요

const model = gltf.scene;
model.scale.set(0.001, 0.001, 0.001);  // m → mm
```

### 스케일 자동 조정
```javascript
function normalizeModelScale(object, targetSize = 1.0) {
  // Bounding Box 계산
  const box = new THREE.Box3().setFromObject(object);
  const size = box.getSize(new THREE.Vector3());
  
  // 가장 긴 축 기준
  const maxDim = Math.max(size.x, size.y, size.z);
  
  // 목표 크기에 맞게 스케일 조정
  const scale = targetSize / maxDim;
  object.scale.multiplyScalar(scale);
  
  console.log(`Model scaled by ${scale.toFixed(4)}`);
}

// 사용
loader.load('face_model.glb', (gltf) => {
  const model = gltf.scene;
  normalizeModelScale(model, 10);  // 10 유닛 크기로
  scene.add(model);
});
```

### 중심점 조정
```javascript
function centerModel(object) {
  const box = new THREE.Box3().setFromObject(object);
  const center = box.getCenter(new THREE.Vector3());
  
  object.position.sub(center);
  
  console.log('Model centered at origin');
}
```

---

## 5. UV 매핑

### UV 좌표란?
**UV**는 3D 모델 표면을 2D 텍스처 이미지에 매핑하는 좌표 시스템입니다.
- **U**: 가로 축 (0~1)
- **V**: 세로 축 (0~1)

```
V (1) ┌─────────┐
      │         │
      │ 텍스처  │
      │         │
V (0) └─────────┘
     U(0)     U(1)
```

### Three.js에서 UV 접근
```javascript
const geometry = mesh.geometry;
const uvAttribute = geometry.attributes.uv;

// 특정 정점의 UV 읽기
const uv = new THREE.Vector2();
uv.fromBufferAttribute(uvAttribute, 0);  // 0번 정점

console.log(`UV: ${uv.x}, ${uv.y}`);

// UV 수정
uvAttribute.setXY(0, 0.5, 0.5);
uvAttribute.needsUpdate = true;
```

### UV 매핑 문제 해결

**문제 1: 텍스처가 늘어남**
```javascript
// UV 좌표가 올바르게 정규화되었는지 확인
function validateUVs(geometry) {
  const uvs = geometry.attributes.uv;
  if (!uvs) return false;
  
  for (let i = 0; i < uvs.count; i++) {
    const u = uvs.getX(i);
    const v = uvs.getY(i);
    
    if (u < 0 || u > 1 || v < 0 || v > 1) {
      console.warn(`UV out of range at vertex ${i}: (${u}, ${v})`);
    }
  }
  
  return true;
}
```

**문제 2: UV가 없음**
```javascript
// 자동 UV 생성 (간단한 박스 매핑)
function generateBoxUVs(geometry) {
  const positions = geometry.attributes.position;
  const uvs = [];
  
  for (let i = 0; i < positions.count; i++) {
    const x = positions.getX(i);
    const y = positions.getY(i);
    
    // XY 평면 투영
    uvs.push(x * 0.5 + 0.5, y * 0.5 + 0.5);
  }
  
  geometry.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2));
}
```

### UV 디버깅 시각화
```javascript
// UV를 색상으로 표시
const material = new THREE.MeshBasicMaterial({
  onBeforeCompile: (shader) => {
    shader.fragmentShader = shader.fragmentShader.replace(
      'void main() {',
      `
      varying vec2 vUv;
      void main() {
      `
    );
    
    shader.fragmentShader = shader.fragmentShader.replace(
      '#include <color_fragment>',
      `
      diffuseColor.rgb = vec3(vUv, 0.0);
      `
    );
  }
});

// 빨강: U축, 초록: V축
```

---

## 6. 노말 벡터 (Normal Vector)

### 노말이란?
**노말**은 표면에 수직인 방향 벡터로, 조명 계산에 필수적입니다.

```
     ↑ Normal
     |
  ───┴───  Surface
```

### 노말의 역할
1. **조명 계산**: Lambert/Phong 셰이딩
2. **면 방향**: 앞면/뒷면 판정
3. **외곽선 검출**: Toon 셰이딩

### Three.js에서 노말 다루기

**노말 자동 계산:**
```javascript
// Flat shading (면 노말)
geometry.computeVertexNormals();

// 부드러운 셰이딩 (정점 노말, 인접 면 평균)
geometry.computeVertexNormals();

// 노말 다시 계산
geometry.deleteAttribute('normal');
geometry.computeVertexNormals();
```

**노말 수동 설정:**
```javascript
const normals = new Float32Array([
  0.0, 0.0, 1.0,  // 정점 0 (Z축 방향)
  0.0, 0.0, 1.0,  // 정점 1
  0.0, 0.0, 1.0,  // 정점 2
]);

geometry.setAttribute('normal', 
  new THREE.Float32BufferAttribute(normals, 3)
);
```

**노말 반전:**
```javascript
function flipNormals(geometry) {
  const normals = geometry.attributes.normal;
  
  for (let i = 0; i < normals.count; i++) {
    normals.setXYZ(
      i,
      -normals.getX(i),
      -normals.getY(i),
      -normals.getZ(i)
    );
  }
  
  normals.needsUpdate = true;
}
```

### Flat vs Smooth Shading

**Flat Shading (각진 느낌):**
```javascript
// 각 면이 독립적인 노말을 가짐
material.flatShading = true;
geometry.computeVertexNormals();
```

**Smooth Shading (부드러운 느낌):**
```javascript
// 정점을 공유하는 면들의 노말을 평균
material.flatShading = false;
geometry.computeVertexNormals();
```

### 노말 맵 (Normal Map)
```javascript
const textureLoader = new THREE.TextureLoader();
const normalMap = textureLoader.load('normal_map.jpg');

const material = new THREE.MeshStandardMaterial({
  color: 0xffffff,
  normalMap: normalMap,
  normalScale: new THREE.Vector2(1, 1)  // 강도 조절
});
```

---

## 7. 좌표계 변환 및 보정

### Y-up vs Z-up 좌표계
```
Three.js (Y-up)      Blender (Z-up)
    Y                    Z
    |                    |
    |___X                |___X
   /                    /
  Z                    Y
```

### 좌표계 변환
```javascript
function convertZupToYup(object) {
  // Z-up → Y-up: X축 기준 -90도 회전
  object.rotation.x = -Math.PI / 2;
}

function convertYupToZup(object) {
  // Y-up → Z-up: X축 기준 +90도 회전
  object.rotation.x = Math.PI / 2;
}
```

### 모델 방향 통일
```javascript
class ModelLoader {
  constructor(scene) {
    this.scene = scene;
    this.gltfLoader = new GLTFLoader();
  }
  
  load(url, options = {}) {
    const defaults = {
      scale: 1.0,
      rotation: { x: 0, y: 0, z: 0 },
      position: { x: 0, y: 0, z: 0 },
      centerModel: true,
      normalizeScale: true,
      targetSize: 10
    };
    
    const config = { ...defaults, ...options };
    
    this.gltfLoader.load(url, (gltf) => {
      const model = gltf.scene;
      
      // 좌표계 변환
      if (config.rotation) {
        model.rotation.set(
          config.rotation.x,
          config.rotation.y,
          config.rotation.z
        );
      }
      
      // 스케일 정규화
      if (config.normalizeScale) {
        normalizeModelScale(model, config.targetSize);
      } else {
        model.scale.set(config.scale, config.scale, config.scale);
      }
      
      // 중심 정렬
      if (config.centerModel) {
        centerModel(model);
      }
      
      // 위치 설정
      model.position.set(
        config.position.x,
        config.position.y,
        config.position.z
      );
      
      this.scene.add(model);
    });
  }
}

// 사용
const loader = new ModelLoader(scene);
loader.load('face_model.glb', {
  rotation: { x: -Math.PI / 2, y: 0, z: 0 },  // Z-up → Y-up
  targetSize: 15,
  centerModel: true
});
```

---

## 8. 메모리 관리 및 최적화

### 리소스 해제
```javascript
function disposeObject(object) {
  object.traverse((child) => {
    if (child.isMesh) {
      // Geometry 해제
      if (child.geometry) {
        child.geometry.dispose();
      }
      
      // Material 해제
      if (child.material) {
        if (Array.isArray(child.material)) {
          child.material.forEach(material => disposeMaterial(material));
        } else {
          disposeMaterial(child.material);
        }
      }
    }
  });
  
  // 씬에서 제거
  if (object.parent) {
    object.parent.remove(object);
  }
}

function disposeMaterial(material) {
  // 텍스처 해제
  const textures = [
    'map', 'lightMap', 'bumpMap', 'normalMap', 
    'specularMap', 'envMap', 'alphaMap', 
    'aoMap', 'displacementMap', 'emissiveMap',
    'roughnessMap', 'metalnessMap'
  ];
  
  textures.forEach(textureName => {
    if (material[textureName]) {
      material[textureName].dispose();
    }
  });
  
  material.dispose();
}
```

### 텍스처 최적화
```javascript
const textureLoader = new THREE.TextureLoader();
const texture = textureLoader.load('large_texture.jpg');

// 밉맵 비활성화 (POT가 아닌 텍스처)
texture.generateMipmaps = false;

// 필터링 설정
texture.minFilter = THREE.LinearFilter;
texture.magFilter = THREE.LinearFilter;

// 압축 텍스처 사용 (모바일)
// KTX2Loader 사용 권장
```

### 로딩 매니저
```javascript
const loadingManager = new THREE.LoadingManager();

loadingManager.onStart = (url, itemsLoaded, itemsTotal) => {
  console.log(`Started loading: ${url}`);
};

loadingManager.onProgress = (url, itemsLoaded, itemsTotal) => {
  const progress = (itemsLoaded / itemsTotal) * 100;
  console.log(`Loading: ${progress.toFixed(2)}%`);
};

loadingManager.onLoad = () => {
  console.log('All resources loaded');
};

loadingManager.onError = (url) => {
  console.error(`Error loading: ${url}`);
};

// 모든 로더에 적용
const gltfLoader = new GLTFLoader(loadingManager);
const textureLoader = new THREE.TextureLoader(loadingManager);
```

---

## 실무 체크리스트

- [ ] 프로젝트에 적합한 포맷 선택 (OBJ vs GLTF)
- [ ] 단위 시스템 통일 (mm/cm/m)
- [ ] 좌표계 방향 확인 및 변환 (Y-up/Z-up)
- [ ] UV 매핑 검증
- [ ] 노말 계산 방식 결정 (Flat/Smooth)
- [ ] 스케일 자동 정규화 구현
- [ ] 중심점 정렬 로직 구현
- [ ] 리소스 dispose 처리
- [ ] 로딩 진행률 표시
- [ ] 에러 핸들링 구현

---

## 참고 자료

- [OBJ Format Specification](http://paulbourke.net/dataformats/obj/)
- [glTF 2.0 Specification](https://registry.khronos.org/glTF/specs/2.0/glTF-2.0.html)
- [GLTFLoader 문서](https://threejs.org/docs/#examples/en/loaders/GLTFLoader)
- [OBJLoader 문서](https://threejs.org/docs/#examples/en/loaders/OBJLoader)
- [Draco 3D Compression](https://google.github.io/draco/)

