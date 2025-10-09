part of 'router.dart';

abstract interface class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: Routes.initial,
    routes: [
      GoRoute(
        path: Routes.initial,
        builder: (context, state) => const MyHomePage(title: 'Flutter Demo Home Page'),
      ),
      // GoRoute(
      //   path: Routes.second,
      //   builder: (context, state) => const SecondPage(),
      // ),
    ],
  );

  static Widget getRootApp({
    required BuildContext context,
    required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  }) {
    final bool isIOS = Platform.isIOS || Platform.isMacOS;

    if (isIOS) {
      return CupertinoApp.router(
        routerConfig: router,
        theme: const CupertinoThemeData(brightness: Brightness.light),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      );
    } else {
      return MaterialApp.router(
        scaffoldMessengerKey: scaffoldMessengerKey,
        routerConfig: router,
        title: 'Flutter Demo',
        theme: ThemeData.light(),
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
      );
    }
  }
}
