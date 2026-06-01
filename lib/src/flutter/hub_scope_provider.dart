import 'package:flutter/widgets.dart';
import '../core/hub_scope.dart';

class HubScopeProvider extends InheritedWidget {
  final HubScope scope;

  const HubScopeProvider({
    super.key,
    required this.scope,
    required super.child,
  });

  static HubScope of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<HubScopeProvider>();
    assert(
      provider != null,
      'No HubScopeProvider found. Wrap your app with HubScopeProvider.',
    );
    return provider!.scope;
  }

  static HubScope? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<HubScopeProvider>()
        ?.scope;
  }

  @override
  bool updateShouldNotify(HubScopeProvider oldWidget) =>
      scope != oldWidget.scope;
}

extension HubScopeContext on BuildContext {
  HubScope get hubScope => HubScopeProvider.of(this);
  T hub<T>(String name) => HubScopeProvider.of(this).get<T>(name);
}

class HubScopeChild extends StatefulWidget {
  final void Function(HubScope scope) register;
  final Widget child;

  const HubScopeChild({
    super.key,
    required this.register,
    required this.child,
  });

  @override
  State<HubScopeChild> createState() => _HubScopeChildState();
}

class _HubScopeChildState extends State<HubScopeChild> {
  late HubScope _childScope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parent = HubScopeProvider.of(context);
    _childScope = parent.child();
    widget.register(_childScope);
  }

  @override
  void dispose() {
    _childScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HubScopeProvider(
      scope: _childScope,
      child: widget.child,
    );
  }
}
