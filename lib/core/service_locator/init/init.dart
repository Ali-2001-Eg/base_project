part of '../service_locator.dart';
final GetIt getIt = GetIt.instance;
abstract class DI{
  static Future<void> execute() async {
    await AuthServiceLocator.execute(getIt: getIt);
  }
}