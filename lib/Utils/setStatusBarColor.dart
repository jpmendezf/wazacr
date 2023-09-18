import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Utils/color_detector.dart';
import 'package:fiberchat/Utils/theme_management.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

setStatusBarColor(SharedPreferences prefs) {
  if (Thm.isDarktheme(prefs) == true) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: fiberchatAPPBARcolorDarkMode,
        statusBarIconBrightness: isDarkColor(fiberchatAPPBARcolorDarkMode)
            ? Brightness.light
            : Brightness.dark));
  } else {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: fiberchatAPPBARcolorLightMode,
        statusBarIconBrightness: isDarkColor(fiberchatAPPBARcolorLightMode)
            ? Brightness.light
            : Brightness.dark));
  }
}
