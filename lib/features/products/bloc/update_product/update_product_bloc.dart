part of '../../products.dart';
class UpdateProductBloc extends Bloc<UpdateProductEvent, BaseState<void>>{
  final ProductsDataSource _productsDataSource;
  UpdateProductBloc(this._productsDataSource):super(BaseState<void>()) {
    on<UpdateProductEvent>(_onUpdateProduct);
  }
  FutureOr<void> _onUpdateProduct(UpdateProductEvent event, Emitter<BaseState<void>> emit) async {
    emit(state.copyWith(status: Status.loading));
    final result = await _productsDataSource.updateProduct(UpdateProductParams(id: event.id, name: event.name,code: event.code));
    emit(
      result.fold(
          (leftFn) => state.copyWith(status: Status.failure, errorMessage: leftFn.message)
      , (rightFn) => state.copyWith(status: Status.success))
    );
  }
}