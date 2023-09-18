//*************   © Copyrighted by Thinkcreative_Technologies. An Exclusive item of Envato market. Make sure you have purchased a Regular License OR Extended license for the Source Code from Envato to use this product. See the License Defination attached with source code. *********************

import 'package:fiberchat/Configs/app_constants.dart';
import 'package:flutter/material.dart';

showDynamicModalBottomSheet({
  required BuildContext context,
  required List<Widget> widgetList,
  Function(BuildContext context)? popableWidgetList,
  String? title,
  required bool isdark,
  bool? isDismissable = true,
  String? desc,
  double? height,
  bool? isextraMargin = true,
  bool isCentre = true,
  double padding = 7,
}) {
  isDismissable == false
      ? showModalBottomSheet(
          isDismissible: false,
          enableDrag: false,
          context: context,
          builder: (context) {
            return WillPopScope(
                onWillPop: () async {
                  return false;
                },
                child: Wrap(
                  children: [
                    popableWidgetList != null
                        ? Builder(
                            builder: (BuildContext popable) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                    ),
                                    title == "" || title == null
                                        ? SizedBox()
                                        : Padding(
                                            padding: EdgeInsets.all(15),
                                            child: Text(
                                              title,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: isdark
                                                    ? fiberchatWhite
                                                    : fiberchatBlack,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount:
                                          popableWidgetList(popable).length,
                                      itemBuilder: (_, index) {
                                        return popableWidgetList(
                                            popable)[index];
                                      },
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                  ],
                                ))
                        : Builder(
                            builder: (BuildContext popable) => ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: widgetList.length,
                              itemBuilder: (_, index) {
                                return widgetList[index];
                              },
                            ),
                          ),
                  ],
                ));
          })
      : showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return Builder(
                builder: (BuildContext popable) => GestureDetector(
                      onTap: () {},
                      child: Container(
                        color: Color.fromRGBO(0, 0, 0, 0.001),
                        child: GestureDetector(
                          onTap: () {},
                          child: DraggableScrollableSheet(
                            initialChildSize: height ??
                                (widgetList.length <= 2
                                    ? 0.33
                                    : widgetList.length > 7
                                        ? 0.8
                                        : (widgetList.length * 0.006) < 0.1
                                            ? 0.56
                                            : (widgetList.length * 0.006) > 0.8
                                                ? 0.85
                                                : widgetList.length * 0.006),
                            minChildSize: 0.3,
                            maxChildSize: 0.85,
                            builder: (_, controller) {
                              return Container(
                                padding: EdgeInsets.all(
                                    isextraMargin == true ? 20 : 0),
                                decoration: BoxDecoration(
                                  color: isdark
                                      ? fiberchatBACKGROUNDcolorDarkMode
                                      : fiberchatBACKGROUNDcolorLightMode,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(25.0),
                                    topRight: const Radius.circular(25.0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.remove,
                                      color: fiberchatGrey,
                                    ),
                                    title == "" || title == null
                                        ? SizedBox()
                                        : Padding(
                                            padding: EdgeInsets.all(15),
                                            child: Text(
                                              title,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: isdark
                                                    ? fiberchatWhite
                                                    : fiberchatBlack,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                    popableWidgetList != null
                                        ? Expanded(
                                            child: ListView.builder(
                                            physics: BouncingScrollPhysics(),
                                            controller: controller,
                                            itemCount:
                                                popableWidgetList(popable)
                                                    .length,
                                            itemBuilder: (_, index) {
                                              return popableWidgetList(
                                                  popable)[index];
                                            },
                                          ))
                                        : Expanded(
                                            child: ListView.builder(
                                              physics: BouncingScrollPhysics(),
                                              controller: controller,
                                              itemCount: widgetList.length,
                                              itemBuilder: (_, index) {
                                                return widgetList[index];
                                              },
                                            ),
                                          ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ));
          },
        );

  // showModalBottomSheet<dynamic>(
  //     isScrollControlled: true,
  //     context: context,
  //     builder: (BuildContext bc) {
  //       return Wrap(children: <Widget>[
  //         Container(
  //           color: Colors.white,
  //           padding: EdgeInsets.all(padding),
  //           child: Container(
  //             decoration: new BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: new BorderRadius.only(
  //                     topLeft: const Radius.circular(25.0),
  //                     topRight: const Radius.circular(25.0))),
  //             child: Column(
  //                 // mainAxisSize: MainAxisSize.max,
  //                 // mainAxisAlignment: MainAxisAlignment.start,
  //                 crossAxisAlignment: isCentre == true
  //                     ? CrossAxisAlignment.center
  //                     : CrossAxisAlignment.start,
  //                 children: widgetList),
  //           ),
  //         )
  //       ]);
  //     });
}
