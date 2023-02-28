part of '../async_notifier.dart';

/// A [StreamNotifier] base class shared between family and non-family notifiers.
///
/// Not meant for public consumption outside of riverpod_generator
@internal
abstract class BuildlessStreamNotifier<State> extends AsyncNotifierBase<State> {
  @override
  late final StreamNotifierProviderElement<AsyncNotifierBase<State>, State>
      _element;

  @override
  void _setElement(ProviderElementBase<AsyncValue<State>> element) {
    _element = element
        as StreamNotifierProviderElement<AsyncNotifierBase<State>, State>;
  }

  @override
  StreamNotifierProviderRef<State> get ref => _element;
}

/// {@template riverpod.streamNotifier}
/// A variant of [StreamNotifier] which has [build] creating a [Stream].
/// {@endtemplate riverpod.streamNotifier}
abstract class StreamNotifier<State> extends BuildlessStreamNotifier<State> {
  /// {@template riverpod.asyncnotifier.build}
  @visibleForOverriding
  Stream<State> build();
}

/// {@macro riverpod.providerrefbase}
abstract class StreamNotifierProviderRef<T> implements Ref<AsyncValue<T>> {}

/// {@template riverpod.async_notifier_provider}
/// {@endtemplate}
typedef StreamNotifierProvider<NotifierT extends StreamNotifier<T>, T>
    = StreamNotifierProviderImpl<NotifierT, T>;

/// The implementation of [StreamNotifierProvider] but with loosened type constraints
/// that can be shared with [AutoDisposeStreamNotifierProvider].
///
/// This enables tests to execute on both [StreamNotifierProvider] and
/// [AutoDisposeStreamNotifierProvider] at the same time.
@visibleForTesting
@internal
class StreamNotifierProviderImpl<NotifierT extends AsyncNotifierBase<T>, T>
    extends StreamNotifierProviderBase<NotifierT, T>
    with AlwaysAliveProviderBase<AsyncValue<T>>, AlwaysAliveAsyncSelector<T> {
  /// {@macro riverpod.async_notifier_provider}
  StreamNotifierProviderImpl(
    super._createNotifier, {
    super.name,
    super.dependencies,
  }) : super(
          allTransitiveDependencies:
              computeAllTransitiveDependencies(dependencies),
          from: null,
          argument: null,
          debugGetCreateSourceHash: null,
        );

  /// An implementation detail of Riverpod
  @internal
  StreamNotifierProviderImpl.internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    super.from,
    super.argument,
  });

  /// {@macro riverpod.autoDispose}
  static const autoDispose = AutoDisposeStreamNotifierProviderBuilder();

  /// {@macro riverpod.family}
  static const family = StreamNotifierProviderFamilyBuilder();

  @override
  late final AlwaysAliveRefreshable<NotifierT> notifier =
      _streamNotifier<NotifierT, T>(this);

  @override
  late final AlwaysAliveRefreshable<Future<T>> future = _streamFuture<T>(this);

  @override
  StreamNotifierProviderElement<NotifierT, T> createElement() {
    return StreamNotifierProviderElement._(this);
  }

  @override
  Stream<T> runNotifierBuild(AsyncNotifierBase<T> notifier) {
    // Not using "covariant" as riverpod_generator subclasses this with a
    // different notifier type
    return (notifier as StreamNotifier<T>).build();
  }

  /// {@macro riverpod.overridewith}
  Override overrideWith(NotifierT Function() create) {
    return ProviderOverride(
      origin: this,
      override: StreamNotifierProviderImpl<NotifierT, T>.internal(
        create,
        from: from,
        argument: argument,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
      ),
    );
  }
}

/// The element of [StreamNotifierProvider].
class StreamNotifierProviderElement<NotifierT extends AsyncNotifierBase<T>, T>
    extends AsyncNotifierProviderElementBase<NotifierT, T>
    implements StreamNotifierProviderRef<T> {
  StreamNotifierProviderElement._(
    StreamNotifierProviderBase<NotifierT, T> super.provider,
  ) : super._();

  @override
  void create({required bool didChangeDependency}) {
    final provider = this.provider as StreamNotifierProviderBase<NotifierT, T>;

    final notifierResult = _notifierNotifier.result ??= Result.guard(() {
      return provider._createNotifier().._setElement(this);
    });

    notifierResult.when(
      error: (error, stackTrace) {
        onError(AsyncError(error, stackTrace), seamless: !didChangeDependency);
      },
      data: (notifier) {
        handleStream(
          () => provider.runNotifierBuild(notifier),
          didChangeDependency: didChangeDependency,
        );
      },
    );
  }
}
