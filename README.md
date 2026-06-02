# StateHub

**Zero-boilerplate reactive state for Dart & Flutter.**
Context-free · Offline-first · Sealed async types · Built-in DI

[![pub.dev](https://img.shields.io/pub/v/statehub.svg)](https://pub.dev/packages/statehub)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## Why StateHub?

| Pain point | Solution |
|---|---|
| Bloc boilerplate (Event + State + Bloc = 3 classes) | One `Hub<T>` |
| Provider's `BuildContext` dependency | All Hubs are context-free |
| No built-in offline/cache support | `CacheHub` with 5 strategies |
| Manual `isLoading / hasError / data` flags | Sealed `AsyncValue<T>` |
| Framework lock-in | Pure Dart core, Flutter optional |

---

## Installation

```yaml
dependencies:
  statehub: ^0.1.0
```

---

## Quick Start

```dart
import 'package:statehub/statehub.dart';
import 'package:statehub/statehub_flutter.dart';

// 1. Create a Hub — no context needed
final counter = Hub(0);

// 2. Listen
counter.listen((prev, next) => print('$prev → $next'));

// 3. Update
counter.set(counter.value + 1);
counter.update((v) => v * 2);

// 4. Derive
final doubled = counter.select((v) => v * 2);

// 5. Flutter widget
HubBuilder<int>(
  hub: counter,
  builder: (context, value) => Text('$value'),
)
```

---

## Core Primitives

### `Hub<T>` — Reactive Atom

```dart
final name = Hub('Alice');
name.listen((prev, next) => print(next));
name.set('Bob');
name.update((v) => v.toUpperCase());
final length = name.select((v) => v.length);
```

### `AsyncHub<T>` — Async State

```dart
final users = AsyncHub<List<User>>();
await users.run(() => api.fetchUsers());
await users.refresh(() => api.fetchUsers()); // no loading flash

users.value.when(
  loading: () => showSpinner(),
  data: (list) => showList(list),
  error: (e, _) => showError(e),
);
```

### `CacheHub<T>` — Offline-First

```dart
final users = CacheHub<List<User>>(
  key: 'users',
  fetcher: () => api.getUsers(),
  strategy: CacheStrategy.staleWhileRevalidate,
  ttl: Duration(minutes: 5),
);

await users.fetch();
await users.invalidate();
await users.optimisticUpdate(newList, () => api.save(newList));
```

**Strategies:** `staleWhileRevalidate` · `networkFirst` · `cacheFirst` · `networkOnly` · `cacheOnly`

### `HubScope` — Dependency Injection

```dart
final scope = HubScope.root()
  ..register(() => Hub(0), name: 'counter')
  ..register(() => AsyncHub<User>(), name: 'user');

final counter = scope.get<Hub<int>>('counter');
```

---

## Flutter Widgets

```dart
// Rebuild on change
HubBuilder<int>(hub: counterHub, builder: (ctx, v) => Text('$v'))

// Async state
AsyncHubBuilder<List<User>>(
  hub: usersHub,
  loading: () => CircularProgressIndicator(),
  data: (users) => UserList(users),
  error: (e, _) => ErrorView(e),
)

// Multiple hubs
MultiHubBuilder(hubs: [hubA, hubB], builder: (ctx) => MyWidget())

// Side effects only
HubListener<Auth>(hub: authHub, listener: (ctx, s) => navigate(s), child: Page())

// DI in widget tree
HubScopeProvider(scope: scope, child: MyApp())
```

---

## License

MIT © 2025 ahsLab
