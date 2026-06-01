import 'package:flutter/widgets.dart';
import '../core/hub.dart';
import '../core/async_value.dart';

class HubBuilder<T> extends StatefulWidget {
  final Hub<T> hub;
  final Widget Function(BuildContext context, T value) builder;

  const HubBuilder({
    super.key,
    required this.hub,
    required this.builder,
  });

  @override
  State<HubBuilder<T>> createState() => _HubBuilderState<T>();
}

class _HubBuilderState<T> extends State<HubBuilder<T>> {
  late T _value;
  late Disposable _subscription;

  @override
  void initState() {
    super.initState();
    _value = widget.hub.value;
    _subscription = widget.hub.listen((_, next) {
      if (mounted) setState(() => _value = next);
    });
  }

  @override
  void didUpdateWidget(HubBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hub != widget.hub) {
      _subscription.dispose();
      _value = widget.hub.value;
      _subscription = widget.hub.listen((_, next) {
        if (mounted) setState(() => _value = next);
      });
    }
  }

  @override
  void dispose() {
    _subscription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}

class AsyncHubBuilder<T> extends StatefulWidget {
  final Hub<AsyncValue<T>> hub;
  final Widget Function()? loading;
  final Widget Function(T value) data;
  final Widget Function(Object error, StackTrace? stackTrace)? error;
  final Widget? loadingFallback;
  final Widget? errorFallback;

  const AsyncHubBuilder({
    super.key,
    required this.hub,
    required this.data,
    this.loading,
    this.error,
    this.loadingFallback,
    this.errorFallback,
  });

  @override
  State<AsyncHubBuilder<T>> createState() => _AsyncHubBuilderState<T>();
}

class _AsyncHubBuilderState<T> extends State<AsyncHubBuilder<T>> {
  late AsyncValue<T> _state;
  late Disposable _subscription;

  @override
  void initState() {
    super.initState();
    _state = widget.hub.value;
    _subscription = widget.hub.listen((_, next) {
      if (mounted) setState(() => _state = next);
    });
  }

  @override
  void didUpdateWidget(AsyncHubBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hub != widget.hub) {
      _subscription.dispose();
      _state = widget.hub.value;
      _subscription = widget.hub.listen((_, next) {
        if (mounted) setState(() => _state = next);
      });
    }
  }

  @override
  void dispose() {
    _subscription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _state.when(
      loading: () =>
          widget.loading?.call() ??
          widget.loadingFallback ??
          const SizedBox.shrink(),
      data: widget.data,
      error: (e, st) =>
          widget.error?.call(e, st) ??
          widget.errorFallback ??
          const SizedBox.shrink(),
    );
  }
}

class MultiHubBuilder extends StatefulWidget {
  final List<Hub<dynamic>> hubs;
  final Widget Function(BuildContext context) builder;

  const MultiHubBuilder({
    super.key,
    required this.hubs,
    required this.builder,
  });

  @override
  State<MultiHubBuilder> createState() => _MultiHubBuilderState();
}

class _MultiHubBuilderState extends State<MultiHubBuilder> {
  final List<Disposable> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _subscribe(widget.hubs);
  }

  void _subscribe(List<Hub<dynamic>> hubs) {
    for (final hub in hubs) {
      _subscriptions.add(hub.listen((_, __) {
        if (mounted) setState(() {});
      }));
    }
  }

  @override
  void didUpdateWidget(MultiHubBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hubs != widget.hubs) {
      for (final s in _subscriptions) {
        s.dispose();
      }
      _subscriptions.clear();
      _subscribe(widget.hubs);
    }
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

class HubListener<T> extends StatefulWidget {
  final Hub<T> hub;
  final void Function(BuildContext context, T value) listener;
  final Widget child;
  final bool listenImmediately;

  const HubListener({
    super.key,
    required this.hub,
    required this.listener,
    required this.child,
    this.listenImmediately = false,
  });

  @override
  State<HubListener<T>> createState() => _HubListenerState<T>();
}

class _HubListenerState<T> extends State<HubListener<T>> {
  late Disposable _subscription;

  @override
  void initState() {
    super.initState();
    if (widget.listenImmediately) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.listener(context, widget.hub.value);
      });
    }
    _subscription = widget.hub.listen((_, next) {
      if (mounted) widget.listener(context, next);
    });
  }

  @override
  void dispose() {
    _subscription.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
