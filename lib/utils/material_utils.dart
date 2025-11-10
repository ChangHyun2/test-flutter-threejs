import 'package:three_js/three_js.dart' as three;

// ============================================================================
// 머티리얼 유틸리티 함수
// ============================================================================

/// obj의 모든 Mesh에 텍스처를 적용
///
/// [obj]: 텍스처를 적용할 3D 오브젝트
/// [texture]: 적용할 텍스처
void applyTextureToObject(three.Object3D obj, three.Texture texture) {
  for (var child in obj.children) {
    if (child is three.Mesh) {
      final material = child.material;
      if (material is three.MeshStandardMaterial) {
        // 기존 MeshStandardMaterial의 map 프로퍼티에 텍스처를 할당
        material.map = texture;
        material.needsUpdate = true;
      } else if (material is three.Material) {
        // MeshStandardMaterial의 생성자가 map 파라미터를 지원하지 않음
        // 따라서 setValues나 fromMap을 사용해 텍스처를 할당해야 함
        // 또는 생성 후 map 프로퍼티로 할당
        final newMaterial = three.MeshStandardMaterial();
        newMaterial.map = texture;
        newMaterial.needsUpdate = true;
        child.material = newMaterial;
      }
    }
  }
}
