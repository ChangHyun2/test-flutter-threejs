import 'package:flutter/material.dart';
import 'package:flutter_test_app/utils/assets_manager.dart';

/// AssetsManager 사용 예제
class AssetsManagerExample extends StatefulWidget {
  const AssetsManagerExample({super.key});

  @override
  State<AssetsManagerExample> createState() => _AssetsManagerExampleState();
}

class _AssetsManagerExampleState extends State<AssetsManagerExample> {
  final assetsManager = AssetsManager();
  String _status = '대기 중...';

  @override
  void initState() {
    super.initState();
    // _loadAssets();
  }

  Future<void> _loadAssets() async {
    setState(() => _status = '에셋 로딩 시작...');

    try {
      // 1. 단일 모델 로드 (캐시 사용)
      final obj1 = await assetsManager.loadObjModel('1');
      setState(() => _status = 'OBJ 모델 1 로드 완료: ${obj1 != null}');

      // 2. 같은 모델 다시 로드 (캐시에서 가져옴)
      final obj1Cached = await assetsManager.loadObjModel('1');
      setState(() => _status = 'OBJ 모델 1 캐시 로드 완료: ${obj1Cached != null}');

      // 3. GLTF 모델 로드
      final gltf1 = await assetsManager.loadGltfModel('1');
      setState(() => _status = 'GLTF 모델 1 로드 완료: ${gltf1 != null}');

      // 4. 텍스처 로드
      final texture = await assetsManager.loadTexture('1', 'Red_F.jpg');
      setState(() => _status = '텍스처 로드 완료: ${texture != null}');

      // 5. 세션 전체 에셋 프리로드
      await assetsManager.preloadSessionAssets('2');
      setState(() => _status = '세션 2 프리로드 완료');

      // 6. 캐시 상태 출력
      assetsManager.printCacheStats();
      final stats = assetsManager.getCacheStats();
      setState(() => _status = '캐시 상태: ${stats.toString()}');
    } catch (e) {
      setState(() => _status = '에러 발생: $e');
    }
  }

  Future<void> _clearCache() async {
    assetsManager.clearAllCaches();
    setState(() => _status = '모든 캐시 클리어 완료');
    assetsManager.printCacheStats();
  }

  Future<void> _clearTextureCache() async {
    assetsManager.clearCache(AssetType.texture);
    setState(() => _status = '텍스처 캐시 클리어 완료');
    assetsManager.printCacheStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AssetsManager 예제')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAssets,
              child: const Text('에셋 다시 로드'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _clearTextureCache,
              child: const Text('텍스처 캐시 클리어'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _clearCache,
              child: const Text('모든 캐시 클리어'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                assetsManager.printCacheStats();
                final stats = assetsManager.getCacheStats();
                setState(() => _status = stats.toString());
              },
              child: const Text('캐시 상태 확인'),
            ),
          ],
        ),
      ),
    );
  }
}
