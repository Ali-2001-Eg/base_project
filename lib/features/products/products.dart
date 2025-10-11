import 'dart:async';

import 'package:base_project/core/bloc/paginated_bloc/exports.dart';
import 'package:base_project/core/enum/status.dart';
import 'package:base_project/core/helpers/helpers.dart';
import 'package:base_project/core/http/either.dart';
import 'package:base_project/core/http/failure.dart';
import 'package:base_project/core/http/http.dart';
import 'package:base_project/core/params/params.dart';
import 'package:base_project/features/products/models/products_model.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part "data_source/products_data_source.dart";
part "data_source/params.dart";
part 'bloc/add_product/add_products_bloc.dart';
part 'bloc/add_product/add_products_event.dart';
part 'bloc/delete_product/delete_product_bloc.dart';
part 'bloc/delete_product/delete_product_event.dart';
part 'bloc/get_products/get_products_bloc.dart';
part 'bloc/update_product/update_product_bloc.dart';
part 'bloc/update_product/update_product_event.dart';