import 'package:three_js/three_js.dart' as three;

/// OBJ 메시를 투명한 회색 톤으로 변경하는 함수입니다.
/// 입력된 Object3D 객체(Group, Mesh 등)의 모든 하위 Mesh에
/// 투명한 회색 머티리얼을 적용합니다.
///
/// [obj] - 변경할 Object3D 객체 (Group, Mesh 등)
/// [grayColor] - 회색 색상 값 (기본값: 0x808080, 중간 회색)
/// [opacity] - 투명도 값 (0.0 = 완전 투명, 1.0 = 불투명, 기본값: 0.5)
///
/// 사용 예:
///   applyTransparentGrayToMesh(objMesh);
///   applyTransparentGrayToMesh(objMesh, grayColor: 0x999999, opacity: 0.7);
void applyTransparentGrayToMesh(
  three.Object3D obj, {
  int grayColor = 0x808080,
  double opacity = 0.5,
}) {
  // 투명한 회색 머티리얼 생성
  final material = three.MeshBasicMaterial()
    ..color = three.Color.fromHex32(grayColor)
    ..transparent = true
    ..opacity = opacity
    ..needsUpdate = true;

  // 재귀적으로 모든 하위 Mesh에 머티리얼 적용
  obj.traverse((child) {
    if (child is three.Mesh) {
      child.material = material;
    }
  });
}
