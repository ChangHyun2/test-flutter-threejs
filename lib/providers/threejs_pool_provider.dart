import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Three.js 인스턴스를 저장하는 클래스
class ThreeJSInstance {
  final String id;
  final dynamic instance;
  final DateTime createdAt;

  ThreeJSInstance({
    required this.id,
    required this.instance,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Three.js 인스턴스 풀 상태 클래스
class ThreeJSPoolState {
  final Map<String, ThreeJSInstance> instances;

  ThreeJSPoolState({Map<String, ThreeJSInstance>? instances})
    : instances = instances ?? {};

  ThreeJSPoolState copyWith({Map<String, ThreeJSInstance>? instances}) {
    return ThreeJSPoolState(instances: instances ?? this.instances);
  }
}

/// Three.js 인스턴스 풀을 관리하는 Notifier
class ThreeJSPoolNotifier extends Notifier<ThreeJSPoolState> {
  @override
  ThreeJSPoolState build() {
    return ThreeJSPoolState();
  }

  /// 인스턴스 추가
  void addInstance(String id, dynamic instance) {
    final newInstances = Map<String, ThreeJSInstance>.from(state.instances);
    newInstances[id] = ThreeJSInstance(id: id, instance: instance);
    state = state.copyWith(instances: newInstances);
  }

  /// 인스턴스 가져오기
  dynamic getInstance(String id) {
    return state.instances[id]?.instance;
  }

  /// 인스턴스 존재 여부 확인
  bool hasInstance(String id) {
    return state.instances.containsKey(id);
  }

  /// 인스턴스 제거
  void removeInstance(String id) {
    final newInstances = Map<String, ThreeJSInstance>.from(state.instances);
    newInstances.remove(id);
    state = state.copyWith(instances: newInstances);
  }

  /// 모든 인스턴스 제거
  void clearAll() {
    state = ThreeJSPoolState();
  }

  /// 인스턴스 목록 가져오기
  List<String> getInstanceIds() {
    return state.instances.keys.toList();
  }

  /// 인스턴스 개수
  int get count => state.instances.length;
}

/// Three.js 인스턴스 풀 Provider
final threeJSPoolProvider =
    NotifierProvider<ThreeJSPoolNotifier, ThreeJSPoolState>(
      () => ThreeJSPoolNotifier(),
    );
