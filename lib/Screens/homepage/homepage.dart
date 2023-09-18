//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fiberchat/Configs/Dbkeys.dart';
import 'package:fiberchat/Configs/Dbpaths.dart';
import 'package:fiberchat/Configs/optional_constants.dart';
import 'package:fiberchat/Screens/Broadcast/AddContactsToBroadcast.dart';
import 'package:fiberchat/Screens/Groups/AddContactsToGroup.dart';
import 'package:fiberchat/Screens/SettingsOption/settingsOption.dart';
import 'package:fiberchat/Screens/homepage/Setupdata.dart';
import 'package:fiberchat/Screens/notifications/AllNotifications.dart';
import 'package:fiberchat/Screens/recent_chats/RecentChatsWithoutLastMessage.dart';
import 'package:fiberchat/Screens/search_chats/SearchRecentChat.dart';
import 'package:fiberchat/Screens/sharing_intent/SelectContactToShare.dart';
import 'package:fiberchat/Screens/splash_screen/splash_screen.dart';
import 'package:fiberchat/Screens/status/status.dart';
import 'package:fiberchat/Services/Providers/SmartContactProviderWithLocalStoreData.dart';
import 'package:fiberchat/Services/Providers/Observer.dart';
import 'package:fiberchat/Services/Providers/StatusProvider.dart';
import 'package:fiberchat/Services/Providers/call_history_provider.dart';
import 'package:fiberchat/Services/localization/language.dart';
import 'package:fiberchat/Utils/color_detector.dart';
import 'package:fiberchat/Utils/custom_url_launcher.dart';
import 'package:fiberchat/Utils/error_codes.dart';
import 'package:fiberchat/Utils/phonenumberVariantsGenerator.dart';
import 'package:fiberchat/Utils/theme_management.dart';
import 'package:fiberchat/widgets/DynamicBottomSheet/dynamic_modal_bottomsheet.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as local;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Screens/auth_screens/login.dart';
import 'package:fiberchat/Services/Providers/currentchat_peer.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Screens/profile_settings/profileSettings.dart';
import 'package:fiberchat/main.dart';
import 'package:fiberchat/Screens/recent_chats/RecentsChats.dart';
import 'package:fiberchat/Screens/call_history/callhistory.dart';
import 'package:fiberchat/Models/DataModel.dart';
import 'package:fiberchat/Services/Providers/user_provider.dart';
import 'package:fiberchat/Screens/calling_screen/pickup_layout.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fiberchat/Utils/unawaited.dart';

class Homepage extends StatefulWidget {
  Homepage(
      {required this.currentUserNo,
      required this.prefs,
      required this.doc,
      this.isShowOnlyCircularSpin = false,
      key})
      : super(key: key);
  final String? currentUserNo;
  final DocumentSnapshot<Map<String, dynamic>> doc;
  final bool? isShowOnlyCircularSpin;
  final SharedPreferences prefs;
  @override
  State createState() => new HomepageState(doc: this.doc);
}

class HomepageState extends State<Homepage>
    with
        WidgetsBindingObserver,
        AutomaticKeepAliveClientMixin,
        TickerProviderStateMixin {
  HomepageState({Key? key, doc}) {
    _filter.addListener(() {
      _userQuery.add(_filter.text.isEmpty ? '' : _filter.text);
    });
  }
  TabController? controllerIfcallallowed;
  TabController? controllerIfcallNotallowed;
  late StreamSubscription _intentDataStreamSubscription;
  List<SharedMediaFile>? _sharedFiles = [];
  String? _sharedText;
  @override
  bool get wantKeepAlive => true;

  bool isFetching = true;
  List phoneNumberVariants = [];
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)
      setIsActive();
    else
      setLastSeen();
  }

  void setIsActive() async {
    if (widget.currentUserNo != null)
      await FirebaseFirestore.instance
          .collection(DbPaths.collectionusers)
          .doc(widget.currentUserNo)
          .update(
        {
          Dbkeys.lastSeen: true,
          Dbkeys.lastOnline: DateTime.now().millisecondsSinceEpoch
        },
      );
  }

  void setLastSeen() async {
    if (widget.currentUserNo != null)
      await FirebaseFirestore.instance
          .collection(DbPaths.collectionusers)
          .doc(widget.currentUserNo)
          .update(
        {Dbkeys.lastSeen: DateTime.now().millisecondsSinceEpoch},
      );
  }

  final TextEditingController _filter = new TextEditingController();
  bool isAuthenticating = false;

  StreamSubscription? spokenSubscription;
  List<StreamSubscription> unreadSubscriptions =
      List.from(<StreamSubscription>[]);

  List<StreamController> controllers = List.from(<StreamController>[]);
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  String? deviceid;
  var mapDeviceInfo = {};
  String? maintainanceMessage;
  bool isNotAllowEmulator = false;
  bool? isblockNewlogins = false;
  bool? isApprovalNeededbyAdminForNewUser = false;
  String? accountApprovalMessage = 'Account Approved';
  String? accountstatus;
  String? accountactionmessage;
  String? userPhotourl;
  String? userFullname;

  @override
  void initState() {
    listenToSharingintent();
    listenToNotification();
    super.initState();
    getSignedInUserOrRedirect();
    setdeviceinfo();
    registerNotification();

    controllerIfcallallowed =
        TabController(length: IsShowSearchTab ? 4 : 3, vsync: this);
    controllerIfcallallowed!.index = IsShowSearchTab ? 1 : 0;
    controllerIfcallNotallowed =
        TabController(length: IsShowSearchTab ? 3 : 2, vsync: this);
    controllerIfcallNotallowed!.index = IsShowSearchTab ? 1 : 0;

    Fiberchat.internetLookUp();
    WidgetsBinding.instance.addObserver(this);

    LocalAuthentication().canCheckBiometrics.then((res) {
      if (res) biometricEnabled = true;
    });
    getModel();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      controllerIfcallallowed!.addListener(() {
        if (IsShowSearchTab == true) {
          if (controllerIfcallallowed!.index == 2) {
            final statusProvider =
                Provider.of<StatusProvider>(context, listen: false);
            final contactsProvider =
                Provider.of<SmartContactProviderWithLocalStoreData>(context,
                    listen: false);
            statusProvider.searchContactStatus(
                widget.currentUserNo!,
                FutureGroup(),
                contactsProvider.alreadyJoinedSavedUsersPhoneNameAsInServer);
          }
        } else {
          if (controllerIfcallallowed!.index == 1) {
            final statusProvider =
                Provider.of<StatusProvider>(context, listen: false);
            final contactsProvider =
                Provider.of<SmartContactProviderWithLocalStoreData>(context,
                    listen: false);
            statusProvider.searchContactStatus(
                widget.currentUserNo!,
                FutureGroup(),
                contactsProvider.alreadyJoinedSavedUsersPhoneNameAsInServer);
          }
        }
      });
      controllerIfcallNotallowed!.addListener(() {
        if (IsShowSearchTab == true) {
          if (controllerIfcallNotallowed!.index == 2) {
            final statusProvider =
                Provider.of<StatusProvider>(context, listen: false);
            final contactsProvider =
                Provider.of<SmartContactProviderWithLocalStoreData>(context,
                    listen: false);
            statusProvider.searchContactStatus(
                widget.currentUserNo!,
                FutureGroup(),
                contactsProvider.alreadyJoinedSavedUsersPhoneNameAsInServer);
          }
        } else {
          if (controllerIfcallNotallowed!.index == 1) {
            final statusProvider =
                Provider.of<StatusProvider>(context, listen: false);
            final contactsProvider =
                Provider.of<SmartContactProviderWithLocalStoreData>(context,
                    listen: false);
            statusProvider.searchContactStatus(
                widget.currentUserNo!,
                FutureGroup(),
                contactsProvider.alreadyJoinedSavedUsersPhoneNameAsInServer);
          }
        }
      });
    });
  }

  // detectLocale() async {
  //   await Devicelocale.currentLocale.then((locale) async {
  //     if (locale == 'ja_JP' &&
  //         (widget.prefs.getBool('islanguageselected') == false ||
  //             widget.prefs.getBool('islanguageselected') == null)) {
  //       Locale _locale = await setLocale('ja');
  //       FiberchatWrapper.setLocale(context, _locale);
  //       setState(() {});
  //     }
  //   }).catchError((onError) {
  //     Fiberchat.toast(
  //       'Error occured while fetching Locale :$onError',
  //     );
  //   });
  // }

  incrementSessionCount(String myphone) async {
    final StatusProvider statusProvider =
        Provider.of<StatusProvider>(context, listen: false);
    final SmartContactProviderWithLocalStoreData contactsProvider =
        Provider.of<SmartContactProviderWithLocalStoreData>(context,
            listen: false);
    final FirestoreDataProviderCALLHISTORY firestoreDataProviderCALLHISTORY =
        Provider.of<FirestoreDataProviderCALLHISTORY>(context, listen: false);
    await FirebaseFirestore.instance
        .collection(DbPaths.collectiondashboard)
        .doc(DbPaths.docuserscount)
        .set(
            Platform.isAndroid
                ? {
                    Dbkeys.totalvisitsANDROID: FieldValue.increment(1),
                  }
                : {
                    Dbkeys.totalvisitsIOS: FieldValue.increment(1),
                  },
            SetOptions(merge: true));
    await FirebaseFirestore.instance
        .collection(DbPaths.collectionusers)
        .doc(widget.currentUserNo)
        .set(
            Platform.isAndroid
                ? {
                    Dbkeys.isNotificationStringsMulitilanguageEnabled: true,
                    Dbkeys.notificationStringsMap:
                        getTranslateNotificationStringsMap(this.context),
                    Dbkeys.totalvisitsANDROID: FieldValue.increment(1),
                  }
                : {
                    Dbkeys.isNotificationStringsMulitilanguageEnabled: true,
                    Dbkeys.notificationStringsMap:
                        getTranslateNotificationStringsMap(this.context),
                    Dbkeys.totalvisitsIOS: FieldValue.increment(1),
                  },
            SetOptions(merge: true));
    firestoreDataProviderCALLHISTORY.fetchNextData(
        'CALLHISTORY',
        FirebaseFirestore.instance
            .collection(DbPaths.collectionusers)
            .doc(widget.currentUserNo)
            .collection(DbPaths.collectioncallhistory)
            .orderBy('TIME', descending: true)
            .limit(10),
        true);
    if (OnlyPeerWhoAreSavedInmyContactCanMessageOrCallMe == false) {
      await contactsProvider.fetchContacts(
          context, _cachedModel, myphone, widget.prefs, false,
          currentuserphoneNumberVariants: phoneNumberVariants);
    }

    //  await statusProvider.searchContactStatus(
    //       myphone, contactsProvider.joinedUserPhoneStringAsInServer);
    statusProvider.triggerDeleteMyExpiredStatus(myphone);
    statusProvider.triggerDeleteOtherUsersExpiredStatus(myphone);
    if (_sharedFiles!.length > 0 || _sharedText != null) {
      triggerSharing();
    }
  }

  triggerSharing() {
    final observer = Provider.of<Observer>(this.context, listen: false);
    if (_sharedText != null) {
      Navigator.push(
          context,
          new MaterialPageRoute(
              builder: (context) => new SelectContactToShare(
                  prefs: widget.prefs,
                  model: _cachedModel!,
                  currentUserNo: widget.currentUserNo,
                  sharedFiles: _sharedFiles!,
                  sharedText: _sharedText)));
    } else if (_sharedFiles != null) {
      if (_sharedFiles!.length > observer.maxNoOfFilesInMultiSharing) {
        Fiberchat.toast(getTranslated(context, 'maxnooffiles') +
            ' ' +
            '${observer.maxNoOfFilesInMultiSharing}');
      } else {
        Navigator.push(
            context,
            new MaterialPageRoute(
                builder: (context) => new SelectContactToShare(
                    prefs: widget.prefs,
                    model: _cachedModel!,
                    currentUserNo: widget.currentUserNo,
                    sharedFiles: _sharedFiles!,
                    sharedText: _sharedText)));
      }
    }
  }

  listenToSharingintent() {
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream()
        .listen((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
      });
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      setState(() {
        _sharedFiles = value;
      });
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      setState(() {
        _sharedText = value;
      });
    }, onError: (err) {
      debugPrint("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String? value) {
      setState(() {
        _sharedText = value;
      });
    });
  }

  unsubscribeToNotification(String? userphone) async {
    if (userphone != null) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(
          '${userphone.replaceFirst(new RegExp(r'\+'), '')}');
    }

    await FirebaseMessaging.instance
        .unsubscribeFromTopic(Dbkeys.topicUSERS)
        .catchError((err) {
      debugPrint(err.toString());
    });
    await FirebaseMessaging.instance
        .unsubscribeFromTopic(Platform.isAndroid
            ? Dbkeys.topicUSERSandroid
            : Platform.isIOS
                ? Dbkeys.topicUSERSios
                : Dbkeys.topicUSERSweb)
        .catchError((err) {
      debugPrint(err.toString());
    });
  }

  void registerNotification() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      provisional: false,
      sound: true,
    );
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

  getuid(BuildContext context) {
    final UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    userProvider.getUserDetails(widget.currentUserNo);
  }

  logout(BuildContext context) async {
    final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
    await firebaseAuth.signOut();

    await widget.prefs.clear();

    FlutterSecureStorage storage = new FlutterSecureStorage();
    // ignore: await_only_futures
    await storage.delete;
    if (widget.currentUserNo != null) {
      await FirebaseFirestore.instance
          .collection(DbPaths.collectionusers)
          .doc(widget.currentUserNo)
          .update({
        Dbkeys.notificationTokens: [],
      });
    }

    await widget.prefs.setBool(Dbkeys.isTokenGenerated, false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (BuildContext context) => FiberchatWrapper(),
      ),
      (Route route) => false,
    );
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
    controllers.forEach((controller) {
      controller.close();
    });
    _filter.dispose();
    spokenSubscription?.cancel();
    _userQuery.close();
    cancelUnreadSubscriptions();
    setLastSeen();

    _intentDataStreamSubscription.cancel();
  }

  void cancelUnreadSubscriptions() {
    unreadSubscriptions.forEach((subscription) {
      subscription.cancel();
    });
  }

  void listenToNotification() async {
    //FOR ANDROID & IOS  background notification is handled at the very top of main.dart ------

    //ANDROID & iOS  OnMessage callback
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // ignore: unnecessary_null_comparison
      flutterLocalNotificationsPlugin..cancelAll();

      if (message.data['title'] != 'Call Ended' &&
          message.data['title'] != 'Missed Call' &&
          message.data['title'] != 'You have new message(s)' &&
          message.data['title'] != 'Incoming Video Call...' &&
          message.data['title'] != 'Incoming Audio Call...' &&
          message.data['title'] != 'Incoming Call ended' &&
          message.data['title'] != 'New message in Group') {
        Fiberchat.toast(getTranslated(this.context, 'newnotifications'));
      } else {
        if (message.data['title'] == 'New message in Group') {
          // var currentpeer =
          //     Provider.of<CurrentChatPeer>(this.context, listen: false);
          // if (currentpeer.groupChatId != message.data['groupid']) {
          //   flutterLocalNotificationsPlugin..cancelAll();

          //   showOverlayNotification((context) {
          //     return Card(
          //       margin: const EdgeInsets.symmetric(horizontal: 4),
          //       child: SafeArea(
          //         child: ListTile(
          //           title: Text(
          //             message.data['titleMultilang'],
          //             maxLines: 1,
          //             overflow: TextOverflow.ellipsis,
          //           ),
          //           subtitle: Text(
          //             message.data['bodyMultilang'],
          //             maxLines: 2,
          //             overflow: TextOverflow.ellipsis,
          //           ),
          //           trailing: IconButton(
          //               icon: Icon(Icons.close),
          //               onPressed: () {
          //                 OverlaySupportEntry.of(context)!.dismiss();
          //               }),
          //         ),
          //       ),
          //     );
          //   }, duration: Duration(milliseconds: 2000));
          // }
        } else if (message.data['title'] == 'Call Ended') {
          flutterLocalNotificationsPlugin..cancelAll();
        } else {
          if (message.data['title'] == 'Incoming Audio Call...' ||
              message.data['title'] == 'Incoming Video Call...') {
            final data = message.data;
            final title = data['title'];
            final body = data['body'];
            final titleMultilang = data['titleMultilang'];
            final bodyMultilang = data['bodyMultilang'];
            await showNotificationWithDefaultSound(
                title, body, titleMultilang, bodyMultilang);
          } else if (message.data['title'] == 'You have new message(s)') {
            var currentpeer =
                Provider.of<CurrentChatPeer>(this.context, listen: false);
            if (currentpeer.peerid != message.data['peerid']) {
              // FlutterRingtonePlayer.playNotification();
              showOverlayNotification((context) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: SafeArea(
                    child: ListTile(
                      title: Text(
                        message.data['titleMultilang'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        message.data['bodyMultilang'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            OverlaySupportEntry.of(context)!.dismiss();
                          }),
                    ),
                  ),
                );
              }, duration: Duration(milliseconds: 2000));
            }
          } else {
            showOverlayNotification((context) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: SafeArea(
                  child: ListTile(
                    leading: message.data.containsKey("image")
                        ? null
                        : message.data["image"] == null
                            ? SizedBox()
                            : Image.network(
                                message.data['image'],
                                width: 50,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                    title: Text(
                      message.data['titleMultilang'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      message.data['bodyMultilang'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          OverlaySupportEntry.of(context)!.dismiss();
                        }),
                  ),
                ),
              );
            }, duration: Duration(milliseconds: 2000));
          }
        }
      }
    });
    //ANDROID & iOS  onMessageOpenedApp callback
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      flutterLocalNotificationsPlugin..cancelAll();
      Map<String, dynamic> notificationData = message.data;
      AndroidNotification? android = message.notification?.android;
      if (android != null) {
        if (notificationData['title'] == 'Call Ended') {
          flutterLocalNotificationsPlugin..cancelAll();
        } else if (notificationData['title'] != 'Call Ended' &&
            notificationData['title'] != 'You have new message(s)' &&
            notificationData['title'] != 'Missed Call' &&
            notificationData['title'] != 'Incoming Video Call...' &&
            notificationData['title'] != 'Incoming Audio Call...' &&
            notificationData['title'] != 'Incoming Call ended' &&
            notificationData['title'] != 'New message in Group') {
          flutterLocalNotificationsPlugin..cancelAll();

          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => AllNotifications(
                        prefs: widget.prefs,
                      )));
        } else {
          flutterLocalNotificationsPlugin..cancelAll();
        }
      }
    });
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        flutterLocalNotificationsPlugin..cancelAll();
        Map<String, dynamic>? notificationData = message.data;
        if (notificationData['title'] != 'Call Ended' &&
            notificationData['title'] != 'You have new message(s)' &&
            notificationData['title'] != 'Missed Call' &&
            notificationData['title'] != 'Incoming Video Call...' &&
            notificationData['title'] != 'Incoming Audio Call...' &&
            notificationData['title'] != 'Incoming Call ended' &&
            notificationData['title'] != 'New message in Group') {
          flutterLocalNotificationsPlugin..cancelAll();

          Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => AllNotifications(
                        prefs: widget.prefs,
                      )));
        }
      }
    });
  }

  DataModel? _cachedModel;
  bool showHidden = false, biometricEnabled = false;

  DataModel? getModel() {
    _cachedModel ??= DataModel(widget.currentUserNo);
    return _cachedModel;
  }

  getSignedInUserOrRedirect() async {
    try {
      setState(() {
        isblockNewlogins = widget.doc.data()![Dbkeys.isblocknewlogins];
        isApprovalNeededbyAdminForNewUser =
            widget.doc[Dbkeys.isaccountapprovalbyadminneeded];
        accountApprovalMessage = widget.doc[Dbkeys.accountapprovalmessage];
      });
      if (widget.doc.data()![Dbkeys.isemulatorallowed] == false &&
          mapDeviceInfo[Dbkeys.deviceInfoISPHYSICAL] == false) {
        setState(() {
          isNotAllowEmulator = true;
        });
      } else {
        if (widget.doc[Platform.isAndroid
                ? Dbkeys.isappunderconstructionandroid
                : Platform.isIOS
                    ? Dbkeys.isappunderconstructionios
                    : Dbkeys.isappunderconstructionweb] ==
            true) {
          await unsubscribeToNotification(widget.currentUserNo);
          maintainanceMessage = widget.doc[Dbkeys.maintainancemessage];
          setState(() {});
        } else {
          final PackageInfo info = await PackageInfo.fromPlatform();
          widget.prefs.setString('app_version', info.version);

          int currentAppVersionInPhone = int.tryParse(info.version
                      .trim()
                      .split(".")[0]
                      .toString()
                      .padLeft(3, '0') +
                  info.version.trim().split(".")[1].toString().padLeft(3, '0') +
                  info.version
                      .trim()
                      .split(".")[2]
                      .toString()
                      .padLeft(3, '0')) ??
              0;
          int currentNewAppVersionInServer =
              int.tryParse(widget.doc[Platform.isAndroid
                              ? Dbkeys.latestappversionandroid
                              : Platform.isIOS
                                  ? Dbkeys.latestappversionios
                                  : Dbkeys.latestappversionweb]
                          .trim()
                          .split(".")[0]
                          .toString()
                          .padLeft(3, '0') +
                      widget.doc[Platform.isAndroid
                              ? Dbkeys.latestappversionandroid
                              : Platform.isIOS
                                  ? Dbkeys.latestappversionios
                                  : Dbkeys.latestappversionweb]
                          .trim()
                          .split(".")[1]
                          .toString()
                          .padLeft(3, '0') +
                      widget.doc[Platform.isAndroid
                              ? Dbkeys.latestappversionandroid
                              : Platform.isIOS
                                  ? Dbkeys.latestappversionios
                                  : Dbkeys.latestappversionweb]
                          .trim()
                          .split(".")[2]
                          .toString()
                          .padLeft(3, '0')) ??
                  0;
          if (currentAppVersionInPhone < currentNewAppVersionInServer) {
            showDialog<String>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                String title = getTranslated(context, 'updateavl');
                String message = getTranslated(context, 'updateavlmsg');

                String btnLabel = getTranslated(context, 'updatnow');

                return new WillPopScope(
                    onWillPop: () async => false,
                    child: AlertDialog(
                      backgroundColor: Thm.isDarktheme(widget.prefs)
                          ? fiberchatDIALOGColorDarkMode
                          : fiberchatDIALOGColorLightMode,
                      title: Text(
                        title,
                        style: TextStyle(
                          color: pickTextColorBasedOnBgColorAdvanced(
                              Thm.isDarktheme(widget.prefs)
                                  ? fiberchatDIALOGColorDarkMode
                                  : fiberchatDIALOGColorLightMode),
                        ),
                      ),
                      content: Text(message),
                      actions: <Widget>[
                        TextButton(
                            child: Text(
                              btnLabel,
                              style: TextStyle(color: fiberchatPRIMARYcolor),
                            ),
                            onPressed: () => custom_url_launcher(
                                widget.doc[Platform.isAndroid
                                    ? Dbkeys.newapplinkandroid
                                    : Platform.isIOS
                                        ? Dbkeys.newapplinkios
                                        : Dbkeys.newapplinkweb])),
                      ],
                    ));
              },
            );
          } else {
            final observer = Provider.of<Observer>(this.context, listen: false);

            observer.setObserver(
              getuserAppSettingsDoc: widget.doc,
              getisWebCompatible:
                  widget.doc.data()!.containsKey('is_web_compatible')
                      ? widget.doc.data()!['is_web_compatible']
                      : false,
              getandroidapplink: widget.doc[Dbkeys.newapplinkandroid],
              getiosapplink: widget.doc[Dbkeys.newapplinkios],
              getisadmobshow: widget.doc[Dbkeys.isadmobshow],
              getismediamessagingallowed:
                  widget.doc[Dbkeys.ismediamessageallowed],
              getistextmessagingallowed:
                  widget.doc[Dbkeys.istextmessageallowed],
              getiscallsallowed: widget.doc[Dbkeys.iscallsallowed],
              gettnc: widget.doc[Dbkeys.tnc],
              gettncType: widget.doc[Dbkeys.tncTYPE],
              getprivacypolicy: widget.doc[Dbkeys.privacypolicy],
              getprivacypolicyType: widget.doc[Dbkeys.privacypolicyTYPE],
              getis24hrsTimeformat: widget.doc[Dbkeys.is24hrsTimeformat],
              getmaxFileSizeAllowedInMB:
                  widget.doc[Dbkeys.maxFileSizeAllowedInMB],
              getisPercentProgressShowWhileUploading:
                  widget.doc[Dbkeys.isPercentProgressShowWhileUploading],
              getisCallFeatureTotallyHide:
                  widget.doc[Dbkeys.isCallFeatureTotallyHide],
              getgroupMemberslimit: widget.doc[Dbkeys.groupMemberslimit],
              getbroadcastMemberslimit:
                  widget.doc[Dbkeys.broadcastMemberslimit],
              getstatusDeleteAfterInHours:
                  widget.doc[Dbkeys.statusDeleteAfterInHours],
              getfeedbackEmail: widget.doc[Dbkeys.feedbackEmail],
              getisLogoutButtonShowInSettingsPage:
                  widget.doc[Dbkeys.isLogoutButtonShowInSettingsPage],
              getisAllowCreatingGroups:
                  widget.doc[Dbkeys.isAllowCreatingGroups],
              getisAllowCreatingBroadcasts:
                  widget.doc[Dbkeys.isAllowCreatingBroadcasts],
              getisAllowCreatingStatus:
                  widget.doc[Dbkeys.isAllowCreatingStatus],
              getmaxNoOfFilesInMultiSharing:
                  widget.doc[Dbkeys.maxNoOfFilesInMultiSharing],
              getmaxNoOfContactsSelectForForward:
                  widget.doc[Dbkeys.maxNoOfContactsSelectForForward],
              getappShareMessageStringAndroid:
                  widget.doc[Dbkeys.appShareMessageStringAndroid],
              getappShareMessageStringiOS:
                  widget.doc[Dbkeys.appShareMessageStringiOS],
              getisCustomAppShareLink: widget.doc[Dbkeys.isCustomAppShareLink],
            );

            if (widget.currentUserNo == null || widget.currentUserNo!.isEmpty) {
              // await unsubscribeToNotification(widget.currentUserNo);

              unawaited(Navigator.pushReplacement(
                  context,
                  new MaterialPageRoute(
                      builder: (context) => new LoginScreen(
                            prefs: widget.prefs,
                            accountApprovalMessage: accountApprovalMessage,
                            isaccountapprovalbyadminneeded:
                                isApprovalNeededbyAdminForNewUser,
                            isblocknewlogins: isblockNewlogins,
                            title: getTranslated(context, 'signin'),
                            doc: widget.doc,
                          ))));
            } else {
              await FirebaseFirestore.instance
                  .collection(DbPaths.collectionusers)
                  .doc(widget.currentUserNo ?? widget.currentUserNo)
                  .get()
                  .then((userDoc) async {
                if (deviceid != userDoc[Dbkeys.currentDeviceID] ||
                    !userDoc.data()!.containsKey(Dbkeys.currentDeviceID)) {
                  if (ConnectWithAdminApp == true) {
                    await unsubscribeToNotification(widget.currentUserNo);
                  }
                  await logout(context);
                } else {
                  if (!userDoc.data()!.containsKey(Dbkeys.accountstatus)) {
                    await logout(context);
                  } else if (userDoc[Dbkeys.accountstatus] !=
                      Dbkeys.sTATUSallowed) {
                    if (userDoc[Dbkeys.accountstatus] == Dbkeys.sTATUSdeleted) {
                      setState(() {
                        accountstatus = userDoc[Dbkeys.accountstatus];
                        accountactionmessage = userDoc[Dbkeys.actionmessage];
                      });
                    } else {
                      setState(() {
                        accountstatus = userDoc[Dbkeys.accountstatus];
                        accountactionmessage = userDoc[Dbkeys.actionmessage];
                      });
                    }
                  } else {
                    setState(() {
                      userFullname = userDoc[Dbkeys.nickname];
                      userPhotourl = userDoc[Dbkeys.photoUrl];
                      phoneNumberVariants = phoneNumberVariantsList(
                          countrycode: userDoc[Dbkeys.countryCode],
                          phonenumber: userDoc[Dbkeys.phoneRaw]);
                      isFetching = false;
                    });
                    getuid(context);
                    setIsActive();

                    incrementSessionCount(userDoc[Dbkeys.phone]);
                  }
                }
              });
            }
          }
        }
      }
    } catch (e) {
      showERRORSheet(this.context, "", message: e.toString());
    }
  }

  StreamController<String> _userQuery =
      new StreamController<String>.broadcast();
  void _changeLanguage(Language language) async {
    Locale _locale = await setLocale(language.languageCode);
    FiberchatWrapper.setLocale(context, _locale);
    if (widget.currentUserNo != null) {
      Future.delayed(const Duration(milliseconds: 800), () {
        FirebaseFirestore.instance
            .collection(DbPaths.collectionusers)
            .doc(widget.currentUserNo)
            .update({
          Dbkeys.notificationStringsMap:
              getTranslateNotificationStringsMap(this.context),
        });
      });
    }
    setState(() {
      // seletedlanguage = language;
    });

    await widget.prefs.setBool('islanguageselected', true);
  }

  DateTime? currentBackPressTime = DateTime.now();
  Future<bool> onWillPop() {
    DateTime now = DateTime.now();
    if (now.difference(currentBackPressTime!) > Duration(seconds: 3)) {
      currentBackPressTime = now;
      Fiberchat.toast(getTranslated(this.context, 'doubletaptogoback'));
      return Future.value(false);
    } else {
      if (!isAuthenticating) setLastSeen();
      return Future.value(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final observer = Provider.of<Observer>(context, listen: true);
    return isNotAllowEmulator == true
        ? errorScreen(
            'Emulator Not Allowed.', ' Please use any real device & Try again.')
        : accountstatus != null
            ? errorScreen(accountstatus, accountactionmessage)
            : ConnectWithAdminApp == true && maintainanceMessage != null
                ? errorScreen('App Under maintainance', maintainanceMessage)
                : ConnectWithAdminApp == true && isFetching == true
                    ? Splashscreen(
                        isShowOnlySpinner: widget.isShowOnlyCircularSpin,
                      )
                    : PickupLayout(
                        prefs: widget.prefs,
                        scaffold: Fiberchat.getNTPWrappedWidget(WillPopScope(
                          onWillPop: onWillPop,
                          child: Scaffold(
                              backgroundColor: Thm.isDarktheme(widget.prefs)
                                  ? fiberchatBACKGROUNDcolorDarkMode
                                  : fiberchatBACKGROUNDcolorLightMode,
                              appBar: AppBar(
                                  elevation: 0.4,
                                  backgroundColor: Thm.isDarktheme(widget.prefs)
                                      ? fiberchatAPPBARcolorDarkMode
                                      : fiberchatAPPBARcolorLightMode,
                                  title: IsShowAppLogoInHomepage == false
                                      ? Text(
                                          Appname,
                                          style: TextStyle(
                                              color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                      .isDarktheme(widget.prefs)
                                                  ? fiberchatAPPBARcolorDarkMode
                                                  : fiberchatAPPBARcolorLightMode),
                                              fontSize: 20.0,
                                              fontFamily:
                                                  FONTFAMILY_NAME_ONLY_LOGO ==
                                                          ''
                                                      ? null
                                                      : FONTFAMILY_NAME_ONLY_LOGO),
                                        )
                                      : Align(
                                          alignment: Alignment.centerLeft,
                                          child: Image.asset(
                                              !Thm.isDarktheme(widget.prefs)
                                                  ? isDarkColor(
                                                          fiberchatAPPBARcolorLightMode)
                                                      ? AppLogoPathDarkModeLogo
                                                      : AppLogoPathLightModeLogo
                                                  : AppLogoPathDarkModeLogo,
	height: 80,
                                              width: 140,
	fit: BoxFit.fitHeight),
                                        ),
                                  titleSpacing:
                                      IsShowAppLogoInHomepage ? 10 : 17,
                                  actions: <Widget>[
//
                                    if (IsShowLanguageChangeButtonInSettings ==
                                        false)
                                      Language.languageList().length < 2 ||
                                              IsShowLanguageChangeButtonInLoginAndHome ==
                                                  false
                                          ? SizedBox()
                                          : InkWell(
                                              onTap: () {
                                                showDynamicModalBottomSheet(
                                                    isdark: Thm.isDarktheme(
                                                        widget.prefs),
                                                    context: context,
                                                    widgetList:
                                                        Language.languageList()
                                                            .map(
                                                              (e) => InkWell(
                                                                onTap: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                  _changeLanguage(
                                                                      e);
                                                                },
                                                                child:
                                                                    Container(
                                                                  margin:
                                                                      EdgeInsets
                                                                          .all(
                                                                              14),
                                                                  child: Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: <
                                                                        Widget>[
                                                                      Text(
                                                                        IsShowLanguageNameInNativeLanguage ==
                                                                                true
                                                                            ? e.flag +
                                                                                ' ' +
                                                                                '    ' +
                                                                                e.name
                                                                            : e.flag + ' ' + '    ' + e.languageNameInEnglish,
                                                                        style: TextStyle(
                                                                            color: Thm.isDarktheme(widget.prefs)
                                                                                ? fiberchatWhite
                                                                                : fiberchatBlack,
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            fontSize: 16),
                                                                      ),
                                                                      Language.languageList().length <
                                                                              2
                                                                          ? SizedBox()
                                                                          : Icon(
                                                                              Icons.done,
                                                                              color: e.languageCode == widget.prefs.getString(LAGUAGE_CODE) ? fiberchatSECONDARYolor : Colors.transparent,
                                                                            )
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            )
                                                            .toList(),
                                                    title: "");
                                              },
                                              child: Container(
                                                width: 60,
                                                height: 30,
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.language_outlined,
                                                      color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                              .isDarktheme(
                                                                  widget.prefs)
                                                          ? fiberchatAPPBARcolorDarkMode
                                                          : fiberchatAPPBARcolorLightMode),
                                                      size: 22,
                                                    ),
                                                    SizedBox(
                                                      width: 5,
                                                    ),
                                                    Icon(
                                                      Icons.keyboard_arrow_down,
                                                      color: Thm.isDarktheme(
                                                              widget.prefs)
                                                          ? fiberchatSECONDARYolor
                                                          : isDarkColor(
                                                                      fiberchatBACKGROUNDcolorLightMode) ==
                                                                  true
                                                              ? fiberchatWhite
                                                                  .withOpacity(
                                                                      0.6)
                                                              : pickTextColorBasedOnBgColorAdvanced(
                                                                      fiberchatAPPBARcolorLightMode)
                                                                  .withOpacity(
                                                                      0.65),
                                                      size: 27,
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
// // //---- All localizations settings----
                                    PopupMenuButton(
                                        padding: EdgeInsets.all(0),
                                        icon: Padding(
                                          padding:
                                              const EdgeInsets.only(right: 1),
                                          child: Icon(
                                            Icons.more_vert_outlined,
                                            color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                    .isDarktheme(widget.prefs)
                                                ? fiberchatAPPBARcolorDarkMode
                                                : fiberchatAPPBARcolorLightMode),
                                          ),
                                        ),
                                        color: Thm.isDarktheme(widget.prefs)
                                            ? fiberchatDIALOGColorDarkMode
                                            : fiberchatDIALOGColorLightMode,
                                        onSelected: (dynamic val) async {
                                          switch (val) {
                                            case 'rate':
                                              break;
                                            case 'tutorials':
                                              showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return SimpleDialog(
                                                      backgroundColor: Thm
                                                              .isDarktheme(
                                                                  widget.prefs)
                                                          ? fiberchatDIALOGColorDarkMode
                                                          : fiberchatDIALOGColorLightMode,
                                                      contentPadding:
                                                          EdgeInsets.all(20),
                                                      children: <Widget>[
                                                        ListTile(
                                                          title: Text(
                                                            getTranslated(
                                                                context,
                                                                'swipeview'),
                                                            style: TextStyle(
                                                              color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                                      .isDarktheme(
                                                                          widget
                                                                              .prefs)
                                                                  ? fiberchatDIALOGColorDarkMode
                                                                  : fiberchatDIALOGColorLightMode),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height: 10,
                                                        ),
                                                        ListTile(
                                                            title: Text(
                                                          getTranslated(context,
                                                              'swipehide'),
                                                          style: TextStyle(
                                                            color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                                    .isDarktheme(
                                                                        widget
                                                                            .prefs)
                                                                ? fiberchatDIALOGColorDarkMode
                                                                : fiberchatDIALOGColorLightMode),
                                                          ),
                                                        )),
                                                        SizedBox(
                                                          height: 10,
                                                        ),
                                                        ListTile(
                                                            title: Text(
                                                          getTranslated(context,
                                                              'lp_setalias'),
                                                          style: TextStyle(
                                                            color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                                    .isDarktheme(
                                                                        widget
                                                                            .prefs)
                                                                ? fiberchatDIALOGColorDarkMode
                                                                : fiberchatDIALOGColorLightMode),
                                                          ),
                                                        ))
                                                      ],
                                                    );
                                                  });
                                              break;
                                            case 'privacy':
                                              break;
                                            case 'tnc':
                                              break;
                                            case 'share':
                                              break;
                                            case 'notifications':
                                              Navigator.push(
                                                  context,
                                                  new MaterialPageRoute(
                                                      builder: (context) =>
                                                          AllNotifications(
                                                            prefs: widget.prefs,
                                                          )));

                                              break;
                                            case 'feedback':
                                              break;
                                            case 'logout':
                                              break;
                                            case 'settings':
                                              Navigator.push(
                                                  context,
                                                  new MaterialPageRoute(
                                                      builder:
                                                          (context) =>
                                                              SettingsOption(
                                                                prefs: widget
                                                                    .prefs,
                                                                onTapLogout:
                                                                    () async {
                                                                  await logout(
                                                                      context);
                                                                },
                                                                onTapEditProfile:
                                                                    () {
                                                                  Navigator.push(
                                                                      context,
                                                                      new MaterialPageRoute(
                                                                          builder: (context) => ProfileSetting(
                                                                                prefs: widget.prefs,
                                                                                biometricEnabled: biometricEnabled,
                                                                                type: Fiberchat.getAuthenticationType(biometricEnabled, _cachedModel),
                                                                              )));
                                                                },
                                                                currentUserNo:
                                                                    widget
                                                                        .currentUserNo!,
                                                                biometricEnabled:
                                                                    biometricEnabled,
                                                                type: Fiberchat
                                                                    .getAuthenticationType(
                                                                        biometricEnabled,
                                                                        _cachedModel),
                                                              )));

                                              break;
                                            case 'group':
                                              if (observer
                                                      .isAllowCreatingGroups ==
                                                  false) {
                                                Fiberchat.showRationale(
                                                    getTranslated(this.context,
                                                        'disabled'));
                                              } else {
                                                final SmartContactProviderWithLocalStoreData
                                                    dbcontactsProvider =
                                                    Provider.of<
                                                            SmartContactProviderWithLocalStoreData>(
                                                        context,
                                                        listen: false);
                                                dbcontactsProvider
                                                    .fetchContacts(
                                                        context,
                                                        _cachedModel,
                                                        widget.currentUserNo!,
                                                        widget.prefs,
                                                        false);
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            AddContactsToGroup(
                                                              currentUserNo: widget
                                                                  .currentUserNo,
                                                              model:
                                                                  _cachedModel,
                                                              biometricEnabled:
                                                                  false,
                                                              prefs:
                                                                  widget.prefs,
                                                              isAddingWhileCreatingGroup:
                                                                  true,
                                                            )));
                                              }
                                              break;

                                            case 'broadcast':
                                              if (observer
                                                      .isAllowCreatingBroadcasts ==
                                                  false) {
                                                Fiberchat.showRationale(
                                                    getTranslated(this.context,
                                                        'disabled'));
                                              } else {
                                                final SmartContactProviderWithLocalStoreData
                                                    dbcontactsProvider =
                                                    Provider.of<
                                                            SmartContactProviderWithLocalStoreData>(
                                                        context,
                                                        listen: false);
                                                dbcontactsProvider
                                                    .fetchContacts(
                                                        context,
                                                        _cachedModel,
                                                        widget.currentUserNo!,
                                                        widget.prefs,
                                                        false);
                                                await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            AddContactsToBroadcast(
                                                              currentUserNo: widget
                                                                  .currentUserNo,
                                                              model:
                                                                  _cachedModel,
                                                              biometricEnabled:
                                                                  false,
                                                              prefs:
                                                                  widget.prefs,
                                                              isAddingWhileCreatingBroadcast:
                                                                  true,
                                                            )));
                                              }
                                              break;
                                          }
                                        },
                                        itemBuilder: (context) =>
                                            <PopupMenuItem<String>>[
                                              PopupMenuItem<String>(
                                                  value: 'group',
                                                  child: Text(
                                                    getTranslated(
                                                        context, 'newgroup'),
                                                    style: TextStyle(
                                                      color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                              .isDarktheme(
                                                                  widget.prefs)
                                                          ? fiberchatDIALOGColorDarkMode
                                                          : fiberchatDIALOGColorLightMode),
                                                    ),
                                                  )),
                                              PopupMenuItem<String>(
                                                  value: 'broadcast',
                                                  child: Text(
                                                    getTranslated(context,
                                                        'newbroadcast'),
                                                    style: TextStyle(
                                                      color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                              .isDarktheme(
                                                                  widget.prefs)
                                                          ? fiberchatDIALOGColorDarkMode
                                                          : fiberchatDIALOGColorLightMode),
                                                    ),
                                                  )),
                                              PopupMenuItem<String>(
                                                value: 'tutorials',
                                                child: Text(
                                                  getTranslated(
                                                      context, 'tutorials'),
                                                  style: TextStyle(
                                                    color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                            .isDarktheme(
                                                                widget.prefs)
                                                        ? fiberchatDIALOGColorDarkMode
                                                        : fiberchatDIALOGColorLightMode),
                                                  ),
                                                ),
                                              ),
                                              PopupMenuItem<String>(
                                                  value: 'settings',
                                                  child: Text(
                                                    getTranslated(context,
                                                        'settingsoption'),
                                                    style: TextStyle(
                                                      color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                              .isDarktheme(
                                                                  widget.prefs)
                                                          ? fiberchatDIALOGColorDarkMode
                                                          : fiberchatDIALOGColorLightMode),
                                                    ),
                                                  )),
                                            ]),
                                  ],
                                  bottom: TabBar(
                                    isScrollable: IsAdaptiveWidthTab == true
                                        ? true
                                        : DEFAULT_LANGUAGE_FILE_CODE == "en" &&
                                                (widget.prefs.getString(
                                                            LAGUAGE_CODE) ==
                                                        null ||
                                                    widget.prefs
                                                            .getString(
                                                                LAGUAGE_CODE) ==
                                                        "en")
                                            ? false
                                            : widget
                                                            .prefs
                                                            .getString(
                                                                LAGUAGE_CODE) ==
                                                        'pt' ||
                                                    widget
                                                            .prefs
                                                            .getString(
                                                                LAGUAGE_CODE) ==
                                                        'my' ||
                                                    widget
                                                            .prefs
                                                            .getString(
                                                                LAGUAGE_CODE) ==
                                                        'nl' ||
                                                    widget
                                                            .prefs
                                                            .getString(
                                                                LAGUAGE_CODE) ==
                                                        'vi' ||
                                                    widget
                                                            .prefs
                                                            .getString(
                                                                LAGUAGE_CODE) ==
                                                        'tr' ||
                                                    widget
                                                            .prefs
                                                            .getString(
                                                                LAGUAGE_CODE) ==
                                                        'id' ||
                                                    widget.prefs.getString(
                                                            LAGUAGE_CODE) ==
                                                        'ka' ||
                                                    widget.prefs.getString(
                                                            LAGUAGE_CODE) ==
                                                        'fr' ||
                                                    widget.prefs.getString(
                                                            LAGUAGE_CODE) ==
                                                        'es'
                                                ? true
                                                : false,
                                    labelStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: FONTFAMILY_NAME == ''
                                          ? null
                                          : FONTFAMILY_NAME,
                                    ),
                                    unselectedLabelStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: FONTFAMILY_NAME == ''
                                          ? null
                                          : FONTFAMILY_NAME,
                                    ),
                                    labelColor:
                                        pickTextColorBasedOnBgColorAdvanced(Thm
                                                .isDarktheme(widget.prefs)
                                            ? fiberchatAPPBARcolorDarkMode
                                            : fiberchatAPPBARcolorLightMode),
                                    unselectedLabelColor:
                                        pickTextColorBasedOnBgColorAdvanced(Thm
                                                    .isDarktheme(widget.prefs)
                                                ? fiberchatAPPBARcolorDarkMode
                                                : fiberchatAPPBARcolorLightMode)
                                            .withOpacity(0.6),
                                    indicatorWeight: 3,
                                    indicatorColor:
                                        Thm.isDarktheme(widget.prefs)
                                            ? fiberchatSECONDARYolor
                                            : fiberchatAPPBARcolorLightMode ==
                                                    Colors.white
                                                ? fiberchatSECONDARYolor
                                                : fiberchatWhite,
                                    controller:
                                        observer.isCallFeatureTotallyHide ==
                                                false
                                            ? controllerIfcallallowed
                                            : controllerIfcallNotallowed,
                                    tabs: observer.isCallFeatureTotallyHide ==
                                            false
                                        ? (IsShowSearchTab
                                                ? <Widget>[
                                                    Tab(
                                                      icon: Icon(
                                                        Icons.search,
                                                        size: 22,
                                                      ),
                                                    ),
                                                  ]
                                                : <Widget>[]) +
                                            <Widget>[
                                              Tab(
                                                child: Text(
                                                  getTranslated(
                                                      context, 'chats'),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        FONTFAMILY_NAME == ''
                                                            ? null
                                                            : FONTFAMILY_NAME,
                                                  ),
                                                ),
                                              ),
                                              Tab(
                                                child: Text(
                                                  getTranslated(
                                                      context, 'status'),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        FONTFAMILY_NAME == ''
                                                            ? null
                                                            : FONTFAMILY_NAME,
                                                  ),
                                                ),
                                              ),
                                              Tab(
                                                child: Text(
                                                  getTranslated(
                                                      context, 'calls'),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        FONTFAMILY_NAME == ''
                                                            ? null
                                                            : FONTFAMILY_NAME,
                                                  ),
                                                ),
                                              ),
                                            ]
                                        : (IsShowSearchTab
                                                ? <Widget>[
                                                    Tab(
                                                      icon: Icon(
                                                        Icons.search,
                                                        size: 22,
                                                      ),
                                                    ),
                                                  ]
                                                : <Widget>[]) +
                                            <Widget>[
                                              Tab(
                                                child: Text(
                                                  getTranslated(
                                                      context, 'chats'),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        FONTFAMILY_NAME == ''
                                                            ? null
                                                            : FONTFAMILY_NAME,
                                                  ),
                                                ),
                                              ),
                                              Tab(
                                                child: Text(
                                                  getTranslated(
                                                      context, 'status'),
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontFamily:
                                                        FONTFAMILY_NAME == ''
                                                            ? null
                                                            : FONTFAMILY_NAME,
                                                  ),
                                                ),
                                              ),
                                            ],
                                  )),
                              body: TabBarView(
                                controller:
                                    observer.isCallFeatureTotallyHide == false
                                        ? controllerIfcallallowed
                                        : controllerIfcallNotallowed,
                                children: observer.isCallFeatureTotallyHide ==
                                        false
                                    ? (IsShowSearchTab
                                            ? <Widget>[
                                                SearchChats(
                                                    prefs: widget.prefs,
                                                    currentUserNo:
                                                        widget.currentUserNo,
                                                    isSecuritySetupDone: false),
                                              ]
                                            : <Widget>[]) +
                                        <Widget>[
                                          IsShowLastMessageInChatTileWithTime ==
                                                  false
                                              ? RecentChatsWithoutLastMessage(
                                                  prefs: widget.prefs,
                                                  currentUserNo:
                                                      widget.currentUserNo,
                                                  isSecuritySetupDone: false)
                                              : RecentChats(
                                                  prefs: widget.prefs,
                                                  currentUserNo:
                                                      widget.currentUserNo,
                                                  isSecuritySetupDone: false),
                                          Status(
                                              currentUserFullname: userFullname,
                                              currentUserPhotourl: userPhotourl,
                                              phoneNumberVariants:
                                                  this.phoneNumberVariants,
                                              currentUserNo:
                                                  widget.currentUserNo,
                                              model: _cachedModel,
                                              biometricEnabled:
                                                  biometricEnabled,
                                              prefs: widget.prefs),
                                          CallHistory(
                                            model: _cachedModel,
                                            userphone: widget.currentUserNo,
                                            prefs: widget.prefs,
                                          ),
                                        ]
                                    : (IsShowSearchTab
                                            ? <Widget>[
                                                SearchChats(
                                                    prefs: widget.prefs,
                                                    currentUserNo:
                                                        widget.currentUserNo,
                                                    isSecuritySetupDone: false),
                                              ]
                                            : <Widget>[]) +
                                        <Widget>[
                                          IsShowLastMessageInChatTileWithTime ==
                                                  false
                                              ? RecentChatsWithoutLastMessage(
                                                  prefs: widget.prefs,
                                                  currentUserNo:
                                                      widget.currentUserNo,
                                                  isSecuritySetupDone: false)
                                              : RecentChats(
                                                  prefs: widget.prefs,
                                                  currentUserNo:
                                                      widget.currentUserNo,
                                                  isSecuritySetupDone: false),
                                          Status(
                                              currentUserFullname: userFullname,
                                              currentUserPhotourl: userPhotourl,
                                              phoneNumberVariants:
                                                  this.phoneNumberVariants,
                                              currentUserNo:
                                                  widget.currentUserNo,
                                              model: _cachedModel,
                                              biometricEnabled:
                                                  biometricEnabled,
                                              prefs: widget.prefs),
                                        ],
                              )),
                        )));
  }
}

// Future<dynamic> myBackgroundMessageHandlerIos(RemoteMessage message) async {
//   await Firebase.initializeApp();

//   if (message.data['title'] == 'Call Ended') {
//     final data = message.data;

//     final titleMultilang = data['titleMultilang'];
//     final bodyMultilang = data['bodyMultilang'];
//     flutterLocalNotificationsPlugin..cancelAll();
//     await showNotificationWithDefaultSound(
//         'Missed Call', 'You have Missed a Call', titleMultilang, bodyMultilang);
//   } else {
//     if (message.data['title'] == 'You have new message(s)') {
//     } else if (message.data['title'] == 'Incoming Audio Call...' ||
//         message.data['title'] == 'Incoming Video Call...') {
//       final data = message.data;
//       final title = data['title'];
//       final body = data['body'];
//       final titleMultilang = data['titleMultilang'];
//       final bodyMultilang = data['bodyMultilang'];
//       await showNotificationWithDefaultSound(
//           title, body, titleMultilang, bodyMultilang);
//     }
//   }

//   return Future<void>.value();
// }

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
Future showNotificationWithDefaultSound(String? title, String? message,
    String? titleMultilang, String? bodyMultilang) async {
  if (Platform.isAndroid) {
    flutterLocalNotificationsPlugin.cancelAll();
  }

  var initializationSettingsAndroid =
      new AndroidInitializationSettings('@mipmap/ic_launcher');
  var initializationSettingsIOS = DarwinInitializationSettings();
  var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  flutterLocalNotificationsPlugin.initialize(initializationSettings);
  var androidPlatformChannelSpecifics =
      title == 'Missed Call' || title == 'Call Ended'
          ? local.AndroidNotificationDetails('channel_id', 'channel_name',
              importance: local.Importance.max,
              priority: local.Priority.high,
              sound: RawResourceAndroidNotificationSound('whistle2'),
              playSound: true,
              ongoing: true,
              visibility: NotificationVisibility.public,
              timeoutAfter: 28000)
          : local.AndroidNotificationDetails('channel_id', 'channel_name',
              sound: RawResourceAndroidNotificationSound('ringtone'),
              playSound: true,
              ongoing: true,
              importance: local.Importance.max,
              priority: local.Priority.high,
              visibility: NotificationVisibility.public,
              timeoutAfter: 28000);
  var iOSPlatformChannelSpecifics = local.DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    sound:
        title == 'Missed Call' || title == 'Call Ended' ? '' : 'ringtone.caf',
    presentSound: true,
  );
  var platformChannelSpecifics = local.NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin
      .show(
    0,
    '$titleMultilang',
    '$bodyMultilang',
    platformChannelSpecifics,
    payload: 'payload',
  )
      .catchError((err) {
    debugPrint('ERROR DISPLAYING NOTIFICATION: $err');
  });
}

Widget errorScreen(String? title, String? subtitle) {
  return Scaffold(
    backgroundColor: fiberchatPRIMARYcolor,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_outlined,
              size: 60,
              color: Colors.yellowAccent,
            ),
            SizedBox(
              height: 30,
            ),
            Text(
              '$title',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  color: fiberchatWhite,
                  fontWeight: FontWeight.w700),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              '$subtitle',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 17,
                  color: fiberchatWhite.withOpacity(0.7),
                  fontWeight: FontWeight.w400),
            )
          ],
        ),
      ),
    ),
  );
}
