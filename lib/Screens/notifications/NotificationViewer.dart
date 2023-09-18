//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Utils/color_detector.dart';
import 'package:fiberchat/Utils/custom_url_launcher.dart';
import 'package:fiberchat/Utils/theme_management.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:shared_preferences/shared_preferences.dart';

void notificationViwer(BuildContext context, String? desc, String? title,
    String? imageurl, String? timeString, SharedPreferences prefs) {
  var h = MediaQuery.of(context).size.height;
  var w = MediaQuery.of(context).size.width;
  showModalBottomSheet(
      backgroundColor: Thm.isDarktheme(prefs)
          ? fiberchatDIALOGColorDarkMode
          : fiberchatDIALOGColorLightMode,
      isScrollControlled: true,
      context: context,
      builder: (builder) {
        return new Container(
          margin: EdgeInsets.only(top: 0),
          height: h > w ? h / 1.3 : w / 1.2,
          color: Colors.transparent,
          child: new Container(
              decoration: new BoxDecoration(
                  color: Thm.isDarktheme(prefs)
                      ? fiberchatDIALOGColorDarkMode
                      : fiberchatDIALOGColorLightMode,
                  borderRadius: new BorderRadius.only(
                      topLeft: const Radius.circular(10.0),
                      topRight: const Radius.circular(10.0))),
              child: SingleChildScrollView(
                  child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          timeString!,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            fontSize: 13.9,
                            color: fiberchatGrey,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Icon(
                            Icons.close_rounded,
                            color: fiberchatGrey,
                          ),
                          alignment: Alignment.centerRight,
                        ),
                      ],
                    ),
                    // Divider(),
                    SizedBox(height: 10),
                    imageurl == null
                        ? SizedBox(
                            height: 0,
                          )
                        : Align(
                            alignment: Alignment.center,
                            child: Image.network(
                              imageurl,
                              height: (w * 0.62),
                              width: w,
                              fit: BoxFit.contain,
                            ),
                          ),
                    SizedBox(height: 30),
                    SelectableText(
                      title ?? '',
                      textAlign: TextAlign.left,
                      style: TextStyle(
                          fontSize: 19,
                          color: pickTextColorBasedOnBgColorAdvanced(
                              Thm.isDarktheme(prefs)
                                  ? fiberchatDIALOGColorDarkMode
                                  : fiberchatDIALOGColorLightMode),
                          fontWeight: FontWeight.w800),
                    ),

                    Divider(),
                    SizedBox(height: 10),
                    SelectableLinkify(
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: pickTextColorBasedOnBgColorAdvanced(
                                Thm.isDarktheme(prefs)
                                    ? fiberchatDIALOGColorDarkMode
                                    : fiberchatDIALOGColorLightMode)
                            .withOpacity(0.7),
                      ),
                      text: desc ?? "",
                      onOpen: (link) async {
                        custom_url_launcher(link.url);
                      },
                    ),
                  ],
                ),
              ))),
        );
      });
}
