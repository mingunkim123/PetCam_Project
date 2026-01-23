import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:mobile_app/src/core/constants/constants.dart';
import 'package:mobile_app/src/routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found or invalid: $e");
  }

  // Initialize Naver Map
  try {
    // Client ID should be in .env, but handling potential null/empty
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

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PetCam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kAppBackground,
        textTheme: kAppTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: kSecondaryColor,
          primary: kPrimaryColor,
          surface: kCardBackground,
          error: kErrorColor,
        ),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
