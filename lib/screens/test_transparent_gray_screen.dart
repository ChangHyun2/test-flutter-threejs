import 'package:flutter/material.dart';
import 'package:flutter_test_app/utils/loader.dart';
import 'package:flutter_test_app/utils/threejs/object3d/transparent_gray.dart';
import 'package:flutter_test_app/widgets/threejs/threejs_viewer.dart';
import 'package:three_js/three_js.dart' as three;
import 'package:three_js_core/three_js_core.dart' as THREE;

/// 두 개의 서로 다른 메시를 투명한 그레이톤으로 겹쳐서 보여주는 테스트 화면
class TestTransparentGrayScreen extends StatelessWidget {
  const TestTransparentGrayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String sessionId1 = '1';
    final String sessionId2 = '2';

    // 시간 측정을 위한 Stopwatch
    final stopwatch = Stopwatch()..start();

    // 각 Future에 시간 측정 래퍼 추가
    Future<T> measureTime<T>(Future<T> future, String name) async {
      final startTime = DateTime.now();
      final result = await future;
      final duration = DateTime.now().difference(startTime);
      print(
        '[$name] 소요 시간: ${duration.inMilliseconds}ms (${duration.inSeconds}s)',
      );
      return result;
    }

    final future = Future.wait([
      measureTime(
        loadGltfFileBySessionId(sessionId1),
        'loadGltfFileBySessionId($sessionId1)',
      ),
      measureTime(
        loadObjFileBySessionId(sessionId2),
        'loadObjFileBySessionId($sessionId2)',
      ),
    ]).then((results) {
      stopwatch.stop();
      print(
        '[전체 Future.wait] 총 소요 시간: ${stopwatch.elapsedMilliseconds}ms (${stopwatch.elapsed.inSeconds}s)',
      );
      return results;
    });

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == null) {
            return const Center(child: Text('Error loading data'));
          }

          final obj1 = snapshot.data![0] as THREE.Group?;
          final obj2 = snapshot.data![1] as THREE.Group?;

          if (obj1 == null || obj2 == null) {
            return const Center(child: Text('Failed to load models'));
          }

          // clone()을 사용하여 원본을 보존
          final threeObj1 = obj1.clone();
          final threeObj2 = obj2.clone();

          // 첫 번째 메시에 투명한 회색톤 적용 (약간 밝은 회색, 0.6 투명도)
          applyTransparentGrayToMesh(
            threeObj1,
            grayColor: 0x999999,
            opacity: 0.6,
          );

          // 두 번째 메시에 투명한 회색톤 적용 (약간 어두운 회색, 0.5 투명도)
          applyTransparentGrayToMesh(
            threeObj2,
            grayColor: 0x666666,
            opacity: 0.5,
          );

          // 두 메시를 하나의 그룹으로 합치기
          final combinedGroup = three.Group();
          combinedGroup.add(threeObj1);
          combinedGroup.add(threeObj2);

          return Column(
            children: [
              // 설명 텍스트
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '투명한 그레이톤 메시 겹치기 테스트',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '두 개의 서로 다른 메시를 투명한 회색톤으로 겹쳐서 표시합니다.',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• 첫 번째 메시: 밝은 회색 (0x999999), 투명도 0.6',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      '• 두 번째 메시: 어두운 회색 (0x666666), 투명도 0.5',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              // 3D 뷰어
              Expanded(
                child: ThreejsViewer(
                  items: [
                    ThreejsViewerItem(
                      object: combinedGroup,
                      isFigure: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('3D 모델 로딩 중...'),
            ],
          ),
        );
      },
    );
  }
}

