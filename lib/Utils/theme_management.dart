import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Configs/optional_constants.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';

class Thm {
  static const THEME_STATUS = "THEMESTATUS";

  static bool isDarktheme(SharedPreferences prefs) {
    return prefs.getBool(THEME_STATUS) ??
        (IsHIDELightDarkModeSwitchInApp == true
            ? false
            : WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
  }
}

class DarkThemePreference {
  static const THEME_STATUS = "THEMESTATUS";

  setDarkTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(THEME_STATUS, value);
  }

  Future<bool> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(THEME_STATUS) ??
        (IsHIDELightDarkModeSwitchInApp == true
            ? false
            : WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
  }
}

class DarkThemeProvider with ChangeNotifier {
  DarkThemePreference darkThemePreference = DarkThemePreference();
  bool _darkTheme = false;

  bool get darkTheme => _darkTheme;

  set darkTheme(bool value) {
    _darkTheme = value;
    darkThemePreference.setDarkTheme(value);
    notifyListeners();
  }
}

MaterialColor getMaterialColor(Color color) {
  final int red = color.red;
  final int green = color.green;
  final int blue = color.blue;

  final Map<int, Color> shades = {
    50: Color.fromRGBO(red, green, blue, .1),
    100: Color.fromRGBO(red, green, blue, .2),
    200: Color.fromRGBO(red, green, blue, .3),
    300: Color.fromRGBO(red, green, blue, .4),
    400: Color.fromRGBO(red, green, blue, .5),
    500: Color.fromRGBO(red, green, blue, .6),
    600: Color.fromRGBO(red, green, blue, .7),
    700: Color.fromRGBO(red, green, blue, .8),
    800: Color.fromRGBO(red, green, blue, .9),
    900: Color.fromRGBO(red, green, blue, 1),
  };

  return MaterialColor(color.value, shades);
}

class Styles {
  static ThemeData themeData(bool isDarkTheme, BuildContext context) {
    return ThemeData(
      splashColor: fiberchatGrey.withOpacity(0.2),
      highlightColor: Colors.transparent,
      //
      fontFamily: FONTFAMILY_NAME == '' ? null : FONTFAMILY_NAME,
      primaryColor: fiberchatPRIMARYcolor,
      primaryColorLight: fiberchatPRIMARYcolor,
      indicatorColor: fiberchatPRIMARYcolor,
      primarySwatch: getMaterialColor(fiberchatPRIMARYcolor),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return fiberchatPRIMARYcolor;
          }
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return fiberchatPRIMARYcolor;
          }
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return fiberchatPRIMARYcolor;
          }
          return null;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return null;
          }
          if (states.contains(MaterialState.selected)) {
            return fiberchatPRIMARYcolor;
          }
          return null;
        }),
      ),
      colorScheme: ColorScheme.fromSwatch(
          brightness: isDarkTheme ? Brightness.dark : Brightness.light,
          backgroundColor: isDarkTheme
              ? fiberchatBACKGROUNDcolorDarkMode
              : fiberchatBACKGROUNDcolorLightMode),
      disabledColor: Colors.grey,
      cardColor: isDarkTheme
          ? fiberchatBACKGROUNDcolorDarkMode
          : fiberchatBACKGROUNDcolorLightMode,
      canvasColor: isDarkTheme
          ? fiberchatBACKGROUNDcolorDarkMode
          : fiberchatBACKGROUNDcolorLightMode,
      brightness: isDarkTheme ? Brightness.dark : Brightness.light,
      buttonTheme: Theme.of(context).buttonTheme.copyWith(
          colorScheme: isDarkTheme ? ColorScheme.dark() : ColorScheme.light()),
      appBarTheme: AppBarTheme(
        elevation: 0.0,
      ),
    );
  }
}
