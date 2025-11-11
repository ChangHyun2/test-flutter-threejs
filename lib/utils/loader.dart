import 'package:flutter/foundation.dart';
import 'package:flutter_test_app/utils/file.dart';
import 'package:three_js_core/three_js_core.dart' as THREE;
import 'package:three_js_simple_loaders/three_js_simple_loaders.dart'
    as SIMPLE_LOADERS;
import 'package:three_js_core_loaders/three_js_core_loaders.dart' as LOADERS;
import 'package:three_js_advanced_loaders/three_js_advanced_loaders.dart';

/// MTL 파일 로드 헬퍼 함수 (isolate에서 실행)
Future<SIMPLE_LOADERS.MaterialCreator?> _loadMtlFileIsolate(
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

/// MTL 파일을 로드하여 MaterialCreator 반환
Future<SIMPLE_LOADERS.MaterialCreator?> loadMtlFileBySessionId(
  String sessionId,
) async {
  return await compute(_loadMtlFileIsolate, sessionId);
}

/// OBJ 파일 로드 헬퍼 함수 (isolate에서 실행)
Future<THREE.Group?> _loadObjFileIsolate(String sessionId) async {
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

Future<THREE.Group?> loadObjFileBySessionId(String sessionId) async {
  return await compute(_loadObjFileIsolate, sessionId);
}

/// GLTF 파일 로드 헬퍼 함수 (isolate에서 실행)
Future<THREE.Group?> _loadGltfFileIsolate(String sessionId) async {
  try {
    final modelPath = getGlftModelPathBySessionId(sessionId);
    final gltfLoader = GLTFLoader();
    final gltf = await gltfLoader.fromAsset(modelPath);
    gltfLoader.dispose();
    return gltf?.scene as THREE.Group?;
  } catch (e) {
    return null;
  }
}

Future<THREE.Group?> loadGltfFileBySessionId(String sessionId) async {
  return await compute(_loadGltfFileIsolate, sessionId);
}

/// 텍스처 파일 로드 헬퍼 함수 (isolate에서 실행)
Future<THREE.Texture?> _loadTextureFileIsolate(
  Map<String, String> params,
) async {
  try {
    final sessionId = params['sessionId']!;
    final textureFileName = params['textureFileName']!;
    final texturePath = getTexturePathBySessionId(sessionId, textureFileName);
    final textureLoader = LOADERS.TextureLoader();
    final texture = await textureLoader.fromAsset(texturePath);
    textureLoader.dispose();
    return texture;
  } catch (e) {
    return null;
  }
}

Future<THREE.Texture?> loadTextureFileBySessionId(
  String sessionId,
  String textureFileName,
) async {
  return await compute(_loadTextureFileIsolate, {
    'sessionId': sessionId,
    'textureFileName': textureFileName,
  });
}
