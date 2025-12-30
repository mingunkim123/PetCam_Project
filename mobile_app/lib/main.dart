import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:provider/provider.dart';

// 💡 사장님의 파일 경로에 맞춰 임포트 (경로가 다르면 수정하세요)
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'providers/photo_provider.dart';
import 'constants.dart';

void main() async {
  // 1. Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 네이버 지도 SDK 초기화 (사장님의 Client ID를 넣으세요)
  await FlutterNaverMap().init(
    clientId: '2gaxc118qr',
    onAuthFailed: (ex) => debugPrint("네이버 지도 인증 실패: $ex"),
  );

  // 3. Provider와 함께 앱 실행
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PhotoProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// 💡 에러 원인 해결: MyApp 클래스 정의 추가
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PetCam AI',
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: kBgColor,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      // 💡 에러 해결: const MapScreen()에서 에러가 나면 const를 빼주세요.
      routes: {
        '/map': (context) => MapScreen(),
      },
    );
  }
}