//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'package:flutter/material.dart';

//*--App Colors : Replace with your own colours---
//-**********---------- WHATSAPP Color Theme: ----------****************---------------

// Unique Color for your App -----

final fiberchatPRIMARYcolor = Color(0xff009466);
// you may change this as per your theme. This applies to large buttons, tabs, text heading etc.
final fiberchatSECONDARYolor = Color(0xff00c166);
// you may change this as per your theme. This applies to small buttons, icons & highlights

const SplashBackgroundSolidColor = Color(0xff00A980);
// you may change this as per your theme. Applies this colors to fill the areas around splash screen.  Color Code: 0xFF00A980 for Whatsapp theme & 0xFFFFFFFF for messenger theme.
const IsSplashOnlySolidColor = false;

// light mode colors -----
final fiberchatAPPBARcolorLightMode = Color(0xff00A980);
// you may change this as per your theme
final fiberchatBACKGROUNDcolorLightMode = Color(0xfff4f5f6);
final fiberchatCONTAINERboxColorLightMode = Color(0xffffffff);
final fiberchatDIALOGColorLightMode = Color(0xffffffff);
final fiberchatCHATBACKGROUNDLightMode = Color(0xffe8ded5);
// dark mode colors -----
final fiberchatAPPBARcolorDarkMode = Color(0xff1d2931);
final fiberchatBACKGROUNDcolorDarkMode = Color(0xff0c151c);
final fiberchatCONTAINERboxColorDarkMode = Color(0xff111920);
final fiberchatDIALOGColorDarkMode = Color(0xff202e35);
final fiberchatCHATBACKGROUNDDarkMode = Color(0xff0e1116);
// other universal colors -----
final fiberchatWhite = Color(0xffffffff);
final fiberchatBlack = Color(0xff1E1E1E);
final fiberchatGrey = Color(0xff8596a0);
final fiberchatREDbuttonColor = Color(0xffe90b41);
final fiberchatCHATBUBBLEcolor = Color(0xffe9fedf);
final fiberchatGreenColorAccent = Color(0xff69F0AE);
final fiberchatGreenColor100 = Color(0xffC8E6C9);
final fiberchatGreenColor200 = Color(0xffA5D6A7);
final fiberchatGreenColor300 = Color(0xff81C784);
final fiberchatGreenColor400 = Color(0xff66BB6A);
final fiberchatGreenColor500 = Color(0xff4CAF50);

//-*********---------- MESSENGER Color Theme:  ----****************---------- Remove below comments & add comment above color values for Messenger theme //------------

// // Unique Color for your App -----
// final fiberchatPRIMARYcolor = Color(0xff009466);
// // you may change this as per your theme. This applies to buttons, icons & highlights
// final fiberchatSECONDARYolor = Color(0xff00c166);
// // you may change this as per your theme. This applies to small buttons, icons & highlights
// const SplashBackgroundSolidColor = Color(0xff00A980);
// // you may change this as per your theme. Applies this colors to fill the areas around splash screen.  Color Code: 0xFF00A980 for Whatsapp theme & 0xFFFFFFFF for messenger theme.
// const IsSplashOnlySolidColor = false;

// // light mode colors -----
// final fiberchatAPPBARcolorLightMode = Color(0xff00A980);
// // you may change this as per your theme
// final fiberchatBACKGROUNDcolorLightMode = Color(0xfff4f5f6);
// final fiberchatCONTAINERboxColorLightMode = Color(0xffffffff);
// final fiberchatDIALOGColorLightMode = Color(0xffffffff);
// final fiberchatCHATBACKGROUNDLightMode = Color(0xffe8ded5);
// // dark mode colors -----
// final fiberchatAPPBARcolorDarkMode = Color(0xff1d2931);
// final fiberchatBACKGROUNDcolorDarkMode = Color(0xff0c151c);
// final fiberchatCONTAINERboxColorDarkMode = Color(0xff111920);
// final fiberchatDIALOGColorDarkMode = Color(0xff202e35);
// final fiberchatCHATBACKGROUNDDarkMode = Color(0xff0e1116);
// // other universal colors -----
// final fiberchatWhite = Color(0xffffffff);
// final fiberchatBlack = Color(0xff1E1E1E);
// final fiberchatGrey = Color(0xff8596a0);
// final fiberchatREDbuttonColor = Color(0xffe90b41);
// final fiberchatCHATBUBBLEcolor = Color(0xffe9fedf);
// final fiberchatGreenColorAccent = Color(0xff69F0AE);
// final fiberchatGreenColor100 = Color(0xffC8E6C9);
// final fiberchatGreenColor200 = Color(0xffA5D6A7);
// final fiberchatGreenColor300 = Color(0xff81C784);
// final fiberchatGreenColor400 = Color(0xff66BB6A);
// final fiberchatGreenColor500 = Color(0xff4CAF50);

//*--Admob Configurations- (By default Test Ad Units pasted)----------
const IsBannerAdShow = false;
// Set this to 'true' if you want to show Banner ads throughout the app
const Admob_BannerAdUnitID_Android = 'ca-app-pub-3940256099942544/6300978111';
// Test Id: 'ca-app-pub-3940256099942544/6300978111'
const Admob_BannerAdUnitID_Ios = 'ca-app-pub-3940256099942544/2934735716';
// Test Id: 'ca-app-pub-3940256099942544/2934735716'
const IsInterstitialAdShow = false;
// Set this to 'true' if you want to show Interstitial ads throughout the app
const InterstitialUnit_Android = 'ca-app-pub-3940256099942544/1033173712';
// Test Id:  'ca-app-pub-3940256099942544/1033173712'
const InterstitialUnit_IOS = 'ca-app-pub-3940256099942544/4411468910';
// Test Id: 'ca-app-pub-3940256099942544/4411468910'
const IsVideoAdShow = false;
// Set this to 'true' if you want to show Video ads throughout the app
const RewardedAdUnit_Android = 'ca-app-pub-3940256099942544/5224354917';
// Test Id: 'ca-app-pub-3940256099942544/5224354917'
const RewardedAdUnit_IOS = 'ca-app-pub-3940256099942544/1712485313';
// Test Id: 'ca-app-pub-3940256099942544/1712485313'
//Also don't forget to Change the Admob App Id in "fiberchat/android/app/src/main/AndroidManifest.xml" & "fiberchat/ios/Runner/Info.plist"

//*--Agora Configurations---
const Agora_APP_ID = 'PASTE_AGORA_APP_ID';
// Grab it from: https://www.agora.io/en/
const Agora_Primary_Certificate = 'PASTE_AGORA_PRIMARY_CERT_HERE';
// Enable the primary certificate for the project and copy & paste the value here.

// *--Giphy Configurations---
const GiphyAPIKey = 'PASTE_GIPHY_API_KEY';
// Grab it from: https://developers.giphy.com/

// *--Google Translation API Configurations---
const GoogleTransalteAPIkey = '';
// Set this api key if you want to enable TEXT message translation. Enable the "Cloud Translation API for your Project from the Google Cloud Platform dashboard: https://console.cloud.google.com/marketplace/product/google/translate.googleapis.com. Then go to "Credentials" and create a API key and paste it here. Leave it blank '' if you don't want translate feature in app.

//*--App Configurations---
const Appname = 'Fiberchat';
//app name shown evrywhere with the app where required
const DEFAULT_COUNTTRYCODE_ISO = 'US';
//default country ISO 2 letter for login screen
const DEFAULT_COUNTTRYCODE_NUMBER = '+1';
//default country code number for login screen
const FONTFAMILY_NAME = '';
// make sure you have registered the font in pubspec.yaml

const FONTFAMILY_NAME_ONLY_LOGO = '';
// make sure you have registered the font in pubspec.yaml

//--WARNING----- PLEASE DONT EDIT THE BELOW LINES UNLESS YOU ARE A DEVELOPER -------
const SplashPath = 'assets/images/splash.jpeg';
const AppLogoPathDarkModeLogo = 'assets/images/applogo_light.png';
const AppLogoPathLightModeLogo = 'assets/images/applogo_dark.png';
