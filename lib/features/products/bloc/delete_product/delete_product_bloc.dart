part of '../../products.dart';
class DeleteProductBloc extends Bloc<DeleteProductEvent, BaseState<void>>{
  final ProductsDataSource _productsDataSource;
  DeleteProductBloc(this._productsDataSource):super(BaseState<void>()){
    on<DeleteProductEvent>(_onDeleteProduct);

  }
  FutureOr<void> _onDeleteProduct(DeleteProductEvent event, Emitter<BaseState<void>> emit) async {
    emit(state.copyWith(status: Status.loading));
    final result = await _productsDataSource.deleteProduct(event.id);
    emit(
      result.fold(
          (leftFn) => state.copyWith(status: Status.failure, errorMessage: leftFn.message)
      , (rightFn) => state.copyWith(status: Status.success))
    );

  }
}