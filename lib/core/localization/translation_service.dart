import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'locales.dart';
import 'codegen_loader.g.dart';
abstract interface class LocalizationService {
  static Future<void> init() async {
    await EasyLocalization.ensureInitialized();
  }

  static Widget rootWidget({required Widget child}) {
    // Access device's locale using PlatformDispatcher
    final deviceLocale = PlatformDispatcher.instance.locale;

    // Determine start locale based on device locale
    // Default to English unless the device is set to Arabic
    final startLocale = deviceLocale.languageCode == 'ar'
        ? Locales.arabic
        : Locales.english;

    return EasyLocalization(
      saveLocale: true,
      supportedLocales: const [Locales.english, Locales.arabic],
      path: 'assets/translations',
      startLocale: startLocale, // Set start locale based on device language
      fallbackLocale: Locales.english,
      assetLoader: const CodegenLoader(),
      child: child,
    );
  }
}