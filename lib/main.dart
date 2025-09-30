import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '/bejel.dart';
import '/menu.dart';
import 'services/api_service.dart';
import 'services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _ensureBaseUrlConsistency();
  await SettingsController.instance.load();
  runApp(const MyApp());
}

Future<void> _ensureBaseUrlConsistency() async {
  final sp = await SharedPreferences.getInstance();
  final current = ApiService.baseUrl;
  final stored = sp.getString('api_base_url');
  if (stored == null || stored != current) {
    // Base URL changed (e.g., switched from 127.0.0.1 to 192.168.x.x) → clear stale auth
    await sp.remove('auth_token');
    await sp.setString('api_base_url', current);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SettingsController.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final light = _buildAppTheme(controller, Brightness.light);
        final dark = _buildAppTheme(controller, Brightness.dark);
        return MaterialApp(
          title: 'Proiect Flutter',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('hu'), Locale('en'), Locale('ro')],
          locale: controller.locale,
          theme: light,
          darkTheme: dark,
          themeMode: controller.effectiveThemeMode,
          initialRoute: '/login',
          builder: (context, child) {
            final data = MediaQuery.of(context);
            final textScale = controller.textScale;
            final textScaler = TextScaler.linear(textScale);
            final reduceMotion = controller.reduceMotion;
            return MediaQuery(
              data: data.copyWith(
                textScaler: textScaler,
                boldText: controller.highContrast ? true : data.boldText,
                disableAnimations: reduceMotion ? true : data.disableAnimations,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          routes: {
            '/login': (_) => const BejelentkezesPage(),
            '/menu': (_) => const MenuScreen(),
          },
        );
      },
    );
  }
}

const _kEmojiFallbackFonts = <String>[
  'Noto Color Emoji',
  'Noto Emoji',
  'Segoe UI Emoji',
  'Apple Color Emoji',
  'EmojiOne Color',
  'Twemoji Mozilla',
];

const Color _kDefaultSeedColor = Color(0xFF00C853);

ThemeData _buildAppTheme(SettingsController controller, Brightness brightness) {
  final seed = controller.seedColor ?? _kDefaultSeedColor;
  final baseTextTheme = ThemeData(brightness: brightness).textTheme;
  final textTheme = _withEmojiFallback(baseTextTheme);

  var colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: brightness,
  );

  if (controller.highContrast) {
    colorScheme = colorScheme.copyWith(
      primary: _boostContrast(colorScheme.primary, brightness),
      onPrimary: brightness == Brightness.dark ? Colors.black : Colors.white,
      secondary: _boostContrast(colorScheme.secondary, brightness),
      tertiary: _boostContrast(colorScheme.tertiary, brightness),
      outline: _boostContrast(colorScheme.outline, brightness, amount: 0.18),
    );
  }

  if (brightness == Brightness.dark && controller.trueBlack) {
    colorScheme = colorScheme.copyWith(
      surface: Colors.black,
      background: Colors.black,
      surfaceVariant: Colors.grey.shade900,
      onSurface: Colors.white,
      onBackground: Colors.white,
    );
  }

  final scaffoldBackground = brightness == Brightness.dark
      ? (controller.trueBlack
          ? Colors.black
          : Color.lerp(colorScheme.background, Colors.black, 0.35) ?? colorScheme.background)
      : Color.lerp(colorScheme.background, Colors.white, 0.72) ?? colorScheme.background;

  final cardColor = brightness == Brightness.dark
      ? colorScheme.surfaceVariant.withOpacity(controller.highContrast ? 0.95 : 0.82)
      : colorScheme.surfaceVariant.withOpacity(controller.highContrast ? 0.98 : 0.88);

  final dialogColor = brightness == Brightness.dark
      ? colorScheme.surface.withOpacity(controller.highContrast ? 0.98 : 0.92)
      : colorScheme.surface.withOpacity(controller.highContrast ? 0.96 : 0.9);

  final reduceMotion = controller.reduceMotion;
  final transitionsBuilder = reduceMotion
      ? const _ZeroAnimationPageTransitionsBuilder()
      : const FadeUpwardsPageTransitionsBuilder();

  final pageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      for (final platform in TargetPlatform.values)
        platform: transitionsBuilder,
    },
  );

  final baseTheme = ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    brightness: brightness,
    textTheme: textTheme,
    primaryTextTheme: _withEmojiFallback(ThemeData(brightness: brightness).primaryTextTheme),
    visualDensity: VisualDensity.adaptivePlatformDensity,
    pageTransitionsTheme: pageTransitions,
    scaffoldBackgroundColor: scaffoldBackground,
  );

  final inputDecoration = baseTheme.inputDecorationTheme.copyWith(
    filled: true,
    fillColor: colorScheme.surface.withOpacity(brightness == Brightness.dark ? 0.24 : 0.12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.18)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.6)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  );

  return baseTheme.copyWith(
    appBarTheme: baseTheme.appBarTheme.copyWith(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      toolbarHeight: 64,
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    ),
    cardTheme: baseTheme.cardTheme.copyWith(
      elevation: 0,
      color: cardColor,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    bottomSheetTheme: baseTheme.bottomSheetTheme.copyWith(
      backgroundColor: dialogColor,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dialogTheme: baseTheme.dialogTheme.copyWith(
      backgroundColor: dialogColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    navigationBarTheme: baseTheme.navigationBarTheme.copyWith(
      backgroundColor: colorScheme.surface.withOpacity(brightness == Brightness.dark ? 0.9 : 0.95),
      indicatorColor: colorScheme.primary.withOpacity(0.18),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        final selected = states.contains(MaterialState.selected);
        return IconThemeData(
          color: selected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
        );
      }),
      labelTextStyle: MaterialStateProperty.resolveWith(
        (states) => states.contains(MaterialState.selected)
            ? textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)
            : textTheme.labelMedium,
      ),
    ),
    chipTheme: baseTheme.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    ),
    snackBarTheme: baseTheme.snackBarTheme.copyWith(
      backgroundColor: colorScheme.surface,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: inputDecoration,
    dividerTheme: baseTheme.dividerTheme.copyWith(
      color: colorScheme.outline.withOpacity(0.12),
      thickness: 1,
    ),
    tooltipTheme: baseTheme.tooltipTheme.copyWith(
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: textTheme.labelSmall?.copyWith(color: brightness == Brightness.dark ? Colors.black : Colors.white),
    ),
  );
}

TextTheme _withEmojiFallback(TextTheme base) {
  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    displayMedium: base.displayMedium?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    displaySmall: base.displaySmall?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    headlineLarge: base.headlineLarge?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    headlineMedium: base.headlineMedium?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    headlineSmall: base.headlineSmall?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    titleLarge: base.titleLarge?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    titleMedium: base.titleMedium?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    titleSmall: base.titleSmall?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    bodyLarge: base.bodyLarge?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    bodyMedium: base.bodyMedium?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    bodySmall: base.bodySmall?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    labelLarge: base.labelLarge?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    labelMedium: base.labelMedium?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
    labelSmall: base.labelSmall?.copyWith(fontFamilyFallback: _kEmojiFallbackFonts),
  );
}

Color _boostContrast(Color color, Brightness brightness, {double amount = 0.12}) {
  final hsl = HSLColor.fromColor(color);
  final lightness = brightness == Brightness.dark
      ? (hsl.lightness + amount).clamp(0.0, 1.0)
      : (hsl.lightness - amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}

class _ZeroAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const _ZeroAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
