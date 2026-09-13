import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'firebase_options.dart';
import 'screens/launch/launch_page.dart';
import 'services/call_service.dart';

final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GoogleSignIn.instance.initialize(
    serverClientId:
    '129348034395-q4uaocgamf3ugnqe02al7bjnaeo12aqk.apps.googleusercontent.com',
  );

  await CallService.instance.initialize();

  // ------------------------------------------------------------
  // ZEGOCLOUD
  // ------------------------------------------------------------

  ZegoUIKitPrebuiltCallInvitationService()
      .setNavigatorKey(navigatorKey);

  await ZegoUIKit().initLog();

  await ZegoUIKitPrebuiltCallInvitationService()
      .useSystemCallingUI(
    [
      ZegoUIKitSignalingPlugin(),
    ],
  );

  runApp(const RingrApp());
}

class RingrApp extends StatelessWidget {
  const RingrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,

      title: 'Ringr',
      debugShowCheckedModeBanner: false,

      themeMode: ThemeMode.system,

      // ----------------------------------------------------------
      // LIGHT THEME
      // ----------------------------------------------------------

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor:
        const Color(0xFFF8F7FC),

        appBarTheme: const AppBarTheme(
          backgroundColor:
          Color(0xFFF8F7FC),
          elevation: 0,
        ),

        inputDecorationTheme:
        InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(16),
            borderSide:
            BorderSide.none,
          ),

          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(16),
            borderSide:
            BorderSide.none,
          ),

          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(16),
            borderSide:
            const BorderSide(
              color: Color(0xFF7C3AED),
              width: 1.5,
            ),
          ),
        ),
      ),

      // ----------------------------------------------------------
      // DARK THEME
      // ----------------------------------------------------------

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),

        // Soft dark gray.
        // NOT the near-black Google Meet style.
        scaffoldBackgroundColor:
        const Color(0xFF202124),

        appBarTheme:
        const AppBarTheme(
          backgroundColor:
          Color(0xFF202124),
          elevation: 0,
        ),

        inputDecorationTheme:
        InputDecorationTheme(
          filled: true,
          fillColor:
          const Color(0xFF2B2D31),

          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(16),
            borderSide:
            BorderSide.none,
          ),

          enabledBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(16),
            borderSide:
            BorderSide.none,
          ),

          focusedBorder:
          OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(16),
            borderSide:
            const BorderSide(
              color: Color(0xFFA78BFA),
              width: 1.5,
            ),
          ),
        ),
      ),

      home: const LaunchPage(),
    );
  }
}