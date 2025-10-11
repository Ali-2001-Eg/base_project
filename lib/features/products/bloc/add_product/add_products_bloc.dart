part of '../../products.dart';

class AddProductBloc extends Bloc<AddProductEvent, BaseState<void>> {
  final ProductsDataSource _productsDataSource;
  AddProductBloc(this._productsDataSource) : super(BaseState<void>()){
    on<AddProductEvent>(_onAddProduct);
  }
  FutureOr<void> _onAddProduct(AddProductEvent event, Emitter<BaseState<void>> emit) async {
    emit(state.copyWith(status: Status.loading));
    final result = await _productsDataSource.addProduct(AddProductParams(name: event.name, code: event.code));
    emit(
      result.fold(
          (leftFn) => state.copyWith(status: Status.failure, errorMessage: leftFn.message)
      , (rightFn) => state.copyWith(status: Status.success))
    );
  }
}