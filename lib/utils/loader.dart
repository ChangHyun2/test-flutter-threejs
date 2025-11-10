import 'package:flutter_test_app/utils/file.dart';
import 'package:three_js_core/three_js_core.dart' as THREE;
import 'package:three_js_simple_loaders/three_js_simple_loaders.dart'
    as SIMPLE_LOADERS;
import 'package:three_js_core_loaders/three_js_core_loaders.dart' as LOADERS;

/// MTL 파일을 로드하여 MaterialCreator 반환
Future<SIMPLE_LOADERS.MaterialCreator?> loadMtlFileBySessionId(
  String sessionId,
) async {
  try {
    final mtlPath = getMtlPathBySessionId(sessionId);
    final mtlLoader = SIMPLE_LOADERS.MTLLoader();
    final materials = await mtlLoader.fromAsset(mtlPath);
    mtlLoader.dispose();
    return materials;
  } catch (e) {
    print('MTL 로드 실패: $e');
    return null;
  }
}

/// MTL과 함께 OBJ 파일을 로드 (머티리얼 적용)
Future<THREE.Group?> loadObjWithMtlBySessionId(String sessionId) async {
  try {
    // 2. OBJ 로더 생성
    final objLoader = SIMPLE_LOADERS.OBJLoader();

    // 4. OBJ 파일 로드
    final modelPath = getModelPathBySessionId(sessionId);
    final obj = await objLoader.fromAsset(modelPath);
    objLoader.dispose();

    return obj;
  } catch (e) {
    print('OBJ 로드 실패: $e');
    return null;
  }
}

/// 기존 함수: MTL 없이 OBJ만 로드
Future<THREE.Group?> loadObjFileBySessionId(String sessionId) async {
  try {
    final modelPath = getModelPathBySessionId(sessionId);
    final objLoader = SIMPLE_LOADERS.OBJLoader();
    final obj = await objLoader.fromAsset(modelPath);
    objLoader.dispose();
    return obj;
  } catch (e) {
    return null;
  }
}

Future<THREE.Texture?> loadTextureFileBySessionId(
  String sessionId,
  String textureFileName,
) async {
  try {
    final texturePath = getTexturePathBySessionId(sessionId, textureFileName);
    final textureLoader = LOADERS.TextureLoader();
    print(texturePath);
    final texture = await textureLoader.fromAsset(texturePath);
    textureLoader.dispose();
    return texture;
  } catch (e) {
    return null;
  }
}
