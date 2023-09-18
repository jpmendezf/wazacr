//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:fiberchat/Configs/app_constants.dart';
import 'package:fiberchat/Screens/calling_screen/audio_call.dart';
import 'package:fiberchat/Screens/calling_screen/video_call.dart';
import 'package:fiberchat/Utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:fiberchat/Models/call.dart';
import 'package:fiberchat/Models/call_methods.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CallUtils {
  static final CallMethods callMethods = CallMethods();

  static dial(
      {String? fromUID,
      String? fromFullname,
      String? fromDp,
      String? toFullname,
      String? toDp,
      String? toUID,
      bool? isvideocall,
      required String? currentuseruid,
      required SharedPreferences prefs,
      context}) async {
    int timeepoch = DateTime.now().millisecondsSinceEpoch;
    Map<String, dynamic>? res = await FunctionCall().makeCloudCall();
    if (res == null) {
      Fiberchat.toast("Failed to Dial Call. Please try again !");
    } else {
      Call call = Call(
          token: res['token'],
          timeepoch: timeepoch,
          callerId: fromUID,
          callerName: fromFullname,
          callerPic: fromDp,
          receiverId: toUID,
          receiverName: toFullname,
          receiverPic: toDp,
          channelId: res['channelId'],
          isvideocall: isvideocall);
      ClientRoleType _role = ClientRoleType.clientRoleBroadcaster;
      bool callMade = await callMethods.makeCall(
          call: call, isvideocall: isvideocall, timeepoch: timeepoch);

      call.hasDialled = true;
      if (isvideocall == false) {
        if (callMade) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AudioCall(
                key: Key(call.timeepoch.toString()),
                prefs: prefs,
                currentuseruid: currentuseruid,
                call: call,
                channelName: call.channelId,
                role: _role,
              ),
            ),
          );
        }
      } else {
        if (callMade) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCall(
                key: Key(call.timeepoch.toString()),
                prefs: prefs,
                currentuseruid: currentuseruid!,
                call: call,
                channelName: call.channelId!,
                role: _role,
              ),
            ),
          );
        }
      }
    }
  }
}

class FunctionCall {
  Future<Map<String, dynamic>?> makeCloudCall() async {
    try {
      HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('createCallsWithTokens');
      dynamic resp = await callable.call(
        {
          "appId": Agora_APP_ID,
          "appCertificate": Agora_Primary_Certificate,
        },
      );

      if (resp.data != null) {
        Map<String, dynamic> res = {
          'token': resp.data['data']['token'],
          'channelId': resp.data['data']['channelId'],
        };
        return res;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }
}
