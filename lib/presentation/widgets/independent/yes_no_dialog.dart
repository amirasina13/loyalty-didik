import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../app_setting/app_setting.dart';
import '../widgets.dart';

/* Widget class for dialog with yes no button.  */

class YesNoDialog extends StatelessWidget {
  final String mainText;
  final String? subText;
  final Color? subTextColor;
  final TextAlign? subTextAlign;
  final Widget? nextButton;

  const YesNoDialog({
    super.key,
    required this.mainText,
    this.subText,
    this.subTextColor = colorRed,
    this.subTextAlign = TextAlign.center,
    required this.nextButton,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colorBackground,
      alignment: Alignment.center,
      height: ScreenSize.height * 0.4,
      padding: EdgeInsets.symmetric(
        vertical: 20,
        horizontal: AppDesign.spaceLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Container(
              height: ScreenSize.width * 0.2,
              width: ScreenSize.width * 0.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: mainColor,
              ),
              child: Icon(
                FontAwesomeIcons.question,
                color: colorWhite,
                size: ScreenSize.height * 0.05,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mainText,
                    style: TextStyle(
                      fontSize: AppDesign.bodySize,
                      fontWeight: FontWeight.bold,
                      color: colorBlack,
                      fontFamily: fontFamilyMain,
                    ),
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.linear(scaleFactor),
                  ),
                  SizedBox(height: subText != null ? sidePadding : 0),
                  subText != null
                      ? Text(
                        subText!,
                        style: TextStyle(
                          fontSize: AppDesign.bodySize,
                          // fontWeight: FontWeight.bold,
                          color: subTextColor,
                          fontFamily: fontFamilyMain,
                        ),
                        textAlign: subTextAlign,
                        textScaler: TextScaler.linear(scaleFactor),
                      )
                      : Container(),
                ],
              ),
            ),
          ),
          Expanded(child: nextButton!),
        ],
      ),
    );
  }

  static Future showYesNoDialog(
    BuildContext context,
    String text,
    String? subText,
    Color? subTextColor,
    TextAlign? subTextAlign,
    Widget nextButton,
  ) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          contentPadding: EdgeInsets.all(10.0),
          backgroundColor: colorWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          content: YesNoDialog(
            mainText: text,
            subText: subText,
            subTextColor: subTextColor,
            subTextAlign: subTextAlign,
            nextButton: nextButton,
          ),
        );
      },
    );
  }
}
