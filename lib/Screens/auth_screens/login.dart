//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:fiberchat/Configs/Dbkeys.dart';
import 'package:fiberchat/Configs/Dbpaths.dart';
import 'package:fiberchat/Configs/optional_constants.dart';
import 'package:fiberchat/Screens/homepage/homepage.dart';
import 'package:fiberchat/Screens/privacypolicy&TnC/PdfViewFromCachedUrl.dart';
import 'package:fiberchat/Services/Providers/Observer.dart';
import 'package:fiberchat/Services/Providers/TimerProvider.dart';
import 'package:fiberchat/Utils/color_detector.dart';
import 'package:fiberchat/Utils/custom_url_launcher.dart';
import 'package:fiberchat/Utils/phonenumberVariantsGenerator.dart';
import 'package:fiberchat/Utils/setStatusBarColor.dart';
import 'package:fiberchat/Utils/theme_management.dart';
import 'package:fiberchat/widgets/DynamicBottomSheet/dynamic_modal_bottomsheet.dart';
import 'package:fiberchat/widgets/PhoneField/countries.dart';
import 'package:fiberchat/widgets/PhoneField/intl_phone_field.dart';
import 'package:fiberchat/widgets/PhoneField/phone_number.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Services/localization/language.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fiberchat/Models/E2EE/e2ee.dart' as e2ee;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fiberchat/Configs/Enum.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:fiberchat/Utils/unawaited.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen(
      {Key? key,
      this.title,
      required this.isaccountapprovalbyadminneeded,
      required this.accountApprovalMessage,
      required this.prefs,
      required this.doc,
      required this.isblocknewlogins})
      : super(key: key);

  final String? title;

  final bool? isblocknewlogins;
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final bool? isaccountapprovalbyadminneeded;
  final String? accountApprovalMessage;
  final SharedPreferences prefs;
  @override
  LoginScreenState createState() => new LoginScreenState();
}

class LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  String _code = "";
  final _phoneNo = TextEditingController();
  int currentStatus = 0;
  final _name = TextEditingController();
  String? phoneCode = DEFAULT_COUNTTRYCODE_NUMBER;
  final storage = new FlutterSecureStorage();
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  int attempt = 1;
  String? verificationId;
  bool isShowCompletedLoading = false;
  bool isVerifyingCode = false;
  bool isCodeSent = false;
  dynamic isLoggedIn = false;
  User? currentUser;
  String? deviceid;
  var mapDeviceInfo = {};
  String? autoDetectedCountryCode;
  @override
  void initState() {
    super.initState();
    setdeviceinfo();
    detectLocale();
  }

  bool islangnotselected() {
    return (widget.prefs.getBool('islanguageselected') == false ||
        widget.prefs.getBool('islanguageselected') == null);
  }

  setParticularLocale(String langCode) async {
    if (Language.languageList()
            .indexWhere((element) => element.languageCode == langCode) >=
        0) {
      Locale _locale = await setLocale(langCode);
      FiberchatWrapper.setLocale(context, _locale);
    }
  }

  detectLocale() async {
    await Devicelocale.currentLocale.then((locale) async {
      // Fiberchat.toast("ssdd${locale.toString()}");
      if (locale != null) {
        List<dynamic> data = languagelist;
        for (final code in data) {
          if ((locale.startsWith('${code}_') || locale.startsWith('$code-')) &&
              islangnotselected() == true) {
            await setParticularLocale(code);
          }
        }
        if (widget.prefs.getString('phonecode') == null) {
          for (final code in data) {
            if (locale.startsWith('${code}_') || locale.startsWith('$code-')) {
              if (code == 'en') {
                autoDetectedCountryCode = DEFAULT_COUNTTRYCODE_ISO;
                phoneCode = DEFAULT_COUNTTRYCODE_NUMBER;
              } else if (code == 'vi') {
                autoDetectedCountryCode = 'VN';
                int i = countries.indexWhere(
                    (element) => element['code'] == autoDetectedCountryCode);
                if (i > 0) {
                  phoneCode = '+${countries[i]['dial_code']}';
                }
              } else if (code == 'hi') {
                autoDetectedCountryCode = 'IN';
                int i = countries.indexWhere(
                    (element) => element['code'] == autoDetectedCountryCode);
                if (i > 0) {
                  phoneCode = '+${countries[i]['dial_code']}';
                }
              } else {
                autoDetectedCountryCode = DEFAULT_COUNTTRYCODE_ISO;
                phoneCode = DEFAULT_COUNTTRYCODE_NUMBER;
              }

              setState(() {});
              await widget.prefs.setString(
                  'phonecode', phoneCode ?? DEFAULT_COUNTTRYCODE_NUMBER);
              await widget.prefs.setString('autoDetectedCountryCode',
                  autoDetectedCountryCode ?? DEFAULT_COUNTTRYCODE_ISO);
            }
          }
        } else {
          autoDetectedCountryCode =
              widget.prefs.getString('autoDetectedCountryCode');
          phoneCode = widget.prefs.getString('phonecode');

          setState(() {});
        }
        setState(() {});
      }
    }).catchError((onError) {
      print(
        'Error occured while fetching Locale :$onError',
      );
    });
  }

  setdeviceinfo() async {
    if (Platform.isAndroid == true) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      setState(() {
        deviceid = androidInfo.id + androidInfo.device;
        mapDeviceInfo = {
          Dbkeys.deviceInfoMODEL: androidInfo.model,
          Dbkeys.deviceInfoOS: 'android',
          Dbkeys.deviceInfoISPHYSICAL: androidInfo.isPhysicalDevice,
          Dbkeys.deviceInfoDEVICEID: androidInfo.id,
          Dbkeys.deviceInfoOSID: androidInfo.id,
          Dbkeys.deviceInfoOSVERSION: androidInfo.version.baseOS,
          Dbkeys.deviceInfoMANUFACTURER: androidInfo.manufacturer,
          Dbkeys.deviceInfoLOGINTIMESTAMP: DateTime.now(),
        };
      });
    } else if (Platform.isIOS == true) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      setState(() {
        deviceid =
            "${iosInfo.systemName}${iosInfo.model ?? ""}${iosInfo.systemVersion ?? ""}";
        mapDeviceInfo = {
          Dbkeys.deviceInfoMODEL: iosInfo.model,
          Dbkeys.deviceInfoOS: 'ios',
          Dbkeys.deviceInfoISPHYSICAL: iosInfo.isPhysicalDevice,
          Dbkeys.deviceInfoDEVICEID: iosInfo.identifierForVendor,
          Dbkeys.deviceInfoOSID: iosInfo.name,
          Dbkeys.deviceInfoOSVERSION: iosInfo.name,
          Dbkeys.deviceInfoMANUFACTURER: iosInfo.name,
          Dbkeys.deviceInfoLOGINTIMESTAMP: DateTime.now(),
        };
      });
    }
  }

  int currentPinAttemps = 0;
  Future<void> verifyPhoneNumber() async {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    final PhoneVerificationCompleted verificationCompleted =
        (AuthCredential phoneAuthCredential) {
      isShowCompletedLoading = true;
      setState(() {});
      handleSignIn(authCredential: phoneAuthCredential);
    };

    final PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException authException) {
      setState(() {
        currentStatus = LoginStatus.failure.index;
        // _phoneNo.clear();
        // _code = '';
        isCodeSent = false;

        timerProvider.resetTimer();

        isShowCompletedLoading = false;
        isVerifyingCode = false;
        currentPinAttemps = 0;
      });

      debugPrint(
          'Authentication failed -ERROR: ${authException.message}. Try again later.');

      Fiberchat.toast('Authentication failed - ${authException.message}');
    };

    final PhoneCodeSent codeSent =
        (String verificationId, [int? forceResendingToken]) async {
      timerProvider.startTimer();
      setState(() {
        currentStatus = LoginStatus.sentSMSCode.index;
        isVerifyingCode = false;
        isCodeSent = true;
      });

      this.verificationId = verificationId;
    };

    final PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout =
        (String verificationId) {
      this.verificationId = verificationId;
      if (mounted) {
        setState(() {
          currentStatus = LoginStatus.failure.index;
          // _phoneNo.clear();
          // _code = '';
          isCodeSent = false;

          timerProvider.resetTimer();

          isShowCompletedLoading = false;
          isVerifyingCode = false;
          currentPinAttemps = 0;
        });

        Fiberchat.toast('Authentication failed Timeout. please try again.');
      }
    };
    debugPrint('Verify phone triggered');
    // try {
    await firebaseAuth.verifyPhoneNumber(
        phoneNumber: (phoneCode! + _phoneNo.text).trim(),
        timeout: Duration(seconds: timeOutSeconds),
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
    // } catch (e) {
    //   Fiberchat.toast('NEW CATCH' + e.toString());
    // }
  }

  subscribeToNotification(String currentUserNo, bool isFreshNewAccount) async {
    await FirebaseMessaging.instance
        .subscribeToTopic(
            '${currentUserNo.replaceFirst(new RegExp(r'\+'), '')}')
        .catchError((err) {
      debugPrint('ERROR SUBSCRIBING NOTIFICATION' + err.toString());
    });
    await FirebaseMessaging.instance
        .subscribeToTopic(Dbkeys.topicUSERS)
        .catchError((err) {
      debugPrint('ERROR SUBSCRIBING NOTIFICATION' + err.toString());
    });
    await FirebaseMessaging.instance
        .subscribeToTopic(Platform.isAndroid
            ? Dbkeys.topicUSERSandroid
            : Platform.isIOS
                ? Dbkeys.topicUSERSios
                : Dbkeys.topicUSERSweb)
        .catchError((err) {
      debugPrint('ERROR SUBSCRIBING NOTIFICATION' + err.toString());
    });

    if (isFreshNewAccount == false) {
      await FirebaseFirestore.instance
          .collection(DbPaths.collectiongroups)
          .where(Dbkeys.groupMEMBERSLIST, arrayContains: currentUserNo)
          .get()
          .then((query) async {
        if (query.docs.length > 0) {
          query.docs.forEach((doc) async {
            if (doc.data().containsKey(Dbkeys.groupMUTEDMEMBERS)) {
              if (doc[Dbkeys.groupMUTEDMEMBERS].contains(currentUserNo)) {
              } else {
                await FirebaseMessaging.instance
                    .subscribeToTopic(
                        "GROUP${doc[Dbkeys.groupID].replaceAll(RegExp('-'), '').substring(1, doc[Dbkeys.groupID].replaceAll(RegExp('-'), '').toString().length)}")
                    .catchError((err) {
                  debugPrint('ERROR SUBSCRIBING NOTIFICATION' + err.toString());
                });
              }
            } else {
              await FirebaseMessaging.instance
                  .subscribeToTopic(
                      "GROUP${doc[Dbkeys.groupID].replaceAll(RegExp('-'), '').substring(1, doc[Dbkeys.groupID].replaceAll(RegExp('-'), '').toString().length)}")
                  .catchError((err) {
                debugPrint('ERROR SUBSCRIBING NOTIFICATION' + err.toString());
              });
            }
          });
        }
      });
    }
  }

  Future<Null> handleSignIn({AuthCredential? authCredential}) async {
    setState(() {
      isShowCompletedLoading = true;
    });
    var phoneNo = (phoneCode! + _phoneNo.text).trim();

    try {
      AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId!, smsCode: _code);

      UserCredential firebaseUser =
          await firebaseAuth.signInWithCredential(credential);

      // ignore: unnecessary_null_comparison
      if (firebaseUser != null) {
        // Check is already sign up
        final QuerySnapshot result = await FirebaseFirestore.instance
            .collection(DbPaths.collectionusers)
            .where(Dbkeys.id, isEqualTo: firebaseUser.user!.uid)
            .get();
        final List documents = result.docs;
        final pair = await e2ee.X25519().generateKeyPair();

        if (documents.length == 0) {
          String? fcmTokenn = await FirebaseMessaging.instance.getToken();
          if (fcmTokenn != null) {
            await storage.write(
                key: Dbkeys.privateKey, value: pair.secretKey.toBase64());
            // Update data to server if new user
            await FirebaseFirestore.instance
                .collection(DbPaths.collectionusers)
                .doc(phoneNo)
                .set({
              Dbkeys.publicKey: pair.publicKey.toBase64(),
              Dbkeys.privateKey: pair.secretKey.toBase64(),
              Dbkeys.countryCode: phoneCode,
              Dbkeys.nickname: _name.text.trim(),
              Dbkeys.photoUrl: firebaseUser.user!.photoURL ?? '',
              Dbkeys.id: firebaseUser.user!.uid,
              Dbkeys.phone: phoneNo,
              Dbkeys.phoneRaw: _phoneNo.text,
              Dbkeys.authenticationType: AuthenticationType.passcode.index,
              Dbkeys.aboutMe: '',
              //---Additional fields added for Admin app compatible----
              Dbkeys.accountstatus:
                  widget.isaccountapprovalbyadminneeded == true
                      ? Dbkeys.sTATUSpending
                      : Dbkeys.sTATUSallowed,
              Dbkeys.actionmessage: widget.accountApprovalMessage,
              Dbkeys.lastLogin: DateTime.now().millisecondsSinceEpoch,
              Dbkeys.joinedOn: DateTime.now().millisecondsSinceEpoch,
              Dbkeys.searchKey: _name.text.trim().substring(0, 1).toUpperCase(),
              Dbkeys.videoCallMade: 0,
              Dbkeys.videoCallRecieved: 0,
              Dbkeys.audioCallMade: 0,
              Dbkeys.groupsCreated: 0,
              Dbkeys.blockeduserslist: [],
              Dbkeys.audioCallRecieved: 0,
              Dbkeys.mssgSent: 0,
              Dbkeys.deviceDetails: mapDeviceInfo,
              Dbkeys.currentDeviceID: deviceid,
              Dbkeys.phonenumbervariants: phoneNumberVariantsList(
                  countrycode: phoneCode, phonenumber: _phoneNo.text)
            }, SetOptions(merge: true));
            currentUser = firebaseUser.user;
            await FirebaseFirestore.instance
                .collection(DbPaths.collectiondashboard)
                .doc(DbPaths.docuserscount)
                .set(
                    widget.isaccountapprovalbyadminneeded == false
                        ? {
                            Dbkeys.totalapprovedusers: FieldValue.increment(1),
                          }
                        : {
                            Dbkeys.totalpendingusers: FieldValue.increment(1),
                          },
                    SetOptions(merge: true));

            await FirebaseFirestore.instance
                .collection(DbPaths.collectioncountrywiseData)
                .doc(phoneCode)
                .set({
              Dbkeys.totalusers: FieldValue.increment(1),
            }, SetOptions(merge: true));

            await FirebaseFirestore.instance
                .collection(DbPaths.collectionnotifications)
                .doc(DbPaths.adminnotifications)
                .update({
              Dbkeys.nOTIFICATIONxxaction: 'PUSH',
              Dbkeys.nOTIFICATIONxxdesc: widget
                          .isaccountapprovalbyadminneeded ==
                      true
                  ? '${_name.text.trim()} has Joined $Appname. APPROVE the user account. You can view the user profile from All Users List.'
                  : '${_name.text.trim()} has Joined $Appname. You can view the user profile from All Users List.',
              Dbkeys.nOTIFICATIONxxtitle: 'New User Joined',
              Dbkeys.nOTIFICATIONxximageurl: null,
              Dbkeys.nOTIFICATIONxxlastupdate: DateTime.now(),
              'list': FieldValue.arrayUnion([
                {
                  Dbkeys.docid:
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  Dbkeys.nOTIFICATIONxxdesc: widget
                              .isaccountapprovalbyadminneeded ==
                          true
                      ? '${_name.text.trim()} has Joined $Appname. APPROVE the user account. You can view the user profile from All Users List.'
                      : '${_name.text.trim()} has Joined $Appname. You can view the user profile from All Users List.',
                  Dbkeys.nOTIFICATIONxxtitle: 'New User Joined',
                  Dbkeys.nOTIFICATIONxximageurl: null,
                  Dbkeys.nOTIFICATIONxxlastupdate: DateTime.now(),
                  Dbkeys.nOTIFICATIONxxauthor:
                      currentUser!.uid + 'XXX' + 'userapp',
                }
              ])
            });

            // Write data to local

            await widget.prefs.setString(Dbkeys.id, currentUser!.uid);
            await widget.prefs.setString(Dbkeys.nickname, _name.text.trim());
            await widget.prefs
                .setString(Dbkeys.photoUrl, currentUser!.photoURL ?? '');
            await widget.prefs.setString(Dbkeys.phone, phoneNo);
            await widget.prefs.setString(Dbkeys.countryCode, phoneCode!);
            await FirebaseFirestore.instance
                .collection(DbPaths.collectionusers)
                .doc(phoneNo)
                .set({
              Dbkeys.notificationTokens: [fcmTokenn]
            }, SetOptions(merge: true));
            unawaited(widget.prefs.setBool(Dbkeys.isTokenGenerated, true));
            await widget.prefs.setString(Dbkeys.isSecuritySetupDone, phoneNo);
            await subscribeToNotification(phoneNo, true);
            unawaited(Navigator.pushReplacement(
                this.context,
                MaterialPageRoute(
                    builder: (newContext) => Homepage(
                          doc: widget.doc,
                          currentUserNo: phoneNo,
                          prefs: widget.prefs,
                        ))));
          } else {
            unawaited(Navigator.pushReplacement(
                this.context,
                new MaterialPageRoute(
                    builder: (context) => FiberchatWrapper())));
            Fiberchat.toast(getTranslated(this.context, 'failedtologin'));
          }
        } else {
          String? fcmToken = await FirebaseMessaging.instance.getToken();
          if (fcmToken != null) {
            await storage.write(
                key: Dbkeys.privateKey, value: documents[0][Dbkeys.privateKey]);

            await FirebaseFirestore.instance
                .collection(DbPaths.collectionusers)
                .doc(phoneNo)
                .update(
                  !documents[0].data().containsKey(Dbkeys.deviceDetails)
                      ? {
                          Dbkeys.authenticationType:
                              AuthenticationType.passcode.index,
                          Dbkeys.accountstatus:
                              widget.isaccountapprovalbyadminneeded == true
                                  ? Dbkeys.sTATUSpending
                                  : Dbkeys.sTATUSallowed,
                          Dbkeys.actionmessage: widget.accountApprovalMessage,
                          Dbkeys.lastLogin:
                              DateTime.now().millisecondsSinceEpoch,
                          Dbkeys.joinedOn:
                              documents[0].data()![Dbkeys.lastSeen] != true
                                  ? documents[0].data()![Dbkeys.lastSeen]
                                  : DateTime.now().millisecondsSinceEpoch,
                          Dbkeys.nickname: _name.text.trim(),
                          Dbkeys.searchKey:
                              _name.text.trim().substring(0, 1).toUpperCase(),
                          Dbkeys.videoCallMade: 0,
                          Dbkeys.videoCallRecieved: 0,
                          Dbkeys.audioCallMade: 0,
                          Dbkeys.audioCallRecieved: 0,
                          Dbkeys.mssgSent: 0,
                          Dbkeys.deviceDetails: mapDeviceInfo,
                          Dbkeys.currentDeviceID: deviceid,
                          Dbkeys.phonenumbervariants: phoneNumberVariantsList(
                              countrycode:
                                  documents[0].data()![Dbkeys.countryCode],
                              phonenumber:
                                  documents[0].data()![Dbkeys.phoneRaw]),
                          Dbkeys.notificationTokens: [fcmToken],
                        }
                      : {
                          Dbkeys.searchKey:
                              _name.text.trim().substring(0, 1).toUpperCase(),
                          Dbkeys.nickname: _name.text.trim(),
                          Dbkeys.authenticationType:
                              AuthenticationType.passcode.index,
                          Dbkeys.lastLogin:
                              DateTime.now().millisecondsSinceEpoch,
                          Dbkeys.deviceDetails: mapDeviceInfo,
                          Dbkeys.currentDeviceID: deviceid,
                          Dbkeys.phonenumbervariants: phoneNumberVariantsList(
                              countrycode:
                                  documents[0].data()![Dbkeys.countryCode],
                              phonenumber:
                                  documents[0].data()![Dbkeys.phoneRaw]),
                          Dbkeys.notificationTokens: [fcmToken],
                        },
                );
            // Write data to local
            await widget.prefs.setString(Dbkeys.id, documents[0][Dbkeys.id]);
            await widget.prefs.setString(Dbkeys.nickname, _name.text.trim());
            await widget.prefs.setString(
                Dbkeys.photoUrl, documents[0][Dbkeys.photoUrl] ?? '');
            await widget.prefs
                .setString(Dbkeys.aboutMe, documents[0][Dbkeys.aboutMe] ?? '');
            await widget.prefs
                .setString(Dbkeys.phone, documents[0][Dbkeys.phone]);

            await subscribeToNotification(documents[0][Dbkeys.phone], false);
            unawaited(Navigator.pushReplacement(
                this.context,
                new MaterialPageRoute(
                    builder: (context) => FiberchatWrapper())));
            Fiberchat.toast(getTranslated(this.context, 'welcomeback'));
          } else {
            unawaited(Navigator.pushReplacement(
                this.context,
                new MaterialPageRoute(
                    builder: (context) => FiberchatWrapper())));
            Fiberchat.toast(getTranslated(this.context, 'failedlogin'));
          }
        }
      } else {
        Fiberchat.toast(getTranslated(this.context, 'failedlogin'));
      }
    } catch (e) {
      setState(() {
        if (currentPinAttemps >= 4) {
          currentStatus = LoginStatus.failure.index;
          // _phoneNo.clear();
          // _code = '';
          isCodeSent = false;
        }

        isShowCompletedLoading = false;
        isVerifyingCode = false;
        currentPinAttemps++;
      });
      if (e.toString().contains('invalid') ||
          e.toString().contains('code') ||
          e.toString().contains('verification')) {
        Fiberchat.toast(getTranslated(this.context, 'makesureotp'));
      }
    }
  }

  void _changeLanguage(Language language) async {
    Locale _locale = await setLocale(language.languageCode);
    FiberchatWrapper.setLocale(this.context, _locale);
    setState(() {
      seletedlanguage = language;
    });

    await widget.prefs.setBool('islanguageselected', true);
  }

  Language? seletedlanguage;
  customclippath(double w, double h) {
    return ClipPath(
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.only(top: MediaQuery.of(this.context).padding.top),
        height: 400,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Thm.isDarktheme(widget.prefs)
                  ? fiberchatAPPBARcolorDarkMode
                  : fiberchatAPPBARcolorLightMode,
              Thm.isDarktheme(widget.prefs)
                  ? fiberchatAPPBARcolorDarkMode
                  : fiberchatAPPBARcolorLightMode
            ],
          ),
        ),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: Platform.isIOS ? 0 : 10,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10, left: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Language.languageList().length < 2 ||
                          IsShowLanguageChangeButtonInLoginAndHome == false
                      ? SizedBox(
                          height: 40,
                        )
                      : InkWell(
                          onTap: () {
                            showDynamicModalBottomSheet(
                                isdark: Thm.isDarktheme(widget.prefs),
                                context: context,
                                widgetList: Language.languageList()
                                    .map(
                                      (e) => InkWell(
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          _changeLanguage(e);
                                        },
                                        child: Container(
                                          margin: EdgeInsets.all(14),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Text(
                                                IsShowLanguageNameInNativeLanguage ==
                                                        true
                                                    ? e.flag +
                                                        ' ' +
                                                        '    ' +
                                                        e.name
                                                    : e.flag +
                                                        ' ' +
                                                        '    ' +
                                                        e.languageNameInEnglish,
                                                style: TextStyle(
                                                    color: Thm.isDarktheme(
                                                            widget.prefs)
                                                        ? fiberchatWhite
                                                        : fiberchatBlack,
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 16),
                                              ),
                                              Language.languageList().length < 2
                                                  ? SizedBox()
                                                  : Icon(
                                                      Icons.done,
                                                      color: e.languageCode ==
                                                              widget.prefs
                                                                  .getString(
                                                                      LAGUAGE_CODE)
                                                          ? fiberchatSECONDARYolor
                                                          : Colors.transparent,
                                                    )
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                title: "");
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  Icons.language_outlined,
                                  color: pickTextColorBasedOnBgColorAdvanced(
                                          Thm.isDarktheme(widget.prefs)
                                              ? fiberchatAPPBARcolorDarkMode
                                              : fiberchatAPPBARcolorLightMode)
                                      .withOpacity(0.85),
                                ),
                                SizedBox(
                                  width: 30,
                                  child: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Thm.isDarktheme(widget.prefs)
                                        ? fiberchatSECONDARYolor
                                        : isDarkColor(
                                                    fiberchatBACKGROUNDcolorLightMode) ==
                                                true
                                            ? fiberchatWhite.withOpacity(0.6)
                                            : pickTextColorBasedOnBgColorAdvanced(
                                                    fiberchatAPPBARcolorLightMode)
                                                .withOpacity(0.65),
                                    size: 27,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),

                  //---- Dark mode/light mode switch----
                  if (IsShowLightDarkModeSwitchInLoginScreen == true &&
                      IsHIDELightDarkModeSwitchInApp != true)
                    IconButton(
                        onPressed: () {
                          final themeChange = Provider.of<DarkThemeProvider>(
                              this.context,
                              listen: false);

                          themeChange.darkTheme =
                              !Thm.isDarktheme(widget.prefs);
                          setState(() {});
                          Future.delayed(const Duration(milliseconds: 500), () {
                            setStatusBarColor(widget.prefs);
                          });
                        },
                        icon: Icon(
                          !Thm.isDarktheme(widget.prefs) == false
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: pickTextColorBasedOnBgColorAdvanced(
                                  Thm.isDarktheme(widget.prefs)
                                      ? fiberchatAPPBARcolorDarkMode
                                      : fiberchatAPPBARcolorLightMode)
                              .withOpacity(0.85),
                        )),
                ],
              ),
            ),
            SizedBox(
              height: w > h ? 0 : 15,
            ),
            w < h
                ? Image.asset(
                    !Thm.isDarktheme(widget.prefs)
                        ? isDarkColor(fiberchatAPPBARcolorLightMode)
                            ? AppLogoPathDarkModeLogo
                            : AppLogoPathLightModeLogo
                        : AppLogoPathDarkModeLogo,
                    width: w / 1.35,
                  )
                : Image.asset(
                    !Thm.isDarktheme(widget.prefs)
                        ? isDarkColor(fiberchatAPPBARcolorLightMode)
                            ? AppLogoPathDarkModeLogo
                            : AppLogoPathLightModeLogo
                        : AppLogoPathDarkModeLogo,
                    height: h / 6,
                  ),
            SizedBox(
              height: 0,
            ),
          ],
        ),
      ),
    );
  }

  buildCurrentWidget(double w) {
    if (currentStatus == LoginStatus.sendSMScode.index) {
      return loginWidgetsendSMScode(w);
    } else if (currentStatus == LoginStatus.sendingSMScode.index) {
      return loginWidgetsendingSMScode();
    } else if (currentStatus == LoginStatus.sentSMSCode.index) {
      return loginWidgetsentSMScode();
    } else if (currentStatus == LoginStatus.verifyingSMSCode.index) {
      return loginWidgetVerifyingSMScode();
    } else if (currentStatus == LoginStatus.sendingSMScode.index) {
      return loginWidgetsendingSMScode();
    } else {
      return loginWidgetsendSMScode(w);
    }
  }

  loginWidgetsendSMScode(double w) {
    return autoDetectedCountryCode == null
        ? SizedBox()
        : Consumer<Observer>(
            builder: (context, observer, _) => Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [boxShadow()],
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.fromLTRB(
                          15,
                          MediaQuery.of(this.context).size.height / 2.50,
                          16,
                          0),
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            height: 13,
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                            // height: 63,
                            height: 83,
                            width: w / 1.24,
                            child: InpuTextBox(
                              isDark: false,
                              inputFormatter: [
                                LengthLimitingTextInputFormatter(25),
                              ],
                              controller: _name,
                              leftrightmargin: 0,
                              showIconboundary: false,
                              boxcornerradius: 5.5,
                              boxheight: 50,
                              hinttext:
                                  getTranslated(this.context, 'name_hint'),
                              prefixIconbutton: Icon(
                                Icons.person,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 0),
                            // padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                            // height: 63,
                            height: 63,
                            width: w / 1.24,
                            child: Form(
                              // key: _enterNumberFormKey,
                              child: MobileInputWithOutline(
                                buttonhintTextColor: fiberchatGrey,
                                borderColor: fiberchatGrey.withOpacity(0.2),
                                controller: _phoneNo,
                                initialCountryCode: autoDetectedCountryCode!,
                                onSaved: (phone) async {
                                  setState(() {
                                    phoneCode = phone!.countryCode;
                                  });
                                  await widget.prefs.setString('phonecode',
                                      phoneCode ?? DEFAULT_COUNTTRYCODE_NUMBER);
                                  await widget.prefs.setString(
                                      'autoDetectedCountryCode',
                                      phone!.countryISOCode ??
                                          DEFAULT_COUNTTRYCODE_ISO);
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(17),
                            child: Text(
                              getTranslated(this.context, 'sendsmscode'),
                              // 'Send a SMS Code to verify your number',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: fiberchatBlack),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(17, 22, 17, 5),
                            child: MySimpleButton(
                              width: w / 1.24,
                              spacing: 0.3,
                              height: 57,
                              buttoncolor: fiberchatSECONDARYolor,
                              buttontext:
                                  getTranslated(this.context, 'sendverf'),
                              onpressed: widget.isblocknewlogins == true
                                  ? () {
                                      Fiberchat.toast(
                                        getTranslated(
                                            this.context, 'logindisabled'),
                                      );
                                    }
                                  : () {
                                      final timerProvider =
                                          Provider.of<TimerProvider>(context,
                                              listen: false);

                                      setState(() {});
                                      RegExp e164 =
                                          new RegExp(r'^\+[1-9]\d{1,14}$');
                                      if (_name.text.trim().isNotEmpty) {
                                        String _phone =
                                            _phoneNo.text.toString().trim();
                                        if (_phone.isNotEmpty &&
                                            e164.hasMatch(
                                                phoneCode! + _phone)) {
                                          if (_phone.startsWith('0') &&
                                              phoneCode == '+81') {
                                            timerProvider.resetTimer();
                                            setState(() {
                                              _phone = _phone.substring(1);
                                              _phoneNo.text = _phone;
                                              currentStatus = LoginStatus
                                                  .sendingSMScode.index;
                                              isCodeSent = false;
                                            });

                                            verifyPhoneNumber();
                                          } else {
                                            timerProvider.resetTimer();
                                            setState(() {
                                              currentStatus = LoginStatus
                                                  .sendingSMScode.index;
                                              isCodeSent = false;
                                            });
                                            verifyPhoneNumber();
                                          }
                                        } else {
                                          Fiberchat.toast(
                                            getTranslated(
                                                this.context, 'entervalidmob'),
                                          );
                                        }
                                      } else {
                                        Fiberchat.toast(getTranslated(
                                            this.context, 'nameem'));
                                      }
                                    },
                            ),
                          ),

                          //
                          SizedBox(
                            height: 18,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(20),
                      width: w * 0.95,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                                text:
                                    '${getTranslated(this.context, 'agree')} \n',
                                style: TextStyle(
                                    color: pickTextColorBasedOnBgColorAdvanced(
                                        Thm.isDarktheme(widget.prefs)
                                            ? fiberchatAPPBARcolorDarkMode
                                            : fiberchatAPPBARcolorLightMode),
                                    fontWeight: FontWeight.w400,
                                    fontFamily: FONTFAMILY_NAME == ''
                                        ? null
                                        : FONTFAMILY_NAME,
                                    fontSize: 14.0,
                                    height: 1.7)),
                            TextSpan(
                                text: getTranslated(this.context, 'tnc'),
                                style: TextStyle(
                                    height: 1.7,
                                    color: Thm.isDarktheme(widget.prefs)
                                        ? fiberchatSECONDARYolor
                                        : isDarkColor(
                                                    fiberchatBACKGROUNDcolorLightMode) ==
                                                true
                                            ? fiberchatWhite.withOpacity(0.6)
                                            : pickTextColorBasedOnBgColorAdvanced(
                                                    fiberchatAPPBARcolorLightMode)
                                                .withOpacity(0.95),
                                    fontWeight: FontWeight.w700,
                                    fontFamily: FONTFAMILY_NAME == ''
                                        ? null
                                        : FONTFAMILY_NAME,
                                    fontSize: 14.8),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () async {
                                    if (ConnectWithAdminApp == false) {
                                      custom_url_launcher(TERMS_CONDITION_URL);
                                    } else {
                                      final observer = Provider.of<Observer>(
                                          this.context,
                                          listen: false);
                                      if (observer.tncType == 'url') {
                                        if (observer.tnc == null) {
                                          custom_url_launcher(
                                              TERMS_CONDITION_URL);
                                        } else {
                                          custom_url_launcher(observer.tnc!);
                                        }
                                      } else if (observer.tncType == 'file') {
                                        Navigator.push(
                                            this.context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PDFViewerCachedFromUrl(
                                                prefs: widget.prefs,
                                                title: getTranslated(
                                                    this.context, 'tnc'),
                                                url: observer.tnc,
                                                isregistered: false,
                                              ),
                                            ));
                                      }
                                    }
                                  }),
                            TextSpan(
                                text: '  ○  ',
                                style: TextStyle(
                                    height: 1.7,
                                    fontFamily: FONTFAMILY_NAME == ''
                                        ? null
                                        : FONTFAMILY_NAME,
                                    color: pickTextColorBasedOnBgColorAdvanced(
                                            Thm.isDarktheme(widget.prefs)
                                                ? fiberchatAPPBARcolorDarkMode
                                                : fiberchatAPPBARcolorLightMode)
                                        .withOpacity(0.79),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11.8)),
                            TextSpan(
                                text: getTranslated(this.context, 'pp'),
                                style: TextStyle(
                                    height: 1.7,
                                    fontFamily: FONTFAMILY_NAME == ''
                                        ? null
                                        : FONTFAMILY_NAME,
                                    color: Thm.isDarktheme(widget.prefs)
                                        ? fiberchatSECONDARYolor
                                        : isDarkColor(
                                                    fiberchatBACKGROUNDcolorLightMode) ==
                                                true
                                            ? fiberchatWhite.withOpacity(0.6)
                                            : pickTextColorBasedOnBgColorAdvanced(
                                                    fiberchatAPPBARcolorLightMode)
                                                .withOpacity(0.95),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14.8),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    if (ConnectWithAdminApp == false) {
                                      custom_url_launcher(PRIVACY_POLICY_URL);
                                    } else {
                                      if (observer.privacypolicyType == 'url') {
                                        if (observer.privacypolicy == null) {
                                          custom_url_launcher(
                                              PRIVACY_POLICY_URL);
                                        } else {
                                          custom_url_launcher(
                                              observer.privacypolicy!);
                                        }
                                      } else if (observer.privacypolicyType ==
                                          'file') {
                                        Navigator.push(
                                            this.context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PDFViewerCachedFromUrl(
                                                prefs: widget.prefs,
                                                title: getTranslated(
                                                    this.context, 'pp'),
                                                url: observer.privacypolicy,
                                                isregistered: false,
                                              ),
                                            ));
                                      }
                                    }
                                  }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ));
  }

  boxShadow() {
    return BoxShadow(
      blurRadius: 3.0,
      color: pickTextColorBasedOnBgColorAdvanced(Thm.isDarktheme(widget.prefs)
              ? fiberchatAPPBARcolorDarkMode
              : fiberchatAPPBARcolorLightMode)
          .withOpacity(0.1),
      spreadRadius: 1.0,
    );
  }

  loginWidgetsendingSMScode() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [boxShadow()],
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      margin: EdgeInsets.fromLTRB(
          15, MediaQuery.of(this.context).size.height / 2.50, 16, 0),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 13,
          ),
          Padding(
            padding: EdgeInsets.all(17),
            child: Text(
              getTranslated(this.context, 'sending_code') +
                  ' $phoneCode-${_phoneNo.text}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  height: 1.5,
                  fontFamily: FONTFAMILY_NAME == '' ? null : FONTFAMILY_NAME,
                  color: fiberchatBlack),
            ),
          ),
          SizedBox(
            height: 30,
          ),
          Center(
            child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
              fiberchatSECONDARYolor,
            )),
          ),
          SizedBox(
            height: 48,
          ),
        ],
      ),
    );
  }

  loginWidgetsentSMScode() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [boxShadow()],
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      margin: EdgeInsets.fromLTRB(
          15, MediaQuery.of(this.context).size.height / 2.50, 16, 0),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 13,
          ),

          Container(
            margin: EdgeInsets.all(25),
            // height: 70,
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: PinFieldAutoFill(
                codeLength: 6,
                decoration: UnderlineDecoration(
                  bgColorBuilder:
                      FixedColorBuilder(fiberchatGrey.withOpacity(0.1)),
                  textStyle: TextStyle(
                      fontSize: 22,
                      color: fiberchatBlack,
                      fontWeight: FontWeight.bold),
                  colorBuilder:
                      FixedColorBuilder(fiberchatGrey.withOpacity(0.1)),
                ),
                currentCode: _code,
                onCodeSubmitted: (code) {
                  setState(() {
                    _code = code;
                  });
                  if (code.length == 6) {
                    setState(() {
                      currentStatus = LoginStatus.verifyingSMSCode.index;
                    });
                    handleSignIn();
                  } else {
                    Fiberchat.toast(getTranslated(this.context, 'correctotp'));
                  }
                },
                onCodeChanged: (code) {
                  if (code!.length == 6) {
                    FocusScope.of(this.context).requestFocus(FocusNode());
                    setState(() {
                      _code = code;
                    });
                  }
                },
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.all(17),
            child: Text(
              getTranslated(this.context, 'enter_verfcode') +
                  ' $phoneCode-${_phoneNo.text}',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5, color: fiberchatBlack),

              // style: TextStyle(color: Mycolors.black),
            ),
          ),
          isShowCompletedLoading == true
              ? Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          fiberchatSECONDARYolor)),
                )
              : Padding(
                  padding: EdgeInsets.fromLTRB(17, 22, 17, 5),
                  child: MySimpleButton(
                    height: 57,
                    buttoncolor: fiberchatSECONDARYolor,
                    buttontext: getTranslated(this.context, 'verify_otp'),
                    onpressed: () {
                      if (_code.length == 6) {
                        setState(() {
                          isVerifyingCode = true;
                        });
                        handleSignIn();
                      } else
                        Fiberchat.toast(
                            getTranslated(this.context, 'correctotp'));
                    },
                  ),
                ),
          SizedBox(
            height: 20,
          ),
          isShowCompletedLoading == true
              ? SizedBox(
                  height: 36,
                )
              : Consumer<TimerProvider>(
                  builder: (context, timeProvider, _) => timeProvider.wait ==
                              true &&
                          isCodeSent == true
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
                          child: RichText(
                              text: TextSpan(
                            children: [
                              TextSpan(
                                text: getTranslated(this.context, 'resendcode'),
                                style: TextStyle(
                                    fontSize: 14, color: fiberchatGrey),
                              ),
                              TextSpan(
                                text: " 00:${timeProvider.start} ",
                                style: TextStyle(
                                    fontSize: 15,
                                    color: fiberchatPRIMARYcolor,
                                    fontWeight: FontWeight.w700),
                              ),
                              TextSpan(
                                text: getTranslated(this.context, 'seconds'),
                                style: TextStyle(
                                    fontSize: 14, color: fiberchatGrey),
                              ),
                            ],
                          )),
                        )
                      : timeProvider.isActionBarShow == false
                          ? SizedBox(
                              height: 35,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                    onTap: () {
                                      final timerProvider =
                                          Provider.of<TimerProvider>(context,
                                              listen: false);
                                      timerProvider.resetTimer();
                                      unawaited(Navigator.pushReplacement(
                                          this.context,
                                          MaterialPageRoute(
                                              builder: (newContext) => Homepage(
                                                    doc: widget.doc,
                                                    currentUserNo: null,
                                                    prefs: widget.prefs,
                                                  ))));
                                    },
                                    child: Container(
                                      margin:
                                          EdgeInsets.fromLTRB(23, 12, 10, 10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.arrow_back_ios,
                                            color: fiberchatGrey,
                                            size: 16,
                                          ),
                                          Text(
                                            getTranslated(this.context, 'back'),
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: fiberchatGrey,
                                                fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    )),
                                attempt > 1
                                    ? SizedBox(
                                        height: 0,
                                      )
                                    : InkWell(
                                        onTap: () {
                                          setState(() {
                                            attempt++;

                                            timeProvider.resetTimer();
                                            isCodeSent = false;
                                            currentStatus = LoginStatus
                                                .sendingSMScode.index;
                                          });
                                          verifyPhoneNumber();
                                        },
                                        child: Container(
                                          margin:
                                              EdgeInsets.fromLTRB(10, 4, 23, 4),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.restart_alt_outlined,
                                                  color: fiberchatPRIMARYcolor),
                                              Text(
                                                ' ' +
                                                    getTranslated(
                                                        this.context, 'resend'),
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        fiberchatPRIMARYcolor,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ))
                              ],
                            ),
                ),

          SizedBox(
            height: 27,
          ),
          //
        ],
      ),
    );
  }

  loginWidgetVerifyingSMScode() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [boxShadow()],
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
      ),
      margin: EdgeInsets.fromLTRB(
          15, MediaQuery.of(this.context).size.height / 2.50, 16, 0),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 13,
          ),

          Center(
            child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(fiberchatSECONDARYolor)),
          ),

          InkWell(
            onTap: () {
              setState(() {
                // isLoading = false;
                currentStatus = LoginStatus.sendSMScode.index;
                // _phoneNo.clear();
                // _code = '';
              });
            },
            child: Padding(
                padding: EdgeInsets.fromLTRB(13, 22, 13, 8),
                child: Center(
                  child: Text(
                    getTranslated(this.context, 'Back'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: fiberchatSECONDARYolor),
                  ),
                )),
          ),
          //
          SizedBox(
            height: 18,
          ),
        ],
      ),
    );
  }

  // final _enterNumberFormKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(this.context).size.width;
    var h = MediaQuery.of(this.context).size.height;

    return Fiberchat.getNTPWrappedWidget(Scaffold(
      backgroundColor: Thm.isDarktheme(widget.prefs)
          ? fiberchatAPPBARcolorDarkMode
          : fiberchatAPPBARcolorLightMode,
      body: SingleChildScrollView(
          child: Column(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[customclippath(w, h), buildCurrentWidget(w)],
          ),
        ],
      )),
    ));
  }
}

//___CONSTRUCTORS----

class MySimpleButton extends StatefulWidget {
  final Color? buttoncolor;
  final Color? buttontextcolor;
  final Color? shadowcolor;
  final String? buttontext;
  final double? width;
  final double? height;
  final double? spacing;
  final double? borderradius;
  final Function? onpressed;

  MySimpleButton(
      {this.buttontext,
      this.buttoncolor,
      this.height,
      this.spacing,
      this.borderradius,
      this.width,
      this.buttontextcolor,
      // this.icon,
      this.onpressed,
      // this.forcewidget,
      this.shadowcolor});
  @override
  _MySimpleButtonState createState() => _MySimpleButtonState();
}

class _MySimpleButtonState extends State<MySimpleButton> {
  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(this.context).size.width;
    return GestureDetector(
        onTap: widget.onpressed as void Function()?,
        child: Container(
          alignment: Alignment.center,
          width: widget.width ?? w - 40,
          height: widget.height ?? 50,
          padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Text(
            widget.buttontext ?? getTranslated(this.context, 'submit'),
            textAlign: TextAlign.center,
            style: TextStyle(
              letterSpacing: widget.spacing ?? 2,
              fontSize: 15,
              color: widget.buttontextcolor ?? Colors.white,
            ),
          ),
          decoration: BoxDecoration(
              color: widget.buttoncolor ?? Colors.primaries as Color?,
              //gradient: LinearGradient(colors: [bgColor, whiteColor]),

              border: Border.all(
                color: widget.buttoncolor ?? fiberchatPRIMARYcolor,
              ),
              borderRadius:
                  BorderRadius.all(Radius.circular(widget.borderradius ?? 5))),
        ));
  }
}

class MobileInputWithOutline extends StatefulWidget {
  final String? initialCountryCode;
  final String? hintText;
  final double? height;
  final double? width;
  final TextEditingController? controller;
  final Color? borderColor;
  final Color? buttonTextColor;
  final Color? buttonhintTextColor;
  final TextStyle? hintStyle;
  final String? buttonText;
  final Function(PhoneNumber? phone)? onSaved;

  MobileInputWithOutline(
      {this.height,
      this.width,
      this.borderColor,
      this.buttonhintTextColor,
      this.hintStyle,
      this.buttonTextColor,
      this.onSaved,
      this.hintText,
      this.controller,
      this.initialCountryCode,
      this.buttonText});
  @override
  _MobileInputWithOutlineState createState() => _MobileInputWithOutlineState();
}

class _MobileInputWithOutlineState extends State<MobileInputWithOutline> {
  BoxDecoration boxDecoration(
      {double radius = 5,
      Color bgColor = Colors.white,
      var showShadow = false}) {
    return BoxDecoration(
        color: bgColor,
        boxShadow: showShadow
            ? [
                BoxShadow(
                    color: fiberchatSECONDARYolor,
                    blurRadius: 10,
                    spreadRadius: 2)
              ]
            : [BoxShadow(color: Colors.transparent)],
        border:
            Border.all(color: widget.borderColor ?? Colors.grey, width: 1.5),
        borderRadius: BorderRadius.all(Radius.circular(radius)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsetsDirectional.only(bottom: 7, top: 5),
          height: widget.height ?? 50,
          width: widget.width ?? MediaQuery.of(this.context).size.width,
          decoration: boxDecoration(),
          child: IntlPhoneField(
              countryCodeTextColor: Colors.black,
              searchText: "Search by Country / Region Name",
              dropDownArrowColor:
                  widget.buttonhintTextColor ?? Colors.grey[300],
              textAlign: TextAlign.left,
              initialCountryCode: widget.initialCountryCode,
              controller: widget.controller,
              style: TextStyle(
                  height: 1.35,
                  letterSpacing: 1,
                  fontSize: 16.0,
                  color: widget.buttonTextColor ?? Colors.black87,
                  fontWeight: FontWeight.bold),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.fromLTRB(3, 15, 8, 0),
                  hintText: widget.hintText ??
                      getTranslated(this.context, 'enter_mobilenumber'),
                  hintStyle: widget.hintStyle ??
                      TextStyle(
                          letterSpacing: 1,
                          height: 0.0,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w400,
                          color: widget.buttonhintTextColor ?? fiberchatGrey),
                  fillColor: Colors.white,
                  filled: true,
                  border: new OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10.0),
                    ),
                    borderSide: BorderSide.none,
                  )),
              onChanged: (phone) {
                widget.onSaved!(phone);
              },
              validator: (v) {
                return null;
              },
              onSaved: widget.onSaved),
        ),
        // Positioned(
        //     left: 110,
        //     child: Container(
        //       width: 1.5,
        //       height: widget.height ?? 48,
        //       color: widget.borderColor ?? Colors.grey,
        //     ))
      ],
    );
  }
}

class InpuTextBox extends StatefulWidget {
  final bool isDark;
  final Color? boxbcgcolor;
  final Color? boxbordercolor;
  final double? boxcornerradius;
  final double? fontsize;
  final double? boxwidth;
  final double? boxborderwidth;
  final double? boxheight;
  final EdgeInsets? forcedmargin;
  final double? letterspacing;
  final double? leftrightmargin;
  final TextEditingController? controller;
  final Function(String val)? validator;
  final Function(String? val)? onSaved;
  final Function(String val)? onchanged;
  final TextInputType? keyboardtype;
  final TextCapitalization? textCapitalization;

  final String? title;
  final String? subtitle;
  final String? hinttext;
  final String? placeholder;
  final int? maxLines;
  final int? minLines;
  final int? maxcharacters;
  final bool? isboldinput;
  final bool? obscuretext;
  final bool? autovalidate;
  final bool? disabled;
  final bool? showIconboundary;
  final Widget? sufficIconbutton;
  final List<TextInputFormatter>? inputFormatter;
  final Widget? prefixIconbutton;

  InpuTextBox(
      {this.controller,
      required this.isDark,
      this.boxbordercolor,
      this.boxheight,
      this.fontsize,
      this.leftrightmargin,
      this.letterspacing,
      this.forcedmargin,
      this.boxwidth,
      this.boxcornerradius,
      this.boxbcgcolor,
      this.hinttext,
      this.boxborderwidth,
      this.onSaved,
      this.textCapitalization,
      this.onchanged,
      this.placeholder,
      this.showIconboundary,
      this.subtitle,
      this.disabled,
      this.keyboardtype,
      this.inputFormatter,
      this.validator,
      this.title,
      this.maxLines,
      this.autovalidate,
      this.prefixIconbutton,
      this.maxcharacters,
      this.isboldinput,
      this.obscuretext,
      this.sufficIconbutton,
      this.minLines});
  @override
  _InpuTextBoxState createState() => _InpuTextBoxState();
}

class _InpuTextBoxState extends State<InpuTextBox> {
  bool isobscuretext = false;
  @override
  void initState() {
    super.initState();
    setState(() {
      isobscuretext = widget.obscuretext ?? false;
    });
  }

  changeobscure() {
    setState(() {
      isobscuretext = !isobscuretext;
    });
  }

  @override
  Widget build(BuildContext context) {
    double w = MediaQuery.of(this.context).size.width;
    return Align(
      child: Container(
        margin: EdgeInsets.fromLTRB(
            widget.leftrightmargin ?? 8, 5, widget.leftrightmargin ?? 8, 5),
        width: widget.boxwidth ?? w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              // color: Colors.white,
              height: widget.boxheight ?? 50,
              // decoration: BoxDecoration(
              //     color: widget.boxbcgcolor ?? Colors.white,
              //     border: Border.all(
              //         color:
              //             widget.boxbordercolor ?? Mycolors.grey.withOpacity(0.2),
              //         style: BorderStyle.solid,
              //         width: 1.8),
              //     borderRadius: BorderRadius.all(
              //         Radius.circular(widget.boxcornerradius ?? 5))),
              child: TextFormField(
                minLines: widget.minLines ?? null,
                maxLines: widget.maxLines ?? 1,
                controller: widget.controller ?? null,
                obscureText: isobscuretext,
                onSaved: widget.onSaved ?? (val) {},
                readOnly: widget.disabled ?? false,
                onChanged: widget.onchanged ?? (val) {},
                maxLength: widget.maxcharacters ?? null,
                validator:
                    widget.validator as String? Function(String?)? ?? null,
                keyboardType: widget.keyboardtype ?? null,
                autovalidateMode: widget.autovalidate == true
                    ? AutovalidateMode.always
                    : AutovalidateMode.disabled,
                inputFormatters: widget.inputFormatter ?? [],
                textCapitalization:
                    widget.textCapitalization ?? TextCapitalization.sentences,
                style: TextStyle(
                  letterSpacing: widget.letterspacing ?? null,
                  fontSize: widget.fontsize ?? 15,
                  fontWeight: widget.isboldinput == true
                      ? FontWeight.w600
                      : FontWeight.w400,
                  // fontFamily:
                  //     widget.isboldinput == true ? 'NotoBold' : 'NotoRegular',
                  color: widget.isDark == true ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                    prefixIcon: widget.prefixIconbutton != null
                        ? Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                    width: widget.boxborderwidth ?? 1.5,
                                    color: widget.showIconboundary == true ||
                                            widget.showIconboundary == null
                                        ? Colors.grey.withOpacity(0.3)
                                        : Colors.transparent),
                              ),
                              // color: Colors.white,
                            ),
                            margin: EdgeInsets.only(
                                left: 2, right: 5, top: 2, bottom: 2),
                            // height: 45,
                            alignment: Alignment.center,
                            width: 50,
                            child: widget.prefixIconbutton != null
                                ? widget.prefixIconbutton
                                : null)
                        : null,
                    suffixIcon: widget.sufficIconbutton != null ||
                            widget.obscuretext == true
                        ? Container(
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                    width: widget.boxborderwidth ?? 1.5,
                                    color: widget.showIconboundary == true ||
                                            widget.showIconboundary == null
                                        ? Colors.grey.withOpacity(0.3)
                                        : Colors.transparent),
                              ),
                              // color: Colors.white,
                            ),
                            margin: EdgeInsets.only(
                                left: 2, right: 5, top: 2, bottom: 2),
                            // height: 45,
                            alignment: Alignment.center,
                            width: 50,
                            child: widget.sufficIconbutton != null
                                ? widget.sufficIconbutton
                                : widget.obscuretext == true
                                    ? IconButton(
                                        icon: Icon(
                                            isobscuretext == true
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: Colors.blueGrey),
                                        onPressed: () {
                                          changeobscure();
                                        })
                                    : null)
                        : null,
                    filled: true,
                    fillColor: widget.boxbcgcolor ??
                        (widget.isDark
                            ? Colors.grey.withOpacity(0.2)
                            : Colors.white),
                    enabledBorder: OutlineInputBorder(
                      // width: 0.0 produces a thin "hairline" border
                      borderRadius:
                          BorderRadius.circular(widget.boxcornerradius ?? 1),
                      borderSide: BorderSide(
                          color: widget.boxbordercolor ??
                              Colors.grey.withOpacity(0.2),
                          width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      // width: 0.0 produces a thin "hairline" border
                      borderRadius:
                          BorderRadius.circular(widget.boxcornerradius ?? 1),
                      borderSide:
                          BorderSide(color: fiberchatSECONDARYolor, width: 1.5),
                    ),
                    border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(widget.boxcornerradius ?? 1),
                        borderSide: BorderSide(color: Colors.grey)),
                    contentPadding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                    // labelText: 'Password',
                    hintText: widget.hinttext ?? '',
                    // fillColor: widget.boxbcgcolor ?? Colors.white,
                    hintStyle: TextStyle(
                        letterSpacing: widget.letterspacing ?? 1.5,
                        color: fiberchatGrey,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w400)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
