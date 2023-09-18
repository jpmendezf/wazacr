//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiberchat/Configs/Dbkeys.dart';
import 'package:fiberchat/Configs/Dbpaths.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Screens/auth_screens/login.dart';
import 'package:fiberchat/Screens/call_history/callhistory.dart';
import 'package:fiberchat/Screens/calling_screen/pickup_layout.dart';
import 'package:fiberchat/Services/Providers/SmartContactProviderWithLocalStoreData.dart';
import 'package:fiberchat/Services/Providers/GroupChatProvider.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Models/DataModel.dart';
import 'package:fiberchat/Utils/color_detector.dart';
import 'package:fiberchat/Utils/theme_management.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:fiberchat/widgets/MyElevatedButton/MyElevatedButton.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddContactsToGroup extends StatefulWidget {
  const AddContactsToGroup({
    required this.currentUserNo,
    required this.model,
    required this.biometricEnabled,
    required this.prefs,
    required this.isAddingWhileCreatingGroup,
    this.groupID,
  });
  final String? groupID;
  final String? currentUserNo;
  final DataModel? model;
  final SharedPreferences prefs;
  final bool biometricEnabled;
  final bool isAddingWhileCreatingGroup;

  @override
  _AddContactsToGroupState createState() => new _AddContactsToGroupState();
}

class _AddContactsToGroupState extends State<AddContactsToGroup>
    with AutomaticKeepAliveClientMixin {
  GlobalKey<ScaffoldState> _scaffold = new GlobalKey<ScaffoldState>();
  Map<String?, String?>? contacts;
  List<LocalUserData> _selectedList = [];
  List<String> targetUserNotificationTokens = [];
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _filter = new TextEditingController();
  final TextEditingController groupname = new TextEditingController();
  final TextEditingController groupdesc = new TextEditingController();
  void setStateIfMounted(f) {
    if (mounted) setState(f);
  }

  @override
  void dispose() {
    super.dispose();
    _filter.dispose();
  }

  loading() {
    return Stack(children: [
      Container(
        color: Thm.isDarktheme(widget.prefs)
            ? fiberchatCONTAINERboxColorDarkMode
            : fiberchatCONTAINERboxColorLightMode,
        child: Center(
            child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(fiberchatSECONDARYolor),
        )),
      )
    ]);
  }

  bool iscreatinggroup = false;
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return PickupLayout(
        prefs: widget.prefs,
        scaffold: Fiberchat.getNTPWrappedWidget(ScopedModel<DataModel>(
            model: widget.model!,
            child: ScopedModelDescendant<DataModel>(
                builder: (context, child, model) {
              return Consumer<SmartContactProviderWithLocalStoreData>(
                  builder: (context, contactsProvider, _child) =>
                      Consumer<List<GroupModel>>(
                          builder: (context, groupList, _child) => Scaffold(
                              key: _scaffold,
                              backgroundColor: Thm.isDarktheme(widget.prefs)
                                  ? fiberchatBACKGROUNDcolorDarkMode
                                  : fiberchatBACKGROUNDcolorLightMode,
                              appBar: AppBar(
                                elevation: 0.4,
                                leading: IconButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  icon: Icon(
                                    Icons.arrow_back,
                                    size: 24,
                                    color: pickTextColorBasedOnBgColorAdvanced(
                                        Thm.isDarktheme(widget.prefs)
                                            ? fiberchatAPPBARcolorDarkMode
                                            : fiberchatAPPBARcolorLightMode),
                                  ),
                                ),
                                backgroundColor: Thm.isDarktheme(widget.prefs)
                                    ? fiberchatAPPBARcolorDarkMode
                                    : fiberchatAPPBARcolorLightMode,
                                centerTitle: false,
                                // leadingWidth: 40,
                                title: _selectedList.length == 0
                                    ? Text(
                                        getTranslated(
                                            this.context, 'selectcontacts'),
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: pickTextColorBasedOnBgColorAdvanced(
                                              Thm.isDarktheme(widget.prefs)
                                                  ? fiberchatAPPBARcolorDarkMode
                                                  : fiberchatAPPBARcolorLightMode),
                                        ),
                                        textAlign: TextAlign.left,
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            getTranslated(
                                                this.context, 'selectcontacts'),
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                      .isDarktheme(widget.prefs)
                                                  ? fiberchatAPPBARcolorDarkMode
                                                  : fiberchatAPPBARcolorLightMode),
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                          SizedBox(
                                            height: 4,
                                          ),
                                          Text(
                                            widget.isAddingWhileCreatingGroup ==
                                                    true
                                                ? '${_selectedList.length} / ${contactsProvider.alreadyJoinedSavedUsersPhoneNameAsInServer.length}'
                                                : '${_selectedList.length} ${getTranslated(this.context, 'selected')}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                      .isDarktheme(widget.prefs)
                                                  ? fiberchatAPPBARcolorDarkMode
                                                  : fiberchatAPPBARcolorLightMode),
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                        ],
                                      ),
                                actions: <Widget>[
                                  _selectedList.length == 0
                                      ? SizedBox()
                                      : IconButton(
                                          icon: Icon(
                                            Icons.check,
                                            color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                    .isDarktheme(widget.prefs)
                                                ? fiberchatAPPBARcolorDarkMode
                                                : fiberchatAPPBARcolorLightMode),
                                          ),
                                          onPressed:
                                              widget.isAddingWhileCreatingGroup ==
                                                      true
                                                  ? () async {
                                                      groupdesc.clear();
                                                      groupname.clear();
                                                      showModalBottomSheet(
                                                          backgroundColor: Thm
                                                                  .isDarktheme(
                                                                      widget
                                                                          .prefs)
                                                              ? fiberchatDIALOGColorDarkMode
                                                              : fiberchatDIALOGColorLightMode,
                                                          isScrollControlled:
                                                              true,
                                                          context: context,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.vertical(
                                                                    top: Radius
                                                                        .circular(
                                                                            25.0)),
                                                          ),
                                                          builder: (BuildContext
                                                              context) {
                                                            // return your layout
                                                            var w =
                                                                MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width;
                                                            return Padding(
                                                              padding: EdgeInsets.only(
                                                                  bottom: MediaQuery.of(
                                                                          context)
                                                                      .viewInsets
                                                                      .bottom),
                                                              child: Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              16),
                                                                  height: MediaQuery.of(
                                                                              context)
                                                                          .size
                                                                          .height /
                                                                      2.2,
                                                                  child: Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .stretch,
                                                                      children: [
                                                                        SizedBox(
                                                                          height:
                                                                              12,
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              3,
                                                                        ),
                                                                        Padding(
                                                                          padding:
                                                                              const EdgeInsets.only(left: 8),
                                                                          child:
                                                                              Text(
                                                                            getTranslated(this.context,
                                                                                'setgroup'),
                                                                            textAlign:
                                                                                TextAlign.left,
                                                                            style: TextStyle(
                                                                                color: pickTextColorBasedOnBgColorAdvanced(Thm.isDarktheme(widget.prefs) ? fiberchatDIALOGColorDarkMode : fiberchatDIALOGColorLightMode),
                                                                                fontWeight: FontWeight.bold,
                                                                                fontSize: 16.5),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              10,
                                                                        ),
                                                                        Container(
                                                                          margin:
                                                                              EdgeInsets.only(top: 10),
                                                                          padding: EdgeInsets.fromLTRB(
                                                                              0,
                                                                              0,
                                                                              0,
                                                                              0),
                                                                          // height: 63,
                                                                          height:
                                                                              83,
                                                                          width:
                                                                              w / 1.24,
                                                                          child:
                                                                              InpuTextBox(
                                                                            isDark:
                                                                                Thm.isDarktheme(widget.prefs),
                                                                            controller:
                                                                                groupname,
                                                                            leftrightmargin:
                                                                                0,
                                                                            showIconboundary:
                                                                                false,
                                                                            boxcornerradius:
                                                                                5.5,
                                                                            boxheight:
                                                                                50,
                                                                            hinttext:
                                                                                getTranslated(this.context, 'groupname'),
                                                                            prefixIconbutton:
                                                                                Icon(
                                                                              Icons.edit,
                                                                              color: Colors.grey.withOpacity(0.5),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        Container(
                                                                          margin:
                                                                              EdgeInsets.only(top: 10),
                                                                          padding: EdgeInsets.fromLTRB(
                                                                              0,
                                                                              0,
                                                                              0,
                                                                              0),
                                                                          // height: 63,
                                                                          height:
                                                                              83,
                                                                          width:
                                                                              w / 1.24,
                                                                          child:
                                                                              InpuTextBox(
                                                                            isDark:
                                                                                Thm.isDarktheme(widget.prefs),
                                                                            maxLines:
                                                                                1,
                                                                            controller:
                                                                                groupdesc,
                                                                            leftrightmargin:
                                                                                0,
                                                                            showIconboundary:
                                                                                false,
                                                                            boxcornerradius:
                                                                                5.5,
                                                                            boxheight:
                                                                                50,
                                                                            hinttext:
                                                                                getTranslated(this.context, 'groupdesc'),
                                                                            prefixIconbutton:
                                                                                Icon(
                                                                              Icons.message,
                                                                              color: Colors.grey.withOpacity(0.5),
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              6,
                                                                        ),
                                                                        myElevatedButton(
                                                                            color:
                                                                                fiberchatSECONDARYolor,
                                                                            child:
                                                                                Padding(
                                                                              padding: const EdgeInsets.fromLTRB(10, 15, 10, 15),
                                                                              child: Text(
                                                                                getTranslated(this.context, 'creategroup'),
                                                                                style: TextStyle(color: Colors.white, fontSize: 18),
                                                                              ),
                                                                            ),
                                                                            onPressed:
                                                                                () async {
                                                                              Navigator.of(_scaffold.currentContext!).pop();
                                                                              List<String> listusers = [];
                                                                              List<String> listmembers = [];

                                                                              for (var element in _selectedList) {
                                                                                await contactsProvider.fetchFromFiretsoreAndReturnData(widget.prefs, element.id, (peerDoc) async {
                                                                                  listusers.add(element.id);
                                                                                  listmembers.add(element.id);
                                                                                  if (peerDoc.data()![Dbkeys.notificationTokens] != null) {
                                                                                    if (peerDoc.data()![Dbkeys.notificationTokens].length > 0) {
                                                                                      targetUserNotificationTokens.add(peerDoc.data()![Dbkeys.notificationTokens].last);
                                                                                    }
                                                                                  }
                                                                                });
                                                                              }
                                                                              listmembers.add(widget.currentUserNo!);
                                                                              if (widget.model!.currentUser![Dbkeys.notificationTokens].last != null) {
                                                                                targetUserNotificationTokens.add(widget.model!.currentUser![Dbkeys.notificationTokens].last);
                                                                              }

                                                                              DateTime time = DateTime.now();
                                                                              DateTime time2 = DateTime.now().add(Duration(seconds: 1));
                                                                              String groupID = '${widget.currentUserNo!.toString()}--${time.millisecondsSinceEpoch.toString()}';
                                                                              Map<String, dynamic> groupdata = {
                                                                                Dbkeys.groupDESCRIPTION: groupdesc.text.isEmpty ? '' : groupdesc.text.trim(),
                                                                                Dbkeys.groupCREATEDON: time,
                                                                                Dbkeys.groupCREATEDBY: widget.currentUserNo,
                                                                                Dbkeys.groupNAME: groupname.text.isEmpty ? 'Unnamed Group' : groupname.text.trim(),
                                                                                Dbkeys.groupIDfiltered: groupID.replaceAll(RegExp('-'), '').substring(1, groupID.replaceAll(RegExp('-'), '').toString().length),
                                                                                Dbkeys.groupISTYPINGUSERID: '',
                                                                                Dbkeys.groupADMINLIST: [
                                                                                  widget.currentUserNo
                                                                                ],
                                                                                Dbkeys.groupID: groupID,
                                                                                Dbkeys.groupPHOTOURL: null,
                                                                                Dbkeys.groupMEMBERSLIST: listmembers,
                                                                                Dbkeys.groupLATESTMESSAGETIME: time.millisecondsSinceEpoch,
                                                                                Dbkeys.groupTYPE: Dbkeys.groupTYPEallusersmessageallowed,
                                                                              };

                                                                              listmembers.forEach((element) {
                                                                                groupdata.putIfAbsent(element.toString(), () => time.millisecondsSinceEpoch);

                                                                                groupdata.putIfAbsent('$element-joinedOn', () => time.millisecondsSinceEpoch);
                                                                              });
                                                                              setStateIfMounted(() {
                                                                                iscreatinggroup = true;
                                                                              });
                                                                              await FirebaseFirestore.instance.collection(DbPaths.collectiongroups).doc(widget.currentUserNo!.toString() + '--' + time.millisecondsSinceEpoch.toString()).set(groupdata).then((value) async {
                                                                                await FirebaseFirestore.instance.collection(DbPaths.collectiongroups).doc(widget.currentUserNo!.toString() + '--' + time.millisecondsSinceEpoch.toString()).collection(DbPaths.collectiongroupChats).doc(time.millisecondsSinceEpoch.toString() + '--' + widget.currentUserNo!.toString()).set({
                                                                                  Dbkeys.groupmsgCONTENT: '',
                                                                                  Dbkeys.groupmsgLISToptional: listusers,
                                                                                  Dbkeys.groupmsgTIME: time.millisecondsSinceEpoch,
                                                                                  Dbkeys.groupmsgSENDBY: widget.currentUserNo,
                                                                                  Dbkeys.groupmsgISDELETED: false,
                                                                                  Dbkeys.groupmsgTYPE: Dbkeys.groupmsgTYPEnotificationCreatedGroup,
                                                                                }).then((value) async {
                                                                                  await FirebaseFirestore.instance.collection(DbPaths.collectiongroups).doc(widget.currentUserNo!.toString() + '--' + time.millisecondsSinceEpoch.toString()).collection(DbPaths.collectiongroupChats).doc(time2.millisecondsSinceEpoch.toString() + '--' + widget.currentUserNo!.toString()).set({
                                                                                    Dbkeys.groupmsgCONTENT: '',
                                                                                    Dbkeys.groupmsgLISToptional: listmembers,
                                                                                    Dbkeys.groupmsgTIME: time2.millisecondsSinceEpoch,
                                                                                    Dbkeys.groupmsgSENDBY: widget.currentUserNo,
                                                                                    Dbkeys.groupmsgISDELETED: false,
                                                                                    Dbkeys.groupmsgTYPE: Dbkeys.groupmsgTYPEnotificationAddedUser,
                                                                                  }).then((val) async {
                                                                                    await FirebaseFirestore.instance.collection(DbPaths.collectiontemptokensforunsubscribe).doc(groupID).set({
                                                                                      Dbkeys.groupIDfiltered: '${groupID.replaceAll(RegExp('-'), '').substring(1, groupID.replaceAll(RegExp('-'), '').toString().length)}',
                                                                                      Dbkeys.notificationTokens: targetUserNotificationTokens,
                                                                                      'type': 'subscribe'
                                                                                    });
                                                                                  }).then((value) async {
                                                                                    Navigator.of(_scaffold.currentContext!).pop();
                                                                                  }).catchError((err) {
                                                                                    setStateIfMounted(() {
                                                                                      iscreatinggroup = false;
                                                                                    });

                                                                                    Fiberchat.toast('Error Creating group. $err');
                                                                                    debugPrint('Error Creating group: $err');
                                                                                  });
                                                                                });
                                                                              });
                                                                            }),
                                                                      ])),
                                                            );
                                                          });
                                                    }
                                                  : () async {
                                                      // List<String> listusers = [];
                                                      List<String> listmembers =
                                                          [];
                                                      for (var element
                                                          in _selectedList) {
                                                        await contactsProvider
                                                            .fetchFromFiretsoreAndReturnData(
                                                                widget.prefs,
                                                                element.id,
                                                                (peerDoc) async {
                                                          listmembers
                                                              .add(element.id);
                                                          if (peerDoc.data()![Dbkeys
                                                                  .notificationTokens] !=
                                                              null) {
                                                            if (peerDoc
                                                                    .data()![Dbkeys
                                                                        .notificationTokens]
                                                                    .length >
                                                                0) {
                                                              targetUserNotificationTokens
                                                                  .add(peerDoc
                                                                      .data()![
                                                                          Dbkeys
                                                                              .notificationTokens]
                                                                      .last);
                                                            }
                                                          }
                                                        });
                                                      }
                                                      DateTime time =
                                                          DateTime.now();

                                                      setStateIfMounted(() {
                                                        iscreatinggroup = true;
                                                      });

                                                      Map<String, dynamic>
                                                          docmap = {
                                                        Dbkeys.groupMEMBERSLIST:
                                                            FieldValue
                                                                .arrayUnion(
                                                                    listmembers)
                                                      };

                                                      _selectedList.forEach(
                                                          (element) async {
                                                        docmap.putIfAbsent(
                                                            '${element.id}-joinedOn',
                                                            () => time
                                                                .millisecondsSinceEpoch);
                                                        docmap.putIfAbsent(
                                                            '${element.id}',
                                                            () => time
                                                                .millisecondsSinceEpoch);
                                                      });
                                                      setStateIfMounted(() {});
                                                      try {
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(DbPaths
                                                                .collectiontemptokensforunsubscribe)
                                                            .doc(widget.groupID)
                                                            .delete();
                                                      } catch (err) {}
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(DbPaths
                                                              .collectiongroups)
                                                          .doc(widget.groupID)
                                                          .update(docmap)
                                                          .then((value) async {
                                                        await FirebaseFirestore
                                                            .instance
                                                            .collection(DbPaths
                                                                .collectiongroups)
                                                            .doc(widget.groupID)
                                                            .collection(DbPaths
                                                                .collectiongroupChats)
                                                            .doc(widget.groupID)
                                                            .set({
                                                          Dbkeys.groupmsgCONTENT:
                                                              '',
                                                          Dbkeys.groupmsgLISToptional:
                                                              listmembers,
                                                          Dbkeys.groupmsgTIME: time
                                                              .millisecondsSinceEpoch,
                                                          Dbkeys.groupmsgSENDBY:
                                                              widget
                                                                  .currentUserNo,
                                                          Dbkeys.groupmsgISDELETED:
                                                              false,
                                                          Dbkeys.groupmsgTYPE:
                                                              Dbkeys
                                                                  .groupmsgTYPEnotificationAddedUser,
                                                        }).then((v) async {
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(DbPaths
                                                                  .collectiontemptokensforunsubscribe)
                                                              .doc(widget
                                                                  .groupID)
                                                              .set({
                                                            Dbkeys.groupIDfiltered:
                                                                '${widget.groupID!.replaceAll(RegExp('-'), '').substring(1, widget.groupID!.replaceAll(RegExp('-'), '').toString().length)}',
                                                            Dbkeys.notificationTokens:
                                                                targetUserNotificationTokens,
                                                            'type': 'subscribe'
                                                          });
                                                        }).then((value) async {
                                                          Navigator.of(context)
                                                              .pop();
                                                        }).catchError((err) {
                                                          setStateIfMounted(() {
                                                            iscreatinggroup =
                                                                false;
                                                          });

                                                          Fiberchat.toast(
                                                              getTranslated(
                                                                  this.context,
                                                                  'errorcreatinggroup'));
                                                        });
                                                      });
                                                    },
                                        )
                                ],
                              ),
                              bottomSheet: contactsProvider
                                              .searchingcontactsindatabase ==
                                          true ||
                                      iscreatinggroup == true ||
                                      _selectedList.length == 0
                                  ? SizedBox(
                                      height: 0,
                                      width: 0,
                                    )
                                  : Container(
                                      color: Thm.isDarktheme(widget.prefs)
                                          ? fiberchatDIALOGColorDarkMode
                                          : fiberchatDIALOGColorLightMode,
                                      padding: EdgeInsets.only(top: 6),
                                      width: MediaQuery.of(context).size.width,
                                      height: 94,
                                      child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _selectedList.reversed
                                              .toList()
                                              .length,
                                          itemBuilder: (context, int i) {
                                            return Stack(
                                              children: [
                                                Container(
                                                  width: 90,
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          11, 10, 12, 10),
                                                  child: Column(
                                                    children: [
                                                      customCircleAvatar(
                                                          url: _selectedList
                                                              .reversed
                                                              .toList()[i]
                                                              .photoURL,
                                                          radius: 20),
                                                      SizedBox(
                                                        height: 7,
                                                      ),
                                                      Text(
                                                        _selectedList.reversed
                                                            .toList()[i]
                                                            .name,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: pickTextColorBasedOnBgColorAdvanced(Thm
                                                                  .isDarktheme(
                                                                      widget
                                                                          .prefs)
                                                              ? fiberchatCONTAINERboxColorDarkMode
                                                              : fiberchatCONTAINERboxColorLightMode),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 17,
                                                  top: 5,
                                                  child: new InkWell(
                                                    onTap: () {
                                                      setStateIfMounted(() {
                                                        _selectedList
                                                            .removeAt(i);
                                                      });
                                                    },
                                                    child: new Container(
                                                      width: 20.0,
                                                      height: 20.0,
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2.0),
                                                      decoration:
                                                          new BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.black,
                                                      ),
                                                      child: Icon(
                                                        Icons.close,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                    ), //............
                                                  ),
                                                )
                                              ],
                                            );
                                          }),
                                    ),
                              body: RefreshIndicator(
                                  onRefresh: () {
                                    return contactsProvider.fetchContacts(
                                        context,
                                        model,
                                        widget.currentUserNo!,
                                        widget.prefs,
                                        false);
                                  },
                                  child: contactsProvider
                                                  .searchingcontactsindatabase ==
                                              true ||
                                          iscreatinggroup == true
                                      ? loading()
                                      : contactsProvider
                                                  .alreadyJoinedSavedUsersPhoneNameAsInServer
                                                  .length ==
                                              0
                                          ? ListView(
                                              shrinkWrap: true,
                                              children: [
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          top: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .height /
                                                              2.5),
                                                      child: Center(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .center,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                                getTranslated(
                                                                    context,
                                                                    'nocontacts'),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 18,
                                                                  color:
                                                                      fiberchatGrey,
                                                                )),
                                                            SizedBox(
                                                              height: 40,
                                                            ),
                                                            IconButton(
                                                                onPressed:
                                                                    () async {
                                                                  contactsProvider
                                                                      .setIsLoading(
                                                                          true);
                                                                  await contactsProvider
                                                                      .fetchContacts(
                                                                    context,
                                                                    model,
                                                                    widget
                                                                        .currentUserNo!,
                                                                    widget
                                                                        .prefs,
                                                                    true,
                                                                    isRequestAgain:
                                                                        true,
                                                                  )
                                                                      .then(
                                                                          (d) {
                                                                    Future.delayed(
                                                                        const Duration(
                                                                            milliseconds:
                                                                                500),
                                                                        () {
                                                                      contactsProvider
                                                                          .setIsLoading(
                                                                              false);
                                                                    });
                                                                  });
                                                                  setState(
                                                                      () {});
                                                                },
                                                                icon: Icon(
                                                                  Icons
                                                                      .refresh_rounded,
                                                                  size: 40,
                                                                  color:
                                                                      fiberchatPRIMARYcolor,
                                                                ))
                                                          ],
                                                        ),
                                                      ))
                                                ])
                                          : Padding(
                                              padding: EdgeInsets.only(
                                                  bottom:
                                                      _selectedList.length == 0
                                                          ? 0
                                                          : 80),
                                              child: Stack(
                                                children: [
                                                  FutureBuilder(
                                                      future: Future.delayed(
                                                          Duration(seconds: 2)),
                                                      builder: (c, s) =>
                                                          s.connectionState ==
                                                                  ConnectionState
                                                                      .done
                                                              ? Container(
                                                                  alignment:
                                                                      Alignment
                                                                          .topCenter,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        EdgeInsets.all(
                                                                            30),
                                                                    child: Card(
                                                                      elevation:
                                                                          0.5,
                                                                      color: Colors
                                                                              .grey[
                                                                          100],
                                                                      child: Container(
                                                                          padding: EdgeInsets.fromLTRB(8, 10, 8, 10),
                                                                          child: RichText(
                                                                            textAlign:
                                                                                TextAlign.center,
                                                                            text:
                                                                                TextSpan(
                                                                              children: [
                                                                                WidgetSpan(
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.only(bottom: 2.5, right: 4),
                                                                                    child: Icon(
                                                                                      Icons.contact_page,
                                                                                      color: fiberchatPRIMARYcolor.withOpacity(0.7),
                                                                                      size: 14,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                TextSpan(
                                                                                    text: getTranslated(this.context, 'nosavedcontacts'),
                                                                                    // text:
                                                                                    //     'No Saved Contacts available for this task',
                                                                                    style: TextStyle(color: fiberchatPRIMARYcolor.withOpacity(0.7), height: 1.3, fontSize: 13, fontWeight: FontWeight.w400)),
                                                                              ],
                                                                            ),
                                                                          )),
                                                                    ),
                                                                  ),
                                                                )
                                                              : Container(
                                                                  alignment:
                                                                      Alignment
                                                                          .topCenter,
                                                                  child: Padding(
                                                                      padding: EdgeInsets.all(30),
                                                                      child: CircularProgressIndicator(
                                                                        valueColor:
                                                                            AlwaysStoppedAnimation<Color>(fiberchatSECONDARYolor),
                                                                      )),
                                                                )),
                                                  Container(
                                                    color: Thm.isDarktheme(
                                                            widget.prefs)
                                                        ? fiberchatCONTAINERboxColorDarkMode
                                                        : fiberchatCONTAINERboxColorLightMode,
                                                    child: ListView.builder(
                                                      physics:
                                                          AlwaysScrollableScrollPhysics(),
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      itemCount: contactsProvider
                                                          .alreadyJoinedSavedUsersPhoneNameAsInServer
                                                          .length,
                                                      itemBuilder:
                                                          (context, idx) {
                                                        String phone =
                                                            contactsProvider
                                                                .alreadyJoinedSavedUsersPhoneNameAsInServer[
                                                                    idx]
                                                                .phone;
                                                        Widget? alreadyAddedUser = widget
                                                                    .isAddingWhileCreatingGroup ==
                                                                true
                                                            ? null
                                                            : groupList
                                                                        .lastWhere((element) =>
                                                                            element.docmap[Dbkeys.groupID] ==
                                                                            widget
                                                                                .groupID)
                                                                        .docmap[Dbkeys
                                                                            .groupMEMBERSLIST]
                                                                        .contains(
                                                                            phone) ||
                                                                    groupList
                                                                        .lastWhere((element) =>
                                                                            element.docmap[Dbkeys.groupID] ==
                                                                            widget
                                                                                .groupID)
                                                                        .docmap[Dbkeys
                                                                            .groupADMINLIST]
                                                                        .contains(
                                                                            phone)
                                                                ? SizedBox()
                                                                : null;
                                                        return alreadyAddedUser ??
                                                            FutureBuilder<
                                                                    LocalUserData?>(
                                                                future: contactsProvider
                                                                    .fetchUserDataFromnLocalOrServer(
                                                                        widget
                                                                            .prefs,
                                                                        phone),
                                                                builder: (BuildContext
                                                                        context,
                                                                    AsyncSnapshot<
                                                                            LocalUserData?>
                                                                        snapshot) {
                                                                  // if (snapshot
                                                                  //         .connectionState ==
                                                                  //     ConnectionState
                                                                  //         .waiting) {
                                                                  //   return Container(
                                                                  //     color: Colors
                                                                  //         .white,
                                                                  //     height: MediaQuery.of(
                                                                  //             context)
                                                                  //         .size
                                                                  //         .height,
                                                                  //     width: MediaQuery.of(
                                                                  //             context)
                                                                  //         .size
                                                                  //         .width,
                                                                  //     child: Center(
                                                                  //       child:
                                                                  //           CircularProgressIndicator(
                                                                  //         valueColor:
                                                                  //             AlwaysStoppedAnimation<Color>(
                                                                  //                 fiberchatBlue),
                                                                  //       ),
                                                                  //     ),
                                                                  //   );
                                                                  // } else
                                                                  if (snapshot
                                                                      .hasData) {
                                                                    LocalUserData
                                                                        user =
                                                                        snapshot
                                                                            .data!;
                                                                    return Container(
                                                                        color: Thm.isDarktheme(widget.prefs)
                                                                            ? fiberchatCONTAINERboxColorDarkMode
                                                                            : fiberchatCONTAINERboxColorLightMode,
                                                                        child:
                                                                            Column(
                                                                          children: [
                                                                            ListTile(
                                                                              tileColor: Thm.isDarktheme(widget.prefs) ? fiberchatCONTAINERboxColorDarkMode : fiberchatCONTAINERboxColorLightMode,
                                                                              leading: customCircleAvatar(
                                                                                url: user.photoURL,
                                                                                radius: 22.5,
                                                                              ),
                                                                              trailing: Container(
                                                                                decoration: BoxDecoration(
                                                                                  border: Border.all(color: fiberchatGrey, width: 1),
                                                                                  borderRadius: BorderRadius.circular(5),
                                                                                ),
                                                                                child: _selectedList.lastIndexWhere((element) => element.id == phone) >= 0
                                                                                    ? Icon(
                                                                                        Icons.check,
                                                                                        size: 19.0,
                                                                                        color: fiberchatPRIMARYcolor,
                                                                                      )
                                                                                    : Icon(
                                                                                        Icons.check,
                                                                                        color: Colors.transparent,
                                                                                        size: 19.0,
                                                                                      ),
                                                                              ),
                                                                              title: Text(user.name,
                                                                                  style: TextStyle(
                                                                                    color: pickTextColorBasedOnBgColorAdvanced(Thm.isDarktheme(widget.prefs) ? fiberchatCONTAINERboxColorDarkMode : fiberchatCONTAINERboxColorLightMode),
                                                                                  )),
                                                                              subtitle: Text(phone, style: TextStyle(color: fiberchatGrey)),
                                                                              contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
                                                                              onTap: () {
                                                                                if (_selectedList.indexWhere((element) => element.id == phone) >= 0) {
                                                                                  _selectedList.removeAt(_selectedList.indexWhere((element) => element.id == phone));
                                                                                  setStateIfMounted(() {});
                                                                                } else {
                                                                                  _selectedList.add(user);
                                                                                  setStateIfMounted(() {});
                                                                                }
                                                                              },
                                                                            ),
                                                                            Divider()
                                                                          ],
                                                                        ));
                                                                  }
                                                                  return SizedBox(
                                                                    height: 0,
                                                                  );
                                                                });
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )))));
            }))));
  }
}
