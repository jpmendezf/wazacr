//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'package:fiberchat/Configs/app_constants.dart';
import 'package:flutter/material.dart';

class Splashscreen extends StatelessWidget {
  final bool? isShowOnlySpinner;

  Splashscreen({this.isShowOnlySpinner = false});
  @override
  Widget build(BuildContext context) {
    return IsSplashOnlySolidColor == true || this.isShowOnlySpinner == true
        ? Scaffold(
            backgroundColor: SplashBackgroundSolidColor,
            body: Center(
              child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(fiberchatSECONDARYolor)),
            ))
        : Scaffold(
            backgroundColor: SplashBackgroundSolidColor,
            body: Center(
                child: Image.asset(
              '$SplashPath',
              width: double.infinity,
              fit: MediaQuery.of(context).size.height >
                      MediaQuery.of(context).size.width
                  ? BoxFit.cover
                  : BoxFit.fitHeight,
              height: MediaQuery.of(context).size.height,
            )),
          );
  }
}
