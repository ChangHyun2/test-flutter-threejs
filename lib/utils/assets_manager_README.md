# ThreeJS AssetsManager

LRU 캐시 기반의 ThreeJS 에셋 관리 시스템입니다. 메모리 오버플로우를 방지하면서 자주 사용하는 에셋을 효율적으로 캐싱합니다.

## 주요 기능

- ✅ **LRU 캐시**: 가장 오래 사용하지 않은 에셋을 자동으로 제거
- ✅ **타입별 캐시**: OBJ, GLTF, MTL, Texture 각각 독립적인 캐시
- ✅ **메모리 관리**: 캐시 크기 제한으로 메모리 오버플로우 방지
- ✅ **자동 리소스 정리**: 캐시에서 제거될 때 Three.js 리소스 자동 dispose
- ✅ **싱글톤 패턴**: 앱 전체에서 하나의 인스턴스로 관리
- ✅ **캐시 통계**: 실시간 캐시 상태 모니터링

## 캐시 크기 설정

기본 캐시 크기:

- OBJ 모델: 10개
- GLTF 모델: 10개
- MTL 머티리얼: 10개
- 텍스처: 20개

## 사용법

### 1. 기본 사용

```dart
import 'package:flutter_test_app/utils/assets_manager.dart';

// 싱글톤 인스턴스 가져오기
final assetsManager = AssetsManager();

// OBJ 모델 로드
final objModel = await assetsManager.loadObjModel('1');

// GLTF 모델 로드
final gltfModel = await assetsManager.loadGltfModel('1');

// MTL 머티리얼 로드
final mtlMaterial = await assetsManager.loadMtlMaterial('1');

// 텍스처 로드
final texture = await assetsManager.loadTexture('1', 'Red_F.jpg');
```

### 2. 세션 전체 에셋 프리로드

화면 전환 전에 필요한 에셋을 미리 로드할 수 있습니다.

```dart
// 세션 ID의 모든 에셋 프리로드
await assetsManager.preloadSessionAssets('1');

// 이후 같은 세션의 에셋은 캐시에서 빠르게 로드됩니다
final model = await assetsManager.loadObjModel('1'); // 캐시에서 즉시 반환
```

### 3. 캐시 관리

```dart
// 특정 타입의 캐시 클리어
assetsManager.clearCache(AssetType.texture);

// 모든 캐시 클리어
assetsManager.clearAllCaches();

// 캐시 상태 확인
final stats = assetsManager.getCacheStats();
print(stats);

// 캐시 상태 콘솔 출력
assetsManager.printCacheStats();
```

### 4. 실제 사용 예제

```dart
class HistoricalScreen extends StatefulWidget {
  final String sessionId;
  const HistoricalScreen({required this.sessionId, super.key});

  @override
  State<HistoricalScreen> createState() => _HistoricalScreenState();
}

class _HistoricalScreenState extends State<HistoricalScreen> {
  final assetsManager = AssetsManager();
  THREE.Group? _model;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() => _isLoading = true);

    // AssetsManager를 통해 모델 로드 (캐시 사용)
    final model = await assetsManager.loadGltfModel(widget.sessionId);

    setState(() {
      _model = model;
      _isLoading = false;
    });

    // 캐시 상태 출력
    assetsManager.printCacheStats();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_model == null) {
      return const Center(child: Text('모델을 로드할 수 없습니다'));
    }

    return ThreeJsViewer(model: _model!);
  }
}
```

## LRU 캐시 동작 방식

1. **캐시 히트**: 요청한 에셋이 캐시에 있으면 즉시 반환하고 최근 사용으로 마킹
2. **캐시 미스**: 캐시에 없으면 파일에서 로드하고 캐시에 저장
3. **캐시 만료**: 캐시가 가득 차면 가장 오래 사용하지 않은 에셋을 자동 제거
4. **리소스 정리**: 제거된 에셋의 Three.js 리소스는 자동으로 dispose

### 예시 시나리오

```dart
// 캐시 크기가 3이라고 가정
final cache = LRUCache<String, Model>(maxSize: 3);

cache.put('A', modelA); // 캐시: [A]
cache.put('B', modelB); // 캐시: [A, B]
cache.put('C', modelC); // 캐시: [A, B, C]

cache.get('A');         // 캐시: [B, C, A] (A를 최근 사용으로 이동)

cache.put('D', modelD); // 캐시: [C, A, D] (B가 제거됨 - 가장 오래 사용)
```

## 캐시 상태 모니터링

```dart
final stats = assetsManager.getCacheStats();
/*
{
  'obj': {
    'size': 5,
    'maxSize': 10,
    'isFull': false,
  },
  'gltf': {
    'size': 3,
    'maxSize': 10,
    'isFull': false,
  },
  'mtl': {
    'size': 2,
    'maxSize': 10,
    'isFull': false,
  },
  'texture': {
    'size': 15,
    'maxSize': 20,
    'isFull': false,
  },
}
*/
```

## 주의사항

1. **Clone 반환**: 캐시된 원본을 보호하기 위해 항상 clone()된 객체를 반환합니다.
2. **자동 리소스 정리**: 캐시에서 제거되는 에셋은 자동으로 dispose되므로 별도 정리 불필요.
3. **싱글톤**: AssetsManager는 싱글톤이므로 앱 전체에서 하나의 인스턴스만 존재합니다.
4. **Thread-Safe 아님**: Dart는 싱글 스레드이므로 별도 동기화 처리 불필요.

## 성능 최적화 팁

1. **프리로드 활용**: 화면 전환 전에 필요한 에셋을 미리 로드
2. **캐시 크기 조정**: 앱의 메모리 상황에 따라 캐시 크기 조정 (코드 수정 필요)
3. **선택적 캐시 클리어**: 메모리 부족 시 사용하지 않는 타입의 캐시만 클리어
4. **캐시 상태 모니터링**: 주기적으로 캐시 상태를 확인하여 적절한 크기 설정

## 문제 해결

### Q: 에셋이 로드되지 않아요

A: 캐시 상태를 확인하고 필요시 캐시를 클리어한 후 다시 시도하세요.

```dart
assetsManager.printCacheStats();
assetsManager.clearAllCaches();
```

### Q: 메모리 사용량이 너무 높아요

A: 캐시 크기를 줄이거나 사용하지 않는 캐시를 클리어하세요.

```dart
// Texture 캐시만 클리어
assetsManager.clearCache(AssetType.texture);
```

### Q: 캐시 크기를 변경하고 싶어요

A: `assets_manager.dart` 파일에서 LRUCache 생성 시 maxSize를 변경하세요.

```dart
// lib/utils/assets_manager.dart
final LRUCache<String, THREE.Group> _objCache = LRUCache(maxSize: 20); // 10 -> 20으로 변경
```
