# Three.js 학습 가이드 - 얼굴 모델 시각화 프로젝트

이 학습 자료는 Three.js를 사용하여 얼굴 모델의 영역 선택, 확대, 변화량 시각화를 구현하기 위한 종합 가이드입니다.

## 📚 학습 목차

### 1. 기초 개념 (01-03)
- **[01. 좌표계와 카메라 시스템](./01_coordinate_camera_system.md)**
  - Three.js 오른손 좌표계
  - PerspectiveCamera vs OrthographicCamera
  - fitCameraToObject 구현

- **[02. Raycaster와 인터랙션](./02_raycaster_interaction.md)**
  - Raycaster 기본 구조
  - 터치/마우스 입력 처리
  - 영역 선택 구현
  - OrbitControls 통합

- **[03. BufferGeometry와 Mesh](./03_buffergeometry_mesh.md)**
  - BufferGeometry 구성 요소
  - Attributes (position, normal, uv)
  - Material 커스터마이징 (onBeforeCompile)
  - 부분 메쉬 추출

### 2. 데이터 관리 (04-05)
- **[04. 3D 모델 포맷과 데이터](./04_3d_model_formats.md)**
  - OBJ vs GLTF 비교
  - 스케일과 단위 관리
  - UV 매핑
  - 노말 벡터
  - 좌표계 변환

- **[05. Object3D 변형과 그룹화](./05_object3d_transform.md)**
  - Position, Rotation, Scale
  - Group 계층 구조
  - 영역 확대 구현
  - Morph Target
  - Skinning

### 3. 통합 및 시각화 (06-08)
- **[06. Flutter와 Three.js 통합](./06_flutter_threejs_integration.md)**
  - three_dart / WebView 패키지
  - Flutter ↔ Three.js 통신
  - 제스처 처리
  - 상태 관리

- **[07. 화살표 시각화](./07_arrow_visualization.md)**
  - ArrowHelper 사용법
  - 커스텀 화살표 메쉬
  - 스케일 팩터 관리
  - 색상 코딩
  - 인터랙션

- **[08. 애니메이션](./08_animation.md)**
  - requestAnimationFrame
  - Tween.js vs GSAP
  - 벡터 보간 (lerp)
  - 카메라 애니메이션
  - 비포/애프터 전환

### 4. 최적화 및 실습 (09-10)
- **[09. 성능 최적화](./09_performance_optimization.md)**
  - FPS/메모리 측정
  - Geometry 병합
  - InstancedMesh
  - LOD (Level of Detail)
  - Draw Call 감소
  - 모바일 최적화

- **[10. 통합 실습 가이드](./10_integrated_practice.md)**
  - 전체 프로젝트 구조
  - 핵심 클래스 구현
  - 영역 선택 + 확대 + 화살표
  - HTML UI
  - 테스트 및 배포

---

## 🎯 학습 로드맵

### Phase 1: 기초 다지기 (1주)
1. 좌표계와 카메라 이해
2. Raycaster로 기본 선택 구현
3. BufferGeometry 구조 파악

### Phase 2: 데이터 처리 (1주)
4. GLTF 모델 로딩 및 정규화
5. 좌표계 변환 실습
6. Object3D Transform 마스터

### Phase 3: 시각화 구현 (1주)
7. Flutter 통합 준비
8. 화살표 시스템 구축
9. 애니메이션 효과 추가

### Phase 4: 통합 및 최적화 (1주)
10. 성능 측정 및 최적화
11. 전체 시스템 통합
12. 테스트 및 디버깅

---

## 💡 주요 학습 포인트

### 좌표 시스템
```javascript
// Three.js 오른손 좌표계
//       +Y (위)
//        |
//        |___+X (오른쪽)
//       /
//     +Z (앞)
```

### 영역 선택 워크플로
```
1. Raycaster로 face index 추출
2. 반경 내 face들 Set에 저장
3. 선택된 face로 서브 Geometry 생성
4. 하이라이트 Mesh 렌더링
```

### 화살표 시각화
```
1. 비포/애프터 키포인트 비교
2. 변화 벡터 계산
3. 스케일 팩터 적용
4. ArrowHelper 생성 및 애니메이션
```

---

## 🛠 필수 도구 및 라이브러리

### Three.js 관련
```bash
npm install three
npm install @tweenjs/tween.js  # 또는
npm install gsap
```

### 개발 도구
```bash
npm install -D vite
npm install stats.js
npm install -D typescript  # 선택
```

### Flutter 패키지
```yaml
dependencies:
  three_dart: ^0.0.17
  flutter_gl: ^0.0.21
  # 또는
  webview_flutter: ^4.0.0
```

---

## 📖 참고 자료

### 공식 문서
- [Three.js 공식 문서](https://threejs.org/docs/)
- [Three.js Examples](https://threejs.org/examples/)
- [GSAP 문서](https://greensock.com/docs/)

### 추천 학습 자료
- [Three.js Journey](https://threejs-journey.com/)
- [Discover three.js](https://discoverthreejs.com/)
- [Three.js Fundamentals](https://threejsfundamentals.org/)

### 커뮤니티
- [Three.js Discourse](https://discourse.threejs.org/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/three.js)
- [Reddit r/threejs](https://www.reddit.com/r/threejs/)

---

## 🎓 실습 팁

### 1. 점진적 학습
- 각 문서를 순서대로 학습
- 예제 코드를 직접 실행
- 파라미터를 변경하며 실험

### 2. 디버깅 도구 활용
```javascript
// AxesHelper로 좌표축 확인
const axesHelper = new THREE.AxesHelper(5);
scene.add(axesHelper);

// Stats.js로 성능 모니터링
const stats = new Stats();
document.body.appendChild(stats.dom);
```

### 3. 작은 프로젝트로 시작
- 단일 메쉬 회전
- 간단한 선택 기능
- 기본 화살표 표시
→ 점차 복잡도 증가

### 4. 코드 정리
- 기능별로 클래스 분리
- 재사용 가능한 유틸리티
- 명확한 네이밍

---

## 🚀 다음 단계

학습을 완료한 후:

1. **실제 프로젝트 적용**
   - 실제 얼굴 모델 데이터 사용
   - 키포인트 추출 로직 구현
   - 측정 기능 추가

2. **고급 기능 탐구**
   - WebGL Shader 프로그래밍
   - Post-processing 효과
   - 물리 엔진 통합

3. **성능 극대화**
   - WebWorker 활용
   - GPU 가속 최적화
   - 메모리 프로파일링

4. **배포 및 운영**
   - 프로덕션 빌드 최적화
   - 브라우저 호환성 테스트
   - 사용자 피드백 수집

---

## 📝 라이선스 및 기여

이 학습 자료는 교육 목적으로 작성되었습니다.

- Three.js는 MIT 라이선스
- GSAP는 Standard License (상업적 사용 시 유료)
- 예제 코드는 자유롭게 사용 가능

---

**즐거운 학습 되세요! 🎉**

궁금한 점이나 개선 사항이 있다면 언제든 질문해주세요.

