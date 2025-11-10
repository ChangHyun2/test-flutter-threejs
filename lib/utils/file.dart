import 'package:flutter/services.dart';

Future<String> loadFileFromAssets(String path) async {
  return await rootBundle.loadString(path);
}

String getModelPathBySessionId(String sessionId) {
  if (!['1', '2', '3'].contains(sessionId)) {
    throw ArgumentError('Invalid session ID. Must be 1, 2, or 3');
  }
  return '$sessionId/model.obj';
}

String getTexturePathBySessionId(String sessionId, String textureFileName) {
  if (!['1', '2', '3'].contains(sessionId)) {
    throw ArgumentError('Invalid session ID. Must be 1, 2, or 3');
  }
  return 'assets/$sessionId/$textureFileName';
}

String getMtlPathBySessionId(String sessionId) {
  if (!['1', '2', '3'].contains(sessionId)) {
    throw ArgumentError('Invalid session ID. Must be 1, 2, or 3');
  }
  return '$sessionId/model.obj.mtl';
}
