# Flutter와 Three.js 통합

## 1. Flutter Three.js 패키지 개요

### 주요 패키지

| 패키지 | 설명 | 특징 |
|--------|------|------|
| `flutter_gl` | OpenGL ES 바인딩 | 네이티브 렌더링 |
| `three_dart` | Three.js의 Dart 포트 | 순수 Dart/Flutter |
| `three_js` (webview) | WebView 기반 | 웹 Three.js 사용 |
| `flutter_3d_controller` | 3D 뷰어 위젯 | 간단한 모델 표시 |

### 추천: three_dart + flutter_gl
```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  three_dart: ^0.0.17
  flutter_gl: ^0.0.21
```

---

## 2. three_dart 기본 설정

### 설치 및 초기화
```dart
import 'package:flutter/material.dart';
import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as three;

class ThreeDView extends StatefulWidget {
  @override
  _ThreeDViewState createState() => _ThreeDViewState();
}

class _ThreeDViewState extends State<ThreeDView> {
  late FlutterGlPlugin flutterGlPlugin;
  int? textureId;
  
  three.WebGLRenderer? renderer;
  three.Scene? scene;
  three.Camera? camera;
  three.Mesh? mesh;
  
  @override
  void initState() {
    super.initState();
    initGL();
  }
  
  Future<void> initGL() async {
    flutterGlPlugin = FlutterGlPlugin();
    
    Map<String, dynamic> options = {
      "antialias": true,
      "alpha": false,
      "width": 300,
      "height": 300,
      "dpr": 1.0
    };
    
    await flutterGlPlugin.initialize(options: options);
    
    setState(() {
      textureId = flutterGlPlugin.textureId;
    });
    
    setupScene();
    animate();
  }
  
  void setupScene() {
    // Scene
    scene = three.Scene();
    
    // Camera
    camera = three.PerspectiveCamera(50, 1.0, 0.1, 1000);
    camera!.position.z = 5;
    
    // Renderer
    renderer = three.WebGLRenderer({
      "width": 300,
      "height": 300,
      "gl": flutterGlPlugin,
      "antialias": true
    });
    
    // Geometry & Material
    var geometry = three.BoxGeometry(1, 1, 1);
    var material = three.MeshBasicMaterial({"color": 0x00ff00});
    mesh = three.Mesh(geometry, material);
    scene!.add(mesh!);
  }
  
  void animate() {
    if (!mounted) return;
    
    // 회전 애니메이션
    mesh!.rotation.x += 0.01;
    mesh!.rotation.y += 0.01;
    
    // 렌더링
    renderer!.render(scene!, camera!);
    
    // 다음 프레임
    Future.delayed(Duration(milliseconds: 16), animate);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Three.js in Flutter')),
      body: Center(
        child: textureId != null
          ? Texture(textureId: textureId!)
          : CircularProgressIndicator(),
      ),
    );
  }
  
  @override
  void dispose() {
    renderer?.dispose();
    flutterGlPlugin.dispose();
    super.dispose();
  }
}
```

---

## 3. WebView 기반 통합 (대안)

### 장점
- 완전한 Three.js 생태계 사용
- 많은 예제와 라이브러리
- 빠른 개발

### 단점
- 네이티브보다 낮은 성능
- Flutter-JS 통신 오버헤드
- 플랫폼 제약

### 구현
```dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';

class ThreeJSWebView extends StatefulWidget {
  @override
  _ThreeJSWebViewState createState() => _ThreeJSWebViewState();
}

class _ThreeJSWebViewState extends State<ThreeJSWebView> {
  late WebViewController controller;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WebView(
        initialUrl: 'about:blank',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          controller = webViewController;
          _loadHtmlFromAssets();
        },
        javascriptChannels: {
          JavascriptChannel(
            name: 'FlutterBridge',
            onMessageReceived: (JavascriptMessage message) {
              _handleMessageFromJS(message.message);
            },
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _sendToJS({'action': 'rotate', 'speed': 2.0});
        },
        child: Icon(Icons.play_arrow),
      ),
    );
  }
  
  void _loadHtmlFromAssets() async {
    String htmlContent = await DefaultAssetBundle.of(context)
        .loadString('assets/threejs_viewer.html');
    
    controller.loadUrl(Uri.dataFromString(
      htmlContent,
      mimeType: 'text/html',
      encoding: Encoding.getByName('utf-8')
    ).toString());
  }
  
  void _sendToJS(Map<String, dynamic> data) {
    String json = jsonEncode(data);
    controller.runJavascript("handleFlutterMessage($json)");
  }
  
  void _handleMessageFromJS(String message) {
    Map<String, dynamic> data = jsonDecode(message);
    
    if (data['type'] == 'faceSelected') {
      setState(() {
        // Update Flutter state
      });
    }
  }
}
```

### HTML 파일 (assets/threejs_viewer.html)
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { margin: 0; overflow: hidden; }
    canvas { display: block; }
  </style>
</head>
<body>
  <script src="https://cdn.jsdelivr.net/npm/three@0.150.0/build/three.min.js"></script>
  <script>
    let scene, camera, renderer, mesh;
    
    function init() {
      scene = new THREE.Scene();
      
      camera = new THREE.PerspectiveCamera(
        50, 
        window.innerWidth / window.innerHeight, 
        0.1, 
        1000
      );
      camera.position.z = 5;
      
      renderer = new THREE.WebGLRenderer({ antialias: true });
      renderer.setSize(window.innerWidth, window.innerHeight);
      document.body.appendChild(renderer.domElement);
      
      const geometry = new THREE.BoxGeometry(1, 1, 1);
      const material = new THREE.MeshBasicMaterial({ color: 0x00ff00 });
      mesh = new THREE.Mesh(geometry, material);
      scene.add(mesh);
      
      animate();
    }
    
    function animate() {
      requestAnimationFrame(animate);
      mesh.rotation.x += 0.01;
      mesh.rotation.y += 0.01;
      renderer.render(scene, camera);
    }
    
    // Flutter에서 호출할 함수
    function handleFlutterMessage(data) {
      if (data.action === 'rotate') {
        mesh.rotation.y += data.speed * 0.1;
      }
    }
    
    // Flutter로 메시지 전송
    function sendToFlutter(data) {
      if (window.FlutterBridge) {
        FlutterBridge.postMessage(JSON.stringify(data));
      }
    }
    
    // 클릭 이벤트
    renderer.domElement.addEventListener('click', (event) => {
      sendToFlutter({
        type: 'clicked',
        x: event.clientX,
        y: event.clientY
      });
    });
    
    window.addEventListener('resize', () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    });
    
    init();
  </script>
</body>
</html>
```

---

## 4. Flutter ↔ Three.js 통신

### Flutter → Three.js (명령)
```dart
class ThreeJSController {
  final WebViewController webViewController;
  
  ThreeJSController(this.webViewController);
  
  // 카메라 위치 변경
  Future<void> setCameraPosition(double x, double y, double z) async {
    await webViewController.runJavascript('''
      camera.position.set($x, $y, $z);
    ''');
  }
  
  // 객체 회전
  Future<void> rotateObject(String objectName, double x, double y, double z) async {
    await webViewController.runJavascript('''
      const obj = scene.getObjectByName('$objectName');
      if (obj) {
        obj.rotation.set($x, $y, $z);
      }
    ''');
  }
  
  // Raycasting으로 선택
  Future<void> selectAtPosition(double x, double y) async {
    await webViewController.runJavascript('''
      handleTouch($x, $y, window.innerWidth, window.innerHeight);
    ''');
  }
  
  // 영역 확대
  Future<void> zoomRegion(List<int> faceIndices, double factor) async {
    String indices = jsonEncode(faceIndices);
    await webViewController.runJavascript('''
      zoomSelectedRegion($indices, $factor);
    ''');
  }
  
  // 모델 로드
  Future<void> loadModel(String url) async {
    await webViewController.runJavascript('''
      loadModelFromUrl('$url');
    ''');
  }
}
```

### Three.js → Flutter (이벤트)
```dart
class ThreeJSEventHandler {
  final Function(Map<String, dynamic>) onFaceSelected;
  final Function(double) onLoadProgress;
  final Function(String) onError;
  
  ThreeJSEventHandler({
    required this.onFaceSelected,
    required this.onLoadProgress,
    required this.onError,
  });
  
  void handleMessage(String message) {
    try {
      Map<String, dynamic> data = jsonDecode(message);
      
      switch (data['type']) {
        case 'faceSelected':
          onFaceSelected({
            'faceIndex': data['faceIndex'],
            'point': data['point'],
          });
          break;
          
        case 'loadProgress':
          onLoadProgress(data['progress']);
          break;
          
        case 'error':
          onError(data['message']);
          break;
      }
    } catch (e) {
      print('Error parsing message: $e');
    }
  }
}
```

### JavaScript 측 (이벤트 송신)
```javascript
// Raycasting 결과 전송
function onFaceSelected(faceIndex, point) {
  sendToFlutter({
    type: 'faceSelected',
    faceIndex: faceIndex,
    point: { x: point.x, y: point.y, z: point.z }
  });
}

// 로딩 진행률 전송
function onLoadProgress(loaded, total) {
  sendToFlutter({
    type: 'loadProgress',
    progress: loaded / total
  });
}

// 에러 전송
function onError(message) {
  sendToFlutter({
    type: 'error',
    message: message
  });
}
```

---

## 5. 제스처 처리

### Flutter GestureDetector
```dart
class ThreeJSGestureView extends StatefulWidget {
  @override
  _ThreeJSGestureViewState createState() => _ThreeJSGestureViewState();
}

class _ThreeJSGestureViewState extends State<ThreeJSGestureView> {
  late ThreeJSController controller;
  Offset? lastPanPosition;
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: (details) {
        // 터치 선택
        _handleTap(details.localPosition);
      },
      onPanStart: (details) {
        lastPanPosition = details.localPosition;
      },
      onPanUpdate: (details) {
        // 드래그로 회전
        _handlePan(details.localPosition);
      },
      onScaleStart: (details) {
        // 줌 시작
      },
      onScaleUpdate: (details) {
        // 핀치 줌
        _handleZoom(details.scale);
      },
      child: WebView(
        // ... WebView 설정
      ),
    );
  }
  
  void _handleTap(Offset position) {
    controller.selectAtPosition(position.dx, position.dy);
  }
  
  void _handlePan(Offset newPosition) {
    if (lastPanPosition != null) {
      double dx = newPosition.dx - lastPanPosition!.dx;
      double dy = newPosition.dy - lastPanPosition!.dy;
      
      controller.webViewController.runJavascript('''
        controls.rotate($dx * 0.01, $dy * 0.01);
      ''');
    }
    
    lastPanPosition = newPosition;
  }
  
  void _handleZoom(double scale) {
    controller.webViewController.runJavascript('''
      camera.zoom = $scale;
      camera.updateProjectionMatrix();
    ''');
  }
}
```

### OrbitControls 비활성화 (선택 모드)
```dart
bool isSelectionMode = false;

void toggleSelectionMode() {
  setState(() {
    isSelectionMode = !isSelectionMode;
  });
  
  controller.webViewController.runJavascript('''
    controls.enabled = ${!isSelectionMode};
  ''');
}
```

---

## 6. 상태 관리 통합

### Provider 패턴
```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ThreeJSState extends ChangeNotifier {
  List<int> selectedFaces = [];
  double zoomFactor = 1.0;
  bool isLoading = false;
  String? errorMessage;
  
  void selectFace(int faceIndex) {
    if (selectedFaces.contains(faceIndex)) {
      selectedFaces.remove(faceIndex);
    } else {
      selectedFaces.add(faceIndex);
    }
    notifyListeners();
  }
  
  void clearSelection() {
    selectedFaces.clear();
    notifyListeners();
  }
  
  void setZoomFactor(double factor) {
    zoomFactor = factor;
    notifyListeners();
  }
  
  void setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }
  
  void setError(String? error) {
    errorMessage = error;
    notifyListeners();
  }
}

// 사용
class ThreeJSViewWithState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThreeJSState(),
      child: Consumer<ThreeJSState>(
        builder: (context, state, child) {
          return Stack(
            children: [
              ThreeJSWebView(
                onFaceSelected: (faceIndex) {
                  context.read<ThreeJSState>().selectFace(faceIndex);
                },
              ),
              
              // UI 오버레이
              Positioned(
                bottom: 20,
                left: 20,
                child: Text(
                  'Selected: ${state.selectedFaces.length} faces',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              
              // 로딩 인디케이터
              if (state.isLoading)
                Center(child: CircularProgressIndicator()),
              
              // 에러 표시
              if (state.errorMessage != null)
                Center(
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
```

---

## 7. 성능 최적화

### 프레임 레이트 제한
```javascript
// Three.js 측
let lastFrameTime = 0;
const targetFPS = 60;
const frameInterval = 1000 / targetFPS;

function animate(currentTime) {
  requestAnimationFrame(animate);
  
  const elapsed = currentTime - lastFrameTime;
  
  if (elapsed > frameInterval) {
    lastFrameTime = currentTime - (elapsed % frameInterval);
    
    // 렌더링
    renderer.render(scene, camera);
  }
}
```

### 메시지 쓰로틀링
```dart
import 'dart:async';

class ThrottledController {
  final ThreeJSController controller;
  Timer? _throttleTimer;
  final Duration throttleDuration;
  
  ThrottledController(this.controller, {
    this.throttleDuration = const Duration(milliseconds: 50),
  });
  
  void selectAtPosition(double x, double y) {
    if (_throttleTimer?.isActive ?? false) return;
    
    controller.selectAtPosition(x, y);
    
    _throttleTimer = Timer(throttleDuration, () {});
  }
  
  void dispose() {
    _throttleTimer?.cancel();
  }
}
```

### 렌더링 최적화
```javascript
// 뷰포트 밖이면 렌더 중지
let isVisible = true;

document.addEventListener('visibilitychange', () => {
  isVisible = !document.hidden;
});

function animate() {
  requestAnimationFrame(animate);
  
  if (isVisible) {
    renderer.render(scene, camera);
  }
}
```

---

## 8. 디버깅 및 테스트

### Flutter DevTools 통합
```dart
import 'dart:developer' as developer;

void logThreeJSEvent(String event, Map<String, dynamic> data) {
  developer.log(
    event,
    name: 'ThreeJS',
    time: DateTime.now(),
    error: data['error'],
  );
}
```

### JavaScript 콘솔 → Flutter
```javascript
// JavaScript console.log를 Flutter로 전달
(function() {
  const originalLog = console.log;
  console.log = function(...args) {
    originalLog.apply(console, args);
    sendToFlutter({
      type: 'console',
      level: 'log',
      message: args.join(' ')
    });
  };
  
  const originalError = console.error;
  console.error = function(...args) {
    originalError.apply(console, args);
    sendToFlutter({
      type: 'console',
      level: 'error',
      message: args.join(' ')
    });
  };
})();
```

---

## 실무 체크리스트

- [ ] 패키지 선택 (three_dart vs WebView)
- [ ] Flutter ↔ Three.js 통신 구조 설계
- [ ] 제스처 핸들러 구현
- [ ] 상태 관리 통합 (Provider/Riverpod)
- [ ] 메시지 쓰로틀링 구현
- [ ] 에러 핸들링 및 로깅
- [ ] 성능 모니터링 도구 연동
- [ ] 크로스 플랫폼 테스트 (iOS/Android/Web)
- [ ] 메모리 누수 체크

---

## 참고 자료

- [three_dart 패키지](https://pub.dev/packages/three_dart)
- [flutter_gl 패키지](https://pub.dev/packages/flutter_gl)
- [webview_flutter 패키지](https://pub.dev/packages/webview_flutter)
- [Three.js 공식 문서](https://threejs.org/docs/)

