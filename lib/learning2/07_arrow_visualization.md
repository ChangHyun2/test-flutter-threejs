# 화살표 시각화 시스템

## 1. ArrowHelper 기초

### ArrowHelper란?
**ArrowHelper**는 Three.js에서 제공하는 3D 화살표 시각화 도구입니다. 방향 벡터, 법선, 힘의 방향 등을 표시하는 데 사용됩니다.

### 기본 사용법
```javascript
// ArrowHelper(방향, 시작점, 길이, 색상, 머리크기, 머리너비)
const direction = new THREE.Vector3(1, 0, 0).normalize();
const origin = new THREE.Vector3(0, 0, 0);
const length = 2;
const color = 0xff0000;
const headLength = 0.4;  // 화살촉 길이
const headWidth = 0.2;   // 화살촉 너비

const arrow = new THREE.ArrowHelper(
  direction,
  origin,
  length,
  color,
  headLength,
  headWidth
);

scene.add(arrow);
```

### ArrowHelper 구성 요소
```javascript
// ArrowHelper는 3개 객체로 구성됨
arrow.line      // 화살표 몸통 (Line)
arrow.cone      // 화살촉 (Mesh - ConeGeometry)
arrow.children  // [line, cone]
```

### 동적 업데이트
```javascript
// 방향 변경
const newDirection = new THREE.Vector3(0, 1, 0).normalize();
arrow.setDirection(newDirection);

// 길이 변경
arrow.setLength(3, 0.5, 0.3);  // (전체, 머리길이, 머리너비)

// 색상 변경
arrow.setColor(0x00ff00);
```

---

## 2. 커스텀 화살표 메쉬

### 실린더 + 콘 방식
```javascript
function createCustomArrow(from, to, color = 0xff6600) {
  const direction = new THREE.Vector3().subVectors(to, from);
  const length = direction.length();
  direction.normalize();
  
  const group = new THREE.Group();
  
  // 화살표 몸통 (실린더)
  const shaftLength = length * 0.8;
  const shaftRadius = length * 0.02;
  
  const shaftGeometry = new THREE.CylinderGeometry(
    shaftRadius, 
    shaftRadius, 
    shaftLength, 
    8
  );
  const shaftMaterial = new THREE.MeshBasicMaterial({ color: color });
  const shaft = new THREE.Mesh(shaftGeometry, shaftMaterial);
  
  // 실린더 회전 (Y축 → 방향 벡터)
  shaft.position.y = shaftLength / 2;
  group.add(shaft);
  
  // 화살촉 (콘)
  const headLength = length * 0.2;
  const headRadius = length * 0.05;
  
  const headGeometry = new THREE.ConeGeometry(headRadius, headLength, 8);
  const headMaterial = new THREE.MeshBasicMaterial({ color: color });
  const head = new THREE.Mesh(headGeometry, headMaterial);
  
  head.position.y = shaftLength + headLength / 2;
  group.add(head);
  
  // 그룹 위치 및 방향 설정
  group.position.copy(from);
  
  // Y축(0,1,0)을 direction으로 회전
  const axis = new THREE.Vector3(0, 1, 0).cross(direction).normalize();
  const angle = Math.acos(new THREE.Vector3(0, 1, 0).dot(direction));
  
  if (axis.length() > 0) {
    group.quaternion.setFromAxisAngle(axis, angle);
  } else if (direction.y < 0) {
    // 방향이 정확히 아래쪽인 경우
    group.quaternion.setFromAxisAngle(new THREE.Vector3(1, 0, 0), Math.PI);
  }
  
  return group;
}

// 사용
const arrow = createCustomArrow(
  new THREE.Vector3(0, 0, 0),
  new THREE.Vector3(1, 2, 3),
  0xff0000
);
scene.add(arrow);
```

### 튜브 기반 커브 화살표
```javascript
function createCurvedArrow(points, color = 0x00ff00) {
  // 베지어 곡선 생성
  const curve = new THREE.CatmullRomCurve3(points);
  
  // 튜브 Geometry
  const tubeGeometry = new THREE.TubeGeometry(
    curve,
    64,      // 세그먼트 수
    0.02,    // 반경
    8,       // 방사형 세그먼트
    false    // 닫힘 여부
  );
  
  const material = new THREE.MeshBasicMaterial({ color: color });
  const tube = new THREE.Mesh(tubeGeometry, material);
  
  // 끝점에 화살촉 추가
  const lastPoint = points[points.length - 1];
  const secondLastPoint = points[points.length - 2];
  const direction = new THREE.Vector3()
    .subVectors(lastPoint, secondLastPoint)
    .normalize();
  
  const headGeometry = new THREE.ConeGeometry(0.05, 0.2, 8);
  const head = new THREE.Mesh(headGeometry, material);
  
  head.position.copy(lastPoint);
  
  const axis = new THREE.Vector3(0, 1, 0).cross(direction).normalize();
  const angle = Math.acos(new THREE.Vector3(0, 1, 0).dot(direction));
  
  if (axis.length() > 0) {
    head.quaternion.setFromAxisAngle(axis, angle);
  }
  
  const group = new THREE.Group();
  group.add(tube);
  group.add(head);
  
  return group;
}

// 사용
const points = [
  new THREE.Vector3(0, 0, 0),
  new THREE.Vector3(1, 1, 0),
  new THREE.Vector3(2, 1.5, 0.5),
  new THREE.Vector3(3, 2, 1)
];

const curvedArrow = createCurvedArrow(points, 0x00ff00);
scene.add(curvedArrow);
```

---

## 3. 얼굴 변화 화살표 구현

### 키포인트 기반 변화 측정
```javascript
class FaceChangeVisualizer {
  constructor(scene) {
    this.scene = scene;
    this.arrowGroup = new THREE.Group();
    this.arrowGroup.name = 'ChangeArrows';
    scene.add(this.arrowGroup);
  }
  
  // 두 모델의 키포인트 비교
  visualizeChanges(beforeKeypoints, afterKeypoints, options = {}) {
    this.clearArrows();
    
    const defaults = {
      color: 0xff6600,
      minLength: 0.1,     // 최소 표시 길이
      scaleFactor: 1.0,   // 화살표 길이 배율
      showLabels: true
    };
    
    const config = { ...defaults, ...options };
    
    // 각 키포인트별 변화 계산
    for (let i = 0; i < beforeKeypoints.length; i++) {
      const before = beforeKeypoints[i];
      const after = afterKeypoints[i];
      
      // 변화 벡터
      const change = new THREE.Vector3()
        .subVectors(after.position, before.position);
      
      const magnitude = change.length();
      
      // 작은 변화는 무시
      if (magnitude < config.minLength) continue;
      
      // 화살표 생성
      const arrow = this.createChangeArrow(
        before.position,
        change,
        magnitude,
        config
      );
      
      this.arrowGroup.add(arrow);
      
      // 라벨 추가 (선택)
      if (config.showLabels) {
        const label = this.createLabel(
          after.position,
          `${magnitude.toFixed(2)}mm`,
          before.name
        );
        this.arrowGroup.add(label);
      }
    }
  }
  
  createChangeArrow(origin, direction, magnitude, config) {
    const group = new THREE.Group();
    
    // 화살표 길이 스케일링
    const displayLength = magnitude * config.scaleFactor;
    const normalizedDir = direction.clone().normalize();
    
    // ArrowHelper 사용
    const arrow = new THREE.ArrowHelper(
      normalizedDir,
      origin,
      displayLength,
      config.color,
      displayLength * 0.2,  // 머리 길이
      displayLength * 0.1   // 머리 너비
    );
    
    group.add(arrow);
    
    // 메타데이터 저장
    group.userData = {
      magnitude: magnitude,
      direction: direction.clone()
    };
    
    return group;
  }
  
  createLabel(position, text, name) {
    // Canvas 텍스처로 라벨 생성
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
    sprite.position.y += 0.2;  // 약간 위로
    sprite.scale.set(0.5, 0.125, 1);
    
    sprite.userData = { name: name };
    
    return sprite;
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

// 사용 예
const visualizer = new FaceChangeVisualizer(scene);

const beforeKeypoints = [
  { name: 'nose', position: new THREE.Vector3(0, 1, 0.5) },
  { name: 'leftEye', position: new THREE.Vector3(-0.3, 1.2, 0.4) },
  { name: 'rightEye', position: new THREE.Vector3(0.3, 1.2, 0.4) }
];

const afterKeypoints = [
  { name: 'nose', position: new THREE.Vector3(0, 1.1, 0.6) },
  { name: 'leftEye', position: new THREE.Vector3(-0.32, 1.25, 0.45) },
  { name: 'rightEye', position: new THREE.Vector3(0.32, 1.25, 0.45) }
];

visualizer.visualizeChanges(beforeKeypoints, afterKeypoints, {
  scaleFactor: 5.0,  // 화살표 5배 확대
  minLength: 0.05
});
```

---

## 4. 스케일 팩터 관리

### 실제 치수 ↔ 화면 좌표 변환

**문제:** 얼굴 변화량이 1mm라면, 화면에서 너무 작아서 보이지 않음.

**해결:** 스케일 팩터를 사용해 시각적으로 확대.

```javascript
class ScaleManager {
  constructor() {
    // 실제 단위 (mm)와 Three.js 유닛 비율
    this.worldToReal = 1.0;  // 1 unit = 1mm
    
    // 화살표 시각적 배율
    this.arrowScale = 10.0;  // 10배 확대 표시
    
    // 최소/최대 화살표 길이
    this.minArrowLength = 0.1;
    this.maxArrowLength = 5.0;
  }
  
  // 실제 변화량 → 화면 화살표 길이
  realToDisplay(realMagnitude) {
    const worldMagnitude = realMagnitude * this.worldToReal;
    const displayLength = worldMagnitude * this.arrowScale;
    
    // 클램핑
    return Math.max(
      this.minArrowLength,
      Math.min(this.maxArrowLength, displayLength)
    );
  }
  
  // 화면 길이 → 실제 변화량
  displayToReal(displayLength) {
    return (displayLength / this.arrowScale) / this.worldToReal;
  }
  
  // 적응형 스케일 (변화량 범위에 따라 자동 조정)
  autoScale(magnitudes) {
    const maxMag = Math.max(...magnitudes);
    const minMag = Math.min(...magnitudes);
    
    if (maxMag < 0.5) {
      // 작은 변화: 크게 확대
      this.arrowScale = 20.0;
    } else if (maxMag < 2.0) {
      // 중간 변화
      this.arrowScale = 10.0;
    } else {
      // 큰 변화: 적게 확대
      this.arrowScale = 5.0;
    }
    
    console.log(`Auto scale: ${this.arrowScale}x (range: ${minMag.toFixed(2)} - ${maxMag.toFixed(2)}mm)`);
  }
}

// 사용
const scaleManager = new ScaleManager();

// 변화량 배열로 자동 스케일 결정
const changes = [0.2, 0.5, 1.2, 0.8];  // mm
scaleManager.autoScale(changes);

// 화살표 생성 시 적용
changes.forEach(change => {
  const displayLength = scaleManager.realToDisplay(change);
  // createArrow(..., displayLength);
});
```

### 스케일 레전드 표시
```javascript
function createScaleLegend(scaleManager, scene) {
  const group = new THREE.Group();
  group.name = 'ScaleLegend';
  
  // 기준 화살표 (1mm, 5mm, 10mm)
  const referenceValues = [1, 5, 10];  // mm
  
  referenceValues.forEach((value, index) => {
    const displayLength = scaleManager.realToDisplay(value);
    
    // 화살표
    const arrow = new THREE.ArrowHelper(
      new THREE.Vector3(1, 0, 0),
      new THREE.Vector3(0, index * 0.3, 0),
      displayLength,
      0xffffff,
      displayLength * 0.2,
      displayLength * 0.1
    );
    
    group.add(arrow);
    
    // 라벨
    const label = createTextSprite(`${value}mm`);
    label.position.set(displayLength + 0.2, index * 0.3, 0);
    label.scale.set(0.3, 0.075, 1);
    group.add(label);
  });
  
  // 레전드 위치 (화면 왼쪽 하단)
  group.position.set(-5, -3, 0);
  
  scene.add(group);
  return group;
}
```

---

## 5. 색상 코딩 (변화 크기별)

### 그라디언트 컬러맵
```javascript
class ColorMapper {
  constructor(minValue, maxValue) {
    this.minValue = minValue;
    this.maxValue = maxValue;
    
    // 색상 그라디언트: 파랑 → 초록 → 노랑 → 빨강
    this.colors = [
      new THREE.Color(0x0000ff),  // 최소 (파랑)
      new THREE.Color(0x00ff00),  // 중간-저
      new THREE.Color(0xffff00),  // 중간-고
      new THREE.Color(0xff0000)   // 최대 (빨강)
    ];
  }
  
  getColor(value) {
    // 정규화 (0~1)
    const normalized = (value - this.minValue) / (this.maxValue - this.minValue);
    const clamped = Math.max(0, Math.min(1, normalized));
    
    // 색상 구간 결정
    const numSegments = this.colors.length - 1;
    const segment = clamped * numSegments;
    const index = Math.floor(segment);
    const t = segment - index;
    
    // 두 색상 보간
    const color1 = this.colors[Math.min(index, numSegments)];
    const color2 = this.colors[Math.min(index + 1, numSegments)];
    
    return new THREE.Color().lerpColors(color1, color2, t);
  }
  
  // 히트맵 방식
  getHeatmapColor(value) {
    const normalized = (value - this.minValue) / (this.maxValue - this.minValue);
    const clamped = Math.max(0, Math.min(1, normalized));
    
    // HSL: Hue 240 (파랑) → 0 (빨강)
    const hue = (1 - clamped) * 240 / 360;
    const color = new THREE.Color();
    color.setHSL(hue, 1.0, 0.5);
    
    return color;
  }
}

// 사용
const colorMapper = new ColorMapper(0, 10);  // 0~10mm 범위

const magnitude = 5.5;  // mm
const color = colorMapper.getColor(magnitude);

const arrow = new THREE.ArrowHelper(
  direction,
  origin,
  length,
  color.getHex()
);
```

### 변화 방향별 색상
```javascript
function getDirectionalColor(changeVector) {
  const normalized = changeVector.clone().normalize();
  
  // 위쪽 = 빨강, 아래쪽 = 파랑
  if (normalized.y > 0.5) {
    return 0xff0000;  // 빨강 (팽창/성장)
  } else if (normalized.y < -0.5) {
    return 0x0000ff;  // 파랑 (수축/감소)
  } else {
    return 0x00ff00;  // 초록 (측면 이동)
  }
}
```

---

## 6. 애니메이션 효과

### 화살표 성장 애니메이션
```javascript
import { gsap } from 'gsap';

function animateArrow(arrow, duration = 1.0) {
  // 초기 길이 0
  arrow.setLength(0);
  
  const targetLength = arrow.userData.targetLength || 2.0;
  
  gsap.to(arrow, {
    duration: duration,
    ease: 'power2.out',
    onUpdate: function() {
      const progress = this.progress();
      arrow.setLength(targetLength * progress);
    }
  });
}

// 순차 애니메이션
function animateArrowsSequentially(arrows, delay = 0.1) {
  arrows.forEach((arrow, index) => {
    setTimeout(() => {
      animateArrow(arrow, 0.8);
    }, index * delay * 1000);
  });
}
```

### 펄스 효과
```javascript
class PulsingArrow extends THREE.Group {
  constructor(direction, origin, length, color) {
    super();
    
    this.baseLength = length;
    this.arrow = new THREE.ArrowHelper(
      direction,
      new THREE.Vector3(0, 0, 0),
      length,
      color
    );
    
    this.add(this.arrow);
    this.position.copy(origin);
    
    this.time = 0;
  }
  
  update(deltaTime) {
    this.time += deltaTime * 2;
    
    // 사인파 펄스
    const pulse = Math.sin(this.time) * 0.2 + 1.0;
    this.arrow.setLength(this.baseLength * pulse);
    
    // 색상 펄스
    const brightness = Math.sin(this.time) * 0.3 + 0.7;
    this.arrow.line.material.color.setRGB(
      brightness,
      brightness * 0.4,
      0
    );
  }
}

// 사용
const pulsingArrow = new PulsingArrow(
  new THREE.Vector3(1, 0, 0).normalize(),
  new THREE.Vector3(0, 0, 0),
  2.0,
  0xff6600
);

scene.add(pulsingArrow);

function animate() {
  const deltaTime = clock.getDelta();
  pulsingArrow.update(deltaTime);
  
  renderer.render(scene, camera);
  requestAnimationFrame(animate);
}
```

---

## 7. 인터랙션

### 화살표 클릭/호버
```javascript
const raycaster = new THREE.Raycaster();
const pointer = new THREE.Vector2();

let hoveredArrow = null;

function onPointerMove(event) {
  pointer.x = (event.clientX / window.innerWidth) * 2 - 1;
  pointer.y = -(event.clientY / window.innerHeight) * 2 + 1;
  
  raycaster.setFromCamera(pointer, camera);
  
  // arrowGroup의 모든 화살표 체크
  const intersects = raycaster.intersectObjects(
    arrowGroup.children, 
    true  // 재귀
  );
  
  // 이전 하이라이트 제거
  if (hoveredArrow) {
    hoveredArrow.setColor(hoveredArrow.userData.originalColor);
    hoveredArrow = null;
  }
  
  // 새 하이라이트
  if (intersects.length > 0) {
    // ArrowHelper 객체 찾기
    let object = intersects[0].object;
    while (object && !(object instanceof THREE.ArrowHelper)) {
      object = object.parent;
    }
    
    if (object && object instanceof THREE.ArrowHelper) {
      hoveredArrow = object;
      
      if (!object.userData.originalColor) {
        object.userData.originalColor = object.line.material.color.getHex();
      }
      
      object.setColor(0xffffff);  // 흰색으로 하이라이트
      
      // 툴팁 표시
      showTooltip(
        event.clientX,
        event.clientY,
        `변화량: ${object.userData.magnitude.toFixed(2)}mm`
      );
    }
  } else {
    hideTooltip();
  }
}

canvas.addEventListener('pointermove', onPointerMove);
```

### 툴팁
```javascript
function showTooltip(x, y, text) {
  let tooltip = document.getElementById('arrow-tooltip');
  
  if (!tooltip) {
    tooltip = document.createElement('div');
    tooltip.id = 'arrow-tooltip';
    tooltip.style.position = 'absolute';
    tooltip.style.background = 'rgba(0, 0, 0, 0.8)';
    tooltip.style.color = 'white';
    tooltip.style.padding = '5px 10px';
    tooltip.style.borderRadius = '4px';
    tooltip.style.fontSize = '14px';
    tooltip.style.pointerEvents = 'none';
    tooltip.style.zIndex = '1000';
    document.body.appendChild(tooltip);
  }
  
  tooltip.textContent = text;
  tooltip.style.left = `${x + 10}px`;
  tooltip.style.top = `${y + 10}px`;
  tooltip.style.display = 'block';
}

function hideTooltip() {
  const tooltip = document.getElementById('arrow-tooltip');
  if (tooltip) {
    tooltip.style.display = 'none';
  }
}
```

---

## 8. 최적화

### 인스턴싱으로 대량 화살표
```javascript
function createInstancedArrows(positions, directions, lengths, colors) {
  // 단일 geometry (화살표 몸통)
  const shaftGeometry = new THREE.CylinderGeometry(0.02, 0.02, 1, 8);
  const shaftMesh = new THREE.InstancedMesh(
    shaftGeometry,
    new THREE.MeshBasicMaterial(),
    positions.length
  );
  
  const matrix = new THREE.Matrix4();
  const color = new THREE.Color();
  
  for (let i = 0; i < positions.length; i++) {
    const position = positions[i];
    const direction = directions[i];
    const length = lengths[i];
    
    // Transform 행렬 설정
    matrix.makeTranslation(position.x, position.y, position.z);
    
    // 회전 (Y축 → direction)
    const quaternion = new THREE.Quaternion();
    quaternion.setFromUnitVectors(
      new THREE.Vector3(0, 1, 0),
      direction.clone().normalize()
    );
    matrix.makeRotationFromQuaternion(quaternion);
    matrix.setPosition(position);
    
    // 스케일 (길이 적용)
    const scale = new THREE.Vector3(1, length, 1);
    matrix.scale(scale);
    
    shaftMesh.setMatrixAt(i, matrix);
    shaftMesh.setColorAt(i, color.setHex(colors[i]));
  }
  
  shaftMesh.instanceMatrix.needsUpdate = true;
  shaftMesh.instanceColor.needsUpdate = true;
  
  return shaftMesh;
}
```

---

## 실무 체크리스트

- [ ] ArrowHelper vs 커스텀 메쉬 선택
- [ ] 스케일 매니저 구현
- [ ] 색상 매핑 전략 결정 (크기/방향)
- [ ] 실제 단위(mm) ↔ 화면 좌표 변환
- [ ] 스케일 레전드 UI 구현
- [ ] 화살표 애니메이션 효과
- [ ] 인터랙션 (호버, 클릭, 툴팁)
- [ ] 대량 화살표 최적화 (인스턴싱)
- [ ] 라벨 텍스트 렌더링

---

## 참고 자료

- [ArrowHelper 문서](https://threejs.org/docs/#api/en/helpers/ArrowHelper)
- [InstancedMesh 문서](https://threejs.org/docs/#api/en/objects/InstancedMesh)
- [GSAP 애니메이션](https://greensock.com/gsap/)
- [Canvas 텍스처](https://threejs.org/docs/#api/en/textures/CanvasTexture)

