import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:fiberchat/Configs/Dbkeys.dart';
import 'package:fiberchat/Configs/Dbpaths.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Configs/optional_constants.dart';
import 'package:fiberchat/Models/DataModel.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Utils/open_settings.dart';
import 'package:fiberchat/Utils/theme_management.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:fiberchat/widgets/DynamicBottomSheet/dynamic_modal_bottomsheet.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUserData {
  final lastUpdated, userType;
  final Int8List? photoBytes;
  final String id, name, photoURL, aboutUser;
  final List<dynamic> idVariants;

  LocalUserData({
    required this.id,
    required this.idVariants,
    required this.userType,
    required this.aboutUser,
    required this.lastUpdated,
    required this.name,
    required this.photoURL,
    this.photoBytes,
  });

  factory LocalUserData.fromJson(Map<String, dynamic> jsonData) {
    return LocalUserData(
      id: jsonData['id'],
      aboutUser: jsonData['about'],
      idVariants: jsonData['idVars'],
      name: jsonData['name'],
      photoURL: jsonData['url'],
      photoBytes: jsonData['bytes'],
      userType: jsonData['type'],
      lastUpdated: jsonData['time'],
    );
  }

  Map<String, dynamic> toMapp(LocalUserData user) {
    return {
      'id': user.id,
      'about': user.aboutUser,
      'idVars': user.idVariants,
      'name': user.name,
      'url': user.photoURL,
      'bytes': user.photoBytes,
      'type': user.userType,
      'time': user.lastUpdated,
    };
  }

  static Map<String, dynamic> toMap(LocalUserData user) => {
        'id': user.id,
        'about': user.aboutUser,
        'idVars': user.idVariants,
        'name': user.name,
        'url': user.photoURL,
        'bytes': user.photoBytes,
        'type': user.userType,
        'time': user.lastUpdated,
      };

  static String encode(List<LocalUserData> users) => json.encode(
        users
            .map<Map<String, dynamic>>((user) => LocalUserData.toMap(user))
            .toList(),
      );

  static List<LocalUserData> decode(String users) =>
      (json.decode(users) as List<dynamic>)
          .map<LocalUserData>((item) => LocalUserData.fromJson(item))
          .toList();
}

class SmartContactProviderWithLocalStoreData with ChangeNotifier {
  //********---LOCAL STORE USER DATA PREVIUSLY FETCHED IN PREFS::::::::-----
  int daysToUpdateCache = 7;
  var usersDocsRefinServer =
      FirebaseFirestore.instance.collection(DbPaths.collectionusers);
  List<LocalUserData> localUsersLIST = [];
  String localUsersSTRING = "";

  addORUpdateLocalUserDataMANUALLY(
      {required SharedPreferences prefs,
      required LocalUserData localUserData,
      required bool isNotifyListener}) {
    int ind =
        localUsersLIST.indexWhere((element) => element.id == localUserData.id);
    if (ind >= 0) {
      if (localUsersLIST[ind].name.toString() !=
              localUserData.name.toString() ||
          localUsersLIST[ind].photoURL.toString() !=
              localUserData.photoURL.toString()) {
        localUsersLIST.removeAt(ind);
        localUsersLIST.insert(ind, localUserData);
        localUsersLIST.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        if (isNotifyListener == true) {
          notifyListeners();
        }
        saveFetchedLocalUsersInPrefs(prefs);
      }
    } else {
      localUsersLIST.add(localUserData);
      localUsersLIST
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (isNotifyListener == true) {
        notifyListeners();
      }
      saveFetchedLocalUsersInPrefs(prefs);
    }
  }

  Future<LocalUserData?> fetchUserDataFromnLocalOrServer(
      SharedPreferences prefs, String userid) async {
    int ind = localUsersLIST.indexWhere((element) => element.id == userid);
    if (ind >= 0) {
      // print("LOADED ${localUsersLIST[ind].id} LOCALLY ");
      LocalUserData localUser = localUsersLIST[ind];
      if (DateTime.now()
              .difference(
                  DateTime.fromMillisecondsSinceEpoch(localUser.lastUpdated))
              .inDays >
          daysToUpdateCache) {
        DocumentSnapshot<Map<String, dynamic>> doc =
            await usersDocsRefinServer.doc(localUser.id).get();
        if (doc.exists) {
          var updatedUserData = LocalUserData(
              aboutUser: doc.data()![Dbkeys.aboutMe] ?? "",
              idVariants: doc.data()![Dbkeys.phonenumbervariants] ?? [userid],
              id: localUser.id,
              userType: 0,
              lastUpdated: DateTime.now().millisecondsSinceEpoch,
              name: doc.data()![Dbkeys.nickname],
              photoURL: doc.data()![Dbkeys.photoUrl] ?? "");
          // print("UPDATED ${localUser.id} LOCALLY AFTER EXPIRED");
          addORUpdateLocalUserDataMANUALLY(
              prefs: prefs,
              isNotifyListener: false,
              localUserData: updatedUserData);
          return Future.value(updatedUserData);
        } else {
          return Future.value(localUser);
        }
      } else {
        return Future.value(localUser);
      }
    } else {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await usersDocsRefinServer.doc(userid).get();
      if (doc.exists) {
        // print("LOADED ${doc.data()![Dbkeys.phone]} SERVER ");
        var updatedUserData = LocalUserData(
            aboutUser: doc.data()![Dbkeys.aboutMe] ?? "",
            idVariants: doc.data()![Dbkeys.phonenumbervariants] ?? [userid],
            id: doc.data()![Dbkeys.phone],
            userType: 0,
            lastUpdated: DateTime.now().millisecondsSinceEpoch,
            name: doc.data()![Dbkeys.nickname],
            photoURL: doc.data()![Dbkeys.photoUrl] ?? "");

        addORUpdateLocalUserDataMANUALLY(
            prefs: prefs,
            isNotifyListener: false,
            localUserData: updatedUserData);
        return Future.value(updatedUserData);
      } else {
        return Future.value(null);
      }
    }
  }

  fetchFromFiretsoreAndReturnData(SharedPreferences prefs, String userid,
      Function(DocumentSnapshot<Map<String, dynamic>> doc) onReturnData) async {
    var doc = await usersDocsRefinServer.doc(userid).get();
    if (doc.exists && doc.data() != null) {
      onReturnData(doc);
      addORUpdateLocalUserDataMANUALLY(
          isNotifyListener: true,
          prefs: prefs,
          localUserData: LocalUserData(
              id: userid,
              idVariants: doc.data()![Dbkeys.phonenumbervariants],
              userType: 0,
              aboutUser: doc.data()![Dbkeys.aboutMe],
              lastUpdated: DateTime.now().millisecondsSinceEpoch,
              name: doc.data()![Dbkeys.nickname],
              photoURL: doc.data()![Dbkeys.photoUrl] ?? ""));
    }
  }

  Future<bool?> fetchLocalUsersFromPrefs(SharedPreferences prefs) async {
    localUsersSTRING = prefs.getString('localUsersSTRING') ?? "";
    // String? localUsersDEVICECONTACT =
    //     prefs.getString('localUsersDEVICECONTACT') ?? "";

    if (localUsersSTRING != "") {
      localUsersLIST = LocalUserData.decode(localUsersSTRING);
      localUsersLIST
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      // for (var user in localUsersLIST) {
      //   alreadyJoinedSavedUsersPhoneNameAsInServer = [];
      //   if (user.id != phone) {
      //     alreadyJoinedSavedUsersPhoneNameAsInServer
      //         .add(DeviceContactIdAndName(phone: phone, name: user.name));
      //   }
      // }
      // print("FOUND ${localUsersLIST.length} LOCAL USERS STORED - at start");
      notifyListeners();

      return true;
    } else {
      return true;
    }

    // if (localUsersDEVICECONTACT != "") {
    //   alreadyJoinedSavedUsersPhoneNameAsInServer =
    //       DeviceContactIdAndName.decode(localUsersDEVICECONTACT);
    //   alreadyJoinedSavedUsersPhoneNameAsInServer.sort((a, b) =>
    //       (a.name ?? "").toLowerCase().compareTo((b.name ?? "").toLowerCase()));
    // }
  }

  saveFetchedLocalUsersInPrefs(SharedPreferences prefs) async {
    if (searchingcontactsindatabase == false) {
      localUsersSTRING = LocalUserData.encode(localUsersLIST);
      await prefs.setString('localUsersSTRING', localUsersSTRING);

      // print("SAVED ${localUsersLIST.length} LOCAL USERS - at end");
    }
  }

  //********---DEVICE CONTACT FETCH STARTS BELOW::::::::-----

  List<DeviceContactIdAndName> previouslyFetchedKEYPhoneInSharedPrefs = [];
  List<DeviceContactIdAndName> alreadyJoinedSavedUsersPhoneNameAsInServer = [];

//-------
  Map<String?, String?>? contactsBookContactList = new Map<String, String>();
  bool searchingcontactsindatabase = true;
  List<dynamic> currentUserPhoneNumberVariants = [];

  getContactsIfAgreed(BuildContext context, DataModel? model,
      String currentuserphone, SharedPreferences prefs, bool isForceFetch,
      {List<dynamic>? currentuserphoneNumberVariants}) async {
    if (currentuserphoneNumberVariants != null) {
      currentUserPhoneNumberVariants = currentuserphoneNumberVariants;
    }
    await getContactsFromDevice(context, model, prefs).then((value) async {
      final List<DeviceContactIdAndName> decodedPhoneStrings =
          prefs.getString('availablePhoneString') == null ||
                  prefs.getString('availablePhoneString') == ''
              ? []
              : DeviceContactIdAndName.decode(
                  prefs.getString('availablePhoneString')!);
      final List<DeviceContactIdAndName> decodedPhoneAndNameStrings =
          prefs.getString('availablePhoneAndNameString') == null ||
                  prefs.getString('availablePhoneAndNameString') == ''
              ? []
              : DeviceContactIdAndName.decode(
                  prefs.getString('availablePhoneAndNameString')!);
      previouslyFetchedKEYPhoneInSharedPrefs = decodedPhoneStrings;
      alreadyJoinedSavedUsersPhoneNameAsInServer = decodedPhoneAndNameStrings;

      var a = alreadyJoinedSavedUsersPhoneNameAsInServer;
      var b = previouslyFetchedKEYPhoneInSharedPrefs;

      alreadyJoinedSavedUsersPhoneNameAsInServer = a;
      previouslyFetchedKEYPhoneInSharedPrefs = b;

      await fetchLocalUsersFromPrefs(prefs).then((b) async {
        if (b == true) {
          await searchAvailableContactsInDb(
              context, currentuserphone, prefs, isForceFetch);
        }
      });
    });
  }

  fetchContacts(BuildContext context, DataModel? model, String currentuserphone,
      SharedPreferences prefs, bool isForceFetch,
      {List<dynamic>? currentuserphoneNumberVariants,
      bool? isRequestAgain = false}) async {
    if (prefs.getBool('allowed-contacts') == null || isRequestAgain == true) {
      showDynamicModalBottomSheet(
          isDismissable: false,
          height: 0.4,
          context: context,
          widgetList: [],
          popableWidgetList: (popable) {
            return [
              Padding(
                padding: const EdgeInsets.all(13.0),
                child: Text(
                  getTranslated(popable, 'usecontactsdesc'),
                  textAlign: TextAlign.center,
                  style: TextStyle(height: 1.3, color: fiberchatGrey),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 25, 18, 30),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            side: BorderSide(
                                color: Thm.isDarktheme(prefs)
                                    ? fiberchatWhite
                                    : fiberchatGrey.withOpacity(0.3),
                                width: 1),
                            elevation: 0.44,
                            backgroundColor: fiberchatWhite),
                        onPressed: () async {
                          Navigator.of(popable).pop();
                          await prefs.setBool('allowed-contacts', false);
                          searchingcontactsindatabase = false;
                          notifyListeners();
                        },
                        child: Text(
                          getTranslated(popable, 'declinebutton'),
                          style: TextStyle(color: fiberchatBlack),
                        )),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            elevation: 0.4,
                            backgroundColor: fiberchatSECONDARYolor),
                        onPressed: () async {
                          Navigator.of(popable).pop();
                          await prefs.setBool('allowed-contacts', true);
                          await getContactsIfAgreed(context, model,
                              currentuserphone, prefs, isForceFetch,
                              currentuserphoneNumberVariants:
                                  currentuserphoneNumberVariants);
                        },
                        child: Text(getTranslated(popable, 'agreebutton'))),
                  ],
                ),
              )
            ];
          },
          title: getTranslated(context, 'usecontacts'),
          isdark: Thm.isDarktheme(prefs));
    } else if (prefs.getBool('allowed-contacts') == false) {
      setIsLoading(false);
    } else if (prefs.getBool('allowed-contacts') == true) {
      await getContactsIfAgreed(
          context, model, currentuserphone, prefs, isForceFetch,
          currentuserphoneNumberVariants: currentuserphoneNumberVariants);
    } else {}
  }

  setIsLoading(bool val) {
    searchingcontactsindatabase = val;
    notifyListeners();
  }

  Future<Map<String?, String?>> getContactsFromDevice(
      BuildContext context, DataModel? model, SharedPreferences prefs,
      {bool refresh = false}) async {
    Completer<Map<String?, String?>> completer =
        new Completer<Map<String?, String?>>();

    LocalStorage storage = LocalStorage(Dbkeys.cachedContacts);

    Map<String?, String?> _cachedContacts = {};

    completer.future.then((c) {
      c.removeWhere((key, val) => _isHidden(key, model));

      this.contactsBookContactList = c;
      if (this.contactsBookContactList!.isEmpty) {
        searchingcontactsindatabase = false;
        notifyListeners();
      }
    });

    Fiberchat.checkAndRequestPermission(Permission.contacts).then((res) {
      if (res) {
        storage.ready.then((ready) async {
          if (ready) {
            String? getNormalizedNumber(String? number) {
              if (number == null) return null;
              return number.replaceAll(new RegExp('[^0-9+]'), '');
            }

            ContactsService.getContacts(withThumbnails: false)
                .then((Iterable<Contact> contacts) async {
              for (Contact p in contacts.where((c) => c.phones!.isNotEmpty)) {
                if (p.displayName != null && p.phones!.isNotEmpty) {
                  List<String?> numbers = p.phones!
                      .map((number) {
                        String? _phone = getNormalizedNumber(number.value);

                        return _phone;
                      })
                      .toList()
                      .where((s) => s != null)
                      .toList();
                  for (var number in numbers) {
                    _cachedContacts[number] = p.displayName;
                  }
                }
              }

              completer.complete(_cachedContacts);
            });
          }
          // }
        });
      } else {
        Fiberchat.showRationale(getTranslated(context, 'perm_contact'));
        Navigator.pushReplacement(
            context,
            new MaterialPageRoute(
                builder: (context) => OpenSettings(
                      permtype: 'contact',
                      prefs: prefs,
                    )));
      }
    }).catchError((onError) {
      Fiberchat.showRationale('Error occured: $onError');
    });
    notifyListeners();
    return completer.future;
  }

  String? getNormalizedNumber(String number) {
    if (number.isEmpty) {
      return null;
    }

    return number.replaceAll(new RegExp('[^0-9+]'), '');
  }

  _isHidden(String? phoneNo, DataModel? model) {
    return false;
  }

  Future<List<QueryDocumentSnapshot>?> getUsersUsingChunks(
      List<String> chunks) async {
    QuerySnapshot result = await FirebaseFirestore.instance
        .collection(DbPaths.collectionusers)
        .where(Dbkeys.phonenumbervariants, arrayContainsAny: chunks)
        .get();
    if (result.docs.isNotEmpty) {
      return result.docs;
    } else {
      return null;
    }
  }

  searchAvailableContactsInDb(
    BuildContext context,
    String currentuserphone,
    SharedPreferences existingPrefs,
    bool isForceFetch,
  ) async {
    if (existingPrefs.getString('lastTimeCheckedContactBookSavedCopy') ==
            contactsBookContactList.toString() &&
        isForceFetch == false) {
      searchingcontactsindatabase = false;
      if (previouslyFetchedKEYPhoneInSharedPrefs.length == 0 ||
          alreadyJoinedSavedUsersPhoneNameAsInServer.length == 0) {
        final List<DeviceContactIdAndName> decodedPhoneStrings =
            existingPrefs.getString('availablePhoneString') == null ||
                    existingPrefs.getString('availablePhoneString') == ''
                ? []
                : DeviceContactIdAndName.decode(
                    existingPrefs.getString('availablePhoneString')!);
        final List<DeviceContactIdAndName> decodedPhoneAndNameStrings =
            existingPrefs.getString('availablePhoneAndNameString') == null ||
                    existingPrefs.getString('availablePhoneAndNameString') == ''
                ? []
                : DeviceContactIdAndName.decode(
                    existingPrefs.getString('availablePhoneAndNameString')!);
        previouslyFetchedKEYPhoneInSharedPrefs = decodedPhoneStrings;
        alreadyJoinedSavedUsersPhoneNameAsInServer = decodedPhoneAndNameStrings;
      }

      notifyListeners();

      // print(
      //     '11. SKIPPED SEARCHING - AS ${contactsBookContactList!.entries.length} CONTACTS ALREADY CHECKED IN DATABASE, ${alreadyJoinedSavedUsersPhoneNameAsInServer.length} EXISTS');
    } else {
      // print(
      //     '22. STARTED SEARCHING : ${contactsBookContactList!.entries.length} CONTACTS  IN DATABASE');
      List<String> myArray = contactsBookContactList!.entries
          .toList()
          .map((e) => e.key.toString())
          .toList();
      List<List<String>> chunkList = Fiberchat.divideIntoChuncks(myArray, 10);

      List<List<List<String>>> chunkgroups = Fiberchat.divideIntoChuncksGroup(
          chunkList, ContactsSearchCountBatchSize);

      for (var chunks in chunkgroups) {
        var futureGroup = FutureGroup();

        for (var chunk in chunks) {
          futureGroup.add(getUsersUsingChunks(chunk));
        }
        futureGroup.close();
        var p = await futureGroup.future;
        for (var batch in p) {
          if (batch != null) {
            for (QueryDocumentSnapshot<Map<String, dynamic>> registeredUser
                in batch) {
              if (registeredUser.data().containsKey(Dbkeys.joinedOn)) {
                if (alreadyJoinedSavedUsersPhoneNameAsInServer.indexWhere(
                            (element) =>
                                element.phone == registeredUser[Dbkeys.phone]) <
                        0 &&
                    registeredUser[Dbkeys.phone] != currentuserphone) {
                  for (var phone in registeredUser
                      .data()[Dbkeys.phonenumbervariants]
                      .toList()) {
                    previouslyFetchedKEYPhoneInSharedPrefs
                        .add(DeviceContactIdAndName(phone: phone ?? ''));
                  }

                  alreadyJoinedSavedUsersPhoneNameAsInServer.add(
                      DeviceContactIdAndName(
                          phone: registeredUser.data()[Dbkeys.phone] ?? '',
                          name: registeredUser.data()[Dbkeys.phone]));
                  // print('INSERTED $key IN LOCAL USER DATA LIST');
                  addORUpdateLocalUserDataMANUALLY(
                      prefs: existingPrefs,
                      localUserData: LocalUserData(
                          aboutUser:
                              registeredUser.data()[Dbkeys.aboutMe] ?? "",
                          id: registeredUser.data()[Dbkeys.phone],
                          idVariants:
                              registeredUser.data()[Dbkeys.phonenumbervariants],
                          userType: 0,
                          lastUpdated: DateTime.now().millisecondsSinceEpoch,
                          name: registeredUser.data()[Dbkeys.nickname],
                          photoURL:
                              registeredUser.data()[Dbkeys.photoUrl] ?? ""),
                      isNotifyListener: true);
                }
              } else {}
            }
          }
        }
      }
      int i = alreadyJoinedSavedUsersPhoneNameAsInServer
          .indexWhere((element) => element.phone == currentuserphone);
      if (i >= 0) {
        alreadyJoinedSavedUsersPhoneNameAsInServer.removeAt(i);
        previouslyFetchedKEYPhoneInSharedPrefs.removeAt(i);
      }
      finishLoadingTasks(context, existingPrefs, currentuserphone,
          "24. SEARCHING STOPPED as users search completed in database.");
    }
  }

  finishLoadingTasks(BuildContext context, SharedPreferences existingPrefs,
      String currentuserphone, String printStatement,
      {bool isrealyfinish = true}) async {
    if (isrealyfinish == true) {
      searchingcontactsindatabase = false;
    }

    final String encodedavailablePhoneString =
        DeviceContactIdAndName.encode(previouslyFetchedKEYPhoneInSharedPrefs);
    await existingPrefs.setString(
        'availablePhoneString', encodedavailablePhoneString);

    final String encodedalreadyJoinedSavedUsersPhoneNameAsInServer =
        DeviceContactIdAndName.encode(
            alreadyJoinedSavedUsersPhoneNameAsInServer);
    await existingPrefs.setString('availablePhoneAndNameString',
        encodedalreadyJoinedSavedUsersPhoneNameAsInServer);

    if (isrealyfinish == true) {
      await existingPrefs.setString('lastTimeCheckedContactBookSavedCopy',
          contactsBookContactList.toString());
      notifyListeners();
    }
  }

  String getUserNameOrIdQuickly(String userid) {
    if (localUsersLIST.indexWhere((element) => element.id == userid) >= 0) {
      return localUsersLIST[
              localUsersLIST.indexWhere((element) => element.id == userid)]
          .name;
    } else {
      return 'User';
    }
  }
}

class DeviceContactIdAndName {
  final String phone;
  final String? name;

  DeviceContactIdAndName({
    required this.phone,
    this.name,
  });

  factory DeviceContactIdAndName.fromJson(Map<String, dynamic> jsonData) {
    return DeviceContactIdAndName(
      phone: jsonData['id'],
      name: jsonData['name'],
    );
  }

  static Map<String, dynamic> toMap(DeviceContactIdAndName contact) => {
        'id': contact.phone,
        'name': contact.name,
      };

  static String encode(List<DeviceContactIdAndName> contacts) => json.encode(
        contacts
            .map<Map<String, dynamic>>(
                (contact) => DeviceContactIdAndName.toMap(contact))
            .toList(),
      );

  static List<DeviceContactIdAndName> decode(String contacts) =>
      (json.decode(contacts) as List<dynamic>)
          .map<DeviceContactIdAndName>(
              (item) => DeviceContactIdAndName.fromJson(item))
          .toList();
}
