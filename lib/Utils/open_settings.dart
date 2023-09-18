//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Services/localization/language_constants.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:fiberchat/main.dart';
import 'package:fiberchat/widgets/MyElevatedButton/MyElevatedButton.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OpenSettings extends StatefulWidget {
  final String? permtype;
  final SharedPreferences? prefs;
  OpenSettings({
    this.permtype = 'other',
    this.prefs,
  });
  @override
  State<OpenSettings> createState() => _OpenSettingsState();
}

class _OpenSettingsState extends State<OpenSettings> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Fiberchat.getNTPWrappedWidget(Material(
        color: fiberchatPRIMARYcolor,
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contact_page,
              color: Colors.white60,
              size: 100,
            ),
            Padding(
              padding: EdgeInsets.all(30),
              child: Text(
                widget.permtype == 'contact'
                    ? "Allow Contact Access"
                    : getTranslated(this.context, "settingsexplanation"),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(30),
              child: Text(
                widget.permtype == 'contact'
                    ? "This app to requires Contacts access to show you Friends available to Chat & Call with.  "
                    : getTranslated(this.context, "settingssteps"),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: myElevatedButton(
                    color: fiberchatSECONDARYolor,
                    onPressed: () {
                      openAppSettings();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "Manage Permission",
                        style: TextStyle(color: fiberchatWhite),
                      ),
                    ))),
            if (widget.permtype == 'contact')
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
                  child: myElevatedButton(
                      color: fiberchatWhite,
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushAndRemoveUntil(
                          // the new route
                          MaterialPageRoute(
                            builder: (BuildContext context) =>
                                FiberchatWrapper(),
                          ),

                          (Route route) => false,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Back",
                          style: TextStyle(color: fiberchatBlack),
                        ),
                      ))),
            SizedBox(height: 20),
            if (widget.permtype == 'contact')
              Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  "If you do not wish to allow Contact permission, you may uninstall the app ",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ),
          ],
        ))));
  }
}
