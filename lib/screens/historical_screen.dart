import 'package:flutter/material.dart';
import 'package:flutter_test_app/widgets/threejs/threejs_viewer.dart';
import 'package:flutter_test_app/utils/loader.dart';
import 'package:flutter_test_app/utils/material_utils.dart';

class HistoricalScreen extends StatelessWidget {
  const HistoricalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String sessionId = '1';
    final String sessionId2 = '2';
    final String textureFileName = 'Rgb_F.jpg';

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

    final future =
        Future.wait([
          measureTime(
            loadGltfFileBySessionId(sessionId),
            'loadGltfFileBySessionId($sessionId)',
          ),
          measureTime(
            loadTextureFileBySessionId(sessionId, textureFileName),
            'loadTextureFileBySessionId($sessionId, $textureFileName)',
          ),
          measureTime(
            loadObjFileBySessionId(sessionId),
            'loadObjFileBySessionId($sessionId)',
          ),
          measureTime(
            loadTextureFileBySessionId(sessionId, textureFileName),
            'loadTextureFileBySessionId($sessionId, $textureFileName)',
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

          final items1 = [];
          final items2 = [];

          final obj = snapshot.data![0];
          if (obj != null) {
            applyTextureToObject(obj, snapshot.data![1], isFlipY: true);
            items1.add(ThreejsViewerItem(object: obj, isFigure: true));
          }

          final obj2 = snapshot.data![2];
          if (obj2 != null) {
            applyTextureToObject(obj2, snapshot.data![3]);
            items2.add(ThreejsViewerItem(object: obj2, isFigure: true));
          }

          return Row(
            children: [
              Expanded(
                child: ThreejsViewer(
                  items: [ThreejsViewerItem(object: obj, isFigure: true)],
                ),
              ),
              Expanded(
                child: ThreejsViewer(
                  items: [ThreejsViewerItem(object: obj2, isFigure: true)],
                ),
              ),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
