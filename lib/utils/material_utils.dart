import 'package:three_js/three_js.dart' as three;

/// obj의 모든 Mesh에 텍스처를 적용 (재귀적으로)
void applyTextureToObject(three.Object3D obj, three.Texture texture) {
  _applyTextureRecursive(obj, texture);
}

/// 재귀적으로 모든 자식 Mesh에 텍스처 적용
void _applyTextureRecursive(three.Object3D obj, three.Texture texture) {
  final newMaterial = three.MeshBasicMaterial();
  newMaterial.map = texture;
  newMaterial.needsUpdate = true;
  texture.colorSpace = three.SRGBColorSpace;

  obj.traverse((child) {
    if (child is three.Mesh) {
      child.material = newMaterial;
    }
  });
}
