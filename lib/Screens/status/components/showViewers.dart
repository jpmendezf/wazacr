//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fiberchat/Configs/Dbkeys.dart';
import 'package:fiberchat/Configs/Dbpaths.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Models/DataModel.dart';
import 'package:fiberchat/Screens/profile_settings/profile_view.dart';
import 'package:fiberchat/Screens/status/components/formatStatusTime.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Utils/color_detector.dart';
import 'package:fiberchat/Utils/theme_management.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

showViewers(BuildContext context, DocumentSnapshot myStatusDoc, var filtered,
    String currentuserno, SharedPreferences prefs, DataModel model) {
  var statusViewerList = [];
  myStatusDoc[Dbkeys.statusVIEWERLIST].forEach((phone) {
    if (!statusViewerList.contains(phone)) {
      statusViewerList.add(phone);
    }
  });

  showModalBottomSheet(
      backgroundColor: Thm.isDarktheme(prefs)
          ? fiberchatDIALOGColorDarkMode
          : fiberchatDIALOGColorLightMode,
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        // return your layout
        return Container(
            padding: EdgeInsets.all(12),
            height: MediaQuery.of(context).size.height / 1.1,
            child: ListView(
              physics: BouncingScrollPhysics(),
              shrinkWrap: true,
              children: [
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        getTranslated(context, 'viewedby'),
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: pickTextColorBasedOnBgColorAdvanced(
                              Thm.isDarktheme(prefs)
                                  ? fiberchatDIALOGColorDarkMode
                                  : fiberchatDIALOGColorLightMode),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.visibility, color: fiberchatGrey),
                        SizedBox(
                          width: 2,
                        ),
                        Text(
                          ' ${statusViewerList.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: pickTextColorBasedOnBgColorAdvanced(
                                Thm.isDarktheme(prefs)
                                    ? fiberchatDIALOGColorDarkMode
                                    : fiberchatDIALOGColorLightMode),
                          ),
                        ),
                        SizedBox(
                          width: 7,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
                SizedBox(
                  height: 10,
                ),
                Container(
                  // height: 96,
                  child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: statusViewerList.length,
                      itemBuilder: (context, int i) {
                        List viewerslist = [];
                        List viewerslistNotFinal =
                            myStatusDoc[Dbkeys.statusVIEWERLISTWITHTIME]
                                .reversed
                                .toList();
                        viewerslistNotFinal.forEach((m) {
                          if (!viewerslist.contains(m)) {
                            viewerslist.add(m);
                          }
                        });

                        return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection(DbPaths.collectionusers)
                                .doc(viewerslist[i]['phone'])
                                .get(),
                            builder: (context, AsyncSnapshot snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return ListTile(
                                  isThreeLine: false,
                                  contentPadding:
                                      EdgeInsets.fromLTRB(5, 6, 10, 6),
                                  leading: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: Container(
                                        width: 50.0,
                                        height: 50.0,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.26),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    filtered!.entries.toList().indexWhere(
                                                (element) =>
                                                    element.key ==
                                                    viewerslist[i]['phone']) >
                                            0
                                        ? filtered!.entries
                                            .elementAt(filtered!.entries
                                                .toList()
                                                .indexWhere((element) =>
                                                    element.key ==
                                                    viewerslist[i]['phone']))
                                            .value
                                            .toString()
                                        : viewerslist[i]['phone'],
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: pickTextColorBasedOnBgColorAdvanced(
                                          Thm.isDarktheme(prefs)
                                              ? fiberchatDIALOGColorDarkMode
                                              : fiberchatDIALOGColorLightMode),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    getStatusTime(
                                        viewerslist[i]['time'], context),
                                    style: TextStyle(
                                        height: 1.4, color: fiberchatGrey),
                                  ),
                                );
                              } else if (snapshot.hasData &&
                                  snapshot.data.exists) {
                                return ListTile(
                                  onTap: () {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      new MaterialPageRoute(
                                          builder: (context) => new ProfileView(
                                                snapshot.data!.data(),
                                                currentuserno,
                                                model,
                                                prefs,
                                                [],
                                                firestoreUserDoc: snapshot.data,
                                              )),
                                    );
                                  },
                                  contentPadding:
                                      EdgeInsets.fromLTRB(5, 6, 10, 6),
                                  leading: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Padding(
                                      padding: const EdgeInsets.all(3.0),
                                      child: snapshot.data[Dbkeys.photoUrl] ==
                                              null
                                          ? Container(
                                              width: 50.0,
                                              height: 50.0,
                                              child: Icon(Icons.person),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                shape: BoxShape.circle,
                                              ),
                                            )
                                          : CachedNetworkImage(
                                              imageUrl: snapshot
                                                      .data[Dbkeys.photoUrl] ??
                                                  '',
                                              imageBuilder:
                                                  (context, imageProvider) =>
                                                      Container(
                                                width: 50.0,
                                                height: 50.0,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                      image: imageProvider,
                                                      fit: BoxFit.cover),
                                                ),
                                              ),
                                              placeholder: (context, url) =>
                                                  Container(
                                                width: 50.0,
                                                height: 50.0,
                                                child: Icon(Icons.person),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                width: 50.0,
                                                height: 50.0,
                                                child: Icon(Icons.person),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[300],
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  title: Text(
                                    filtered!.entries.toList().indexWhere(
                                                (element) =>
                                                    element.key ==
                                                    viewerslist[i]['phone']) >
                                            0
                                        ? filtered!.entries
                                            .elementAt(filtered!.entries
                                                .toList()
                                                .indexWhere((element) =>
                                                    element.key ==
                                                    viewerslist[i]['phone']))
                                            .value
                                            .toString()
                                        : snapshot.data[Dbkeys.nickname],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: pickTextColorBasedOnBgColorAdvanced(
                                          Thm.isDarktheme(prefs)
                                              ? fiberchatDIALOGColorDarkMode
                                              : fiberchatDIALOGColorLightMode),
                                    ),
                                  ),
                                  subtitle: Text(
                                    getStatusTime(
                                        viewerslist[i]['time'], context),
                                    style: TextStyle(
                                        height: 1.4, color: fiberchatGrey),
                                  ),
                                );
                              }
                              return ListTile(
                                contentPadding:
                                    EdgeInsets.fromLTRB(5, 6, 10, 6),
                                leading: Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Container(
                                      width: 50.0,
                                      height: 50.0,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.26),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Text(
                                  filtered!.entries.toList().indexWhere(
                                              (element) =>
                                                  element.key ==
                                                  viewerslist[i]['phone']) >
                                          0
                                      ? filtered!.entries
                                          .elementAt(filtered!.entries
                                              .toList()
                                              .indexWhere((element) =>
                                                  element.key ==
                                                  viewerslist[i]['phone']))
                                          .value
                                          .toString()
                                      : viewerslist[i]['phone'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: pickTextColorBasedOnBgColorAdvanced(
                                        Thm.isDarktheme(prefs)
                                            ? fiberchatDIALOGColorDarkMode
                                            : fiberchatDIALOGColorLightMode),
                                  ),
                                ),
                                subtitle: Text(
                                  getStatusTime(
                                      viewerslist[i]['time'], context),
                                  style: TextStyle(
                                      height: 1.4, color: fiberchatGrey),
                                ),
                              );
                            });
                      }),
                ),
              ],
            ));
      });
}
