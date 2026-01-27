import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:mobile_app/src/core/constants/constants.dart';
import 'package:mobile_app/src/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style for modern look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: kCardBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Enable edge-to-edge
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Load env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or invalid: $e");
  }

  // Initialize Naver Map
  try {
    final clientId = dotenv.env['NAVER_MAP_CLIENT_ID'];
    if (clientId != null && clientId.isNotEmpty) {
      await FlutterNaverMap().init(
        clientId: clientId,
        onAuthFailed: (ex) => debugPrint("Naver Map Auth Failed: $ex"),
      );
    } else {
      debugPrint("Warning: NAVER_MAP_CLIENT_ID not found in .env");
    }
  } catch (e) {
    debugPrint("Naver Map Init Failed: $e");
  }

  // Check auth on app start
  await authNotifier.checkAuth();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PetCam',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(context),
      routerConfig: appRouter,
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    final base = ThemeData.light();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: kSecondaryColor,
        onPrimary: Colors.white,
        primaryContainer: kSecondaryLight.withOpacity(0.15),
        onPrimaryContainer: kSecondaryDark,
        secondary: kAccentColor,
        onSecondary: Colors.white,
        secondaryContainer: kAccentColor.withOpacity(0.15),
        onSecondaryContainer: kAccentColor,
        tertiary: kAccentGreen,
        onTertiary: Colors.white,
        tertiaryContainer: kAccentGreen.withOpacity(0.15),
        onTertiaryContainer: kAccentGreen,
        error: kErrorColor,
        onError: Colors.white,
        errorContainer: kErrorColor.withOpacity(0.15),
        onErrorContainer: kErrorColor,
        surface: kCardBackground,
        onSurface: kTextPrimary,
        surfaceContainerHighest: kSurfaceElevated,
        onSurfaceVariant: kTextSecondary,
        outline: kTextMuted,
        outlineVariant: kTextMuted.withOpacity(0.5),
        shadow: kTextPrimary.withOpacity(0.1),
        scrim: kTextPrimary.withOpacity(0.5),
        inverseSurface: kPrimaryColor,
        onInverseSurface: Colors.white,
        inversePrimary: kSecondaryLight,
      ),

      // Scaffold
      scaffoldBackgroundColor: kAppBackground,

      // Typography
      textTheme: kAppTextTheme(base.textTheme),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: kAppTextTheme(base.textTheme).titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: kPrimaryColor),
        actionsIconTheme: const IconThemeData(color: kPrimaryColor),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),

      // Card
      cardTheme: CardThemeData(
        color: kCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusXL),
        ),
        margin: EdgeInsets.zero,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kSecondaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: kSpaceXXL,
            vertical: kSpaceL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusL),
          ),
          textStyle: kAppTextTheme(base.textTheme).titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kSecondaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: kSpaceL,
            vertical: kSpaceM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusM),
          ),
          textStyle: kAppTextTheme(base.textTheme).titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kSecondaryColor,
          side: const BorderSide(color: kSecondaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: kSpaceXXL,
            vertical: kSpaceL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusL),
          ),
        ),
      ),

      // Icon Button
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: kTextSecondary,
          highlightColor: kSecondaryColor.withOpacity(0.1),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: kSecondaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusL),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: kSurfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: kSpaceL,
          vertical: kSpaceL,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusL),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusL),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusL),
          borderSide: const BorderSide(color: kSecondaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusL),
          borderSide: const BorderSide(color: kErrorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusL),
          borderSide: const BorderSide(color: kErrorColor, width: 2),
        ),
        labelStyle: kAppTextTheme(base.textTheme).bodyMedium,
        hintStyle: kAppTextTheme(base.textTheme).bodyMedium?.copyWith(
          color: kTextTertiary,
        ),
        prefixIconColor: kTextSecondary,
        suffixIconColor: kTextSecondary,
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: kCardBackground,
        selectedItemColor: kSecondaryColor,
        unselectedItemColor: kTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: kCardBackground,
        indicatorColor: kSecondaryColor.withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: kSecondaryColor, size: 24);
          }
          return const IconThemeData(color: kTextTertiary, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kSecondaryColor,
            );
          }
          return const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: kTextTertiary,
          );
        }),
        height: kBottomNavHeight,
        elevation: 0,
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: kCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(kRadiusXXL),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: kTextMuted,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: kCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusXXL),
        ),
        titleTextStyle: kAppTextTheme(base.textTheme).headlineMedium,
        contentTextStyle: kAppTextTheme(base.textTheme).bodyMedium,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: kPrimaryColor,
        contentTextStyle: kAppTextTheme(base.textTheme).bodyMedium?.copyWith(
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusM),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: kSurfaceElevated,
        selectedColor: kSecondaryColor.withOpacity(0.15),
        labelStyle: kAppTextTheme(base.textTheme).labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: kSpaceM, vertical: kSpaceS),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusFull),
        ),
        side: BorderSide.none,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: kTextMuted.withOpacity(0.3),
        thickness: 1,
        space: kSpaceXXL,
      ),

      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: kSecondaryColor,
        linearTrackColor: kSurfaceElevated,
        circularTrackColor: kSurfaceElevated,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return kTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return kSecondaryColor;
          }
          return kSurfaceElevated;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // List Tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: kSpaceL,
          vertical: kSpaceXS,
        ),
        horizontalTitleGap: kSpaceM,
        minLeadingWidth: kIconXL,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadiusM)),
        ),
      ),

      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // Splash & Highlight
      splashColor: kSecondaryColor.withOpacity(0.1),
      highlightColor: kSecondaryColor.withOpacity(0.05),
      hoverColor: kSecondaryColor.withOpacity(0.04),
      focusColor: kSecondaryColor.withOpacity(0.12),
    );
  }
}
