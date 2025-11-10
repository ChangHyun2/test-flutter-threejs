# BufferGeometry와 Mesh 구조

## 1. BufferGeometry 기초

### BufferGeometry란?
**BufferGeometry**는 Three.js에서 3D 형상의 정점(vertex) 데이터를 효율적으로 저장하는 구조입니다. GPU에 직접 전달되는 타입드 배열(Typed Array)을 사용하여 높은 성능을 제공합니다.

### 기본 구조
```javascript
const geometry = new THREE.BufferGeometry();

// Float32Array로 정점 데이터 저장
const positions = new Float32Array([
  // x,  y,  z
  -1.0, -1.0,  1.0,  // vertex 0
   1.0, -1.0,  1.0,  // vertex 1
   1.0,  1.0,  1.0,  // vertex 2
]);

// BufferAttribute로 변환하여 지오메트리에 추가
geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
```

### 주요 Attributes

| Attribute | 설명 | 크기 | 필수 |
|-----------|------|------|------|
| `position` | 정점 좌표 (x, y, z) | 3 | ✓ |
| `normal` | 법선 벡터 (조명 계산용) | 3 | 선택 |
| `uv` | 텍스처 좌표 (u, v) | 2 | 선택 |
| `color` | 정점별 색상 (r, g, b) | 3 | 선택 |
| `tangent` | 접선 벡터 (노말 맵용) | 4 | 선택 |

---

## 2. BufferGeometry 상세 구성

### Position (위치)
```javascript
// 삼각형 예제 (3개 정점 = 9개 값)
const positions = new Float32Array([
  0.0,  1.0,  0.0,  // 정점 0 (x, y, z)
 -1.0, -1.0,  0.0,  // 정점 1
  1.0, -1.0,  0.0,  // 정점 2
]);

geometry.setAttribute('position', 
  new THREE.BufferAttribute(positions, 3)
);
```

### Normal (법선)
```javascript
// 각 정점의 법선 벡터
const normals = new Float32Array([
  0.0, 0.0, 1.0,  // 정점 0의 법선 (Z축 방향)
  0.0, 0.0, 1.0,  // 정점 1의 법선
  0.0, 0.0, 1.0,  // 정점 2의 법선
]);

geometry.setAttribute('normal', 
  new THREE.BufferAttribute(normals, 3)
);

// 자동 계산
geometry.computeVertexNormals();
```

### UV (텍스처 좌표)
```javascript
// UV는 0~1 범위의 2D 좌표
const uvs = new Float32Array([
  0.5, 1.0,  // 정점 0의 UV
  0.0, 0.0,  // 정점 1의 UV
  1.0, 0.0,  // 정점 2의 UV
]);

geometry.setAttribute('uv', 
  new THREE.BufferAttribute(uvs, 2)
);
```

### Index (인덱스 버퍼)
```javascript
// 인덱스를 사용하여 정점 재사용 (메모리 절약)
const positions = new Float32Array([
  // 4개 정점으로 사각형 정의
  -1.0, -1.0, 0.0,  // 0
   1.0, -1.0, 0.0,  // 1
   1.0,  1.0, 0.0,  // 2
  -1.0,  1.0, 0.0,  // 3
]);

// 인덱스로 2개 삼각형 정의 (6개 인덱스 = 2개 삼각형)
const indices = new Uint16Array([
  0, 1, 2,  // 첫 번째 삼각형
  0, 2, 3,  // 두 번째 삼각형
]);

geometry.setAttribute('position', 
  new THREE.BufferAttribute(positions, 3)
);
geometry.setIndex(new THREE.BufferAttribute(indices, 1));
```

---

## 3. BufferGeometry 생성 및 조작

### 동적으로 생성하기
```javascript
function createCustomGeometry() {
  const geometry = new THREE.BufferGeometry();
  
  const vertices = [];
  const normals = [];
  const uvs = [];
  
  // 구 형태 생성 (간단한 예)
  const radius = 1;
  const segments = 16;
  
  for (let lat = 0; lat <= segments; lat++) {
    const theta = (lat * Math.PI) / segments;
    const sinTheta = Math.sin(theta);
    const cosTheta = Math.cos(theta);
    
    for (let lon = 0; lon <= segments; lon++) {
      const phi = (lon * 2 * Math.PI) / segments;
      const sinPhi = Math.sin(phi);
      const cosPhi = Math.cos(phi);
      
      // 위치
      const x = radius * sinTheta * cosPhi;
      const y = radius * cosTheta;
      const z = radius * sinTheta * sinPhi;
      
      vertices.push(x, y, z);
      
      // 노말 (구의 경우 중심에서 정점으로 향하는 방향)
      normals.push(x / radius, y / radius, z / radius);
      
      // UV
      const u = lon / segments;
      const v = lat / segments;
      uvs.push(u, v);
    }
  }
  
  // 인덱스 생성
  const indices = [];
  for (let lat = 0; lat < segments; lat++) {
    for (let lon = 0; lon < segments; lon++) {
      const first = lat * (segments + 1) + lon;
      const second = first + segments + 1;
      
      indices.push(first, second, first + 1);
      indices.push(second, second + 1, first + 1);
    }
  }
  
  geometry.setAttribute('position', 
    new THREE.Float32BufferAttribute(vertices, 3));
  geometry.setAttribute('normal', 
    new THREE.Float32BufferAttribute(normals, 3));
  geometry.setAttribute('uv', 
    new THREE.Float32BufferAttribute(uvs, 2));
  geometry.setIndex(indices);
  
  return geometry;
}
```

### Attribute 접근 및 수정
```javascript
const geometry = mesh.geometry;
const positionAttribute = geometry.attributes.position;

// 특정 정점 읽기
const vertex = new THREE.Vector3();
vertex.fromBufferAttribute(positionAttribute, 0);  // 0번 정점

console.log(`Vertex 0: ${vertex.x}, ${vertex.y}, ${vertex.z}`);

// 특정 정점 수정
positionAttribute.setXYZ(0, 1.0, 2.0, 3.0);  // 0번 정점을 (1, 2, 3)으로

// 변경 사항 GPU에 반영
positionAttribute.needsUpdate = true;

// Bounding Box/Sphere 재계산
geometry.computeBoundingBox();
geometry.computeBoundingSphere();
```

### 지오메트리 복제
```javascript
// 깊은 복사
const clonedGeometry = originalGeometry.clone();

// 참조 복사 (메모리 절약, 데이터 공유)
const sharedGeometry = originalGeometry;
```

---

## 4. Mesh와 Material

### Mesh 생성
```javascript
const geometry = new THREE.BoxGeometry(1, 1, 1);
const material = new THREE.MeshStandardMaterial({ color: 0x00ff00 });
const mesh = new THREE.Mesh(geometry, material);

scene.add(mesh);
```

### 주요 Material 종류

| Material | 특징 | 조명 영향 | 성능 |
|----------|------|-----------|------|
| `MeshBasicMaterial` | 단순 색상/텍스처 | 없음 | ⚡⚡⚡ |
| `MeshLambertMaterial` | 난반사 (Diffuse) | 있음 | ⚡⚡ |
| `MeshPhongMaterial` | 정반사 (Specular) | 있음 | ⚡ |
| `MeshStandardMaterial` | PBR (물리 기반) | 있음 | ⚡ |
| `MeshPhysicalMaterial` | 고급 PBR | 있음 | 느림 |

### Material 주요 속성
```javascript
const material = new THREE.MeshStandardMaterial({
  color: 0xffffff,           // 기본 색상
  map: texture,              // 디퓨즈 텍스처
  normalMap: normalTexture,  // 노말 맵
  roughness: 0.5,            // 거칠기 (0=거울, 1=거침)
  metalness: 0.5,            // 금속성 (0=비금속, 1=금속)
  transparent: true,         // 투명도 활성화
  opacity: 0.8,              // 불투명도 (0=투명, 1=불투명)
  side: THREE.DoubleSide,    // 양면 렌더링
  wireframe: false,          // 와이어프레임 모드
});
```

---

## 5. MeshBasicMaterial 커스터마이징 (onBeforeCompile)

### 기본 사용법
```javascript
const material = new THREE.MeshBasicMaterial({ color: 0xcccccc });

material.onBeforeCompile = (shader) => {
  console.log('Vertex Shader:', shader.vertexShader);
  console.log('Fragment Shader:', shader.fragmentShader);
  
  // Shader 코드를 수정하여 커스텀 효과 구현
};
```

### 커스텀 Uniform 추가
```javascript
const material = new THREE.MeshBasicMaterial({ color: 0xffffff });

material.onBeforeCompile = (shader) => {
  // Uniform 추가
  shader.uniforms.time = { value: 0 };
  shader.uniforms.highlightColor = { value: new THREE.Color(0xff6600) };
  
  // Vertex Shader 수정
  shader.vertexShader = shader.vertexShader.replace(
    '#include <common>',
    `
    #include <common>
    uniform float time;
    `
  );
  
  // Fragment Shader 수정
  shader.fragmentShader = shader.fragmentShader.replace(
    '#include <common>',
    `
    #include <common>
    uniform float time;
    uniform vec3 highlightColor;
    `
  );
  
  shader.fragmentShader = shader.fragmentShader.replace(
    '#include <color_fragment>',
    `
    #include <color_fragment>
    
    // 시간에 따라 펄스 효과
    float pulse = sin(time * 2.0) * 0.5 + 0.5;
    diffuseColor.rgb = mix(diffuseColor.rgb, highlightColor, pulse * 0.5);
    `
  );
  
  // Shader 참조 저장 (애니메이션용)
  material.userData.shader = shader;
};

// 애니메이션 루프에서 업데이트
function animate() {
  if (material.userData.shader) {
    material.userData.shader.uniforms.time.value = performance.now() / 1000;
  }
  
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
}
```

### 선택 영역 하이라이트 (Vertex별 데이터)
```javascript
// Geometry에 커스텀 attribute 추가
const vertexCount = geometry.attributes.position.count;
const isSelected = new Float32Array(vertexCount);

// 선택된 정점 표시
const selectedVertices = [0, 5, 10, 15];
selectedVertices.forEach(idx => {
  isSelected[idx] = 1.0;
});

geometry.setAttribute('isSelected', 
  new THREE.BufferAttribute(isSelected, 1)
);

// Material에서 사용
material.onBeforeCompile = (shader) => {
  // Vertex Shader
  shader.vertexShader = shader.vertexShader.replace(
    '#include <common>',
    `
    #include <common>
    attribute float isSelected;
    varying float vIsSelected;
    `
  );
  
  shader.vertexShader = shader.vertexShader.replace(
    '#include <begin_vertex>',
    `
    #include <begin_vertex>
    vIsSelected = isSelected;
    `
  );
  
  // Fragment Shader
  shader.fragmentShader = shader.fragmentShader.replace(
    '#include <common>',
    `
    #include <common>
    varying float vIsSelected;
    `
  );
  
  shader.fragmentShader = shader.fragmentShader.replace(
    '#include <color_fragment>',
    `
    #include <color_fragment>
    
    if (vIsSelected > 0.5) {
      diffuseColor.rgb = vec3(1.0, 0.4, 0.0);  // 주황색
    }
    `
  );
};
```

---

## 6. 부분 메쉬 추출 (선택 영역 하이라이트)

### 선택된 Face로 새 Geometry 생성
```javascript
function extractSelectedFaces(originalGeometry, selectedFaceIndices) {
  const position = originalGeometry.attributes.position;
  const normal = originalGeometry.attributes.normal;
  const uv = originalGeometry.attributes.uv;
  const index = originalGeometry.index;
  
  const newPositions = [];
  const newNormals = [];
  const newUvs = [];
  
  for (const faceIndex of selectedFaceIndices) {
    // 인덱스 버퍼 사용 여부에 따라 처리
    let idx0, idx1, idx2;
    
    if (index) {
      // 인덱스 버퍼가 있는 경우
      idx0 = index.getX(faceIndex * 3);
      idx1 = index.getX(faceIndex * 3 + 1);
      idx2 = index.getX(faceIndex * 3 + 2);
    } else {
      // 인덱스 버퍼가 없는 경우
      idx0 = faceIndex * 3;
      idx1 = faceIndex * 3 + 1;
      idx2 = faceIndex * 3 + 2;
    }
    
    // 세 정점 데이터 복사
    [idx0, idx1, idx2].forEach(idx => {
      // Position
      newPositions.push(
        position.getX(idx),
        position.getY(idx),
        position.getZ(idx)
      );
      
      // Normal
      if (normal) {
        newNormals.push(
          normal.getX(idx),
          normal.getY(idx),
          normal.getZ(idx)
        );
      }
      
      // UV
      if (uv) {
        newUvs.push(
          uv.getX(idx),
          uv.getY(idx)
        );
      }
    });
  }
  
  // 새 Geometry 생성
  const newGeometry = new THREE.BufferGeometry();
  
  newGeometry.setAttribute('position',
    new THREE.Float32BufferAttribute(newPositions, 3)
  );
  
  if (newNormals.length > 0) {
    newGeometry.setAttribute('normal',
      new THREE.Float32BufferAttribute(newNormals, 3)
    );
  } else {
    newGeometry.computeVertexNormals();
  }
  
  if (newUvs.length > 0) {
    newGeometry.setAttribute('uv',
      new THREE.Float32BufferAttribute(newUvs, 2)
    );
  }
  
  return newGeometry;
}
```

### 하이라이트 Mesh 생성 및 관리
```javascript
class SelectionHighlighter {
  constructor(scene) {
    this.scene = scene;
    this.highlightMesh = null;
  }
  
  update(originalMesh, selectedFaceIndices) {
    // 기존 하이라이트 제거
    this.clear();
    
    if (selectedFaceIndices.size === 0) return;
    
    // 선택 영역 Geometry 추출
    const highlightGeometry = extractSelectedFaces(
      originalMesh.geometry,
      selectedFaceIndices
    );
    
    // 반투명 주황색 Material
    const highlightMaterial = new THREE.MeshBasicMaterial({
      color: 0xff6600,
      transparent: true,
      opacity: 0.6,
      side: THREE.DoubleSide,
      depthTest: true,
      depthWrite: false,  // Z-fighting 방지
    });
    
    // Mesh 생성
    this.highlightMesh = new THREE.Mesh(highlightGeometry, highlightMaterial);
    
    // 원본과 동일한 Transform 적용
    this.highlightMesh.position.copy(originalMesh.position);
    this.highlightMesh.rotation.copy(originalMesh.rotation);
    this.highlightMesh.scale.copy(originalMesh.scale);
    
    // 약간 앞으로 이동 (Z-fighting 추가 방지)
    this.highlightMesh.position.z += 0.001;
    
    this.scene.add(this.highlightMesh);
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

// 사용 예
const highlighter = new SelectionHighlighter(scene);
const selectedFaces = new Set([0, 5, 10, 15, 20]);
highlighter.update(faceMesh, selectedFaces);
```

---

## 7. Geometry 최적화

### 1. Geometry 병합
```javascript
import { mergeGeometries } from 'three/addons/utils/BufferGeometryUtils.js';

const geometries = [];
for (let i = 0; i < 100; i++) {
  const box = new THREE.BoxGeometry(1, 1, 1);
  box.translate(i * 2, 0, 0);
  geometries.push(box);
}

// 하나의 Geometry로 병합 (Draw Call 감소)
const mergedGeometry = mergeGeometries(geometries);
const mesh = new THREE.Mesh(mergedGeometry, material);
```

### 2. Instanced Mesh (대량 복제)
```javascript
const geometry = new THREE.BoxGeometry(1, 1, 1);
const material = new THREE.MeshStandardMaterial({ color: 0x00ff00 });
const count = 1000;

const instancedMesh = new THREE.InstancedMesh(geometry, material, count);

// 각 인스턴스 위치 설정
const matrix = new THREE.Matrix4();
for (let i = 0; i < count; i++) {
  matrix.setPosition(
    Math.random() * 100 - 50,
    Math.random() * 100 - 50,
    Math.random() * 100 - 50
  );
  
  instancedMesh.setMatrixAt(i, matrix);
}

instancedMesh.instanceMatrix.needsUpdate = true;
scene.add(instancedMesh);
```

### 3. LOD (Level of Detail)
```javascript
const lod = new THREE.LOD();

// 가까울 때 - 고해상도
const highDetail = new THREE.Mesh(
  new THREE.IcosahedronGeometry(1, 3),
  material
);
lod.addLevel(highDetail, 0);

// 중간 거리 - 중해상도
const mediumDetail = new THREE.Mesh(
  new THREE.IcosahedronGeometry(1, 1),
  material
);
lod.addLevel(mediumDetail, 10);

// 멀 때 - 저해상도
const lowDetail = new THREE.Mesh(
  new THREE.IcosahedronGeometry(1, 0),
  material
);
lod.addLevel(lowDetail, 30);

scene.add(lod);
```

---

## 8. 디버깅 도구

### Geometry 정보 출력
```javascript
function debugGeometry(geometry) {
  console.group('Geometry Debug');
  console.log('Vertex count:', geometry.attributes.position.count);
  console.log('Has normals:', !!geometry.attributes.normal);
  console.log('Has UVs:', !!geometry.attributes.uv);
  console.log('Has index:', !!geometry.index);
  
  if (geometry.index) {
    console.log('Triangle count:', geometry.index.count / 3);
  } else {
    console.log('Triangle count:', geometry.attributes.position.count / 3);
  }
  
  geometry.computeBoundingBox();
  console.log('Bounding box:', geometry.boundingBox);
  
  console.groupEnd();
}
```

### Wireframe 오버레이
```javascript
const wireframeMaterial = new THREE.MeshBasicMaterial({
  color: 0x00ff00,
  wireframe: true,
  transparent: true,
  opacity: 0.3
});

const wireframeMesh = new THREE.Mesh(geometry, wireframeMaterial);
wireframeMesh.position.copy(originalMesh.position);
scene.add(wireframeMesh);
```

### Normal 시각화
```javascript
import { VertexNormalsHelper } from 'three/addons/helpers/VertexNormalsHelper.js';

const normalHelper = new VertexNormalsHelper(mesh, 0.1, 0xff0000);
scene.add(normalHelper);
```

---

## 실무 체크리스트

- [ ] BufferGeometry 기본 구조 이해 (position, normal, uv)
- [ ] Attribute 읽기/쓰기 구현
- [ ] 부분 Geometry 추출 함수 구현
- [ ] Material 커스터마이징 (onBeforeCompile)
- [ ] 선택 영역 하이라이트 시스템 구축
- [ ] Geometry 병합/인스턴싱 최적화
- [ ] 메모리 관리 (dispose 호출)
- [ ] 디버그 시각화 도구 준비

---

## 참고 자료

- [BufferGeometry 문서](https://threejs.org/docs/#api/en/core/BufferGeometry)
- [BufferAttribute 문서](https://threejs.org/docs/#api/en/core/BufferAttribute)
- [Material 문서](https://threejs.org/docs/#api/en/materials/Material)
- [BufferGeometryUtils](https://threejs.org/docs/#examples/en/utils/BufferGeometryUtils)

