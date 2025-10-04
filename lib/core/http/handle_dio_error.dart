part of "http.dart";

Failure _handleDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.cancel:
      scaffoldMessengerKey.currentContext!.showErrorMessage('تم الغاء الطلب ');
      return ServerFailure(message: 'تم إلغاء الطلب ');
    case DioExceptionType.connectionTimeout:
      scaffoldMessengerKey.currentContext!.showErrorMessage('انتهت مهلة الاتصال ');
      return ServerFailure(message: 'انتهت مهلة الاتصال ');
    case DioExceptionType.receiveTimeout:
      scaffoldMessengerKey.currentContext!.showErrorMessage('انتهت مهلة الاتصال ');
      return ServerFailure(message: 'انتهت مهلة الاستقبال في الاتصال ');
    case DioExceptionType.sendTimeout:
      scaffoldMessengerKey.currentContext!.showErrorMessage('انتهت مهلة الاتصال ');
      return ServerFailure(message: 'انتهت مهلة الإرسال في الاتصال ');
    case DioExceptionType.badResponse://400-500
      if (error.response?.data != null) {
        try {
          final data = error.response!.data;
          final Map<String, dynamic> decoded =
          data is String ? json.decode(data) : data;
          if (error.response?.statusCode == 503) {
            return ServerFailure(message: 'network failure ${error.message}');
          }
          if (error.response?.statusCode == 401) {
            scaffoldMessengerKey.currentContext!.showErrorMessage('غير مصرح لك');
            ///TODO: navigate to login screen
            // scaffoldMessengerKey.currentContext!.go(const WhoAreYou(forLogin: true));
            return UnauthorizedFailure(
                message: error.message ?? 'غير مصرح لك');
          }

          if (error.response?.statusCode == 413) {
            scaffoldMessengerKey.currentContext!
                .showErrorMessage('File size is too large');

            return ServerFailure(
              message: 'File size is too large',
            );
          }
          if (error.response?.statusCode == 410) {
            scaffoldMessengerKey.currentContext!
                .showErrorMessage('لقد تعرضت للحظر ');
            // scaffoldMessengerKey.currentContext!.goWithNoReturn(const LoginScreen());

            return BanFailure(
              message: 'لقد تعرضت للحظر ',
            );
          }
          // Handle OTP failure for 409 status code
          if (error.response?.statusCode == 409) {
            loggerWarn('VERIFYERROR');
            return VerifyOTPFailure(message: 'خطأ في التحقق من الكود');
          }
          if (decoded.containsKey('message')) {
            String message = decoded['message'];

            // Process validation errors if present
            if (decoded.containsKey('errors') && decoded['errors'] is Map) {
              final Map<String, dynamic> errors = decoded['errors'];
              List<String> errorMessages = [];
              errors.forEach((key, value) {
                if (value is List) {
                  errorMessages.addAll(value.map((e) => '$e').toList());
                } else if (value is String) {
                  errorMessages.add(value);
                }
              });

              if (errorMessages.isNotEmpty) {
                scaffoldMessengerKey.currentContext!
                    .showErrorMessage(errorMessages[0]);
                return ValidationFailure(
                  message: message,
                  errors: errorMessages,
                );
              }
            }

            // scaffoldMessengerKey.currentContext!.showErrorMessage(message);
            return ServerFailure(message: message);
          }
        } catch (e) {
          // scaffoldMessengerKey.currentContext!.showErrorMessage(e.toString());
          return ServerFailure(
              message:
              'Received invalid status code: ${error.response?.statusCode}');
        }
      }
      // scaffoldMessengerKey.currentContext!.showErrorMessage(error.message!);
      return ServerFailure(
          message:
          'Received invalid status code: ${error.response?.statusCode}');
    case DioExceptionType.badCertificate:
      return ServerFailure(message: 'تعذر الاتصال ');
    case DioExceptionType.connectionError:
      scaffoldMessengerKey.currentContext!.showErrorMessage('تعذر الاتصال ');
      return NetworkFailure(message: 'تعذر الاتصال ');
    case DioExceptionType.unknown:
      return UnknownFailure(message: 'Unexpected error: ${error.message}');
  }
}