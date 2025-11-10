# Textures & Resources

## Overview
- 텍스처는 대역폭/GPU 메모리의 주 소비자. 압축/해상도/색공간/미프맵 관리가 핵심.

## Theory
- Color Space: sRGB(컬러) vs Linear(연산). 렌더러/텍스처 색공간 일관성 필요.
- Mipmaps: 원근 축소 시 앨리어싱 감소, 샘플링 품질↑, 캐시 효율↑.
- Compression: KTX2(BasisU)로 범용 압축 → 플랫폼별 ASTC/ETC/BC로 트랜스코딩.

## Practical Notes
- 로딩: 프리로드/지연 로딩/프로그레시브 로딩. 텍스처 재사용으로 스위치 비용↓.
- 업데이트: `texture.needsUpdate=true`는 최소화. 랩/필터 설정 명확화.
- GPU 메모리 모니터링: 텍스처 해상도 정책 수립(예: 2K 상한, 모바일 1K).

## Checklist
- 텍스처 크기/개수 예산 설정, 아틀라스 사용 고려.
- 색공간/감마 일관성(감마 보정 중복/누락 방지).

## Snippet
```js
const tex = await new KTX2Loader().loadAsync('albedo.ktx2');
tex.colorSpace = THREE.SRGBColorSpace;
tex.generateMipmaps = true;
tex.minFilter = THREE.LinearMipmapLinearFilter;
```


