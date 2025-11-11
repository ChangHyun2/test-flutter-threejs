import 'dart:collection';
import 'package:flutter_test_app/utils/loader.dart';
import 'package:three_js_core/three_js_core.dart' as THREE;
import 'package:three_js_simple_loaders/three_js_simple_loaders.dart'
    as SIMPLE_LOADERS;

/// LRU 캐시 구현
class LRUCache<K, V> {
  final int maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();

  LRUCache({required this.maxSize}) {
    if (maxSize <= 0) {
      throw ArgumentError('maxSize must be greater than 0');
    }
  }

  /// 캐시에서 값을 가져옵니다. 접근한 항목은 가장 최근 사용으로 이동됩니다.
  V? get(K key) {
    if (!_cache.containsKey(key)) {
      return null;
    }
    // LRU: 접근한 항목을 맨 뒤로 이동 (가장 최근 사용)
    final value = _cache.remove(key)!;
    _cache[key] = value;
    return value;
  }

  /// 캐시에 값을 저장합니다. 용량 초과시 가장 오래된 항목을 제거합니다.
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= maxSize) {
      // 가장 오래된 항목 제거 (맨 앞)
      final oldestKey = _cache.keys.first;
      final oldestValue = _cache.remove(oldestKey)!;

      // Three.js 리소스 정리
      _disposeResource(oldestValue);

      print('LRU Cache: 용량 초과로 제거됨 - $oldestKey');
    }
    _cache[key] = value;
  }

  /// 특정 키의 캐시를 제거합니다.
  V? remove(K key) {
    if (!_cache.containsKey(key)) {
      return null;
    }
    final value = _cache.remove(key)!;
    _disposeResource(value);
    return value;
  }

  /// 캐시를 모두 비웁니다.
  void clear() {
    for (var value in _cache.values) {
      _disposeResource(value);
    }
    _cache.clear();
  }

  /// Three.js 리소스 정리
  void _disposeResource(V value) {
    try {
      if (value is THREE.Texture) {
        value.dispose();
      } else if (value is THREE.Material) {
        value.dispose();
      } else if (value is THREE.Object3D) {
        value.traverse((child) {
          if (child is THREE.Mesh) {
            child.geometry?.dispose();
            if (child.material is THREE.Material) {
              (child.material as THREE.Material).dispose();
            }
          }
        });
      } else if (value is SIMPLE_LOADERS.MaterialCreator) {
        // MaterialCreator의 경우 개별 material dispose
        // Note: MaterialCreator는 dispose 메서드가 없을 수 있음
      }
    } catch (e) {
      print('리소스 정리 중 오류 발생: $e');
    }
  }

  /// 현재 캐시 크기
  int get length => _cache.length;

  /// 캐시가 비어있는지 확인
  bool get isEmpty => _cache.isEmpty;

  /// 캐시가 가득 찼는지 확인
  bool get isFull => _cache.length >= maxSize;

  /// 캐시에 키가 존재하는지 확인
  bool containsKey(K key) => _cache.containsKey(key);
}

/// ThreeJS 에셋 타입
enum AssetType { obj, gltf, mtl, texture }

/// ThreeJS 에셋 매니저 (싱글톤)
class AssetsManager {
  static final AssetsManager _instance = AssetsManager._internal();
  factory AssetsManager() => _instance;

  AssetsManager._internal();

  // 각 에셋 타입별 LRU 캐시 (기본 용량: 10개)
  final LRUCache<String, THREE.Group> _objCache = LRUCache(maxSize: 10);
  final LRUCache<String, THREE.Group> _gltfCache = LRUCache(maxSize: 10);
  final LRUCache<String, SIMPLE_LOADERS.MaterialCreator> _mtlCache = LRUCache(
    maxSize: 10,
  );
  final LRUCache<String, THREE.Texture> _textureCache = LRUCache(maxSize: 20);

  /// 캐시 크기 설정 (초기화 시 한 번만 호출)
  void configureCacheSize({
    int? objCacheSize,
    int? gltfCacheSize,
    int? mtlCacheSize,
    int? textureCacheSize,
  }) {
    // 캐시 크기는 생성 후 변경 불가하므로, 재생성이 필요한 경우
    // 기존 캐시를 clear하고 새로 생성해야 합니다.
    print('현재 구현은 캐시 크기가 고정되어 있습니다.');
    print(
      'OBJ: ${_objCache.maxSize}, GLTF: ${_gltfCache.maxSize}, '
      'MTL: ${_mtlCache.maxSize}, Texture: ${_textureCache.maxSize}',
    );
  }

  /// OBJ 파일 로드 (캐시 사용)
  Future<THREE.Group?> loadObjModel(String sessionId) async {
    final cacheKey = 'obj_$sessionId';

    // 캐시 확인
    final cached = _objCache.get(cacheKey);
    if (cached != null) {
      print('캐시에서 OBJ 모델 로드: $sessionId');
      return cached.clone() as THREE.Group;
    }

    // 캐시 미스 - 파일에서 로드
    print('파일에서 OBJ 모델 로드: $sessionId');
    final obj = await loadObjFileBySessionId(sessionId);

    if (obj != null) {
      _objCache.put(cacheKey, obj);
      return obj.clone() as THREE.Group;
    }

    return null;
  }

  /// GLTF 파일 로드 (캐시 사용)
  Future<THREE.Group?> loadGltfModel(String sessionId) async {
    final cacheKey = 'gltf_$sessionId';

    // 캐시 확인
    final cached = _gltfCache.get(cacheKey);
    if (cached != null) {
      print('캐시에서 GLTF 모델 로드: $sessionId');
      return cached.clone() as THREE.Group;
    }

    // 캐시 미스 - 파일에서 로드
    print('파일에서 GLTF 모델 로드: $sessionId');
    final gltf = await loadGltfFileBySessionId(sessionId);

    if (gltf != null) {
      _gltfCache.put(cacheKey, gltf);

      return gltf.clone() as THREE.Group;
    }

    return null;
  }

  /// MTL 파일 로드 (캐시 사용)
  Future<SIMPLE_LOADERS.MaterialCreator?> loadMtlMaterial(
    String sessionId,
  ) async {
    final cacheKey = 'mtl_$sessionId';

    // 캐시 확인
    final cached = _mtlCache.get(cacheKey);
    if (cached != null) {
      print('캐시에서 MTL 머티리얼 로드: $sessionId');
      return cached;
    }

    // 캐시 미스 - 파일에서 로드
    print('파일에서 MTL 머티리얼 로드: $sessionId');
    final mtl = await loadMtlFileBySessionId(sessionId);

    if (mtl != null) {
      _mtlCache.put(cacheKey, mtl);
    }

    return mtl;
  }

  /// Texture 파일 로드 (캐시 사용)
  Future<THREE.Texture?> loadTexture(
    String sessionId,
    String textureFileName,
  ) async {
    final cacheKey = 'texture_${sessionId}_$textureFileName';

    // 캐시 확인
    final cached = _textureCache.get(cacheKey);
    if (cached != null) {
      print('캐시에서 텍스처 로드: $sessionId/$textureFileName');
      return cached.clone();
    }

    // 캐시 미스 - 파일에서 로드
    print('파일에서 텍스처 로드: $sessionId/$textureFileName');
    final texture = await loadTextureFileBySessionId(
      sessionId,
      textureFileName,
    );

    if (texture != null) {
      _textureCache.put(cacheKey, texture);
      return texture.clone();
    }

    return null;
  }

  /// 특정 세션의 모든 에셋 프리로드
  Future<void> preloadSessionAssets(String sessionId) async {
    print('세션 에셋 프리로드 시작: $sessionId');

    await Future.wait([
      loadObjModel(sessionId),
      loadGltfModel(sessionId),
      loadMtlMaterial(sessionId),
      // 일반적인 텍스처들 프리로드
      loadTexture(sessionId, 'Red_F.jpg'),
      loadTexture(sessionId, 'Red_heat_F.jpg'),
      loadTexture(sessionId, 'Rgb_F.jpg'),
    ]);

    print('세션 에셋 프리로드 완료: $sessionId');
  }

  /// 특정 타입의 캐시 클리어
  void clearCache(AssetType type) {
    switch (type) {
      case AssetType.obj:
        _objCache.clear();
        break;
      case AssetType.gltf:
        _gltfCache.clear();
        break;
      case AssetType.mtl:
        _mtlCache.clear();
        break;
      case AssetType.texture:
        _textureCache.clear();
        break;
    }
    print('${type.name} 캐시 클리어 완료');
  }

  /// 모든 캐시 클리어
  void clearAllCaches() {
    _objCache.clear();
    _gltfCache.clear();
    _mtlCache.clear();
    _textureCache.clear();
    print('모든 캐시 클리어 완료');
  }

  /// 캐시 상태 정보
  Map<String, dynamic> getCacheStats() {
    return {
      'obj': {
        'size': _objCache.length,
        'maxSize': _objCache.maxSize,
        'isFull': _objCache.isFull,
      },
      'gltf': {
        'size': _gltfCache.length,
        'maxSize': _gltfCache.maxSize,
        'isFull': _gltfCache.isFull,
      },
      'mtl': {
        'size': _mtlCache.length,
        'maxSize': _mtlCache.maxSize,
        'isFull': _mtlCache.isFull,
      },
      'texture': {
        'size': _textureCache.length,
        'maxSize': _textureCache.maxSize,
        'isFull': _textureCache.isFull,
      },
    };
  }

  /// 캐시 상태 출력
  void printCacheStats() {
    final stats = getCacheStats();
    print('=== 캐시 상태 ===');
    stats.forEach((key, value) {
      print(
        '$key: ${value['size']}/${value['maxSize']} '
        '(Full: ${value['isFull']})',
      );
    });
  }
}
