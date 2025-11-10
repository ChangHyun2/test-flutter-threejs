import 'package:flutter/material.dart';
import 'package:flutter_test_app/widgets/threejs/threejs_viewer.dart';
import 'package:flutter_test_app/utils/loader.dart';

class HistoricalScreen extends StatelessWidget {
  const HistoricalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String sessionId = '1';
    final String sessionId2 = '2';
    final String textureFileName = 'Rgb_F.jpg';

    final future = Future.wait([
      loadObjWithMtlBySessionId(sessionId),
      loadTextureFileBySessionId(sessionId, textureFileName),
      loadObjWithMtlBySessionId(sessionId2),
      loadTextureFileBySessionId(sessionId2, textureFileName),
    ]);

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == null) {
            return const Center(child: Text('Error loading data'));
          }

          final obj = snapshot.data![0];
          final texture = snapshot.data![1];
          final obj2 = snapshot.data![2];
          final texture2 = snapshot.data![3];

          return Row(
            children: [
              Expanded(
                child: ThreejsViewer(object: obj, texture: texture),
              ),
              Expanded(
                child: ThreejsViewer(object: obj2, texture: texture2),
              ),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
