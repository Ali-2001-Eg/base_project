import 'package:base_project/features/auth/auth.dart';
import 'package:base_project/features/products/models/products_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../features/products/products.dart';
import '../extensions/extensions.dart';
import 'package:get_it/get_it.dart';

import '../../main.dart';
import '../helpers/helpers.dart';
import '../http/http.dart';
import '../local_storage/local_storage.dart';

part 'init/init.dart';
part 'auth_service_locator/auth_service_locator.dart';
part 'shared_service_locator/shared_service_locator.dart';
part 'products_service_locator/products_service_locator.dart';
part 'hive_service_locator/hive_service_locator.dart';
