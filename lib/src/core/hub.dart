import 'async_value.dart';

typedef HubListener<T> = void Function(T previous, T next);

class Hub<T> {
  T _value;
  final List<HubListener<T>> _listeners = [];
  bool _disposed = false;

  Hub(this._value);

  T get value => _value;

  void set(T newValue) {
    if (_disposed) return;
    if (newValue == _value) return;
    final previous = _value;
    _value = newValue;
    for (final listener in List.of(_listeners)) {
      listener(previous, newValue);
    }
  }

  void update(T Function(T current) transform) => set(transform(_value));

  Disposable listen(HubListener<T> listener) {
    _listeners.add(listener);
    return Disposable(() => _listeners.remove(listener));
  }

  Disposable listenNow(void Function(T value) listener) {
    listener(_value);
    return this.listen((_, next) => listener(next));
  }

  ComputedHub<R, T> select<R>(R Function(T value) selector) {
    return ComputedHub<R, T>(selector(_value), selector, this);
  }

  void dispose() {
    _disposed = true;
    _listeners.clear();
  }

  @override
  String toString() => 'Hub<$T>($_value)';
}

class ComputedHub<R, S> {
  R _value;
  final List<void Function(R)> _listeners = [];
  late final Disposable _subscription;

  ComputedHub(R initialValue, R Function(S) selector, Hub<S> source)
      : _value = initialValue {
    _subscription = source.listen((_, next) {
      final computed = selector(next);
      if (computed == _value) return;
      _value = computed;
      for (final l in List.of(_listeners)) {
        l(_value);
      }
    });
  }

  R get value => _value;

  Disposable listen(void Function(R value) listener) {
    _listeners.add(listener);
    return Disposable(() => _listeners.remove(listener));
  }

  void dispose() {
    _subscription.dispose();
    _listeners.clear();
  }
}

class AsyncHub<T> extends Hub<AsyncValue<T>> {
  AsyncHub([AsyncValue<T>? initial])
      : super(initial ?? const AsyncValue.loading());

  Future<T?> run(
    Future<T> Function() operation, {
    bool setLoadingFirst = true,
  }) async {
    if (setLoadingFirst) set(const AsyncValue.loading());
    try {
      final result = await operation();
      set(AsyncValue.data(result));
      return result;
    } catch (e, st) {
      set(AsyncValue.error(e, stackTrace: st));
      return null;
    }
  }

  Future<T?> refresh(Future<T> Function() operation) =>
      run(operation, setLoadingFirst: false);

  T? get currentData => value.valueOrNull;
  bool get isLoading => value.isLoading;
  bool get hasError => value.hasError;
  Object? get currentError => value.errorOrNull;
}

class Disposable {
  final void Function() _dispose;
  bool _disposed = false;

  Disposable(this._dispose);

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _dispose();
  }
}

class DisposableBag {
  final List<Disposable> _disposables = [];

  void add(Disposable d) => _disposables.add(d);

  void disposeAll() {
    for (final d in _disposables) {
      d.dispose();
    }
    _disposables.clear();
  }
}
