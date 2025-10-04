part of 'exports.dart';

typedef FetchPage<T> = Future<Either<Failure, List<T>>> Function(
    int page,
    int limit,
    Map<String, dynamic>? query,
    dynamic params,
    );

abstract  class PaginatedBloc<T> extends Bloc<PaginatedEvent<T>, BaseState<T>> {
  final SyncManager _syncManager = getIt<SyncManager>();
  final ConnectivityService _connectivityService = getIt<ConnectivityService>();

  late final PaginationHandler<T, PaginatedBloc<T>> _paginationHandler;
  late final FetchPage<T> fetchPage;
  final int pageSize;
  String Function(dynamic params, Map<String, dynamic>? query)? cacheKeyBuilder;

  dynamic lastParams;
  Map<String, dynamic>? lastQuery;
  StreamSubscription<bool>? _connectivitySubscription;

  PaginatedBloc({
    required this.fetchPage,
    this.cacheKeyBuilder,
    this.pageSize = 15,
  }) : super(BaseState<T>()) {
    _syncManager.registerSyncCallback(_syncData);

    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((hasInternet) {
      if (hasInternet) _syncManager.syncAll();
    }); assert(
    cacheKeyBuilder != null,
    'ConnectivityService must be initialized before using PaginatedBloc',
    );

    _paginationHandler = PaginationHandler<T, PaginatedBloc<T>>(bloc: this,pageSize: pageSize);

    on<LoadFirstPage<T>>(_onLoadFirstPage);
    on<LoadNextPage<T>>(_onFetchNextPage);
  }

  FutureOr<void> _onLoadFirstPage(LoadFirstPage<T> event, Emitter<BaseState<T>> emit) async {
    lastParams = event.params;
    lastQuery = event.query;
    emit(state.copyWith(items: []));
    await _paginationHandler.loadFirstPage(
          (page, limit, [_, __]) => fetchPage(page, limit, event.query, event.params),
      cacheKey: cacheKeyBuilder?.call(event.params, event.query),
    );
  }

  FutureOr<void> _onFetchNextPage(LoadNextPage<T> event, Emitter<BaseState<T>> emit) async {
    lastQuery = event.query ?? lastQuery;
    await _paginationHandler.fetchData(
          (page, limit, [_, __]) => fetchPage(page, limit, lastQuery, lastParams),
    );
  }

  bool _isSyncing = false;

  Future<void> _syncData() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      if (lastParams != null || lastQuery != null) {
        add(LoadFirstPage<T>(params: lastParams, query: lastQuery));
      }
    } finally {
      // Delay slightly to debounce fast reconnect events
      await Future.delayed(const Duration(milliseconds: 500));
      _isSyncing = false;
    }
  }

  @override
  Future<void> close() {
    _syncManager.unregisterSyncCallback(_syncData);
    _connectivitySubscription?.cancel();
    return super.close();
  }
}