sealed class AsyncValue<T> {
  const AsyncValue();

  const factory AsyncValue.loading() = AsyncLoading<T>;
  const factory AsyncValue.data(T value) = AsyncData<T>;
  const factory AsyncValue.error(Object error, {StackTrace? stackTrace}) =
      AsyncError<T>;

  bool get hasValue => this is AsyncData<T>;
  bool get isLoading => this is AsyncLoading<T>;
  bool get hasError => this is AsyncError<T>;

  T? get valueOrNull => switch (this) {
        AsyncData(:final value) => value,
        _ => null,
      };

  Object? get errorOrNull => switch (this) {
        AsyncError(:final error) => error,
        _ => null,
      };

  R when<R>({
    required R Function() loading,
    required R Function(T value) data,
    required R Function(Object error, StackTrace? stackTrace) error,
  }) {
    final self = this;
    if (self is AsyncLoading<T>) return loading();
    if (self is AsyncData<T>) return data(self.value);
    if (self is AsyncError<T>) return error(self.error, self.stackTrace);
    throw StateError('Unknown AsyncValue state');
  }

  R maybeWhen<R>({
    R Function()? loading,
    R Function(T value)? data,
    R Function(Object error, StackTrace? stackTrace)? error,
    required R Function() orElse,
  }) {
    final self = this;
    if (self is AsyncLoading<T>) return loading != null ? loading() : orElse();
    if (self is AsyncData<T>) return data != null ? data(self.value) : orElse();
    if (self is AsyncError<T>) {
      return error != null ? error(self.error, self.stackTrace) : orElse();
    }
    return orElse();
  }

  AsyncValue<R> map<R>(R Function(T value) transform) {
    final self = this;
    if (self is AsyncLoading<T>) return const AsyncValue.loading();
    if (self is AsyncData<T>) return AsyncValue.data(transform(self.value));
    if (self is AsyncError<T>) {
      return AsyncValue.error(self.error, stackTrace: self.stackTrace);
    }
    return const AsyncValue.loading();
  }
}

final class AsyncLoading<T> extends AsyncValue<T> {
  const AsyncLoading();
}

final class AsyncData<T> extends AsyncValue<T> {
  final T value;
  const AsyncData(this.value);

  @override
  bool operator ==(Object other) =>
      other is AsyncData<T> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class AsyncError<T> extends AsyncValue<T> {
  final Object error;
  final StackTrace? stackTrace;
  const AsyncError(this.error, {this.stackTrace});

  @override
  bool operator ==(Object other) =>
      other is AsyncError<T> && other.error == error;

  @override
  int get hashCode => error.hashCode;
}
