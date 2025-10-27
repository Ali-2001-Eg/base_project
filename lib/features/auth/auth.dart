import 'dart:async';

import '../../core/bloc/paginated_bloc/exports.dart';
import '../../core/enum/status.dart';
import '../../core/http/either.dart';
import '../../core/http/failure.dart';
import '../../core/http/http.dart';
import '../../core/params/params.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/helpers/helpers.dart';

part '../auth/blocs/forget_password/forget_password_event.dart';
part '../auth/blocs/forget_password/forget_password_bloc.dart';
part '../auth/data_source/forget_password_data_source.dart';
part '../auth/blocs/login/login_event.dart';
part '../auth/blocs/login/login_bloc.dart';
part '../auth/data_source/login_data_source.dart';
part '../auth/blocs/logout/logout_event.dart';
part '../auth/blocs/logout/logout_bloc.dart';
part '../auth/data_source/logout_data_source.dart';
part '../auth/blocs/register/register_event.dart';
part '../auth/blocs/register/register_bloc.dart';
part '../auth/data_source/register_data_source.dart';
part '../auth/blocs/social_auth/social_auth_event.dart';
part '../auth/blocs/social_auth/social_auth_bloc.dart';
part '../auth/data_source/social_auth_data_source.dart';
part '../auth/blocs/verify_otp/verify_otp_event.dart';
part '../auth/blocs/verify_otp/verify_otp_bloc.dart';
part '../auth/data_source/verify_otp_data_source.dart';
part '../auth/blocs/reset_password/reset_password_event.dart';
part '../auth/blocs/reset_password/reset_password_bloc.dart';
part '../auth/data_source/reset_password_data_source.dart';