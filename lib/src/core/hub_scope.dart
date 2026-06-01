import 'hub.dart';

class HubScope {
  final HubScope? _parent;
  final Map<String, _HubEntry> _registry = {};

  HubScope._({HubScope? parent}) : _parent = parent;

  factory HubScope.root() => HubScope._();

  HubScope child() => HubScope._(parent: this);

  HubScope register<T extends Object>(
    T Function() factory, {
    required String name,
    bool singleton = true,
  }) {
    _registry[name] = _HubEntry(factory: factory, singleton: singleton);
    return this;
  }

  T get<T>(String name) {
    if (_registry.containsKey(name)) {
      return _registry[name]!.resolve<T>();
    }
    if (_parent != null) {
      return _parent.get<T>(name);
    }
    throw HubScopeException('Hub "$name" not found. Did you register it?');
  }

  T? tryGet<T>(String name) {
    try {
      return get<T>(name);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    for (final entry in _registry.values) {
      entry.disposeIfCreated();
    }
    _registry.clear();
  }
}

class _HubEntry {
  final Object Function() factory;
  final bool singleton;
  Object? _instance;

  _HubEntry({required this.factory, required this.singleton});

  T resolve<T>() {
    if (singleton) {
      _instance ??= factory();
      return _instance as T;
    }
    return factory() as T;
  }

  void disposeIfCreated() {
    if (_instance case final inst?) {
      if (inst is Hub) inst.dispose();
    }
  }
}

class HubScopeException implements Exception {
  final String message;
  const HubScopeException(this.message);

  @override
  String toString() => 'HubScopeException: $message';
}
