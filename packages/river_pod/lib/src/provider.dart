import 'common.dart';
import 'framework/framework.dart';

class ProviderSubscription<T> extends ProviderBaseSubscription {
  ProviderSubscription._(this.value);

  final T value;
}

class Provider<T> extends AlwaysAliveProvider<ProviderSubscription<T>, T> {
  Provider(this._create);

  final Create<T, ProviderContext> _create;

  @override
  _ProviderState<T> createState() => _ProviderState();
}

class _ProviderState<T>
    extends ProviderBaseState<ProviderSubscription<T>, T, Provider<T>> {
  @override
  T initState() {
    return provider._create(ProviderContext(this));
  }

  @override
  ProviderSubscription<T> createProviderSubscription() {
    return ProviderSubscription._($state);
  }
}