import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:template/common/provider/go_router.dart';
import 'package:template/core/controllers/theme_controller.dart';
import 'package:template/core/themes/app_theme.dart';
import 'package:template/features/todo/screens/sample_screen.dart';
import 'package:template/setup.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// 앱 시작점
void main() {
  runZonedGuarded<Future<void>>(
    () async {
      // Flutter 바인딩 초기화
      WidgetsFlutterBinding.ensureInitialized();
      // 외부 서비스 초기화
      await AppSetup.initialize();
      // 다국어 지원 초기화
      await EasyLocalization.ensureInitialized();
      // Google Fonts 초기화
      await GoogleFonts.pendingFonts();

      runApp(
        // Riverpod 및 EasyLocalization 설정
        EasyLocalization(
          supportedLocales: const [Locale('ko'), Locale('en')],
          path: 'assets/translations',
          fallbackLocale: const Locale('ko'),
          child: const ProviderScope(child: MyApp()),
        ),
      );
    },
    AppSetup.handleZoneError,
  );
}

/// 앱의 루트 위젯
class MyApp extends ConsumerWidget {
  /// MyApp 생성자
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final router = ref.watch(routerProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: FontSizeResolvers.radius,
      child: MaterialApp.router(
        builder: (context, child) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: LoaderOverlay(
              child: child!,
            ),
          );
        },
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        routerDelegate: router.routerDelegate,
        routeInformationParser: router.routeInformationParser,
        routeInformationProvider: router.routeInformationProvider,
        themeMode: themeMode,
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
      ),
    );
  }
}
