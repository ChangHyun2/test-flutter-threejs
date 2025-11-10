// Three.js 인스턴스 풀 사용 예시

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/threejs_pool_provider.dart';

class ThreeJSPoolUsageExample extends ConsumerWidget {
  const ThreeJSPoolUsageExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poolNotifier = ref.read(threeJSPoolProvider.notifier);
    final poolState = ref.watch(threeJSPoolProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Three.js Pool 사용 예시')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('현재 인스턴스 개수: ${poolNotifier.count}'),
                const SizedBox(height: 8),
                Text('인스턴스 ID 목록: ${poolNotifier.getInstanceIds().join(", ")}'),
              ],
            ),
          ),

          // 버튼들
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(
                onPressed: () {
                  // 새 인스턴스 추가
                  final id =
                      'instance_${DateTime.now().millisecondsSinceEpoch}';
                  poolNotifier.addInstance(id, {
                    'data': 'sample three.js instance',
                  });
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('인스턴스 추가됨: $id')));
                },
                child: const Text('인스턴스 추가'),
              ),

              ElevatedButton(
                onPressed: () {
                  final ids = poolNotifier.getInstanceIds();
                  if (ids.isNotEmpty) {
                    final instance = poolNotifier.getInstance(ids.first);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('인스턴스 조회: ${ids.first} - $instance'),
                      ),
                    );
                  }
                },
                child: const Text('첫 번째 인스턴스 조회'),
              ),

              ElevatedButton(
                onPressed: () {
                  final ids = poolNotifier.getInstanceIds();
                  if (ids.isNotEmpty) {
                    poolNotifier.removeInstance(ids.first);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('인스턴스 제거됨: ${ids.first}')),
                    );
                  }
                },
                child: const Text('첫 번째 인스턴스 제거'),
              ),

              ElevatedButton(
                onPressed: () {
                  poolNotifier.clearAll();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('모든 인스턴스 제거됨')));
                },
                child: const Text('전체 삭제'),
              ),
            ],
          ),

          // 인스턴스 목록
          Expanded(
            child: ListView.builder(
              itemCount: poolState.instances.length,
              itemBuilder: (context, index) {
                final id = poolState.instances.keys.elementAt(index);
                final instance = poolState.instances[id]!;
                return ListTile(
                  title: Text(id),
                  subtitle: Text('생성 시간: ${instance.createdAt}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      poolNotifier.removeInstance(id);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// 다른 화면에서 사용하는 예시
// ========================================

class AnotherScreenExample extends ConsumerStatefulWidget {
  const AnotherScreenExample({super.key});

  @override
  ConsumerState<AnotherScreenExample> createState() =>
      _AnotherScreenExampleState();
}

class _AnotherScreenExampleState extends ConsumerState<AnotherScreenExample> {
  @override
  void initState() {
    super.initState();

    // 화면 진입 시 인스턴스 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final poolNotifier = ref.read(threeJSPoolProvider.notifier);

      // 이미 존재하는지 확인
      if (!poolNotifier.hasInstance('screen_instance')) {
        // Three.js 인스턴스 생성 및 추가
        final threeJSInstance = createThreeJSInstance();
        poolNotifier.addInstance('screen_instance', threeJSInstance);
      }
    });
  }

  dynamic createThreeJSInstance() {
    // 실제 Three.js 인스턴스 생성 로직
    // 예: Scene, Camera, Renderer 등
    return {
      'scene': 'SceneInstance',
      'camera': 'CameraInstance',
      'renderer': 'RendererInstance',
    };
  }

  @override
  void dispose() {
    // 화면 종료 시 인스턴스 정리 (선택사항)
    // ref.read(threeJSPoolProvider.notifier).removeInstance('screen_instance');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final poolNotifier = ref.read(threeJSPoolProvider.notifier);

    // 인스턴스 가져오기
    final instance = poolNotifier.getInstance('screen_instance');

    return Scaffold(
      appBar: AppBar(title: const Text('다른 화면 예시')),
      body: Center(child: Text('인스턴스: $instance')),
    );
  }
}
