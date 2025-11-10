import 'package:flutter_test_app/utils/file.dart';
import 'package:three_js_core/three_js_core.dart' as THREE;
import 'package:three_js_simple_loaders/three_js_simple_loaders.dart'
    as SIMPLE_LOADERS;
import 'package:three_js_core_loaders/three_js_core_loaders.dart' as LOADERS;

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
